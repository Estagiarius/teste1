#include <iostream>
#include <string>
#include <thread>
#include <vector>
#include <cstring>
#include <algorithm>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/select.h>
#include <fcntl.h>
#include <csignal>

#include "mbedtls/net_sockets.h"
#include "mbedtls/ssl.h"
#include "mbedtls/entropy.h"
#include "mbedtls/ctr_drbg.h"
#include "mbedtls/error.h"
#include "mbedtls/debug.h"

// Helper function to rewrite HTTP request and extract host
void process_http_request(std::string& request, std::string& host) {
    size_t host_pos = request.find("\r\nHost: ");
    if (host_pos == std::string::npos) {
        host_pos = request.find("\nHost: ");
    }

    if (host_pos != std::string::npos) {
        size_t start = host_pos + (request[host_pos] == '\r' ? 8 : 7);
        size_t end = request.find("\r\n", start);
        if (end == std::string::npos) end = request.find("\n", start);

        if (end != std::string::npos) {
            std::string host_line = request.substr(start, end - start);

            // Cleanup any trailing carriage returns explicitly
            host_line.erase(std::remove(host_line.begin(), host_line.end(), '\r'), host_line.end());

            size_t colon = host_line.find(':');
            if (colon != std::string::npos) {
                host = host_line.substr(0, colon);
            } else {
                host = host_line;
            }
        }
    }

    size_t first_space = request.find(' ');
    if (first_space != std::string::npos) {
        size_t second_space = request.find(' ', first_space + 1);
        if (second_space != std::string::npos) {
            std::string url = request.substr(first_space + 1, second_space - first_space - 1);
            if (url.find("http://") == 0) {
                size_t path_start = url.find('/', 7);
                std::string new_url;
                if (path_start == std::string::npos) {
                    new_url = "/";
                } else {
                    new_url = url.substr(path_start);
                }

                request.replace(first_space + 1, second_space - first_space - 1, new_url);
            }
        }
    }
}

void handle_client(int client_fd) {
    mbedtls_net_context server_fd;
    mbedtls_entropy_context entropy;
    mbedtls_ctr_drbg_context ctr_drbg;
    mbedtls_ssl_context ssl;
    mbedtls_ssl_config conf;

    mbedtls_net_init(&server_fd);
    mbedtls_ssl_init(&ssl);
    mbedtls_ssl_config_init(&conf);
    mbedtls_ctr_drbg_init(&ctr_drbg);
    mbedtls_entropy_init(&entropy);

    bool ssl_setup_done = false;

    auto cleanup = [&]() {
        if (ssl_setup_done) {
            mbedtls_ssl_close_notify(&ssl);
        }
        mbedtls_net_free(&server_fd);
        mbedtls_ssl_free(&ssl);
        mbedtls_ssl_config_free(&conf);
        mbedtls_ctr_drbg_free(&ctr_drbg);
        mbedtls_entropy_free(&entropy);
        close(client_fd);
    };

    const char *pers = "proxy_tls13";
    if (mbedtls_ctr_drbg_seed(&ctr_drbg, mbedtls_entropy_func, &entropy,
                              (const unsigned char *)pers, strlen(pers)) != 0) {
        cleanup();
        return;
    }

    char buffer[8192];
    memset(buffer, 0, sizeof(buffer));

    // Read the first HTTP request
    int bytes_read = read(client_fd, buffer, sizeof(buffer) - 1);
    if (bytes_read <= 0) {
        cleanup();
        return;
    }

    std::string request(buffer, bytes_read);
    std::string host;
    process_http_request(request, host);

    if (host.empty()) {
        cleanup();
        return;
    }

    if (mbedtls_net_connect(&server_fd, host.c_str(), "443", MBEDTLS_NET_PROTO_TCP) != 0) {
        cleanup();
        return;
    }

    if (mbedtls_ssl_config_defaults(&conf,
                                    MBEDTLS_SSL_IS_CLIENT,
                                    MBEDTLS_SSL_TRANSPORT_STREAM,
                                    MBEDTLS_SSL_PRESET_DEFAULT) != 0) {
        cleanup();
        return;
    }

    mbedtls_ssl_conf_authmode(&conf, MBEDTLS_SSL_VERIFY_NONE); // Optional: verify server cert for higher security
    mbedtls_ssl_conf_rng(&conf, mbedtls_ctr_drbg_random, &ctr_drbg);

#if defined(MBEDTLS_SSL_PROTO_TLS1_3)
    // Force TLS 1.3 if mbedtls version supports it natively
    mbedtls_ssl_conf_min_version(&conf, MBEDTLS_SSL_MAJOR_VERSION_3, MBEDTLS_SSL_MINOR_VERSION_4);
#endif

    if (mbedtls_ssl_setup(&ssl, &conf) != 0) {
        cleanup();
        return;
    }

    ssl_setup_done = true;

    if (mbedtls_ssl_set_hostname(&ssl, host.c_str()) != 0) {
        cleanup();
        return;
    }

    mbedtls_ssl_set_bio(&ssl, &server_fd, mbedtls_net_send, mbedtls_net_recv, NULL);

    int ret;
    while ((ret = mbedtls_ssl_handshake(&ssl)) != 0) {
        if (ret != MBEDTLS_ERR_SSL_WANT_READ && ret != MBEDTLS_ERR_SSL_WANT_WRITE) {
            cleanup();
            return;
        }
    }

    // Write the modified request
    ret = mbedtls_ssl_write(&ssl, (const unsigned char*)request.c_str(), request.length());
    if (ret <= 0) {
        cleanup();
        return;
    }

    fd_set read_fds;
    while (true) {
        FD_ZERO(&read_fds);
        FD_SET(client_fd, &read_fds);
        FD_SET(server_fd.fd, &read_fds);

        int max_fd = std::max(client_fd, server_fd.fd);

        bool has_buffered = mbedtls_ssl_get_bytes_avail(&ssl) > 0;

        struct timeval tv;
        tv.tv_sec = 60; // 60 sec timeout
        tv.tv_usec = 0;

        int activity = 0;
        if (!has_buffered) {
            activity = select(max_fd + 1, &read_fds, NULL, NULL, &tv);
            if (activity < 0) break;
            if (activity == 0) break;
        } else {
            activity = 1;
        }

        // Data from server to client
        if (has_buffered || FD_ISSET(server_fd.fd, &read_fds)) {
            ret = mbedtls_ssl_read(&ssl, (unsigned char*)buffer, sizeof(buffer));
            if (ret > 0) {
                int written = 0;
                while (written < ret) {
                    int w = write(client_fd, buffer + written, ret - written);
                    if (w <= 0) {
                        goto exit_loop;
                    }
                    written += w;
                }
            } else if (ret == MBEDTLS_ERR_SSL_WANT_READ || ret == MBEDTLS_ERR_SSL_WANT_WRITE) {
                // SSL logic needs to retry - ignore and loop
            } else if (ret == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY || ret <= 0) {
                break; // Server disconnected or fatal error
            }
        }

        // Data from client to server
        if (!has_buffered && FD_ISSET(client_fd, &read_fds)) {
            int len = read(client_fd, buffer, sizeof(buffer));
            if (len > 0) {
                int written = 0;
                while (written < len) {
                    ret = mbedtls_ssl_write(&ssl, (const unsigned char*)(buffer + written), len - written);
                    if (ret <= 0) {
                        goto exit_loop;
                    }
                    written += ret;
                }
            } else if (len <= 0) {
                break; // Client disconnected
            }
        }
    }

exit_loop:
    cleanup();
}

int main() {
    signal(SIGPIPE, SIG_IGN);

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd == -1) {
        std::cerr << "Failed to create socket." << std::endl;
        return 1;
    }

    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        std::cerr << "Failed to set SO_REUSEADDR." << std::endl;
        close(server_fd);
        return 1;
    }

    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK); // 127.0.0.1
    address.sin_port = htons(8080);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        std::cerr << "Failed to bind to 127.0.0.1:8080." << std::endl;
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 10) < 0) {
        std::cerr << "Failed to listen." << std::endl;
        close(server_fd);
        return 1;
    }

    std::cout << "Native Proxy (mbedTLS) listening on 127.0.0.1:8080..." << std::endl;

    while (true) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        int client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &client_len);

        if (client_fd >= 0) {
            // Protect against select() FD_SETSIZE limitations which can cause buffer overruns
            if (client_fd >= FD_SETSIZE) {
                std::cerr << "Max connections reached, dropping client." << std::endl;
                close(client_fd);
            } else {
                std::thread t(handle_client, client_fd);
                t.detach();
            }
        }
    }

    close(server_fd);
    return 0;
}
