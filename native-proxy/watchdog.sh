#!/bin/sh
#
# Watchdog e Daemon de Inicialização para o Proxy TLS 1.3
# Compatível com ksh / pdksh do BlackBerry 10 / QNX 6.5
#

# Definição de caminhos absolutos no Sandbox do usuário no BB10
PROXY_BIN="/accounts/1000/shared/documents/proxy_tls13"
LOG_FILE="/accounts/1000/shared/documents/proxy_watchdog.log"
PROXY_NAME="proxy_tls13"

# Função para registrar mensagens de log com data e hora
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Verifica se o binário tem permissão de execução
if [ ! -x "$PROXY_BIN" ]; then
    log_msg "ERRO: Binario $PROXY_BIN nao encontrado ou sem permissao de execucao."
    exit 1
fi

log_msg "Iniciando Watchdog do Proxy TLS 1.3..."

# Loop infinito de monitoramento (Watchdog)
while true; do
    # Verifica se o processo já está rodando.
    # No QNX/BB10, 'pidof' costuma estar disponível. Caso não esteja,
    # uma alternativa segura é usar 'ps -A' filtrando com grep
    # (ignorando o próprio grep na busca).
    if ! ps -A | grep -v grep | grep -q "$PROXY_NAME"; then
        log_msg "AVISO: Instancia do $PROXY_NAME nao encontrada. Iniciando processo em background."

        # Inicia o proxy em background, redirecionando saída de erro e padrão para /dev/null
        # para evitar encher o disco local com logs do próprio daemon, mantendo-o silencioso.
        "$PROXY_BIN" >/dev/null 2>&1 &

        # Obtém o PID do último processo em background iniciado pelo script
        NEW_PID=$!
        log_msg "INFO: $PROXY_NAME iniciado com sucesso (PID: $NEW_PID)."
    fi

    # Dorme por 45 segundos para liberar a CPU do Cortex-A7 (consumo ~0%)
    sleep 45
done
