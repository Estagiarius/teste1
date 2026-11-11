;;;; src/gui.lisp

;;; Define o pacote para a Interface Gráfica de Usuário (GUI).
;;; A GUI será responsável por exibir telas e janelas usando a biblioteca LTk (Lisp Toolkit),
;;; uma ligação Lisp para o clássico framework Tcl/Tk.
(defpackage #:profgent/gui
  (:use #:cl #:ltk)
  ;; Importa a lógica do banco de dados (para inicializá-lo, se necessário) e as funções CRUD.
  (:import-from #:profgent/db #:init-db)
  (:import-from #:profgent/crud #:listar-turmas)
  (:import-from #:profgent/ai #:processar-comando-ia)
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

    ;; O gerenciador de geometria da janela principal.
    (wm-geometry *tk* "800x600")

    ;; 1. Criação de um NoteBook (Sistema de Abas)
    ;; O NoteBook permite separar os diferentes módulos do sistema em abas,
    ;; organizando a Fase 2 (Design de Sistema).
    (let* ((notebook (make-instance 'notebook))

           ;; Aba 1: Dashboard e Assistente de IA
           (tab-dash (make-instance 'frame :master notebook))

           ;; Aba 2: Gestão Acadêmica (CRUD)
           (tab-crud (make-instance 'frame :master notebook))

           ;; Aba 3: Horários e BNCC
           (tab-horarios (make-instance 'frame :master notebook)))

      ;; Empacota o notebook para ocupar toda a janela principal.
      (pack notebook :fill :both :expand t)

      ;; Adiciona os frames como abas no notebook, com seus respectivos títulos.
      (notebook-add notebook tab-dash :text "Dashboard & IA")
      (notebook-add notebook tab-crud :text "Gestão Acadêmica (CRUD)")
      (notebook-add notebook tab-horarios :text "Horários & BNCC")

      ;; --- CONTEÚDO DA ABA 1: DASHBOARD ---
      (let ((lbl-dash (make-instance 'label
                                     :master tab-dash
                                     :text "Bem-vindo ao ProfGent (Wireframe - Fase 2)")))
        (pack lbl-dash :side :top :pady 20))

      ;; Frame para o "Assistente de IA" na Aba 1
      (let ((ai-frame (make-instance 'labelframe :master tab-dash :text "Assistente Inteligente (Mock)")))
        (pack ai-frame :fill :x :padx 20 :pady 10)

        ;; Entrada de texto para interagir com a IA (O placeholder da Fase 2)
        (let* ((ai-input (make-instance 'entry :master ai-frame))
               (btn-ai (make-instance 'button
                                      :master ai-frame
                                      :text "Perguntar à IA"
                                      :command (lambda ()
                                                 (let* ((input-text (text ai-input))
                                                        (resposta (processar-comando-ia input-text)))
                                                   (format t "IA Responde: ~A~%" resposta)
                                                   ;; Limpa o campo de texto após enviar
                                                   (setf (text ai-input) ""))))))
          (pack ai-input :side :left :fill :x :expand t :padx 5 :pady 5)
          (pack btn-ai :side :right :padx 5 :pady 5)))

      ;; --- CONTEÚDO DA ABA 2: CRUD ---
      (let ((lbl-crud (make-instance 'label
                                     :master tab-crud
                                     :text "Módulo de Cadastros - Alunos, Turmas, Disciplinas")))
        (pack lbl-crud :side :top :pady 20))

      ;; Botão simulando a listagem (Mantido da Fase 1, realocado para cá)
      (let ((btn-test (make-instance 'button
                                     :master tab-crud
                                     :text "Listar Turmas no Console"
                                     :command (lambda ()
                                                (let ((turmas (listar-turmas)))
                                                  (format t "As turmas cadastradas são: ~a~%" turmas))))))
        (pack btn-test :side :top :pady 10))

      ;; --- CONTEÚDO DA ABA 3: HORÁRIOS ---
      (let ((lbl-horario (make-instance 'label
                                        :master tab-horarios
                                        :text "Módulo de Alocação Semanal e Planejamento BNCC")))
        (pack lbl-horario :side :top :pady 20)))

    ;; Botão de Saída fixo no fundo da janela (fora do Notebook)
    (let ((btn-sair (make-instance 'button
                                   :text "Sair"
                                   :command (lambda ()
                                              (setf *exit-mainloop* t)))))
      (pack btn-sair :side :bottom :pady 10))))
