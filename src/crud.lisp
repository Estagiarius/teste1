;;;; src/crud.lisp

;;; Define o pacote (namespace) que agrupa as lógicas de CRUD (Create, Read, Update, Delete).
;;; Este arquivo cuida apenas das regras de negócio (manipulação de dados de Alunos e Turmas).
(defpackage #:profgent/crud
  (:use #:cl)
  ;; Importa a macro que usamos para abrir e fechar a conexão do banco em segurança.
  (:import-from #:profgent/db #:with-db)
  ;; Exporta as funções que a Interface Gráfica (GUI) poderá chamar futuramente.
  (:export #:criar-turma
           #:listar-turmas
           #:criar-aluno
           #:listar-alunos
           #:deletar-aluno
           #:criar-disciplina
           #:criar-avaliacao))

(in-package #:profgent/crud)

;;; =========================================================================
;;; MÓDULO: TURMAS
;;; =========================================================================

;;; Função para inserir uma nova Turma no banco.
;;; Recebe o NOME da turma e o ANO-LETIVO (ambos textos/strings).
(defun criar-turma (nome ano-letivo)
  "Insere uma nova turma no banco de dados e retorna T em caso de sucesso."
  ;; Abre a conexão com o banco de dados.
  (with-db (db)
    ;; Executa um comando SQL (INSERT INTO).
    ;; Os pontos de interrogação (?) previnem "SQL Injection" (ataques onde código malicioso
    ;; é inserido via formulários). A biblioteca cl-sqlite troca os ? por NOME e ANO-LETIVO com segurança.
    (sqlite:execute-non-query db
      "INSERT INTO turmas (nome, ano_letivo) VALUES (?, ?)"
      nome ano-letivo))
  ;; Retorna True (T em Lisp) indicando que a função terminou bem.
  t)

;;; Função para ler todas as Turmas cadastradas.
(defun listar-turmas ()
  "Lê e retorna todas as turmas cadastradas como uma lista de listas."
  ;; Abre conexão
  (with-db (db)
    ;; A função execute-to-list devolve todos os registros achados na consulta SELECT.
    ;; O formato de retorno será algo como: ((1 "8º Ano" "2024") (2 "9º Ano" "2024"))
    (sqlite:execute-to-list db
      "SELECT id, nome, ano_letivo FROM turmas")))


;;; =========================================================================
;;; MÓDULO: ALUNOS
;;; =========================================================================

;;; Função para inserir um novo Aluno no banco.
;;; Recebe o NOME, MATRICULA (que deve ser única) e o ID da Turma em que ele estuda.
(defun criar-aluno (nome matricula turma-id)
  "Insere um novo aluno associando-o a uma turma existente."
  ;; Abre conexão
  (with-db (db)
    ;; Executa inserção com parâmetros protegidos (?)
    (sqlite:execute-non-query db
      "INSERT INTO alunos (nome, matricula, turma_id) VALUES (?, ?, ?)"
      nome matricula turma-id))
  t)

;;; Função para listar os Alunos.
;;; Se passarmos o argumento opcional (turma-id), ele lista APENAS os alunos daquela turma.
;;; Se não passarmos nada (ou passarmos nil), ele lista TODOS os alunos da escola.
(defun listar-alunos (&optional turma-id)
  "Retorna a lista de alunos. Opcionalmente filtrado pelo ID da turma."
  (with-db (db)
    ;; Verifica se o filtro de turma foi enviado
    (if turma-id
        ;; Se turma-id existe, rodamos uma consulta SELECT usando a cláusula WHERE para filtrar.
        ;; CORREÇÃO DE BUG: Adicionado 'turma_id' na seleção para manter a mesma aridade/formato
        ;; em todos os retornos e evitar crashes na listagem da GUI (LTk Treeview).
        (sqlite:execute-to-list db
          "SELECT id, nome, matricula, turma_id FROM alunos WHERE turma_id = ?"
          turma-id)

        ;; Caso contrário, simplesmente lemos e listamos a tabela de alunos inteira.
        (sqlite:execute-to-list db
          "SELECT id, nome, matricula, turma_id FROM alunos"))))

;;; Função para excluir um aluno do banco (útil caso haja transferências de escola ou erros).
(defun deletar-aluno (aluno-id)
  "Remove o aluno específico do banco de dados pelo seu ID."
  (with-db (db)
    (sqlite:execute-non-query db
      "DELETE FROM alunos WHERE id = ?"
      aluno-id))
  t)

;;; =========================================================================
;;; MÓDULO: DISCIPLINAS E AVALIAÇÕES (FASE 2)
;;; =========================================================================

;;; Função para inserir uma nova Disciplina (ex: "Matemática")
(defun criar-disciplina (nome)
  "Insere uma nova disciplina no banco de dados."
  (with-db (db)
    (sqlite:execute-non-query db
      "INSERT INTO disciplinas (nome) VALUES (?)"
      nome))
  t)

;;; Função para criar uma Avaliação que pertence a uma turma e uma disciplina
(defun criar-avaliacao (nome data turma-id disciplina-id)
  "Cria um registro de avaliação ou prova."
  (with-db (db)
    (sqlite:execute-non-query db
      "INSERT INTO avaliacoes (nome, data, turma_id, disciplina_id) VALUES (?, ?, ?, ?)"
      nome data turma-id disciplina-id))
  t)
