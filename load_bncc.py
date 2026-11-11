import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "profgent.settings")
django.setup()

from core.models import BNCC

# Exemplo de habilidades básicas para a carga inicial
habilidades = [
    {"codigo": "EF01MA01", "descricao": "Utilizar números naturais como indicador de quantidade ou de ordem em diferentes situações cotidianas...", "etapa": "Ensino Fundamental I", "componente": "Matemática"},
    {"codigo": "EF01LP01", "descricao": "Reconhecer que textos são lidos e escritos da esquerda para a direita e de cima para baixo...", "etapa": "Ensino Fundamental I", "componente": "Língua Portuguesa"},
    {"codigo": "EF06CI01", "descricao": "Classificar como misturas homogêneas ou heterogêneas a água salgada, a água com açúcar e areia...", "etapa": "Ensino Fundamental II", "componente": "Ciências"},
    {"codigo": "EF08HI01", "descricao": "Identificar os principais aspectos conceituais do iluminismo e do liberalismo e discutir a sua relação com a organização do mundo contemporâneo.", "etapa": "Ensino Fundamental II", "componente": "História"},
]

def load():
    for hab in habilidades:
        BNCC.objects.get_or_create(codigo=hab['codigo'], defaults=hab)
    print("Habilidades BNCC carregadas com sucesso!")

if __name__ == '__main__':
    load()
