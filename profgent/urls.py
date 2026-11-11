from django.contrib import admin
from django.urls import path
from core import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.home, name='home'),

    path('turmas/', views.TurmaListView.as_view(), name='turma_list'),
    path('turmas/nova/', views.TurmaCreateView.as_view(), name='turma_create'),
    path('turmas/<int:pk>/', views.TurmaDetailView.as_view(), name='turma_detail'),
    path('turmas/<int:pk>/importar/', views.importar_alunos_view, name='importar_alunos'),
    path('turmas/<int:turma_id>/notas/', views.notas_turma_view, name='notas_turma'),
    path('turmas/<int:turma_id>/grafico/', views.DesempenhoChartJSONView.as_view(), name='grafico_notas'),

    path('alunos/novo/', views.AlunoCreateView.as_view(), name='aluno_create'),
    path('alunos/<int:aluno_id>/boletim/', views.boletim_pdf, name='boletim_pdf'),

    path('aulas/nova/', views.AulaCreateView.as_view(), name='aula_create'),
]
urlpatterns += [
    path('turmas/<int:turma_id>/copiar/', views.copiar_turma_view, name='copiar_turma'),
]
urlpatterns += [
    path('api/chat/', views.api_chat, name='api_chat'),
]

urlpatterns += [
    path('disciplinas/nova/', views.DisciplinaCreateView.as_view(), name='disciplina_create'),
    path('avaliacoes/nova/', views.AvaliacaoCreateView.as_view(), name='avaliacao_create'),
    path('notas/nova/', views.NotaCreateView.as_view(), name='nota_create'),
    path('horarios/novo/', views.HorarioCreateView.as_view(), name='horario_create'),
    path('turmas/<int:pk>/editar/', views.TurmaUpdateView.as_view(), name='turma_update'),
    path('turmas/<int:pk>/excluir/', views.TurmaDeleteView.as_view(), name='turma_delete'),
    path('turmas/<int:turma_origem_id>/replicar_aulas/', views.replicar_aulas_view, name='replicar_aulas'),
]

urlpatterns += [
    path('alunos/<int:pk>/editar/', views.AlunoUpdateView.as_view(), name='aluno_update'),
    path('alunos/<int:pk>/excluir/', views.AlunoDeleteView.as_view(), name='aluno_delete'),
    path('disciplinas/<int:pk>/editar/', views.DisciplinaUpdateView.as_view(), name='disciplina_update'),
    path('disciplinas/<int:pk>/excluir/', views.DisciplinaDeleteView.as_view(), name='disciplina_delete'),
    path('avaliacoes/<int:pk>/editar/', views.AvaliacaoUpdateView.as_view(), name='avaliacao_update'),
    path('avaliacoes/<int:pk>/excluir/', views.AvaliacaoDeleteView.as_view(), name='avaliacao_delete'),
    path('notas/<int:pk>/editar/', views.NotaUpdateView.as_view(), name='nota_update'),
    path('notas/<int:pk>/excluir/', views.NotaDeleteView.as_view(), name='nota_delete'),
    path('horarios/<int:pk>/editar/', views.HorarioUpdateView.as_view(), name='horario_update'),
    path('horarios/<int:pk>/excluir/', views.HorarioDeleteView.as_view(), name='horario_delete'),
    path('aulas/', views.AulaListView.as_view(), name='aula_list'),
    path('aulas/<int:pk>/editar/', views.AulaUpdateView.as_view(), name='aula_update'),
    path('aulas/<int:pk>/excluir/', views.AulaDeleteView.as_view(), name='aula_delete'),
]
