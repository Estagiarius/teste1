# Native Proxy TLS 1.3 para BlackBerry 10

## Visão Geral
Este módulo (`native-proxy`) é um daemon de rede leve e autônomo projetado especificamente para o sistema operacional QNX 6.5 / BlackBerry 10 (foco no BlackBerry Q5/Q10/Z10/Passport).
Dispositivos legados enfrentam problemas para navegar na web moderna devido à obsolescência de seus conjuntos de cifras criptográficas e à falta de suporte ao protocolo TLS 1.3 nativo no navegador.

A solução consiste em um servidor de **Loopback Local (127.0.0.1:8080)** construído em **C++11 estrito**. Ele opera capturando o tráfego HTTP limpo enviado pelo navegador interno, e repassando (tunelando) transparentemente esses bytes de forma assíncrona para a internet usando a biblioteca **mbedTLS** encriptada em TLS 1.3.

A arquitetura inclui:
- Proteção de Threading Limitada para o processador Cortex-A7 (uso de PRNG/DRBG compartilhado).
- Prevenção ativa contra Memory Leaks via controle restrito de Sockets (fechamento forçado no limite do Kernel `FD_SETSIZE`).
- Script Daemon/Watchdog integrado e silencioso.

## Pré-requisitos
Para compilar este módulo, é estritamente necessário ter o ambiente configurado com as ferramentas oficiais da plataforma:
1. **BlackBerry 10 Native Development Kit (NDK)** instalado.
2. Variáveis de ambiente de cross-compiling (QNX_HOST e QNX_TARGET) definidas na sua sessão bash (Geralmente chamando `source bbndk-env.sh`).
3. **CMake** instalado na máquina Host (Windows/Linux/macOS).
4. Código-fonte do **mbedTLS** (2.x ou 3.x) (normalmente buildado pelo script `build_dependencies.sh` na raiz do projeto).

## Instruções de Compilação
Como a compilação depende do ecossistema NDK do BlackBerry, siga este roteiro no terminal host:

1. **Ative o ambiente do NDK:**
   ```bash
   source ~/qnx/bbndk/bbndk-env.sh
   ```
2. **Crie e entre no diretório de build:**
   ```bash
   mkdir build && cd build
   ```
3. **Invoque o CMake com o Toolchain do QNX:**
   (Ajuste o caminho do toolchain file caso necessário)
   ```bash
   cmake .. -DCMAKE_TOOLCHAIN_FILE=../qnx.toolchain.cmake
   ```
4. **Compile o binário estaticamente:**
   ```bash
   make proxy_tls13
   ```
   *O arquivo executável gerado chamará `proxy_tls13`*.

## Instalação e Execução no Dispositivo

Devido às restrições do microkernel QNX e o Sandboxing de aplicativos, os binários devem ficar contidos no espaço do usuário padrão do BB10.

1. Conecte-se ao seu dispositivo via SSH ou Sideload Tool via Wi-Fi/USB.
2. Envie os arquivos `proxy_tls13` e o `watchdog.sh` para o armazenamento compartilhado:
   ```bash
   scp proxy_tls13 watchdog.sh root@<IP_DO_BLACKBERRY>:/accounts/1000/shared/documents/
   ```
3. Acesse o aparelho via SSH, aplique as permissões corretas de execução aos arquivos:
   ```bash
   chmod +x /accounts/1000/shared/documents/proxy_tls13
   chmod +x /accounts/1000/shared/documents/watchdog.sh
   ```
4. **Inicialize o Watchdog em Background:**
   ```bash
   sh /accounts/1000/shared/documents/watchdog.sh &
   ```
   *Nota: O script Watchdog verificará a cada 45 segundos se o proxy está ativo e o levantará novamente de forma silenciosa para evitar consumo de bateria.*

## Uso
Com o daemon rodando, abra o **Navegador Nativo do BlackBerry**.
1. Vá nas Configurações da Conexão e Defina o **Servidor Proxy HTTP** para `127.0.0.1` e a porta para `8080`.
2. Acesse sites em texto plano (`http://example.com`); o proxy irá reescrever a requisição, capturar a porta HTTPS externa e exibir o site devidamente encriptado usando o Open/mbedTLS moderno por trás dos panos!
