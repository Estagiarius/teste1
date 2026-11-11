from django.db import models

class BNCC(models.Model):
    codigo = models.CharField(max_length=20, unique=True)
    descricao = models.TextField()
    etapa = models.CharField(max_length=100) # Ex: Ensino Fundamental
    componente = models.CharField(max_length=100) # Ex: Matemática

    def __str__(self):
        return f"{self.codigo} - {self.descricao[:50]}"

class Turma(models.Model):
    nome = models.CharField(max_length=100)
    ano_letivo = models.IntegerField()
    turno = models.CharField(max_length=50)

    def __str__(self):
        return f"{self.nome} ({self.ano_letivo})"

class Aluno(models.Model):
    nome = models.CharField(max_length=200)
    data_nascimento = models.DateField()
    matricula = models.CharField(max_length=50, blank=True, null=True)
    situacao = models.CharField(max_length=50, default='Ativo')
    turma = models.ForeignKey(Turma, on_delete=models.SET_NULL, null=True, blank=True, related_name='alunos')

    def __str__(self):
        return self.nome

class Disciplina(models.Model):
    nome = models.CharField(max_length=100)
    turma = models.ForeignKey(Turma, on_delete=models.CASCADE, related_name='disciplinas')

    def __str__(self):
        return f"{self.nome} - {self.turma}"

class Avaliacao(models.Model):
    nome = models.CharField(max_length=100)
    data = models.DateField()
    peso = models.DecimalField(max_digits=5, decimal_places=2, default=1.0)
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='avaliacoes')

    def __str__(self):
        return f"{self.nome} - {self.disciplina}"

class Nota(models.Model):
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='notas')
    avaliacao = models.ForeignKey(Avaliacao, on_delete=models.CASCADE, related_name='notas')
    valor = models.DecimalField(max_digits=5, decimal_places=2)

    def __str__(self):
        return f"{self.aluno} - {self.avaliacao}: {self.valor}"

class Horario(models.Model):
    turma = models.ForeignKey(Turma, on_delete=models.CASCADE, related_name='horarios')
    dia_semana = models.IntegerField(choices=[(0, 'Segunda'), (1, 'Terça'), (2, 'Quarta'), (3, 'Quinta'), (4, 'Sexta'), (5, 'Sábado')])
    tempo_aula = models.IntegerField(help_text="Número do tempo (1º tempo, 2º tempo, etc)")
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.turma} - {self.get_dia_semana_display()} - {self.tempo_aula}º tempo"

class Aula(models.Model):
    data = models.DateField()
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='aulas')
    conteudo_lecionado = models.TextField()
    habilidades_bncc = models.ManyToManyField(BNCC, blank=True, related_name='aulas')

    def __str__(self):
        return f"{self.data} - {self.disciplina}"
