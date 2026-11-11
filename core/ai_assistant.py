import json
import re
import os
from .models import Aluno, Turma, Nota
try:
    from openai import OpenAI
    # Para Ollama local, a base_url seria "http://localhost:11434/v1" e a api_key "ollama"
    api_key = os.environ.get("OPENAI_API_KEY", "sk-mock")
    base_url = os.environ.get("OPENAI_BASE_URL", None)

    if api_key != "sk-mock":
        client_kwargs = {"api_key": api_key}
        if base_url:
            client_kwargs["base_url"] = base_url
        client = OpenAI(**client_kwargs)
    else:
        client = None
except ImportError:
    client = None

def parse_and_execute_command(message: str):
    """
    Sistema híbrido: Se cliente OpenAI estiver configurado e válido, utiliza LLM com function calling.
    Se não, usa fallback offline determinístico.
    """
    if client:
        return _use_llm_function_calling(message)
    else:
        return _use_offline_fallback(message)

def _use_llm_function_calling(message: str):
    # Ferramentas expostas para a IA
    tools = [
        {
            "type": "function",
            "function": {
                "name": "cadastrar_aluno",
                "description": "Cadastra um novo aluno em uma turma.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "nome": {"type": "string", "description": "Nome completo do aluno."},
                        "turma_id": {"type": "integer", "description": "ID da turma (opcional, pode ser omitido)."}
                    },
                    "required": ["nome"]
                }
            }
        },
        {
            "type": "function",
            "function": {
                "name": "calcular_media_geral",
                "description": "Calcula a média geral das notas de todas as turmas cadastradas.",
            }
        }
    ]

    try:
        response = client.chat.completions.create(
            model=os.environ.get("OPENAI_MODEL", "gpt-3.5-turbo"),
            messages=[
                {"role": "system", "content": "Você é um assistente de gestão escolar útil. Use as funções fornecidas quando solicitado. Responda em português."},
                {"role": "user", "content": message}
            ],
            tools=tools,
            tool_choice="auto"
        )

        response_message = response.choices[0].message
        tool_calls = response_message.tool_calls

        if tool_calls:
            results = []
            for tool_call in tool_calls:
                func_name = tool_call.function.name
                func_args = json.loads(tool_call.function.arguments)

                if func_name == "cadastrar_aluno":
                    nome = func_args.get("nome").title()
                    turma = Turma.objects.first()
                    if not turma:
                        turma = Turma.objects.create(nome="Turma Padrão", ano_letivo=2026, turno="Manhã")
                    Aluno.objects.create(nome=nome, data_nascimento="2010-01-01", turma=turma)
                    results.append(f"Aluno '{nome}' cadastrado com sucesso na turma '{turma.nome}'.")

                elif func_name == "calcular_media_geral":
                    notas = Nota.objects.all()
                    if notas.exists():
                        media = sum(n.valor for n in notas) / notas.count()
                        results.append(f"A média geral de todas as turmas é: {media:.2f}.")
                    else:
                        results.append("Não há notas suficientes para calcular a média.")

            return " ".join(results)
        else:
            return response_message.content

    except Exception as e:
        # Fallback caso a API falhe (ex: quota excedida)
        return _use_offline_fallback(message)


def _use_offline_fallback(message: str):
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
