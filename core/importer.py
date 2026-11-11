import pandas as pd
from datetime import datetime
from .models import Aluno, Turma

def import_alunos_csv(file_path, turma_id):
    try:
        turma = Turma.objects.get(id=turma_id)
    except Turma.DoesNotExist:
        return {"success": False, "error": "Turma não encontrada."}

    try:
        # Tenta ler o arquivo inteiro
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # Encontra a linha que começa com "Nº de chamada" ou semelhante para ser o header
        header_idx = -1
        for i, line in enumerate(lines):
            if "Nº de chamada" in line or "Nome do Aluno" in line:
                header_idx = i
                break

        if header_idx == -1:
             return {"success": False, "error": "Cabeçalho não encontrado no CSV."}

        # Lê o dataframe a partir da linha do cabeçalho
        df = pd.read_csv(file_path, sep=';', skiprows=header_idx, dtype=str)

        # Normalizar nomes de colunas
        df.columns = df.columns.str.strip().str.lower()

        col_nome = None
        col_data = None
        col_situacao = None

        for col in df.columns:
            if "nome" in col:
                col_nome = col
            elif "data" in col or "nascimento" in col:
                col_data = col
            elif "situa" in col:
                col_situacao = col

        if not col_nome or not col_data:
             return {"success": False, "error": "Colunas necessárias não encontradas no CSV (Nome e Data de Nascimento)."}

        importados = 0
        for index, row in df.iterrows():
            nome_raw = str(row[col_nome]).strip()
            if not nome_raw or pd.isna(row[col_nome]):
                continue

            nome_formatado = nome_raw.title()
            data_raw = str(row[col_data]).strip()
            try:
                data_nascimento = datetime.strptime(data_raw, '%d/%m/%Y').date()
            except ValueError:
                continue # Pula se a data for inválida

            situacao = str(row[col_situacao]).strip().capitalize() if col_situacao and pd.notna(row.get(col_situacao)) else 'Ativo'
            if situacao.upper() == 'BAIXA - TRANSFERÊNCIA' or 'TRANSFER' in situacao.upper():
                situacao = 'Transferido'

            Aluno.objects.get_or_create(
                nome=nome_formatado,
                data_nascimento=data_nascimento,
                defaults={
                    'situacao': situacao,
                    'turma': turma
                }
            )
            importados += 1

        return {"success": True, "count": importados}

    except Exception as e:
        return {"success": False, "error": str(e)}
