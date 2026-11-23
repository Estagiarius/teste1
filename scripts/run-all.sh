#!/usr/bin/env bash
# scripts/run-all.sh — Executor sequencial respeitando o DAG de dependências em recipes/
# Uso: scripts/run-all.sh [--layer <0..4>] [--from <id>] [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
RECIPES_DIR="${WORKSPACE_ROOT}/recipes"
META_DIR="${WORKSPACE_ROOT}/dist/.pkgmeta"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
MANIFEST_PATH="${WORKSPACE_ROOT}/dist/manifest.json"
PREFIX="/accounts/1000/shared/misc/berrycore"
TARGET="arm-blackberry-qnx8eabi"

FILTER_LAYER=""
FROM_ID=""
FORCE_REBUILD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --layer) FILTER_LAYER="$2"; shift 2 ;;
        --from)  FROM_ID="$2"; shift 2 ;;
        --force) FORCE_REBUILD=1; shift ;;
        *)
            echo "Argumento desconhecido: $1" >&2
            echo "Uso: $0 [--layer <0..4>] [--from <id>] [--force]" >&2
            exit 1
            ;;
    esac
done

mkdir -p "${META_DIR}" "${LOGS_DIR}" "${WORKSPACE_ROOT}/dist"

# Extrai metadados declarativos de uma receita em subshell isolado
read_recipe_meta() {
    local recipe="$1"
    (
        PKG_ID=""
        PKG_NAME=""
        PKG_VER=""
        PKG_LAYER="0"
        PKG_DEPS=""
        PKG_CRITICAL="0"
        # shellcheck disable=SC1090
        source "${recipe}"
        if [[ -z "${PKG_ID}" ]]; then
            PKG_ID="$(basename "${recipe}" | cut -d'-' -f1)"
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "${PKG_ID}" "${PKG_NAME}" "${PKG_VER}" "${PKG_LAYER}" "${PKG_DEPS}" "${PKG_CRITICAL}"
    )
}

get_pkg_status() {
    local pkg_name="$1"
    local meta_file="${META_DIR}/${pkg_name}.json"
    if [[ ! -f "${meta_file}" ]]; then
        echo "PENDING"
        return 0
    fi
    python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status"])' "${meta_file}" 2>/dev/null || echo "UNKNOWN"
}

mark_pkg_blocked() {
    local pkg_id="$1"
    local pkg_name="$2"
    local pkg_ver="$3"
    local pkg_layer="$4"
    local reason="$5"
    local meta_file="${META_DIR}/${pkg_name}.json"
    local err_file="${LOGS_DIR}/${pkg_name}-error.log"

    if [[ ! -f "${err_file}" ]]; then
        {
            echo "=== PACOTE BLOQUEADO: ${pkg_name} (${pkg_ver}) ==="
            echo "Motivo: ${reason}"
            echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        } > "${err_file}"
    fi

    python3 - "${meta_file}" "${pkg_id}" "${pkg_name}" "${pkg_ver}" "${pkg_layer}" "${reason}" <<'PYEOF'
import json, os, sys
meta_file, pkg_id, pkg_name, pkg_ver, pkg_layer, reason = sys.argv[1:7]
data = {}
if os.path.isfile(meta_file):
    try:
        with open(meta_file, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        data = {}

data.update({
    "id": pkg_id,
    "name": pkg_name,
    "version": pkg_ver,
    "layer": int(pkg_layer),
    "status": "BLOCKED",
    "size_kb": data.get("size_kb", 0),
    "binaries": data.get("binaries", []),
    "libraries": data.get("libraries", []),
    "needed": data.get("needed", []),
    "patches": data.get("patches", []),
    "error_summary": reason,
})
with open(meta_file, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PYEOF
}

generate_manifest() {
    python3 - "${META_DIR}" "${MANIFEST_PATH}" "${TARGET}" "${PREFIX}" <<'PYEOF'
import datetime, glob, json, os, sys

meta_dir, manifest_path, target, prefix = sys.argv[1:5]
packages = []
for path in sorted(glob.glob(os.path.join(meta_dir, "*.json"))):
    with open(path, "r", encoding="utf-8") as fh:
        packages.append(json.load(fh))

packages.sort(key=lambda p: (int(p.get("layer", 0)), str(p.get("id", "99")), str(p.get("name", ""))))
success_count = sum(1 for p in packages if p.get("status") == "SUCCESS")
blocked_count = sum(1 for p in packages if p.get("status") == "BLOCKED")
other_count = len(packages) - success_count - blocked_count

manifest = {
    "target": target,
    "prefix": prefix,
    "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "summary": {
        "total": len(packages),
        "success": success_count,
        "blocked": blocked_count,
        "other": other_count,
    },
    "packages": packages,
}

with open(manifest_path, "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PYEOF
}

shopt -s nullglob
RECIPES=("${RECIPES_DIR}"/[0-9][0-9]-*.sh)
shopt -u nullglob

if [[ ${#RECIPES[@]} -eq 0 ]]; then
    echo "[run-all] AVISO: nenhuma receita encontrada em ${RECIPES_DIR}/." >&2
    generate_manifest
    exit 0
fi

echo "[run-all] Executando DAG com ${#RECIPES[@]} receitas encontradas..."

STARTED=0
[[ -z "${FROM_ID}" ]] && STARTED=1

for recipe in "${RECIPES[@]}"; do
    IFS=$'\t' read -r pkg_id pkg_name pkg_ver pkg_layer pkg_deps pkg_critical < <(read_recipe_meta "${recipe}")

    if [[ "${STARTED}" -eq 0 ]]; then
        if [[ "${pkg_id}" == "${FROM_ID}" ]]; then
            STARTED=1
        else
            continue
        fi
    fi

    if [[ -n "${FILTER_LAYER}" && "${pkg_layer}" != "${FILTER_LAYER}" ]]; then
        continue
    fi

    current_status="$(get_pkg_status "${pkg_name}")"
    if [[ "${current_status}" == "SUCCESS" && "${FORCE_REBUILD}" -eq 0 ]]; then
        echo "[run-all] SKIP (já SUCCESS): ${pkg_id}-${pkg_name} (${pkg_ver})"
        continue
    fi

    # Verifica dependências no DAG (isolamento de falhas)
    blocked_dep=""
    for dep in ${pkg_deps}; do
        dep_status="$(get_pkg_status "${dep}")"
        if [[ "${dep_status}" != "SUCCESS" ]]; then
            blocked_dep="${dep} (${dep_status})"
            break
        fi
    done

    if [[ -n "${blocked_dep}" ]]; then
        echo "[run-all] BLOCKED ${pkg_id}-${pkg_name}: dependência indisponível -> ${blocked_dep}"
        mark_pkg_blocked "${pkg_id}" "${pkg_name}" "${pkg_ver}" "${pkg_layer}" "Dependência bloqueada ou ausente: ${blocked_dep}"
        generate_manifest
        continue
    fi

    # Executa build do pacote
    if "${SCRIPT_DIR}/build-pkg.sh" "${recipe}"; then
        echo "[run-all] OK: ${pkg_id}-${pkg_name} (${pkg_ver})"
    else
        echo "[run-all] FALHA -> BLOCKED: ${pkg_id}-${pkg_name} (${pkg_ver}) — ver logs/${pkg_name}-error.log" >&2
        mark_pkg_blocked "${pkg_id}" "${pkg_name}" "${pkg_ver}" "${pkg_layer}" "Falha no build/validação; consultar logs/${pkg_name}-error.log"
    fi

    generate_manifest
done

# Valida critério obrigatório do Definition of Done para Camada 0 e Camada 1 (quando execução não filtrada)
if [[ -z "${FILTER_LAYER}" && -z "${FROM_ID}" ]]; then
    REQUIRED_CRITICAL=(zlib ncurses ca-certificates openssl curl wget openssh-client rsync)
    CRITICAL_FAIL=0
    for req in "${REQUIRED_CRITICAL[@]}"; do
        st="$(get_pkg_status "${req}")"
        if [[ "${st}" != "SUCCESS" ]]; then
            echo "[run-all] CRÍTICO: pacote obrigatório '${req}' está com status '${st}' (esperado SUCCESS)." >&2
            CRITICAL_FAIL=1
        fi
    done
    if [[ "${CRITICAL_FAIL}" -ne 0 ]]; then
        echo "[run-all] Encerrado com falha em pacotes obrigatórios da Camada 0/1. Manifesto salvo em ${MANIFEST_PATH}." >&2
        exit 1
    fi
fi

echo "[run-all] Concluído. Manifesto consolidado salvo em ${MANIFEST_PATH}."
