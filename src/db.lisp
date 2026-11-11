;;;; src/db.lisp

;;; Define um novo pacote (namespace) chamado profgent/db.
;;; Isso evita conflitos de nomes com outras partes do sistema.
;;; Usamos os pacotes padrôes 'cl' (Common Lisp) e exportamos as funções que serão usadas fora deste arquivo.
(defpackage #:profgent/db
  (:use #:cl)
  (:export #:*db-path*
           #:init-db
           #:with-db))

;;; Diz ao Lisp que todo o código a seguir pertence ao pacote profgent/db
(in-package #:profgent/db)

;;; Define uma variável global chamada *db-path* que guarda o caminho para o arquivo do banco de dados.
;;; Os 'asteriscos' (*) ao redor do nome (earmuffs) são uma convenção em Lisp para indicar uma variável global especial.
;;; O merge-pathnames é usado para garantir que o banco fique na pasta 'db/' relativa a onde o sistema ASDF foi carregado.
(defparameter *db-path*
  (merge-pathnames "db/profgent.sqlite" (asdf:system-source-directory "profgent"))
  "Caminho absoluto para o arquivo de banco de dados SQLite.")

;;; Cria uma macro (uma forma de reescrever código) chamada 'with-db'.
;;; Esta macro é usada para facilitar e garantir a conexão com o banco.
;;; O que ela faz: toda vez que quisermos rodar comandos no banco de dados, usamos essa macro.
;;; Ela cuida de abrir a conexão, executar o que precisamos (o parâmetro &body body) e, muito importante,
;;; fechar a conexão no final de forma automática, garantindo que não teremos vazamento de memória ou banco bloqueado.
(defmacro with-db ((db-var) &body body)
  "Macro que abre uma conexão SQLite com o banco de dados, vincula a conexão à variável informada 'db-var', executa o 'body', e garante o fechamento no final."
  `(sqlite:with-open-database (,db-var *db-path*)
     (declare (ignorable ,db-var))
     ,@body))

;;; Função para inicializar o banco de dados.
;;; Esta função é responsável por criar o arquivo .sqlite e construir as tabelas primárias se elas ainda não existirem.
;;; O Project Manager ou outro usuário rodará essa função apenas uma vez no começo do projeto (ou quando resetar o banco).
(defun init-db ()
  "Cria o banco de dados e as tabelas iniciais (Alunos e Turmas) se elas não existirem."
  ;; Abre a conexão com o banco usando a macro criada acima.
  (with-db (db)

    ;; 1. Cria a tabela TURMAS
    ;; Usamos 'CREATE TABLE IF NOT EXISTS' para que não dê erro se rodarmos essa função mais de uma vez.
    ;; id: um número único que identifica a turma, gerado automaticamente.
    ;; nome: o nome da turma (ex: '8º Ano A').
    ;; ano_letivo: o ano a que a turma pertence (ex: 2024).
    (sqlite:execute-non-query db
      "CREATE TABLE IF NOT EXISTS turmas (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         nome TEXT NOT NULL,
         ano_letivo TEXT NOT NULL
       )")

    ;; 2. Cria a tabela ALUNOS
    ;; id: identificador único do aluno.
    ;; nome: nome completo do aluno.
    ;; matricula: o código de registro do aluno na escola.
    ;; turma_id: chave estrangeira que liga este aluno a uma turma específica.
    (sqlite:execute-non-query db
      "CREATE TABLE IF NOT EXISTS alunos (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         nome TEXT NOT NULL,
         matricula TEXT NOT NULL UNIQUE,
         turma_id INTEGER,
         FOREIGN KEY(turma_id) REFERENCES turmas(id)
       )")

    ;; 3. Cria a tabela DISCIPLINAS
    ;; Representa matérias como Matemática, Português, etc.
    (sqlite:execute-non-query db
      "CREATE TABLE IF NOT EXISTS disciplinas (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         nome TEXT NOT NULL UNIQUE
       )")

    ;; 4. Cria a tabela AVALIACOES
    ;; Representa as provas ou trabalhos de uma turma e disciplina específica.
    (sqlite:execute-non-query db
      "CREATE TABLE IF NOT EXISTS avaliacoes (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         nome TEXT NOT NULL,
         data TEXT NOT NULL,
         turma_id INTEGER,
         disciplina_id INTEGER,
         FOREIGN KEY(turma_id) REFERENCES turmas(id),
         FOREIGN KEY(disciplina_id) REFERENCES disciplinas(id)
       )")

    ;; 5. Cria a tabela NOTAS
    ;; Relaciona um aluno a uma avaliação com o valor da nota obtida.
    (sqlite:execute-non-query db
      "CREATE TABLE IF NOT EXISTS notas (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         aluno_id INTEGER,
         avaliacao_id INTEGER,
         valor REAL NOT NULL,
         FOREIGN KEY(aluno_id) REFERENCES alunos(id),
         FOREIGN KEY(avaliacao_id) REFERENCES avaliacoes(id)
       )")

    ;; 6. Cria a tabela AULAS_BNCC
    ;; Registra os planos de aula e as competências da BNCC utilizadas na aula.
    (sqlite:execute-non-query db
      "CREATE TABLE IF NOT EXISTS aulas_bncc (
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         turma_id INTEGER,
         disciplina_id INTEGER,
         data TEXT NOT NULL,
         codigo_bncc TEXT NOT NULL,
         descricao TEXT NOT NULL,
         FOREIGN KEY(turma_id) REFERENCES turmas(id),
         FOREIGN KEY(disciplina_id) REFERENCES disciplinas(id)
       )")

    ;; Retorna a palavra :ok simbolizando sucesso para quem chamou a função.
    :ok))
