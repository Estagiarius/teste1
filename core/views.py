import json
from django.shortcuts import render, redirect, get_object_or_404
from django.http import HttpResponse, JsonResponse
from django.views.generic import ListView, CreateView, UpdateView, DeleteView, DetailView
from django.urls import reverse_lazy
from django.contrib import messages
from chartjs.views.lines import BaseLineChartView
from weasyprint import HTML
from django.template.loader import render_to_string
from io import BytesIO
import tempfile
import os

from .models import Turma, Aluno, Disciplina, Avaliacao, Nota, BNCC, Horario, Aula
from .importer import import_alunos_csv

def home(request):
    return render(request, 'core/home.html')

# Turmas
class TurmaListView(ListView):
    model = Turma
    template_name = 'core/turma_list.html'
    context_object_name = 'turmas'

class TurmaCreateView(CreateView):
    model = Turma
    fields = ['nome', 'ano_letivo', 'turno']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class TurmaDetailView(DetailView):
    model = Turma
    template_name = 'core/turma_detail.html'
    context_object_name = 'turma'

def importar_alunos_view(request, pk):
    turma = get_object_or_404(Turma, pk=pk)
    if request.method == 'POST' and request.FILES.get('csv_file'):
        csv_file = request.FILES['csv_file']

        # Save temp file
        fd, path = tempfile.mkstemp(suffix=".csv")
        try:
            with os.fdopen(fd, 'wb') as t:
                for chunk in csv_file.chunks():
                    t.write(chunk)

            result = import_alunos_csv(path, turma.id)
            if result['success']:
                messages.success(request, f"{result['count']} alunos importados com sucesso!")
            else:
                messages.error(request, f"Erro na importação: {result['error']}")
        finally:
            os.remove(path)

        return redirect('turma_detail', pk=turma.id)
    return render(request, 'core/importar_alunos.html', {'turma': turma})


# Alunos
class AlunoCreateView(CreateView):
    model = Aluno
    fields = ['nome', 'data_nascimento', 'matricula', 'situacao', 'turma']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

# Avaliações e Notas
def notas_turma_view(request, turma_id):
    turma = get_object_or_404(Turma, pk=turma_id)
    disciplinas = turma.disciplinas.all()
    alunos = turma.alunos.all()

    context = {
        'turma': turma,
        'disciplinas': disciplinas,
        'alunos': alunos,
    }
    return render(request, 'core/notas_turma.html', context)

class DesempenhoChartJSONView(BaseLineChartView):
    def get_labels(self):
        return ["0-2", "2-4", "4-6", "6-8", "8-10"]

    def get_providers(self):
        return ["Distribuição de Notas"]

    def get_data(self):
        turma_id = self.kwargs.get('turma_id')
        turma = Turma.objects.get(pk=turma_id)
        notas = Nota.objects.filter(aluno__turma=turma)

        dist = [0, 0, 0, 0, 0]
        for n in notas:
            v = float(n.valor)
            if v <= 2: dist[0] += 1
            elif v <= 4: dist[1] += 1
            elif v <= 6: dist[2] += 1
            elif v <= 8: dist[3] += 1
            else: dist[4] += 1

        return [dist]

def boletim_pdf(request, aluno_id):
    aluno = get_object_or_404(Aluno, pk=aluno_id)
    notas = Nota.objects.filter(aluno=aluno).select_related('avaliacao__disciplina')

    html_string = render_to_string('core/boletim_pdf.html', {'aluno': aluno, 'notas': notas})

    html = HTML(string=html_string)
    pdf = html.write_pdf()

    response = HttpResponse(pdf, content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="boletim_{aluno.nome}.pdf"'
    return response

# Planejamento (Aulas e BNCC)
class AulaCreateView(CreateView):
    model = Aula
    fields = ['data', 'disciplina', 'conteudo_lecionado', 'habilidades_bncc']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('home')

# Ferramentas de Produtividade
def copiar_turma_view(request, turma_id):
    turma_origem = get_object_or_404(Turma, pk=turma_id)
    if request.method == 'POST':
        novo_nome = request.POST.get('novo_nome')
        novo_ano = request.POST.get('novo_ano')

        nova_turma = Turma.objects.create(
            nome=novo_nome,
            ano_letivo=novo_ano,
            turno=turma_origem.turno
        )

        # Copia disciplinas e avaliacoes
        for disc in turma_origem.disciplinas.all():
            nova_disc = Disciplina.objects.create(nome=disc.nome, turma=nova_turma)
            for aval in disc.avaliacoes.all():
                Avaliacao.objects.create(
                    nome=aval.nome,
                    data=aval.data, # Mantém a data original por padrão
                    peso=aval.peso,
                    disciplina=nova_disc
                )

        messages.success(request, f"Turma {turma_origem.nome} copiada com sucesso para {nova_turma.nome}!")
        return redirect('turma_detail', pk=nova_turma.id)

    return render(request, 'core/copiar_turma.html', {'turma': turma_origem})

from django.views.decorators.csrf import csrf_exempt
from .ai_assistant import parse_and_execute_command

from django.contrib.auth.decorators import login_required
# @csrf_exempt

def api_chat(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            message = data.get('message', '')

            # Aqui processa usando a IA offline (regex) criada
            reply = parse_and_execute_command(message)
            return JsonResponse({'reply': reply})
        except Exception as e:
            return JsonResponse({'reply': f'Erro: {str(e)}'})
    return JsonResponse({'reply': 'Método não permitido.'}, status=405)

class DisciplinaCreateView(CreateView):
    model = Disciplina
    fields = ['nome', 'turma']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class AvaliacaoCreateView(CreateView):
    model = Avaliacao
    fields = ['nome', 'data', 'peso', 'disciplina']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class NotaCreateView(CreateView):
    model = Nota
    fields = ['aluno', 'avaliacao', 'valor']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class HorarioCreateView(CreateView):
    model = Horario
    fields = ['turma', 'dia_semana', 'tempo_aula', 'disciplina']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class TurmaUpdateView(UpdateView):
    model = Turma
    fields = ['nome', 'ano_letivo', 'turno']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class TurmaDeleteView(DeleteView):
    model = Turma
    template_name = 'core/confirm_delete.html'
    success_url = reverse_lazy('turma_list')

def replicar_aulas_view(request, turma_origem_id):
    turma_origem = get_object_or_404(Turma, pk=turma_origem_id)
    if request.method == 'POST':
        turma_destino_id = request.POST.get('turma_destino')
        turma_destino = get_object_or_404(Turma, pk=turma_destino_id)

        aulas_origem = Aula.objects.filter(disciplina__turma=turma_origem)
        for aula in aulas_origem:
            disc_destino = Disciplina.objects.filter(turma=turma_destino, nome=aula.disciplina.nome).first()
            if disc_destino:
                nova_aula = Aula.objects.create(
                    data=aula.data,
                    disciplina=disc_destino,
                    conteudo_lecionado=aula.conteudo_lecionado
                )
                nova_aula.habilidades_bncc.set(aula.habilidades_bncc.all())

        messages.success(request, f"Aulas replicadas para {turma_destino.nome} com sucesso!")
        return redirect('turma_detail', pk=turma_destino.id)

    turmas_destino = Turma.objects.exclude(id=turma_origem_id)
    return render(request, 'core/replicar_aulas.html', {'turma': turma_origem, 'turmas_destino': turmas_destino})


# --- UPDATE E DELETE ---
# Aluno
class AlunoUpdateView(UpdateView):
    model = Aluno
    fields = ['nome', 'data_nascimento', 'matricula', 'situacao', 'turma']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class AlunoDeleteView(DeleteView):
    model = Aluno
    template_name = 'core/confirm_delete.html'
    success_url = reverse_lazy('turma_list')

# Disciplina
class DisciplinaUpdateView(UpdateView):
    model = Disciplina
    fields = ['nome', 'turma']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class DisciplinaDeleteView(DeleteView):
    model = Disciplina
    template_name = 'core/confirm_delete.html'
    success_url = reverse_lazy('turma_list')

# Avaliacao
class AvaliacaoUpdateView(UpdateView):
    model = Avaliacao
    fields = ['nome', 'data', 'peso', 'disciplina']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class AvaliacaoDeleteView(DeleteView):
    model = Avaliacao
    template_name = 'core/confirm_delete.html'
    success_url = reverse_lazy('turma_list')

# Nota
class NotaUpdateView(UpdateView):
    model = Nota
    fields = ['aluno', 'avaliacao', 'valor']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class NotaDeleteView(DeleteView):
    model = Nota
    template_name = 'core/confirm_delete.html'
    success_url = reverse_lazy('turma_list')

# Horario
class HorarioUpdateView(UpdateView):
    model = Horario
    fields = ['turma', 'dia_semana', 'tempo_aula', 'disciplina']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('turma_list')

class HorarioDeleteView(DeleteView):
    model = Horario
    template_name = 'core/confirm_delete.html'
    success_url = reverse_lazy('turma_list')

# Aula (BNCC)
class AulaUpdateView(UpdateView):
    model = Aula
    fields = ['data', 'disciplina', 'conteudo_lecionado', 'habilidades_bncc']
    template_name = 'core/form_base.html'
    success_url = reverse_lazy('aula_list')

class AulaDeleteView(DeleteView):
    model = Aula
    template_name = 'core/confirm_delete.html'
    success_url = reverse_lazy('aula_list')

class AulaListView(ListView):
    model = Aula
    template_name = 'core/aula_list.html'
    context_object_name = 'aulas'
