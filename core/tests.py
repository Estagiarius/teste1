from django.test import TestCase
from .models import Turma, Disciplina, Aluno, BNCC

class CoreModelTests(TestCase):
    def setUp(self):
        self.turma = Turma.objects.create(nome="Turma A", ano_letivo=2026, turno="Manhã")
        self.aluno = Aluno.objects.create(nome="João", data_nascimento="2010-01-01", turma=self.turma)

    def test_turma_creation(self):
        self.assertEqual(self.turma.nome, "Turma A")
        self.assertEqual(self.turma.alunos.count(), 1)

    def test_copia_turma(self):
        # Setup inicial
        disc = Disciplina.objects.create(nome="Mat", turma=self.turma)

        # Simulando copia logic
        nova_turma = Turma.objects.create(nome="Turma B", ano_letivo=2027, turno=self.turma.turno)
        for d in self.turma.disciplinas.all():
            Disciplina.objects.create(nome=d.nome, turma=nova_turma)

        self.assertEqual(nova_turma.disciplinas.count(), 1)
        self.assertEqual(nova_turma.disciplinas.first().nome, "Mat")
        self.assertEqual(nova_turma.alunos.count(), 0) # Alunos não devem ser copiados
