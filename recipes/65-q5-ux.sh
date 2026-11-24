# recipes/65-q5-ux.sh — Camada 5 (Pocket Laptop UX): dotfiles Q5 (720x720 + teclado físico), bc-menu, ai, note, q5-setup
PKG_ID="65"
PKG_NAME="q5-ux"
PKG_VER="1.0.0"
PKG_LAYER="5"
PKG_CRITICAL="0"
PKG_DEPS="bash tmux vim nano curl jq python3"
PKG_URL=""
PKG_SHA256=""

build() {
    # Pacote composto por scripts POSIX/Python e dotfiles otimizados para o BlackBerry Q5 (sem compilação C)
    return 0
}

install_staging() {
    local bin_dir="${SYSROOT_PREFIX}/bin"
    local skel_dir="${SYSROOT_PREFIX}/etc/skel"
    install -d "${bin_dir}" "${skel_dir}"

    # 1. Dotfile: .bashrc (prompt curto 55 colunas, atalhos BB10, fzy, aliases cotidianos)
    cat > "${skel_dir}/.bashrc" <<'EOF'
# BerryCore Q5 Pocket Laptop .bashrc (otimizado para tela 720x720 / ~55 colunas)
export PREFIX="/accounts/1000/shared/misc/berrycore"
[ -f "$PREFIX/env.sh" ] && source "$PREFIX/env.sh"

# Pastas rápidas do BlackBerry 10 (evita digitar caminhos longos no polegar)
export BC="$PREFIX"
export DL="/accounts/1000/shared/downloads"
export DOCS="/accounts/1000/shared/documents"
export NOTES_DIR="${NOTES_DIR:-$DOCS/notes}"
export EDITOR="vim"
export VISUAL="vim"
export PAGER="less -R"
export TERM="${TERM:-xterm-256color}"

# Histórico amplo e sem duplicatas
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=5000
export HISTFILESIZE=10000
shopt -s histappend checkwinsize cdspell 2>/dev/null

# Prompt compacto de 1 linha para tela 720x720
PROMPT_DIRTRIM=2
__q5_ps1() {
    local rc=$?
    local c_rc="\[\e[32m\]"
    [ "$rc" -ne 0 ] && c_rc="\[\e[31m\]"
    local br=""
    if command -v git >/dev/null 2>&1; then
        br="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
        [ -n "$br" ] && br=" \[\e[33m\]($br)\[\e[0m\]"
    fi
    PS1="\[\e[36m\]\W\[\e[0m\]${br} ${c_rc}>\[\e[0m\] "
}
PROMPT_COMMAND=__q5_ps1

# Aliases de produtividade para 1 polegar
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lh --color=auto'
alias la='ls -lAh --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias v='vim'
alias n='nano'
alias f='q5-files'
alias m='bc-menu'
alias clima='curl -s "https://wttr.in/?0&T&lang=pt"'

# Atalhos fuzzy com fzy (histórico, arquivos e diretórios)
fh() {
    local cmd
    cmd="$(history | awk '{$1=""; sub(/^ /, ""); print}' | awk '!seen[$0]++' | fzy -l 12)" || return
    [ -n "$cmd" ] && eval "$cmd"
}
ff() {
    local file
    file="$(find . -maxdepth 4 -type f 2>/dev/null | sed 's|^\./||' | fzy -l 12)" || return
    [ -n "$file" ] && "${EDITOR:-vim}" "$file"
}
fcd() {
    local dir
    dir="$(find . -maxdepth 4 -type d 2>/dev/null | sed 's|^\./||' | fzy -l 12)" || return
    [ -n "$dir" ] && cd "$dir"
}

# Sessão tmux pré-montada de "laptop de bolso"
work() {
    if tmux has-session -t q5 2>/dev/null; then
        tmux attach -t q5
    else
        tmux new-session -d -s q5 -n sh
        tmux new-window -t q5:2 -n files 'q5-files || bash'
        tmux new-window -t q5:3 -n notes 'note || bash'
        tmux select-window -t q5:1
        tmux attach -t q5
    fi
}
EOF

    # 2. Dotfile: .inputrc (Readline: menos toques de Tab e busca inteligente no histórico)
    cat > "${skel_dir}/.inputrc" <<'EOF'
set completion-ignore-case on
set completion-map-case on
set show-all-if-ambiguous on
set mark-symlinked-directories on
set visible-stats on
set colored-stats on
"\e[A": history-search-backward
"\e[B": history-search-forward
EOF

    # 3. Dotfile: .tmux.conf (otimizado para tela 720x720 e teclado sem PgUp/PgDn)
    cat > "${skel_dir}/.tmux.conf" <<'EOF'
# Prefixo ergonômico Ctrl+a (mantém Ctrl+b como secundário)
set -g prefix C-a
set -g prefix2 C-b
bind a send-prefix

# Rolagem estilo Vi (h/j/k/l) sem depender de PgUp/PgDn
setw -g mode-keys vi
set -g history-limit 10000
set -sg escape-time 10

# Numeração a partir de 1 (mais fácil nos polegares)
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Barra de status ultra-compacta de 1 linha para 55 colunas
set -g status-position top
set -g status-style bg=colour235,fg=colour250
set -g status-left "#[fg=colour39,bold]Q5 "
set -g status-left-length 8
set -g status-right "#[fg=colour245]%H:%M"
set -g status-right-length 8
setw -g window-status-format " #I:#W "
setw -g window-status-current-format "#[bg=colour39,fg=colour16,bold] #I:#W "

# Splits intuitivos
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display-message "tmux.conf recarregado"
EOF

    # 4. Dotfile: .vimrc (jk/jj -> Esc para o teclado físico do Q5 sem tecla Esc)
    cat > "${skel_dir}/.vimrc" <<'EOF'
set nocompatible
syntax on
set number
set wrap
set linebreak
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set ignorecase
set smartcase
set incsearch
set hlsearch
set hidden
set laststatus=2
set statusline=%f%m\ [%l/%L]

" Essencial no BlackBerry Q5 (sem tecla Esc física)
inoremap jk <Esc>
inoremap jj <Esc>
EOF

    # 5. Dotfile: .nanorc
    cat > "${skel_dir}/.nanorc" <<'EOF'
set softwrap
set linenumbers
set autoindent
set tabsize 4
set tabstospaces
set constantshow
EOF

    # 6. Utilitário: q5-setup (instala dotfiles no $HOME preservando backups)
    cat > "${bin_dir}/q5-setup" <<'EOF'
#!/accounts/1000/shared/misc/berrycore/bin/bash
set -euo pipefail
PREFIX="/accounts/1000/shared/misc/berrycore"
SKEL="$PREFIX/etc/skel"
TS="$(date +%Y%m%d-%H%M%S)"

echo "== Instalando dotfiles BerryCore Q5 em $HOME =="
for f in .bashrc .inputrc .tmux.conf .vimrc .nanorc; do
    if [ -e "$HOME/$f" ]; then
        cp -a "$HOME/$f" "$HOME/${f}.bak.${TS}"
        echo "  backup: $HOME/${f}.bak.${TS}"
    fi
    cp -f "$SKEL/$f" "$HOME/$f"
    echo "  instalado: $HOME/$f"
done

if [ ! -f "$HOME/.profile" ] || ! grep -q "berrycore/env.sh" "$HOME/.profile" 2>/dev/null; then
    {
        echo ""
        echo "# BerryCore Pocket Laptop"
        echo "source $PREFIX/env.sh"
        echo "[ -f \"\$HOME/.bashrc\" ] && source \"\$HOME/.bashrc\""
    } >> "$HOME/.profile"
    echo "  atualizado: $HOME/.profile"
fi

mkdir -p "/accounts/1000/shared/documents/notes"
echo ""
echo "Pronto! Rode 'exec bash' e depois 'bc-menu' (ou 'm') para abrir o launcher Q5."
EOF
    chmod 755 "${bin_dir}/q5-setup"

    # 7. Utilitário: note (caderno de notas Markdown offline + busca + sync Git)
    cat > "${bin_dir}/note" <<'EOF'
#!/accounts/1000/shared/misc/berrycore/bin/bash
set -euo pipefail
NOTES_DIR="${NOTES_DIR:-/accounts/1000/shared/documents/notes}"
mkdir -p "$NOTES_DIR"

case "${1:-}" in
    "")
        TODAY="$NOTES_DIR/$(date +%Y-%m-%d).md"
        if [ ! -f "$TODAY" ]; then
            printf '# Notas %s\n\n- \n' "$(date +%Y-%m-%d)" > "$TODAY"
        fi
        exec "${EDITOR:-vim}" "$TODAY"
        ;;
    ls|list)
        ls -1t "$NOTES_DIR"/*.md 2>/dev/null || echo "Nenhuma nota ainda em $NOTES_DIR"
        ;;
    find|f)
        if command -v fzy >/dev/null 2>&1; then
            sel="$(cd "$NOTES_DIR" && ls -1t *.md 2>/dev/null | fzy -l 12)" || exit 0
            [ -n "$sel" ] && exec "${EDITOR:-vim}" "$NOTES_DIR/$sel"
        else
            ls -1t "$NOTES_DIR"/*.md 2>/dev/null
        fi
        ;;
    sync)
        cd "$NOTES_DIR"
        if [ ! -d .git ]; then
            echo "Para sincronizar, inicialize um repo git em $NOTES_DIR:"
            echo "  cd $NOTES_DIR && git init && git remote add origin <URL>"
            exit 1
        fi
        git add -A
        git commit -m "notes: sync $(date +%Y-%m-%d_%H:%M)" || true
        git pull --rebase || true
        git push
        ;;
    *)
        grep -rnI --color=auto "$*" "$NOTES_DIR" || echo "Sem resultados para: $*"
        ;;
esac
EOF
    chmod 755 "${bin_dir}/note"

    # 8. Utilitário: ai (cliente CLI ultraleve para APIs Gemini ou OpenAI-compatível via curl+jq)
    cat > "${bin_dir}/ai" <<'EOF'
#!/accounts/1000/shared/misc/berrycore/bin/bash
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Uso: ai <sua pergunta>"
    echo "Configure uma das chaves no ~/.bashrc:"
    echo "  export GEMINI_API_KEY='...'"
    echo "  ou export OPENAI_API_KEY='...' (opcional: AI_BASE_URL, AI_MODEL)"
    exit 1
fi

PROMPT="$*"
COLS="${COLUMNS:-55}"
[ "$COLS" -gt 78 ] && COLS=78

if [ -n "${GEMINI_API_KEY:-}" ]; then
    MODEL="${AI_MODEL:-gemini-2.5-flash}"
    URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}"
    PAYLOAD="$(jq -nc --arg p "$PROMPT" '{contents:[{parts:[{text:$p}]}]}')"
    RESP="$(curl -fsSL -H 'Content-Type: application/json' -d "$PAYLOAD" "$URL")"
    printf '%s\n' "$RESP" | jq -r '.candidates[0].content.parts[0].text // .error.message // "Sem resposta"' | fold -s -w "$COLS"
elif [ -n "${OPENAI_API_KEY:-}" ]; then
    BASE="${AI_BASE_URL:-https://api.openai.com/v1}"
    MODEL="${AI_MODEL:-gpt-4o-mini}"
    PAYLOAD="$(jq -nc --arg m "$MODEL" --arg p "$PROMPT" '{model:$m,messages:[{role:"user",content:$p}]}')"
    RESP="$(curl -fsSL -H 'Content-Type: application/json' -H "Authorization: Bearer ${OPENAI_API_KEY}" -d "$PAYLOAD" "${BASE}/chat/completions")"
    printf '%s\n' "$RESP" | jq -r '.choices[0].message.content // .error.message // "Sem resposta"' | fold -s -w "$COLS"
else
    echo "Erro: defina GEMINI_API_KEY ou OPENAI_API_KEY antes de usar 'ai'." >&2
    exit 1
fi
EOF
    chmod 755 "${bin_dir}/ai"

    # 9. Utilitário: q5-files (gerenciador de arquivos TUI em Python+curses para tela 720x720)
    cat > "${bin_dir}/q5-files" <<'EOF'
#!/accounts/1000/shared/misc/berrycore/bin/python3
import curses
import os
import subprocess
import sys

def list_dir(path, show_hidden):
    try:
        names = os.listdir(path)
    except OSError:
        return [("..", True, 0)]
    items = [("..", True, 0)]
    dirs, files = [], []
    for n in sorted(names, key=str.lower):
        if not show_hidden and n.startswith("."):
            continue
        full = os.path.join(path, n)
        try:
            st = os.lstat(full)
            is_d = os.path.isdir(full)
            sz = st.st_size
        except OSError:
            is_d, sz = False, 0
        (dirs if is_d else files).append((n, is_d, sz))
    return items + dirs + files

def fmt_size(sz):
    for unit in ("B", "K", "M", "G"):
        if sz < 1024:
            return f"{sz}{unit}"
        sz //= 1024
    return f"{sz}T"

def run_tui(stdscr, start_dir):
    curses.curs_set(0)
    cwd = os.path.abspath(start_dir)
    idx, top, show_hidden = 0, 0, False
    while True:
        entries = list_dir(cwd, show_hidden)
        h, w = stdscr.getmaxyx()
        body_h = max(1, h - 2)
        idx = max(0, min(idx, len(entries) - 1))
        if idx < top:
            top = idx
        elif idx >= top + body_h:
            top = idx - body_h + 1
        stdscr.erase()
        header = f" {cwd} "
        stdscr.addnstr(0, 0, header.ljust(w), w - 1, curses.A_REVERSE)
        for row in range(body_h):
            i = top + row
            if i >= len(entries):
                break
            name, is_d, sz = entries[i]
            tag = "/" if is_d and name != ".." else ""
            right = " DIR" if is_d else f" {fmt_size(sz)}"
            line = f"{name}{tag}"
            avail = max(1, w - len(right) - 2)
            text = f" {line[:avail].ljust(avail)}{right}"
            attr = curses.A_REVERSE if i == idx else curses.A_NORMAL
            stdscr.addnstr(row + 1, 0, text, w - 1, attr)
        footer = " j/k:mov l/Ent:abr h:pai e:vim n:nano v:less .:hid q:sair"
        stdscr.addnstr(h - 1, 0, footer.ljust(w), w - 1, curses.A_REVERSE)
        stdscr.refresh()
        ch = stdscr.getch()
        name, is_d, _ = entries[idx]
        target = os.path.dirname(cwd) if name == ".." else os.path.join(cwd, name)
        if ch in (ord("q"), 27):
            break
        elif ch in (ord("j"), curses.KEY_DOWN):
            idx = min(len(entries) - 1, idx + 1)
        elif ch in (ord("k"), curses.KEY_UP):
            idx = max(0, idx - 1)
        elif ch in (ord("h"), curses.KEY_LEFT):
            cwd, idx, top = os.path.dirname(cwd), 0, 0
        elif ch == ord("."):
            show_hidden = not show_hidden
        elif ch in (ord("l"), curses.KEY_RIGHT, 10, 13):
            if is_d:
                cwd, idx, top = target, 0, 0
            else:
                curses.endwin()
                subprocess.call(["less", "-R", target])
                stdscr.refresh()
        elif ch == ord("e") and not is_d:
            curses.endwin()
            subprocess.call(["vim", target])
            stdscr.refresh()
        elif ch == ord("n") and not is_d:
            curses.endwin()
            subprocess.call(["nano", target])
            stdscr.refresh()
        elif ch == ord("v") and not is_d:
            curses.endwin()
            subprocess.call(["less", "-R", target])
            stdscr.refresh()

if __name__ == "__main__":
    start = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    curses.wrapper(run_tui, start)
EOF
    chmod 755 "${bin_dir}/q5-files"

    # 10. Utilitário: bc-menu (Launcher TUI de 1 tecla para o BlackBerry Q5)
    cat > "${bin_dir}/bc-menu" <<'EOF'
#!/accounts/1000/shared/misc/berrycore/bin/python3
import os
import subprocess

MENU = [
    ("1", "Tmux Workspace",    "tmux attach -t q5 || tmux new -s q5"),
    ("2", "Arquivos (TUI)",    "q5-files /accounts/1000/shared"),
    ("3", "Assistente IA",     "bash -c 'read -r -p \"Pergunta: \" q; [ -n \"$q\" ] && ai \"$q\" | less -R'"),
    ("4", "Notas de Hoje",     "note"),
    ("5", "Buscar Notas",      "note find"),
    ("6", "E-mail (mutt)",     "mutt"),
    ("7", "Web Texto (w3m)",   "w3m https://lite.duckduckgo.com/lite/"),
    ("8", "Uso de Disco",      "ncdu /accounts/1000/shared"),
    ("9", "Clima Rápido",      "bash -c 'curl -s \"https://wttr.in/?0&T&lang=pt\" | less -R'"),
    ("0", "Shell Bash",        "bash"),
]

def main():
    while True:
        os.system("clear")
        print("=== BerryCore Q5 Pocket CLI ===")
        print("-" * 31)
        for key, label, _ in MENU:
            print(f" [{key}] {label}")
        print(" [q] Sair")
        print("-" * 31)
        try:
            choice = input("Opção: ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if choice == "q":
            break
        matched = [cmd for key, _, cmd in MENU if key == choice]
        if matched:
            subprocess.call(["bash", "-lc", matched[0]])

if __name__ == "__main__":
    main()
EOF
    chmod 755 "${bin_dir}/bc-menu"
}
