;;;; src/import.lisp

;;; Define o pacote para o módulo de Produtividade, especificamente a Importação Inteligente.
(defpackage #:profgent/import
  (:use #:cl)
  ;; Importamos a função de criação de aluno para automatizar o cadastro
  (:import-from #:profgent/crud #:criar-aluno)
  (:export #:importar-alunos-csv))

(in-package #:profgent/import)

;;; =========================================================================
;;; FERRAMENTAS DE PRODUTIVIDADE: IMPORTAÇÃO CSV (FASE 3)
;;; =========================================================================

;;; Função para separar uma string baseada em um caractere delimitador (como vírgula).
;;; O Common Lisp padrão não tem 'split' embutido nativamente, então construímos um simples
;;; para manter a dependência do projeto leve.
(defun split-string-by-comma (string)
  "Divide uma linha de texto pelas vírgulas e devolve uma lista de palavras."
  (loop for i = 0 then (1+ j)
        as j = (position #\, string :start i)
        collect (subseq string i j)
        while j))

;;; Função principal que lê um arquivo de texto (.csv) e insere os alunos na base.
(defun importar-alunos-csv (caminho-arquivo turma-id)
  "Lê um arquivo CSV contendo 'nome,matricula' e cadastra automaticamente na turma informada."
  ;; A macro 'with-open-file' abre o arquivo com segurança e fecha automaticamente ao final,
  ;; evitando problemas de arquivos travados (file locks) no sistema operacional.
  (with-open-file (stream caminho-arquivo :direction :input :if-does-not-exist nil)
    (if stream
        ;; Se o arquivo existe e foi aberto, lemos linha por linha.
        (loop for linha = (read-line stream nil)
              while (and linha (string/= linha "")) do
                ;; Para cada linha, usamos nossa função para separar pelo delimitador (vírgula).
                (let ((dados (split-string-by-comma linha)))
                  ;; Verificação de segurança: ignorar linhas malformadas sem vírgula ou campos vazios
                  (when (>= (length dados) 2)
                    (let* (;; A primeira parte da linha (antes da vírgula) é o NOME.
                           ;; Usamos 'string-trim' para remover espaços em branco que o usuário possa ter deixado.
                           (nome (string-trim " " (first dados)))
                           ;; A segunda parte é a MATRICULA. Protegida caso o second não seja string.
                           (matricula-raw (second dados))
                           (matricula (if matricula-raw (string-trim " " matricula-raw) "")))

                      ;; Somente insere se ambos os campos forem válidos
                      (when (and (string/= nome "") (string/= matricula ""))
                        ;; Imprimimos no console o progresso (útil para auditoria)
                        (format t "Importando Aluno: ~A (Matrícula: ~A) para a turma ID ~A~%" nome matricula turma-id)

                        ;; Chamamos a função de banco de dados para criar o aluno.
                        ;; Em um caso real, englobaríamos em 'handler-case' para pular duplicatas (matrícula já existe).
                        (handler-case (criar-aluno nome matricula turma-id)
                          (error (e)
                            (format t "Falha ao importar matrícula ~A: Já existe ou formato inválido.~%" matricula))))))))

        ;; Caso o arquivo não seja encontrado, mostramos um aviso no console.
        (format t "Erro: O arquivo ~A não foi encontrado.~%" caminho-arquivo)))
  ;; Retorna sucesso.
  t)
