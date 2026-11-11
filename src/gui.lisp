;;;; src/gui.lisp

;;; Define o pacote para a Interface Gráfica de Usuário (GUI).
;;; A GUI será responsável por exibir telas e janelas usando a biblioteca LTk (Lisp Toolkit),
;;; uma ligação Lisp para o clássico framework Tcl/Tk.
(defpackage #:profgent/gui
  (:use #:cl #:ltk)
  ;; Importa a lógica do banco de dados (para inicializá-lo, se necessário) e as funções CRUD.
  (:import-from #:profgent/db #:init-db)
  (:import-from #:profgent/crud #:listar-turmas #:criar-turma #:criar-aluno)
  (:import-from #:profgent/ai #:processar-comando-ia)
  (:import-from #:profgent/import #:importar-alunos-csv)
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

      ;; --- CONTEÚDO DA ABA 2: CRUD (IMPLEMENTAÇÃO FASE 3) ---
      ;; Vamos criar um contêiner para organizar o formulário de "Nova Turma"
      (let ((form-frame (make-instance 'labelframe :master tab-crud :text "Cadastrar Nova Turma")))
        (pack form-frame :fill :x :padx 20 :pady 10)

        ;; Grid (grade) para organizar os campos (Rótulo ao lado da Entrada)
        (let ((lbl-nome (make-instance 'label :master form-frame :text "Nome da Turma:"))
              (entry-nome (make-instance 'entry :master form-frame))
              (lbl-ano (make-instance 'label :master form-frame :text "Ano Letivo:"))
              (entry-ano (make-instance 'entry :master form-frame)))

          ;; Empacotamos os rótulos e as entradas de texto em ordem
          (pack lbl-nome :side :left :padx 5)
          (pack entry-nome :side :left :padx 5)
          (pack lbl-ano :side :left :padx 5)
          (pack entry-ano :side :left :padx 5)

          ;; Listbox para mostrar os cadastros visualmente na GUI
          (let ((lista-gui (make-instance 'listbox :master tab-crud)))
            (pack lista-gui :fill :both :expand t :padx 20 :pady 10)

            ;; Botão que lê as entradas de texto e salva no banco de dados SQLite
            (let ((btn-salvar (make-instance 'button
                                             :master form-frame
                                             :text "Salvar Turma"
                                             :command (lambda ()
                                                        (let ((n (text entry-nome))
                                                              (a (text entry-ano)))
                                                          ;; Chama a função real de negócio
                                                          (criar-turma n a)
                                                          ;; Atualiza o log e a lista visual
                                                          (format t "Nova turma salva: ~A (~A)~%" n a)
                                                          (listbox-append lista-gui (format nil "Turma: ~A - Ano: ~A" n a))
                                                          ;; Limpa os campos de input
                                                          (setf (text entry-nome) "")
                                                          (setf (text entry-ano) ""))))))
              (pack btn-salvar :side :left :padx 15))

            ;; NOVO CONTÊINER: Formulário para "Novo Aluno"
            (let ((form-aluno (make-instance 'labelframe :master tab-crud :text "Cadastrar Novo Aluno")))
              (pack form-aluno :fill :x :padx 20 :pady 10)

              (let ((lbl-aluno-nome (make-instance 'label :master form-aluno :text "Nome:"))
                    (entry-aluno-nome (make-instance 'entry :master form-aluno))
                    (lbl-mat (make-instance 'label :master form-aluno :text "Matrícula:"))
                    (entry-mat (make-instance 'entry :master form-aluno))
                    (lbl-tid (make-instance 'label :master form-aluno :text "ID Turma:"))
                    (entry-tid (make-instance 'entry :master form-aluno :width 5)))

                (pack lbl-aluno-nome :side :left :padx 5)
                (pack entry-aluno-nome :side :left :padx 5)
                (pack lbl-mat :side :left :padx 5)
                (pack entry-mat :side :left :padx 5)
                (pack lbl-tid :side :left :padx 5)
                (pack entry-tid :side :left :padx 5)

                (let ((btn-salvar-aluno (make-instance 'button
                                                       :master form-aluno
                                                       :text "Salvar Aluno"
                                                       :command (lambda ()
                                                                  (let* ((nome (text entry-aluno-nome))
                                                                         (mat (text entry-mat))
                                                                         ;; Parseia o ID da turma de texto para número. Se falhar usa 0.
                                                                         (tid-texto (text entry-tid))
                                                                         (tid (or (parse-integer tid-texto :junk-allowed t) 0)))
                                                                    ;; Chama a função do CRUD para Alunos
                                                                    (handler-case
                                                                        (progn
                                                                          (criar-aluno nome mat tid)
                                                                          (listbox-append lista-gui (format nil "Aluno: ~A (Mat: ~A) -> Turma ID: ~A" nome mat tid))
                                                                          (setf (text entry-aluno-nome) "")
                                                                          (setf (text entry-mat) "")
                                                                          (setf (text entry-tid) ""))
                                                                      (error (e)
                                                                        (format t "Erro ao salvar aluno (Matricula duplicada ou turma nao existe).~%"))))))))
                  (pack btn-salvar-aluno :side :left :padx 15)))))))

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
