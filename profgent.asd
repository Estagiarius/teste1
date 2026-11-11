;;;; profgent.asd

;;; Define o pacote para a definição do sistema ASDF
(defpackage #:profgent-system
  (:use #:cl #:asdf))

(in-package #:profgent-system)

;;; Definição principal do projeto ProfGent
;;; O ASDF (Another System Definition Facility) é a ferramenta padrão em Common Lisp
;;; para gerenciar como o projeto é compilado e carregado. Pense nele como o 'package.json'
;;; ou 'pom.xml' do Common Lisp.
(defsystem "profgent"
  ;; Breve descrição do projeto
  :description "ProfGent - Sistema de Gerenciamento Escolar"
  ;; Versão atual (iniciando em 0.1.0 para a primeira fase da cascata)
  :version "0.1.0"
  ;; Autor ou criador do projeto
  :author "Agente de IA"
  ;; Licença de uso
  :licence "MIT"
  ;; Dependências externas do projeto
  ;; - cl-sqlite: Utilizado para comunicação com o banco de dados SQLite.
  ;; - ltk: Lisp Toolkit, utilizado para a criação da Interface Gráfica de Usuário (GUI) usando Tcl/Tk.
  :depends-on ("cl-sqlite"
               "ltk")
  ;; Componentes do sistema (os arquivos fonte e sua ordem de carregamento)
  :components ((:module "src"
                :components
                (;; O arquivo 'db' configura a conexão e criação de tabelas.
                 (:file "db")
                 ;; O arquivo 'crud' gerencia as regras de negócio (inserir, ler, atualizar, deletar),
                 ;; ele depende de 'db' estar carregado primeiro.
                 (:file "crud" :depends-on ("db"))
                 ;; O arquivo 'ai' contém o mock de design do Assistente Inteligente.
                 (:file "ai")
                 ;; O arquivo 'gui' monta a interface gráfica e depende das lógicas em 'crud', 'db' e 'ai'.
                 (:file "gui" :depends-on ("crud" "db" "ai"))))))
