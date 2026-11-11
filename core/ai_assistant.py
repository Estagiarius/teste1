import json
import re
import os
from .models import Aluno, Turma, Nota
try:
    from openai import OpenAI
    client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY", "sk-mock"))
except ImportError:
    client = None

def parse_and_execute_command(message: str):
    """
    Sistema híbrido: Se OPENAI_API_KEY existir, pode usar gpt-3.5-turbo (mockado aqui por segurança).
    Se não, usa fallback offline determinístico.
    """
    msg_lower = message.lower()

    # Fallback offline
    if "cadastre o aluno" in msg_lower or "cadastrar aluno" in msg_lower:
        match = re.search(r"aluno ([a-zA-Z\s]+)", msg_lower)
        if match:
            nome = match.group(1).strip().title()
            turma = Turma.objects.first()
            if not turma:
                turma = Turma.objects.create(nome="Turma Padrão", ano_letivo=2026, turno="Manhã")
            Aluno.objects.create(nome=nome, data_nascimento="2010-01-01", turma=turma)
            return f"Ação executada: Aluno '{nome}' cadastrado com sucesso na turma '{turma.nome}'!"
        return "Para cadastrar, por favor especifique 'Cadastre o aluno NOME'."

    elif "média da turma" in msg_lower or "media da turma" in msg_lower:
        notas = Nota.objects.all()
        if not notas.exists():
            return "Não encontrei notas cadastradas no momento para calcular médias."
        soma = sum(n.valor for n in notas)
        media = soma / notas.count()
        return f"A média geral das turmas calculada com base nas notas atuais é: {media:.2f}."

    return "Compreendi sua mensagem, mas não tenho uma ação de banco de dados mapeada para isso. Tente: 'Cadastre o aluno João' ou 'Qual a média da turma?'."
