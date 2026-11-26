/*
 * q5-sheet — Planilha de cálculo CLI/TUI nativa em C11 + ncursesw
 * Projetada para o BerryCore no BlackBerry Q5 (tela 720x720, teclado físico QWERTY).
 * Zero dependências de Python ou runtimes externos; usa apenas libc, libm e libncursesw.
 *
 * Uso:
 *   q5-sheet [arquivo.csv]          Abre a interface TUI (cria novo se não existir)
 *   q5-sheet --eval <arquivo.csv>   Modo batch: recalcula fórmulas e imprime tabela no stdout
 *   q5-sheet --csv <arquivo.csv>    Modo batch: recalcula fórmulas e exporta valores em CSV
 */

#include <ctype.h>
#include <errno.h>
#include <math.h>
#ifndef Q5_BATCH_ONLY
#include <ncurses.h>
#endif
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_ROWS 100
#define MAX_COLS 26
#define MAX_TEXT 128
#define MAX_PATH 512

typedef enum {
    CELL_EMPTY = 0,
    CELL_NUMBER,
    CELL_TEXT,
    CELL_FORMULA
} CellType;

typedef enum {
    ERR_NONE = 0,
    ERR_SYNTAX,
    ERR_DIV0,
    ERR_CIRC,
    ERR_REF
} EvalErr;

typedef struct {
    char raw[MAX_TEXT];
    CellType type;
    double value;
    EvalErr err;
    int eval_state; /* 0 = unvisited, 1 = visiting (cycle), 2 = done */
} Cell;

typedef struct {
    Cell cells[MAX_ROWS][MAX_COLS];
    char filename[MAX_PATH];
    bool modified;
    int col_width;
} Sheet;

/* =========================================================================
 * Parser e Avaliador de Fórmulas (Descida Recursiva + Detecção de Ciclos)
 * ========================================================================= */

typedef struct {
    Sheet *sheet;
    const char *p;
    EvalErr err;
} Parser;

static double eval_cell(Sheet *s, int r, int c, EvalErr *out_err);
static double parse_expr(Parser *ps);

static void skip_ws(Parser *ps) {
    while (*ps->p && isspace((unsigned char)*ps->p)) {
        ps->p++;
    }
}

static bool parse_cell_ref_str(const char *s, int *out_r, int *out_c, const char **endp) {
    if (!isalpha((unsigned char)s[0])) return false;
    int col = toupper((unsigned char)s[0]) - 'A';
    if (col < 0 || col >= MAX_COLS) return false;
    if (!isdigit((unsigned char)s[1])) return false;
    char *ep = NULL;
    long row = strtol(s + 1, &ep, 10);
    if (ep == s + 1 || row < 1 || row > MAX_ROWS) return false;
    *out_r = (int)(row - 1);
    *out_c = col;
    if (endp) *endp = ep;
    return true;
}

static double eval_range_func(Parser *ps, const char *fname) {
    skip_ws(ps);
    if (*ps->p != '(') {
        ps->err = ERR_SYNTAX;
        return 0.0;
    }
    ps->p++;
    skip_ws(ps);

    int r1 = 0, c1 = 0, r2 = 0, c2 = 0;
    const char *next = NULL;

    /* Funções de argumento único (ABS, SQRT, ROUND) */
    if (strcmp(fname, "ABS") == 0 || strcmp(fname, "SQRT") == 0 || strcmp(fname, "ROUND") == 0) {
        double v = parse_expr(ps);
        skip_ws(ps);
        if (*ps->p != ')') {
            ps->err = ERR_SYNTAX;
            return 0.0;
        }
        ps->p++;
        if (ps->err != ERR_NONE) return 0.0;
        if (strcmp(fname, "ABS") == 0) return fabs(v);
        if (strcmp(fname, "ROUND") == 0) return floor(v + 0.5);
        if (v < 0.0) {
            ps->err = ERR_DIV0;
            return 0.0;
        }
        return sqrt(v);
    }

    /* Funções de intervalo: SUM, AVG, MIN, MAX, COUNT */
    if (!parse_cell_ref_str(ps->p, &r1, &c1, &next)) {
        ps->err = ERR_REF;
        return 0.0;
    }
    ps->p = next;
    skip_ws(ps);

    if (*ps->p == ':') {
        ps->p++;
        skip_ws(ps);
        if (!parse_cell_ref_str(ps->p, &r2, &c2, &next)) {
            ps->err = ERR_REF;
            return 0.0;
        }
        ps->p = next;
    } else {
        r2 = r1;
        c2 = c1;
    }
    skip_ws(ps);
    if (*ps->p != ')') {
        ps->err = ERR_SYNTAX;
        return 0.0;
    }
    ps->p++;

    if (r1 > r2) { int t = r1; r1 = r2; r2 = t; }
    if (c1 > c2) { int t = c1; c1 = c2; c2 = t; }

    double sum = 0.0;
    double mn = 0.0, mx = 0.0;
    int count = 0;

    for (int r = r1; r <= r2; r++) {
        for (int c = c1; c <= c2; c++) {
            Cell *cell = &ps->sheet->cells[r][c];
            if (cell->type == CELL_EMPTY || cell->type == CELL_TEXT) continue;
            EvalErr ce = ERR_NONE;
            double v = eval_cell(ps->sheet, r, c, &ce);
            if (ce != ERR_NONE) {
                ps->err = ce;
                return 0.0;
            }
            if (count == 0) {
                mn = mx = v;
            } else {
                if (v < mn) mn = v;
                if (v > mx) mx = v;
            }
            sum += v;
            count++;
        }
    }

    if (strcmp(fname, "SUM") == 0) return sum;
    if (strcmp(fname, "COUNT") == 0) return (double)count;
    if (strcmp(fname, "AVG") == 0) return count > 0 ? sum / (double)count : 0.0;
    if (strcmp(fname, "MIN") == 0) return count > 0 ? mn : 0.0;
    if (strcmp(fname, "MAX") == 0) return count > 0 ? mx : 0.0;

    ps->err = ERR_SYNTAX;
    return 0.0;
}

static double parse_primary(Parser *ps) {
    skip_ws(ps);
    if (ps->err != ERR_NONE) return 0.0;

    if (*ps->p == '(') {
        ps->p++;
        double v = parse_expr(ps);
        skip_ws(ps);
        if (*ps->p != ')') {
            ps->err = ERR_SYNTAX;
            return 0.0;
        }
        ps->p++;
        return v;
    }

    if (*ps->p == '+' || *ps->p == '-') {
        char op = *ps->p++;
        double v = parse_primary(ps);
        return (op == '-') ? -v : v;
    }

    if (isdigit((unsigned char)*ps->p) || *ps->p == '.') {
        char *ep = NULL;
        double v = strtod(ps->p, &ep);
        if (ep == ps->p) {
            ps->err = ERR_SYNTAX;
            return 0.0;
        }
        ps->p = ep;
        return v;
    }

    if (isalpha((unsigned char)*ps->p)) {
        /* Verifica primeiro se é função (letras seguidas de '(') */
        const char *q = ps->p;
        char ident[16];
        size_t len = 0;
        while (isalpha((unsigned char)*q) && len < sizeof(ident) - 1) {
            ident[len++] = (char)toupper((unsigned char)*q++);
        }
        ident[len] = '\0';
        const char *after_ident = q;
        while (*after_ident && isspace((unsigned char)*after_ident)) after_ident++;

        if (*after_ident == '(' && len >= 2) {
            ps->p = after_ident;
            return eval_range_func(ps, ident);
        }

        /* Caso contrário, tenta referência de célula (ex.: B2) */
        int r = 0, c = 0;
        const char *next = NULL;
        if (parse_cell_ref_str(ps->p, &r, &c, &next)) {
            ps->p = next;
            EvalErr ce = ERR_NONE;
            double v = eval_cell(ps->sheet, r, c, &ce);
            if (ce != ERR_NONE) {
                ps->err = ce;
                return 0.0;
            }
            return v;
        }
    }

    ps->err = ERR_SYNTAX;
    return 0.0;
}

static double parse_term(Parser *ps) {
    double left = parse_primary(ps);
    while (ps->err == ERR_NONE) {
        skip_ws(ps);
        if (*ps->p == '*' || *ps->p == '/') {
            char op = *ps->p++;
            double right = parse_primary(ps);
            if (ps->err != ERR_NONE) return 0.0;
            if (op == '*') {
                left *= right;
            } else {
                if (fabs(right) < 1e-12) {
                    ps->err = ERR_DIV0;
                    return 0.0;
                }
                left /= right;
            }
        } else {
            break;
        }
    }
    return left;
}

static double parse_expr(Parser *ps) {
    double left = parse_term(ps);
    while (ps->err == ERR_NONE) {
        skip_ws(ps);
        if (*ps->p == '+' || *ps->p == '-') {
            char op = *ps->p++;
            double right = parse_term(ps);
            if (ps->err != ERR_NONE) return 0.0;
            left = (op == '+') ? (left + right) : (left - right);
        } else {
            break;
        }
    }
    return left;
}

static double eval_cell(Sheet *s, int r, int c, EvalErr *out_err) {
    Cell *cell = &s->cells[r][c];
    if (cell->eval_state == 2) {
        if (out_err) *out_err = cell->err;
        return cell->value;
    }
    if (cell->eval_state == 1) {
        cell->err = ERR_CIRC;
        if (out_err) *out_err = ERR_CIRC;
        return 0.0;
    }

    cell->eval_state = 1;
    cell->err = ERR_NONE;

    if (cell->type == CELL_EMPTY || cell->type == CELL_TEXT) {
        cell->value = 0.0;
    } else if (cell->type == CELL_NUMBER) {
        cell->value = strtod(cell->raw, NULL);
    } else if (cell->type == CELL_FORMULA) {
        Parser ps = { s, cell->raw + 1, ERR_NONE };
        double v = parse_expr(&ps);
        skip_ws(&ps);
        if (ps.err == ERR_NONE && *ps.p != '\0') {
            ps.err = ERR_SYNTAX;
        }
        cell->err = ps.err;
        cell->value = (ps.err == ERR_NONE) ? v : 0.0;
    }

    cell->eval_state = 2;
    if (out_err) *out_err = cell->err;
    return cell->value;
}

static void sheet_recalc(Sheet *s) {
    for (int r = 0; r < MAX_ROWS; r++) {
        for (int c = 0; c < MAX_COLS; c++) {
            s->cells[r][c].eval_state = 0;
            s->cells[r][c].err = ERR_NONE;
        }
    }
    for (int r = 0; r < MAX_ROWS; r++) {
        for (int c = 0; c < MAX_COLS; c++) {
            if (s->cells[r][c].type != CELL_EMPTY) {
                eval_cell(s, r, c, NULL);
            }
        }
    }
}

static void cell_set_raw(Sheet *s, int r, int c, const char *text) {
    Cell *cell = &s->cells[r][c];
    if (!text || text[0] == '\0') {
        cell->raw[0] = '\0';
        cell->type = CELL_EMPTY;
        cell->value = 0.0;
        cell->err = ERR_NONE;
        return;
    }
    snprintf(cell->raw, sizeof(cell->raw), "%s", text);
    if (cell->raw[0] == '=') {
        cell->type = CELL_FORMULA;
    } else {
        char *ep = NULL;
        double v = strtod(cell->raw, &ep);
        while (ep && isspace((unsigned char)*ep)) ep++;
        if (ep != cell->raw && ep && *ep == '\0') {
            cell->type = CELL_NUMBER;
            cell->value = v;
        } else {
            cell->type = CELL_TEXT;
            cell->value = 0.0;
        }
    }
    cell->err = ERR_NONE;
}

static void format_cell_display(const Cell *cell, char *buf, size_t bufsz) {
    if (cell->type == CELL_EMPTY) {
        buf[0] = '\0';
        return;
    }
    if (cell->type == CELL_TEXT) {
        snprintf(buf, bufsz, "%s", cell->raw);
        return;
    }
    if (cell->err != ERR_NONE) {
        switch (cell->err) {
            case ERR_DIV0: snprintf(buf, bufsz, "#DIV/0!"); break;
            case ERR_CIRC: snprintf(buf, bufsz, "#CIRC!"); break;
            case ERR_REF:  snprintf(buf, bufsz, "#REF!"); break;
            default:       snprintf(buf, bufsz, "#ERR!"); break;
        }
        return;
    }
    double v = cell->value;
    if (fabs(v - floor(v + 0.5)) < 1e-9 && fabs(v) < 1e12) {
        snprintf(buf, bufsz, "%.0f", v);
    } else {
        snprintf(buf, bufsz, "%.2f", v);
    }
}

/* =========================================================================
 * Persistência CSV (Leitura / Gravação com Fórmulas ou Valores Avaliados)
 * ========================================================================= */

static void sheet_init(Sheet *s) {
    memset(s, 0, sizeof(*s));
    s->col_width = 10;
    snprintf(s->filename, sizeof(s->filename), "planilha.csv");
}

static bool sheet_load_csv(Sheet *s, const char *path) {
    FILE *fp = fopen(path, "r");
    if (!fp) return false;

    sheet_init(s);
    snprintf(s->filename, sizeof(s->filename), "%s", path);

    char line[4096];
    int r = 0;
    while (r < MAX_ROWS && fgets(line, sizeof(line), fp)) {
        size_t len = strlen(line);
        while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r')) {
            line[--len] = '\0';
        }
        int c = 0;
        const char *p = line;
        while (c < MAX_COLS) {
            char field[MAX_TEXT];
            size_t flen = 0;
            if (*p == '"') {
                p++;
                while (*p) {
                    if (*p == '"' && p[1] == '"') {
                        if (flen < sizeof(field) - 1) field[flen++] = '"';
                        p += 2;
                    } else if (*p == '"') {
                        p++;
                        break;
                    } else {
                        if (flen < sizeof(field) - 1) field[flen++] = *p;
                        p++;
                    }
                }
                if (*p == ',') p++;
            } else {
                while (*p && *p != ',') {
                    if (flen < sizeof(field) - 1) field[flen++] = *p;
                    p++;
                }
                if (*p == ',') p++;
                else {
                    field[flen] = '\0';
                    cell_set_raw(s, r, c, field);
                    break;
                }
            }
            field[flen] = '\0';
            cell_set_raw(s, r, c, field);
            c++;
        }
        r++;
    }

    fclose(fp);
    sheet_recalc(s);
    s->modified = false;
    return true;
}

static void write_csv_field(FILE *fp, const char *s) {
    bool needs_quote = (strchr(s, ',') != NULL || strchr(s, '"') != NULL);
    if (!needs_quote) {
        fputs(s, fp);
        return;
    }
    fputc('"', fp);
    for (const char *p = s; *p; p++) {
        if (*p == '"') fputc('"', fp);
        fputc(*p, fp);
    }
    fputc('"', fp);
}

static bool sheet_save_csv(Sheet *s, const char *path, bool evaluated_only) {
    FILE *fp = fopen(path, "w");
    if (!fp) return false;

    int max_r = -1, max_c = -1;
    for (int r = 0; r < MAX_ROWS; r++) {
        for (int c = 0; c < MAX_COLS; c++) {
            if (s->cells[r][c].type != CELL_EMPTY) {
                if (r > max_r) max_r = r;
                if (c > max_c) max_c = c;
            }
        }
    }

    for (int r = 0; r <= max_r; r++) {
        for (int c = 0; c <= max_c; c++) {
            if (c > 0) fputc(',', fp);
            if (evaluated_only) {
                char disp[MAX_TEXT];
                format_cell_display(&s->cells[r][c], disp, sizeof(disp));
                write_csv_field(fp, disp);
            } else {
                write_csv_field(fp, s->cells[r][c].raw);
            }
        }
        fputc('\n', fp);
    }

    fclose(fp);
    if (!evaluated_only) {
        snprintf(s->filename, sizeof(s->filename), "%s", path);
        s->modified = false;
    }
    return true;
}

/* =========================================================================
 * Modo Batch CLI (--eval / --csv) — Útil para pipelines e testes automáticos
 * ========================================================================= */

static int run_batch(const char *path, bool as_csv) {
    Sheet sheet;
    if (!sheet_load_csv(&sheet, path)) {
        fprintf(stderr, "q5-sheet: erro ao abrir '%s': %s\n", path, strerror(errno));
        return 1;
    }
    int max_r = -1, max_c = -1;
    for (int r = 0; r < MAX_ROWS; r++) {
        for (int c = 0; c < MAX_COLS; c++) {
            if (sheet.cells[r][c].type != CELL_EMPTY) {
                if (r > max_r) max_r = r;
                if (c > max_c) max_c = c;
            }
        }
    }
    if (as_csv) {
        for (int r = 0; r <= max_r; r++) {
            for (int c = 0; c <= max_c; c++) {
                if (c > 0) putchar(',');
                char disp[MAX_TEXT];
                format_cell_display(&sheet.cells[r][c], disp, sizeof(disp));
                write_csv_field(stdout, disp);
            }
            putchar('\n');
        }
        return 0;
    }

    printf("    ");
    for (int c = 0; c <= max_c; c++) {
        printf(" %-10c", 'A' + c);
    }
    printf("\n");
    for (int r = 0; r <= max_r; r++) {
        printf("%3d ", r + 1);
        for (int c = 0; c <= max_c; c++) {
            char disp[MAX_TEXT];
            format_cell_display(&sheet.cells[r][c], disp, sizeof(disp));
            if (sheet.cells[r][c].type == CELL_NUMBER || sheet.cells[r][c].type == CELL_FORMULA) {
                printf(" %10.10s", disp);
            } else {
                printf(" %-10.10s", disp);
            }
        }
        printf("\n");
    }
    return 0;
}

/* =========================================================================
 * Interface TUI ncursesw Otimizada para BlackBerry Q5 (720x720 / ~55 cols)
 * ========================================================================= */

#ifndef Q5_BATCH_ONLY

static bool prompt_input(int row, int cols, const char *label, char *buf, size_t bufsz, const char *initial) {
    snprintf(buf, bufsz, "%s", initial ? initial : "");
    size_t len = strlen(buf);
    curs_set(1);

    while (1) {
        move(row, 0);
        clrtoeol();
        attron(A_BOLD);
        mvaddnstr(row, 0, label, cols - 1);
        attroff(A_BOLD);

        int lsize = (int)strlen(label);
        int avail = cols - lsize - 1;
        if (avail < 4) avail = 4;
        const char *view = buf;
        if ((int)len > avail) {
            view = buf + (len - (size_t)avail);
        }
        mvaddnstr(row, lsize, view, avail);
        refresh();

        int ch = getch();
        if (ch == '\n' || ch == '\r' || ch == KEY_ENTER) {
            curs_set(0);
            return true;
        }
        if (ch == 27 || ch == 3 || ch == 7) { /* Esc, Ctrl+C ou Ctrl+G cancelam */
            curs_set(0);
            return false;
        }
        if (ch == KEY_BACKSPACE || ch == 127 || ch == 8) {
            if (len > 0) buf[--len] = '\0';
        } else if (isprint(ch) && len + 1 < bufsz) {
            buf[len++] = (char)ch;
            buf[len] = '\0';
        }
    }
}

static void show_help(void) {
    clear();
    mvaddstr(0, 0, "=== q5-sheet (Ajuda Rapida Q5) ===");
    mvaddstr(2, 0, "Navegacao:");
    mvaddstr(3, 2, "h/j/k/l ou Setas : Mover cursor");
    mvaddstr(4, 2, "g / G            : Topo / Linha 20");
    mvaddstr(5, 2, "< / >            : Largura coluna");
    mvaddstr(7, 0, "Edicao e Formulas:");
    mvaddstr(8, 2, "Enter ou e       : Editar celula");
    mvaddstr(9, 2, "=                : Nova formula");
    mvaddstr(10, 2, "x                : Limpar celula");
    mvaddstr(11, 2, "Ex: =SUM(B2:B10) =AVG(A1:A5) =B2*1.1");
    mvaddstr(12, 2, "Funcoes: SUM AVG MIN MAX COUNT ABS SQRT ROUND");
    mvaddstr(14, 0, "Arquivos:");
    mvaddstr(15, 2, "w : Salvar CSV   | o : Abrir CSV");
    mvaddstr(16, 2, "c : Exportar valores CSV");
    mvaddstr(17, 2, "Ctrl+C / Ctrl+G  : Cancelar edicao");
    mvaddstr(18, 2, "q                : Sair");
    mvaddstr(20, 0, "Pressione qualquer tecla para voltar...");
    refresh();
    getch();
}

static void draw_sheet(const Sheet *s, int cur_r, int cur_c, int top_r, int left_c, const char *status_msg) {
    int rows = 0, cols = 0;
    getmaxyx(stdscr, rows, cols);
    erase();

    /* Linha 0: barra superior compacta (celula ativa + formula/valor) */
    const Cell *ac = &s->cells[cur_r][cur_c];
    char topbar[256];
    snprintf(topbar, sizeof(topbar), " %c%d: %s",
             'A' + cur_c, cur_r + 1,
             ac->raw[0] ? ac->raw : "(vazio)");
    attron(A_REVERSE);
    mvhline(0, 0, ' ', cols);
    mvaddnstr(0, 0, topbar, cols - 1);
    char fname_tag[64];
    snprintf(fname_tag, sizeof(fname_tag), " %.48s%s ", s->filename, s->modified ? "*" : "");
    int fpos = cols - (int)strlen(fname_tag);
    if (fpos > 16) {
        mvaddnstr(0, fpos, fname_tag, cols - fpos);
    }
    attroff(A_REVERSE);

    /* Linha 1: cabecalho das colunas */
    int cw = s->col_width;
    int vis_cols = (cols - 4) / (cw + 1);
    if (vis_cols < 1) vis_cols = 1;

    attron(A_BOLD);
    mvaddstr(1, 0, "   ");
    for (int vc = 0; vc < vis_cols && (left_c + vc) < MAX_COLS; vc++) {
        int c = left_c + vc;
        int x = 4 + vc * (cw + 1);
        char hdr[16];
        snprintf(hdr, sizeof(hdr), "%*c", (cw / 2) + 1, 'A' + c);
        if (c == cur_c) attron(A_UNDERLINE);
        mvaddnstr(1, x, hdr, cw);
        if (c == cur_c) attroff(A_UNDERLINE);
    }
    attroff(A_BOLD);

    /* Grade principal */
    int grid_rows = rows - 4;
    if (grid_rows < 1) grid_rows = 1;

    for (int vr = 0; vr < grid_rows && (top_r + vr) < MAX_ROWS; vr++) {
        int r = top_r + vr;
        int y = 2 + vr;
        char rlbl[16];
        snprintf(rlbl, sizeof(rlbl), "%3d", r + 1);
        if (r == cur_r) attron(A_BOLD);
        mvaddstr(y, 0, rlbl);
        if (r == cur_r) attroff(A_BOLD);

        for (int vc = 0; vc < vis_cols && (left_c + vc) < MAX_COLS; vc++) {
            int c = left_c + vc;
            int x = 4 + vc * (cw + 1);
            const Cell *cell = &s->cells[r][c];
            char disp[MAX_TEXT];
            format_cell_display(cell, disp, sizeof(disp));

            char fmt[64];
            if (cell->type == CELL_NUMBER || cell->type == CELL_FORMULA) {
                snprintf(fmt, sizeof(fmt), "%*.*s", cw, cw, disp);
            } else {
                snprintf(fmt, sizeof(fmt), "%-*.*s", cw, cw, disp);
            }

            if (r == cur_r && c == cur_c) attron(A_REVERSE);
            mvaddnstr(y, x, fmt, cw);
            if (r == cur_r && c == cur_c) attroff(A_REVERSE);
        }
    }

    /* Linha rows-2: mensagem de status */
    if (rows >= 4) {
        mvaddnstr(rows - 2, 0, status_msg ? status_msg : "", cols - 1);
    }

    /* Linha rows-1: legenda compacta para o Q5 */
    if (rows >= 3) {
        attron(A_REVERSE);
        mvhline(rows - 1, 0, ' ', cols);
        mvaddnstr(rows - 1, 0, " hjkl:Nav Ent:Edt =:Frm x:Del w:Sav ?:Hlp q:Quit", cols - 1);
        attroff(A_REVERSE);
    }

    refresh();
}

static int run_tui(const char *initial_file) {
    Sheet sheet;
    sheet_init(&sheet);
    char status[128] = "Pronto. Pressione '?' para ajuda.";

    if (initial_file && initial_file[0] != '\0') {
        if (sheet_load_csv(&sheet, initial_file)) {
            snprintf(status, sizeof(status), "Carregado: %.96s", initial_file);
        } else {
            snprintf(sheet.filename, sizeof(sheet.filename), "%s", initial_file);
            snprintf(status, sizeof(status), "Nova planilha: %.96s", initial_file);
        }
    }

    initscr();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
    curs_set(0);

    int cur_r = 0, cur_c = 0;
    int top_r = 0, left_c = 0;

    while (1) {
        int rows = 0, cols = 0;
        getmaxyx(stdscr, rows, cols);
        int grid_rows = rows - 4;
        if (grid_rows < 1) grid_rows = 1;
        int vis_cols = (cols - 4) / (sheet.col_width + 1);
        if (vis_cols < 1) vis_cols = 1;

        if (cur_r < top_r) top_r = cur_r;
        if (cur_r >= top_r + grid_rows) top_r = cur_r - grid_rows + 1;
        if (cur_c < left_c) left_c = cur_c;
        if (cur_c >= left_c + vis_cols) left_c = cur_c - vis_cols + 1;

        draw_sheet(&sheet, cur_r, cur_c, top_r, left_c, status);
        status[0] = '\0';

        int ch = getch();
        if (ch == 'q') {
            if (sheet.modified) {
                char ans[8];
                if (prompt_input(rows - 2, cols, "Alteracoes nao salvas. Sair? (s/n): ", ans, sizeof(ans), "")) {
                    if (ans[0] == 's' || ans[0] == 'S' || ans[0] == 'y' || ans[0] == 'Y') break;
                }
            } else {
                break;
            }
        } else if (ch == KEY_UP || ch == 'k') {
            if (cur_r > 0) cur_r--;
        } else if (ch == KEY_DOWN || ch == 'j') {
            if (cur_r < MAX_ROWS - 1) cur_r++;
        } else if (ch == KEY_LEFT || ch == 'h') {
            if (cur_c > 0) cur_c--;
        } else if (ch == KEY_RIGHT || ch == 'l') {
            if (cur_c < MAX_COLS - 1) cur_c++;
        } else if (ch == 'g') {
            cur_r = 0; cur_c = 0;
        } else if (ch == 'G') {
            cur_r = 19;
        } else if (ch == '<' && sheet.col_width > 6) {
            sheet.col_width -= 2;
        } else if (ch == '>' && sheet.col_width < 20) {
            sheet.col_width += 2;
        } else if (ch == 'x' || ch == KEY_DC) {
            cell_set_raw(&sheet, cur_r, cur_c, "");
            sheet_recalc(&sheet);
            sheet.modified = true;
            snprintf(status, sizeof(status), "Celula %c%d limpa.", 'A' + cur_c, cur_r + 1);
        } else if (ch == '\n' || ch == '\r' || ch == KEY_ENTER || ch == 'e' || ch == '=') {
            char buf[MAX_TEXT];
            const char *init_val = (ch == '=') ? "=" : sheet.cells[cur_r][cur_c].raw;
            char lbl[24];
            snprintf(lbl, sizeof(lbl), "%c%d> ", 'A' + cur_c, cur_r + 1);
            if (prompt_input(rows - 2, cols, lbl, buf, sizeof(buf), init_val)) {
                cell_set_raw(&sheet, cur_r, cur_c, buf);
                sheet_recalc(&sheet);
                sheet.modified = true;
            }
        } else if (ch == 'w') {
            char path[MAX_PATH];
            if (prompt_input(rows - 2, cols, "Salvar CSV: ", path, sizeof(path), sheet.filename) && path[0]) {
                if (sheet_save_csv(&sheet, path, false)) {
                    snprintf(status, sizeof(status), "Salvo em %.96s", path);
                } else {
                    snprintf(status, sizeof(status), "Erro ao salvar: %.96s", strerror(errno));
                }
            }
        } else if (ch == 'c') {
            char path[MAX_PATH];
            if (prompt_input(rows - 2, cols, "Exportar valores CSV: ", path, sizeof(path), "export.csv") && path[0]) {
                if (sheet_save_csv(&sheet, path, true)) {
                    snprintf(status, sizeof(status), "Exportado para %.96s", path);
                } else {
                    snprintf(status, sizeof(status), "Erro ao exportar: %.96s", strerror(errno));
                }
            }
        } else if (ch == 'o') {
            char path[MAX_PATH];
            if (prompt_input(rows - 2, cols, "Abrir CSV: ", path, sizeof(path), sheet.filename) && path[0]) {
                if (sheet_load_csv(&sheet, path)) {
                    cur_r = cur_c = top_r = left_c = 0;
                    snprintf(status, sizeof(status), "Aberto: %.96s", path);
                } else {
                    snprintf(status, sizeof(status), "Nao encontrado: %.96s", path);
                }
            }
        } else if (ch == '?') {
            show_help();
        }
    }

    endwin();
    return 0;
}

#else
static int run_tui(const char *initial_file) {
    (void)initial_file;
    fprintf(stderr, "q5-sheet compilado em modo Q5_BATCH_ONLY.\n");
    return 1;
}
#endif

int main(int argc, char **argv) {
    if (argc >= 2 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
        printf("q5-sheet — Planilha CLI/TUI em C11 + ncursesw para BerryCore (BlackBerry Q5)\n");
        printf("Uso:\n");
        printf("  q5-sheet [arquivo.csv]          Abre planilha interativa TUI\n");
        printf("  q5-sheet --eval <arquivo.csv>   Avalia formulas e imprime tabela\n");
        printf("  q5-sheet --csv  <arquivo.csv>   Avalia formulas e exporta CSV\n");
        return 0;
    }
    if (argc >= 3 && strcmp(argv[1], "--eval") == 0) {
        return run_batch(argv[2], false);
    }
    if (argc >= 3 && strcmp(argv[1], "--csv") == 0) {
        return run_batch(argv[2], true);
    }
    return run_tui(argc >= 2 ? argv[1] : NULL);
}
