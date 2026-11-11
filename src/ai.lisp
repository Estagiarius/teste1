;;;; src/ai.lisp

;;; Define o pacote para o módulo do Assistente de Inteligência Artificial.
;;; Este arquivo representa o design do fluxo do Assistente para a Fase 2 (Wireframing e Planejamento).
(defpackage #:profgent/ai
  (:use #:cl)
  (:export #:processar-comando-ia))

(in-package #:profgent/ai)

;;; =========================================================================
;;; DESIGN DO ASSISTENTE DE IA (FASE 2)
;;; =========================================================================

;;; A função abaixo serve como um "mock" (simulação) do fluxo de NLP
;;; (Processamento de Linguagem Natural) que será implementado na Fase 3.
;;;
;;; Fluxo Planejado:
;;; 1. O usuário digita um texto (ex: "Qual a média da turma 8A?").
;;; 2. O texto chega nesta função através da GUI.
;;; 3. [Futuro] O texto é enviado para uma API de LLM ou um modelo local.
;;; 4. [Futuro] O modelo traduz a intenção para uma consulta SQL segura.
;;; 5. [Futuro] O módulo de banco (db.lisp) executa a consulta.
;;; 6. A resposta é formatada e devolvida em linguagem natural para a GUI.
(defun processar-comando-ia (texto-input)
  "Simula o recebimento de um comando de linguagem natural e o planejamento do processamento."

  ;; Simula a leitura e interpretação básica do texto inserido
  (format t "IA recebeu o comando: ~A~%" texto-input)
  (format t "IA: [Simulando processamento via NLP...]~%")

  ;; Em vez de realmente chamar a IA agora, retornamos um texto explicativo (placeholder).
  ;; Isso permite que a equipe valide a interface (Aba 1 do Notebook) e o fluxo da GUI sem
  ;; se preocupar com custos de API ou complexidade de backend na Fase 2.
  (let ((resposta-mock (format nil "Entendi. Você disse: '~A'. Na Fase 3, eu traduzirei isso para uma ação no banco de dados." texto-input)))
    ;; Devolve a string de resposta simulada.
    resposta-mock))
