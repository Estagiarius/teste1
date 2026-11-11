import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "profgent.settings")
django.setup()

from core.models import Turma, Aluno
from core.importer import import_alunos_csv

# Cria CSV de teste
csv_content = """Alunos;09/11/2026 15:41

Filtros

Ano Letivo;2026

Nº de chamada;Nome do Aluno;Data de Nascimento;Situação do Aluno
1;ALEKEY WALLACY FIDELES ALVES DA SILVA;26/08/2010;Transferido
2;ALICE MATOS RODRIGUES;22/02/2011;Ativo
3;ALLANA BARBOSA DE ASSIS;18/04/2011;BAIXA - TRANSFERÊNCIA
4;ANA CLARA BRANDAO DA ROCHA;05/09/2010;Ativo
5;ANA KLARA LIMA;06/04/2010;Transferido
6;ANNY GIULIA GOMES PAULINO;17/06/2011;Ativo
"""

with open("teste_import.csv", "w", encoding="utf-8") as f:
    f.write(csv_content)

turma = Turma.objects.create(nome="Turma Teste", ano_letivo=2026, turno="Manhã")

result = import_alunos_csv("teste_import.csv", turma.id)
print("Resultado da importação:", result)

print("Alunos cadastrados:")
for a in Aluno.objects.filter(turma=turma):
    print(f"Nome: {a.nome}, Data: {a.data_nascimento}, Situação: {a.situacao}")
