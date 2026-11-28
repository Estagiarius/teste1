# Manual do Iniciante — BerryCore no BlackBerry Q5

Bem-vindo ao **BerryCore**! Este guia foi feito para quem está começando no terminal do **BlackBerry Q5** (tela 720×720, ~55 colunas e teclado físico QWERTY) e quer aprender a navegar pelo sistema e usar os principais aplicativos no dia a dia.

---

## 1. Primeiros Passos (Configuração Inicial)

Sempre que abrir o terminal pela primeira vez após instalar o BerryCore, ative o ambiente e rode o configurador do Q5:

```sh
source /accounts/1000/shared/misc/berrycore/env.sh
q5-setup
exec bash
```

O `q5-setup` configura automaticamente seu `.bashrc`, `.tmux.conf`, `.vimrc`, `.nanorc` e `.inputrc` para a tela quadrada e o teclado físico do Q5. Da próxima vez que abrir o terminal, tudo já estará pronto.

### Pastas importantes no BlackBerry Q5

| Atalho / Caminho | O que é |
| :--- | :--- |
| `$BC` (`/accounts/1000/shared/misc/berrycore`) | Pasta onde os programas do BerryCore ficam instalados |
| `$DL` (`/accounts/1000/shared/downloads`) | Pasta de Downloads do BlackBerry |
| `$DOCS` (`/accounts/1000/shared/documents`) | Pasta de Documentos |
| `$NOTES_DIR` (`/accounts/1000/shared/documents/notes`) | Onde o app `note` salva suas anotações |
| `/accounts/1000/removable/sdcard` | **Cartão microSD** (ideal para guardar planilhas, livros e backups) |

> **Dica:** para ir rapidamente para Downloads ou Documentos, digite `cd $DL` ou `cd $DOCS`.

---

## 2. Regras de Ouro do Teclado Físico do Q5

Antes de decorar comandos, aprenda estes 6 truques que economizam metade da digitação:

- **`Tab`:** completa automaticamente o nome de comandos e arquivos (digite as primeiras letras e aperte `Tab`).
- **Seta para cima (`↑`) / baixo (`↓`):** navega pelos comandos que você já digitou antes.
- **`Ctrl + C`:** interrompe/cancela qualquer comando travado ou edição em andamento.
- **`Ctrl + L`** (ou comando `clear`): limpa a tela.
- **`Ctrl + D`:** fecha o shell/sessão atual (equivalente a digitar `exit`).
- **Sem tecla `Esc` física?** No **Vim**, digite `jk` ou `jj` rapidamente para sair do modo de edição. No **`q5-sheet`**, use `Ctrl + C` ou `Ctrl + G` para cancelar uma edição.

---

## 3. Navegação Básica e Gestão de Arquivos

### Onde estou e o que tem aqui?
```sh
pwd          # Mostra em qual pasta você está agora
ls           # Lista os arquivos da pasta atual
ll           # Lista detalhada com tamanhos legíveis (KB, MB)
la           # Lista detalhada incluindo arquivos ocultos (que começam com .)
tree -L 2    # Mostra a árvore de pastas até 2 níveis de profundidade
```

### Entrando e saindo de pastas
```sh
cd pasta     # Entra na pasta informada
cd ..        # Volta uma pasta acima (ou digite apenas: ..)
cd ../..     # Volta duas pastas acima (ou digite apenas: ...)
cd ~         # Volta para a sua pasta inicial (HOME)
cd -         # Volta para a última pasta onde você estava
```

### Criando, copiando, movendo e apagando
```sh
mkdir fotos                # Cria uma pasta chamada "fotos"
mkdir -p trabalho/2026     # Cria pastas dentro de pastas de uma vez
cp a.txt b.txt             # Copia a.txt para b.txt
cp -r pasta1 pasta2        # Copia uma pasta inteira e seu conteúdo
mv velho.txt novo.txt      # Renomeia (ou move) um arquivo/pasta
rm arquivo.txt             # Apaga um arquivo (cuidado: não há lixeira!)
rm -r pasta                # Apaga uma pasta e tudo dentro dela
```

### Lendo e buscando texto
```sh
cat arquivo.txt            # Mostra o conteúdo inteiro de um arquivo curto
less arquivo.txt           # Abre arquivos grandes paginados (j/k rola, / busca, q sai)
grep "palavra" texto.txt   # Procura "palavra" dentro de um arquivo
grep -rn "termo" .         # Procura "termo" em todos os arquivos da pasta atual
find . -name "*.csv"       # Encontra todos os arquivos .csv a partir daqui
```

### Compactando e extraindo arquivos
```sh
unzip arquivo.zip          # Extrai um arquivo .zip na pasta atual
unzip -l arquivo.zip       # Apenas lista o conteúdo do .zip sem extrair
zip -r backup.zip pasta/   # Compacta uma pasta inteira em backup.zip
tar -xzf arquivo.tar.gz    # Extrai um arquivo .tar.gz
```

---

## 4. Atalhos Inteligentes do Q5 (`q5-ux` + `fzy`)

O kit `q5-ux` cria comandos curtos pensados para digitar com um polegar:

| Comando | O que faz |
| :--- | :--- |
| `m` (ou `bc-menu`) | Abre o **menu principal** do BerryCore (escolha opções de `1` a `9`) |
| `f` (ou `q5-files`) | Abre o **gerenciador de arquivos visual** (TUI) |
| `work` | Abre (ou retoma) sua **estação de trabalho no `tmux`** com abas prontas |
| `ff` | Busca um arquivo de forma *fuzzy* (digitando poucas letras) e abre no editor |
| `fcd` | Busca uma pasta de forma *fuzzy* e entra nela direto |
| `fh` | Busca um comando antigo no seu histórico e executa novamente |
| `clima` | Mostra a previsão do tempo resumida no terminal |

---

## 5. Guia dos Principais Aplicativos Usáveis

### 5.1. `q5-sheet` — Planilha de Cálculo (C11 puro, sem Python)
Cria e edita planilhas em CSV com recálculo automático de fórmulas.

**Como abrir:**
```sh
# Abrir a planilha de exemplo incluída no BerryCore
q5-sheet /accounts/1000/shared/misc/berrycore/share/q5-sheet/exemplo.csv

# Criar ou abrir sua própria planilha (ex.: no microSD)
q5-sheet /accounts/1000/removable/sdcard/gastos.csv

# Modo terminal (sem abrir a tela): apenas calcula e imprime a tabela
q5-sheet --eval gastos.csv

# Modo terminal: calcula fórmulas e exporta valores prontos em CSV
q5-sheet --csv gastos.csv > gastos_final.csv
```

**Atalhos dentro do `q5-sheet`:**
- `h / j / k / l` (ou setas): mover entre células
- `Enter` ou `e`: editar a célula atual
- `=`: iniciar uma fórmula direto (ex.: `=B2*C2`, `=SUM(B2:B10)`, `=AVG(C2:C6)`)
- `x`: limpar célula
- `<` / `>`: diminuir / aumentar largura das colunas
- `g` / `G`: ir para o topo (`A1`) / linha 20
- `w`: salvar CSV (preservando fórmulas) | `c`: exportar apenas valores calculados | `o`: abrir outro CSV
- `Ctrl + C` ou `Ctrl + G`: cancelar edição | `?`: ajuda | `q`: sair

**Fórmulas suportadas:** `+`, `-`, `*`, `/`, parênteses `()`, `SUM(A1:A5)`, `AVG(...)`, `MIN(...)`, `MAX(...)`, `COUNT(...)`, `ABS(x)`, `SQRT(x)`, `ROUND(x)`.

---

### 5.2. `nano` — Editor de Texto Simples (Recomendado para Iniciantes)
```sh
nano texto.txt     # (ou atalho: n texto.txt)
```
Basta digitar normalmente. Os atalhos ficam sempre visíveis no rodapé (`^` significa `Ctrl`):
- `Ctrl + O` e depois `Enter`: **salvar**
- `Ctrl + X`: **sair**
- `Ctrl + W`: **buscar** uma palavra
- `Ctrl + K`: recortar a linha atual | `Ctrl + U`: colar a linha

---

### 5.3. `vim` — Editor Avançado (Ótimo para o Teclado Físico)
```sh
vim arquivo.txt    # (ou atalho: v arquivo.txt)
```
O Vim tem **dois modos principais**:
1. **Modo Normal** (navegação — é como ele abre):
   - `h / j / k / l`: esquerda / baixo / cima / direita
   - `i`: entra no **Modo Inserção** para digitar texto
   - `dd`: apaga a linha inteira | `u`: desfaz última ação
   - `/palavra` + `Enter`: busca no texto (`n` vai para o próximo resultado)
   - `:w` + `Enter`: salvar | `:q` + `Enter`: sair | `:wq` + `Enter`: salvar e sair | `:q!` + `Enter`: sair sem salvar
2. **Modo Inserção** (digitando texto):
   - Digite **`jk`** ou **`jj`** rapidamente para voltar ao Modo Normal.

---

### 5.4. `tmux` — Múltiplas Telas / Abas no Terminal
Permite manter vários programas abertos ao mesmo tempo (por exemplo: shell, arquivos, notas e planilha).

```sh
work               # Inicia ou reconecta à sessão pronta "q5"
tmux new -s nome   # Cria uma nova sessão manualmente
tmux ls            # Lista sessões abertas
tmux attach        # Reconecta à última sessão
```

No BerryCore Q5, o comando prefixo do `tmux` é **`Ctrl + A`** (aperte `Ctrl+A`, solte, e depois aperte a próxima tecla):
- `Ctrl+A` depois `c`: cria nova aba (janela)
- `Ctrl+A` depois `1`, `2`, `3`: vai direto para a aba 1, 2 ou 3
- `Ctrl+A` depois `n` / `p`: próxima aba / aba anterior
- `Ctrl+A` depois `|`: divide a tela verticalmente | `Ctrl+A` depois `-`: divide horizontalmente
- `Ctrl+A` depois `[`: entra no modo rolagem (use `j`/`k` para subir/descer o histórico e `q` para sair)
- `Ctrl+A` depois `d`: desconecta da sessão (os programas continuam rodando em segundo plano!)

---

### 5.5. `q5-files` — Gerenciador de Arquivos Visual (TUI)
```sh
q5-files           # (ou atalho: f)
```
- `j / k`: desce / sobe na lista
- `l` ou `Enter`: entra na pasta ou visualiza o arquivo com `less`
- `h`: volta para a pasta pai
- `e`: abre o arquivo no `vim` | `n`: abre no `nano` | `v`: abre no `less`
- `.`: mostra/oculta arquivos escondidos | `q`: sair

---

### 5.6. `note` — Caderno de Notas Rápido (Markdown)
```sh
note               # Abre (ou cria) a nota de hoje (AAAA-MM-DD.md)
note ls            # Lista todas as suas notas por data
note find          # Busca e abre uma nota usando o seletor fuzzy (fzy)
note mercado       # Procura a palavra "mercado" dentro de todas as notas
note sync          # Faz commit/pull/push das notas se a pasta for um repo Git
```

---

### 5.7. `ncdu` — Ver o que Ocupa Espaço em Disco
```sh
ncdu /accounts/1000/shared
```
- `j / k`: navega entre pastas/arquivos (ordenados do maior para o menor)
- `Enter`: entra na pasta selecionada
- `d`: apaga o item selecionado (pede confirmação)
- `q`: sair

---

### 5.8. `bc` — Calculadora de Terminal
```sh
bc -l              # Abre a calculadora com suporte a decimais e funções matemáticas
```
Dentro do `bc`: digite `scale=2` para fixar 2 casas decimais, depois contas como `(150 * 1.15) / 3`. Digite `quit` para sair.

---

### 5.9. `sqlite3` — Banco de Dados Offline
```sh
sqlite3 meu_banco.db
```
Comandos úteis dentro do `sqlite3`:
```sql
.headers on        -- Mostra nomes das colunas
.mode column       -- Formata em tabela alinhada
.tables            -- Lista todas as tabelas do banco
SELECT * FROM itens LIMIT 10;
.quit              -- Sai do sqlite3
```

---

### 5.10. `git` — Versionamento e Sincronização com GitHub
```sh
git clone https://github.com/usuario/repo.git   # Baixa um repositório
gs                                              # Atalho para git status -sb
gd                                              # Atalho para git diff
git add .                                       # Prepara arquivos alterados
git commit -m "minha alteracao"                 # Salva versão local
git pull                                        # Baixa atualizações
git push                                        # Envia para o servidor
```

---

### 5.11. `ssh`, `scp` e `rsync` — Acesso Remoto e Backup
```sh
ssh usuario@192.168.0.10                        # Conecta no terminal de um PC/servidor
scp arquivo.csv usuario@192.168.0.10:~/         # Envia um arquivo para o PC
rsync -avz $DOCS/notes/ usuario@192.168.0.10:~/backup_q5/   # Sincroniza só o que mudou
```

---

### 5.12. `curl`, `jq` e `ai` — APIs, JSON e Assistente IA
```sh
curl -s https://api.github.com/zen              # Faz requisição HTTPS rápida
curl -s https://wttr.in/?format=3               # Clima em 1 linha
cat dados.json | jq '.usuario.nome'             # Extrai um campo de um JSON

# Assistente de IA no terminal (requer GEMINI_API_KEY ou OPENAI_API_KEY no ~/.bashrc)
ai "explique o comando tar em 3 linhas"
```

---

### 5.13. `w3m` (Web Texto) e `mutt` (E-mail CLI)
- **`w3m` (navegador em texto):**
  ```sh
  w3m https://lite.duckduckgo.com/lite/
  ```
  - `Tab` / `Shift+Tab`: pula entre links | `Enter`: abre link | `B`: volta página | `U`: digitar nova URL | `q`: sair.
- **`mutt` (e-mail via IMAP/SMTP):**
  - `j / k`: navega mensagens | `Enter`: ler e-mail | `m`: escrever novo | `r`: responder | `d`: apagar | `$`: confirmar alterações | `q`: sair.

---

## 6. Cola Rápida de Bolso (Resumo)

| Quero fazer... | Comando |
| :--- | :--- |
| Abrir menu de apps do Q5 | `m` |
| Navegar pastas visualmente | `f` |
| Abrir várias abas no terminal | `work` |
| Abrir/criar planilha de cálculo | `q5-sheet arquivo.csv` |
| Escrever nota de hoje | `note` |
| Editar texto (fácil / avançado) | `n arquivo` / `v arquivo` |
| Achar arquivo sem digitar caminho | `ff` |
| Ver o que está enchendo o Q5 | `ncdu /accounts/1000/shared` |
| Cancelar comando travado | `Ctrl + C` |
| Limpar a tela | `Ctrl + L` |
