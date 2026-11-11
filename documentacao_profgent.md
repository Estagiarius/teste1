# ProfGent - Documentação de Requisitos e Plano de Projeto

## 1. Visão Geral do Sistema
O **ProfGent** é um sistema de gerenciamento escolar voltado para simplificar a administração de turmas, alunos, notas e horários. Ele é desenvolvido em Common Lisp e focado na facilidade de uso, estabilidade e produtividade, integrando ferramentas de automação e um assistente inteligente.

## 2. Stack Tecnológica (Diretivas Arquiteturais)
*   **Linguagem:** Common Lisp.
*   **Interface:** Aplicação GUI (Graphical User Interface) utilizando a biblioteca **LTk** (Lisp Toolkit / Tkinter).
*   **Banco de Dados:** **SQLite** (usando a biblioteca `cl-sqlite`).
*   **Bibliotecas e Dependências:** Priorizar o uso da biblioteca padrão (Standard Library) do Common Lisp sempre que possível, evitando frameworks pesados.
*   **DIRETIVA DE CÓDIGO ESTRITA:** **TODOS** os blocos de código devem ser extensivamente comentados em português. Esses comentários devem ser didáticos para garantir o entendimento de leigos e do Project Manager, explicando *o que* a função faz, *por que* faz e *como* faz, linha a linha onde aplicável.

## 3. Requisitos Funcionais
O sistema deve conter os seguintes módulos:

1.  **Gestão Acadêmica Completa (CRUD):**
    *   Controle (Criar, Ler, Atualizar e Deletar) sobre Alunos, Turmas, Disciplinas, Avaliações e Notas.
2.  **Horário Escolar:**
    *   Configuração flexível de grades horárias.
    *   Definição de tempos de aula.
    *   Alocação semanal de disciplinas por turma.
3.  **Planejamento com BNCC:**
    *   Ferramentas dedicadas para o registro de aulas.
    *   Seleção de competências da Base Nacional Comum Curricular (BNCC).
4.  **Ferramentas de Produtividade:**
    *   **Cópia de Turmas:** Replicar a estrutura completa de uma turma (disciplinas, avaliações) para um novo ano ou semestre.
    *   **Replicação de Aulas:** Copiar planos de aula e conteúdos entre turmas diferentes.
    *   **Importação Inteligente:** Carregar listas de alunos via arquivo CSV com um parser determinístico que ajusta nomes e formatações automaticamente.
5.  **Visualização de Desempenho:**
    *   Geração automática de gráficos de distribuição de notas.
    *   Boletins de desempenho individual, exportáveis (formato texto) e com visualização em tela.
6.  **Assistente de IA:**
    *   Agente inteligente integrado, capaz de interagir em linguagem natural.
    *   Operações suportadas: Execução de ações no banco de dados (ex: "Cadastre o aluno X"), análise de dados (ex: "Qual a média da turma Y?") e geração de conteúdos de aula.

---

## 4. Plano de Trabalho (Metodologia Cascata - Waterfall)
O desenvolvimento do ProfGent seguirá o modelo em Cascata. Cada fase deve ser completada antes do início da próxima. Agentes de IA futuros deverão seguir rigorosamente a sequência de atividades abaixo.

### Fase 1: Análise de Requisitos e Configuração (Concluída nesta sessão)
*   **Objetivo:** Definir o escopo, stack e inicializar o repositório.
*   **Tarefas do Agente:**
    *   Redigir o documento de requisitos (este documento).
    *   Criar a estrutura de diretórios do projeto (ASDF, `src/`, `db/`).
    *   Estabelecer a conexão inicial com o SQLite.
    *   Implementar e documentar o esqueleto do CRUD inicial (Alunos e Turmas) e da GUI.

### Fase 2: Design de Sistema
*   **Objetivo:** Modelar os dados e planejar as interfaces.
*   **Tarefas do Agente:**
    *   Desenhar o esquema do banco de dados completo (Modelagem E-R para Disciplinas, Avaliações, Notas, BNCC, Horários).
    *   Criar os *wireframes* ou mockups em código (LTk) das telas principais (Dashboard, Tela de CRUD, Tela de Horários).
    *   Definir a arquitetura de integração do Assistente de IA e os fluxos de NLP (Processamento de Linguagem Natural).

### Fase 3: Implementação (Codificação)
*   **Objetivo:** Codificar as lógicas de negócios restantes e montar a interface final.
*   **Tarefas do Agente:**
    *   Implementar a Gestão de Horários e Planejamento BNCC.
    *   Implementar as Ferramentas de Produtividade (importador CSV, copiador de turmas/aulas).
    *   Desenvolver o módulo de Visualização de Desempenho (geração de gráficos em tela e texto).
    *   Integrar a API ou o módulo local de Inteligência Artificial para o Assistente.
    *   *Nota:* Manter a diretiva de comentários didáticos em todo o código.

### Fase 4: Testes
*   **Objetivo:** Garantir a estabilidade e correção das funcionalidades.
*   **Tarefas do Agente:**
    *   Escrever testes unitários utilizando um framework simples padrão (ex: `FiveAM` ou `Lisp-Unit`).
    *   Testar operações de banco de dados, falhas de inserção, parse do CSV.
    *   Realizar testes de interface (simular cliques e preenchimentos na GUI LTk).
    *   Testar os prompts e as respostas do Assistente de IA para garantir segurança e consistência.

### Fase 5: Implantação
*   **Objetivo:** Preparar o software para ser executado pelos usuários finais.
*   **Tarefas do Agente:**
    *   Criar o executável do projeto (utilizando funções como `sb-ext:save-lisp-and-die` no SBCL).
    *   Empacotar o SQLite e dependências (LTk necessita de TCL/Tk instalado no sistema hospedeiro).
    *   Criar o manual do usuário (instruções de instalação e uso básico).

### Fase 6: Manutenção
*   **Objetivo:** Evolução contínua.
*   **Tarefas do Agente:**
    *   Corrigir eventuais bugs reportados.
    *   Atualizar a base de dados da BNCC conforme mudanças governamentais.
    *   Otimizar as consultas ao SQLite à medida que o volume de alunos cresce.
