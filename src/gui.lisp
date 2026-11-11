;;;; src/gui.lisp

;;; Define o pacote para a Interface Gráfica de Usuário (GUI).
;;; A GUI será responsável por exibir telas e janelas usando a biblioteca LTk (Lisp Toolkit),
;;; uma ligação Lisp para o clássico framework Tcl/Tk.
(defpackage #:profgent/gui
  (:use #:cl #:ltk)
  ;; Importa a lógica do banco de dados (para inicializá-lo, se necessário) e as funções CRUD.
  (:import-from #:profgent/db #:init-db)
  (:import-from #:profgent/crud #:listar-turmas)
  ;; Exporta a função principal para iniciar a aplicação visual.
  (:export #:iniciar-app))

(in-package #:profgent/gui)

;;; =========================================================================
;;; INTERFACE GRÁFICA DO USUÁRIO (LTK)
;;; =========================================================================

;;; Função principal que o usuário executa para abrir o programa.
(defun iniciar-app ()
  "Inicia a aplicação GUI do ProfGent, abrindo a janela principal do sistema."

  ;; Passo de precaução: Antes de tentar listar ou adicionar dados,
  ;; rodamos a inicialização do banco para garantir que o arquivo e as tabelas existam!
  (init-db)

  ;; A macro with-ltk é o coração da interface.
  ;; Ela cuida de iniciar e desligar o processo de janelas Tcl/Tk em plano de fundo.
  ;; O programa inteiro do usuário rodará DENTRO desse bloco de código.
  (with-ltk ()
    ;; Configura o título da janela principal
    (wm-title *tk* "ProfGent - Sistema de Gerenciamento Escolar")

    ;; 1. Criação do "Frame" principal
    ;; O Frame é como uma "caixa" ou contêiner invisível na tela que usamos para organizar os elementos.
    (let* ((main-frame (make-instance 'frame)))

      ;; O 'pack' é o gerenciador de layout do Tk. Ao empacotar o frame,
      ;; dizemos para ele ocupar espaço na janela.
      (pack main-frame :fill :both :expand t)

      ;; 2. Rótulo (Label) de boas-vindas
      ;; Criamos um texto que será exibido no topo da tela.
      (let ((lbl-titulo (make-instance 'label
                                       :master main-frame
                                       :text "Bem-vindo ao ProfGent - Fase 1 (Cascata)")))
        ;; O 'pack' empacota esse texto no topo do frame.
        (pack lbl-titulo :side :top :pady 20))

      ;; 3. Criação de um Botão para ver turmas no log/console
      ;; O botão, quando clicado (comando em 'command'), vai rodar a função 'listar-turmas'
      ;; e imprimir o resultado para facilitar a verificação durante a Fase 1 de desenvolvimento.
      (let ((btn-test (make-instance 'button
                                     :master main-frame
                                     :text "Listar Turmas no Console"
                                     ;; Define o que o botão faz ao ser clicado (uma função anônima, ou lambda)
                                     :command (lambda ()
                                                (let ((turmas (listar-turmas)))
                                                  ;; A função format imprime no log do sistema.
                                                  ;; O ~a é onde a lista de turmas vai entrar.
                                                  (format t "As turmas cadastradas são: ~a~%" turmas))))))
        ;; Empacota o botão logo abaixo do título
        (pack btn-test :side :top :pady 10))

      ;; 4. Botão de Saída
      ;; Um botão simples para fechar a janela.
      (let ((btn-sair (make-instance 'button
                                     :master main-frame
                                     :text "Sair"
                                     ;; Em LTk, se quisermos fechar o sistema, podemos só usar (setf *exit-mainloop* t)
                                     ;; ou terminar o processo Tk.
                                     :command (lambda ()
                                                (setf *exit-mainloop* t)))))
        ;; Empacota o botão de saída e posiciona-o na parte inferior do contêiner.
        (pack btn-sair :side :bottom :pady 20)))))
