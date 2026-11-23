#!/usr/bin/env bash
# scripts/build-pkg.sh — Orquestrador genérico de compilação cruzada por receita
# Uso: scripts/build-pkg.sh recipes/<id>-<pacote>.sh

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Uso: $0 recipes/<id>-<pacote>.sh" >&2
    exit 1
fi

RECIPE_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if [[ ! -f "${RECIPE_PATH}" ]]; then
    echo "[build-pkg] ERRO: receita não encontrada: ${RECIPE_PATH}" >&2
    exit 1
fi

# Regra de Isolamento Total: exige execução dentro de contêiner Docker
if [[ ! -f "/.dockerenv" && "${ALLOW_NON_DOCKER:-0}" != "1" ]]; then
    echo "[build-pkg] ERRO: Isolamento Total violado — execute dentro do contêiner Docker x86_64." >&2
    exit 1
fi

# Carrega ambiente padrão de compilação cruzada
# shellcheck source=scripts/env-cross.sh
source "${SCRIPT_DIR}/env-cross.sh"

# Padrões de receita (podem ser sobrescritos no arquivo recipes/<id>-<pkg>.sh)
PKG_ID=""
PKG_NAME=""
PKG_VER=""
PKG_LAYER="0"
PKG_URL=""
PKG_SHA256=""
PKG_ARCHIVE=""
PKG_EXTRACT="auto"
PKG_DEPS=""
PKG_CRITICAL="0"
PKG_SRC_SUBDIR=""

# shellcheck disable=SC1090
source "${RECIPE_PATH}"

if [[ -z "${PKG_NAME}" || -z "${PKG_VER}" ]]; then
    echo "[build-pkg] ERRO: receita ${RECIPE_PATH} deve definir PKG_NAME e PKG_VER." >&2
    exit 1
fi

if ! declare -F build >/dev/null || ! declare -F install_staging >/dev/null; then
    echo "[build-pkg] ERRO: receita ${RECIPE_PATH} deve definir funções build() e install_staging()." >&2
    exit 1
fi

if [[ -z "${PKG_ID}" ]]; then
    PKG_ID="$(basename "${RECIPE_PATH}" | cut -d'-' -f1)"
fi

if [[ -z "${PKG_ARCHIVE}" && -n "${PKG_URL}" ]]; then
    PKG_ARCHIVE="$(basename "${PKG_URL%%\?*}")"
fi

DOWNLOADS_DIR="${WORKSPACE_ROOT}/downloads"
PATCHES_DIR="${WORKSPACE_ROOT}/patches/${PKG_NAME}"
LOGS_DIR="${WORKSPACE_ROOT}/logs"
META_DIR="${WORKSPACE_ROOT}/dist/.pkgmeta"
BUILD_ROOT="/tmp/build/${PKG_NAME}"
LOG_FILE="${LOGS_DIR}/${PKG_NAME}.log"
ERR_FILE="${LOGS_DIR}/${PKG_NAME}-error.log"
FILES_LIST="${META_DIR}/${PKG_NAME}.files"
META_JSON="${META_DIR}/${PKG_NAME}.json"

mkdir -p "${DOWNLOADS_DIR}" "${LOGS_DIR}" "${META_DIR}"

write_pkg_meta() {
    local status="$1"
    local error_summary="${2:-}"
    python3 - "${META_JSON}" "${PKG_ID}" "${PKG_NAME}" "${PKG_VER}" "${PKG_LAYER}" \
        "${status}" "${FILES_LIST}" "${SYSROOT_PREFIX}" "${PATCHES_DIR}" \
        "${READELF}" "${error_summary}" <<'PYEOF'
import json
import os
import subprocess
import sys

(
    meta_json, pkg_id, pkg_name, pkg_ver, pkg_layer,
    status, files_list, sysroot_prefix, patches_dir,
    readelf_bin, error_summary
) = sys.argv[1:12]

if not os.path.isfile(readelf_bin):
    readelf_bin = "readelf"

files = []
if os.path.isfile(files_list):
    with open(files_list, "r", encoding="utf-8") as fh:
        files = [line.strip() for line in fh if line.strip()]

total_bytes = 0
binaries = []
libraries = []
needed_set = set()

for rel in files:
    full = os.path.join(sysroot_prefix, rel)
    if not os.path.exists(full):
        continue
    if os.path.isfile(full) and not os.path.islink(full):
        total_bytes += os.path.getsize(full)
        try:
            with open(full, "rb") as f:
                is_elf = f.read(4) == b"\x7fELF"
        except OSError:
            is_elf = False
        if is_elf:
            if rel.startswith(("bin/", "sbin/")):
                binaries.append(rel)
            elif ".so" in os.path.basename(rel) or rel.startswith("lib/"):
                libraries.append(rel)
            else:
                binaries.append(rel)
            try:
                out = subprocess.check_output(
                    [readelf_bin, "-d", full],
                    stderr=subprocess.DEVNULL,
                    text=True,
                )
                for line in out.splitlines():
                    if "(NEEDED)" in line and "[" in line and "]" in line:
                        lib = line.split("[", 1)[1].split("]", 1)[0]
                        needed_set.add(lib)
            except Exception:
                pass

patches = []
if os.path.isdir(patches_dir):
    patches = sorted(
        f"patches/{pkg_name}/{p}"
        for p in os.listdir(patches_dir)
        if p.endswith(".patch")
    )

data = {
    "id": pkg_id,
    "name": pkg_name,
    "version": pkg_ver,
    "layer": int(pkg_layer),
    "status": status,
    "size_kb": (total_bytes + 1023) // 1024,
    "binaries": sorted(binaries),
    "libraries": sorted(libraries),
    "needed": sorted(needed_set),
    "patches": patches,
    "error_summary": error_summary if error_summary else None,
}

with open(meta_json, "w", encoding="utf-8") as out_fh:
    json.dump(data, out_fh, indent=2, ensure_ascii=False)
    out_fh.write("\n")
PYEOF
}

on_error() {
    local exit_code=$?
    local reason="${1:-Falha durante o build de ${PKG_NAME} (exit ${exit_code})}"
    echo "[build-pkg] FALHA em ${PKG_NAME}: ${reason}" >&2
    {
        echo "=== ERRO NO PACOTE: ${PKG_NAME} (${PKG_VER}) ==="
        echo "Receita: ${RECIPE_PATH}"
        echo "Motivo: ${reason}"
        echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "=== ÚLTIMAS 80 LINHAS DE ${LOG_FILE} ==="
        if [[ -f "${LOG_FILE}" ]]; then
            tail -n 80 "${LOG_FILE}"
        fi
    } > "${ERR_FILE}"
    write_pkg_meta "FAILED" "${reason}"
    exit "${exit_code}"
}

trap 'on_error "Comando falhou na linha ${LINENO}"' ERR

# Inicia log limpo para este ciclo
: > "${LOG_FILE}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=================================================================="
echo "[build-pkg] Iniciando ${PKG_ID}-${PKG_NAME} (${PKG_VER}) | Camada ${PKG_LAYER}"
echo "=================================================================="

# 1. Download (com reutilização de cache) e validação SHA256
if [[ -n "${PKG_URL}" ]]; then
    ARCHIVE_PATH="${DOWNLOADS_DIR}/${PKG_ARCHIVE}"
    if [[ ! -f "${ARCHIVE_PATH}" ]]; then
        echo "[build-pkg] Baixando ${PKG_URL} -> ${ARCHIVE_PATH}"
        curl -fSL --retry 3 --retry-delay 2 -o "${ARCHIVE_PATH}.tmp" "${PKG_URL}"
        mv "${ARCHIVE_PATH}.tmp" "${ARCHIVE_PATH}"
    else
        echo "[build-pkg] Reutilizando cache local: ${ARCHIVE_PATH}"
    fi

    if [[ -n "${PKG_SHA256}" && "${PKG_SHA256}" != "SKIP" ]]; then
        echo "[build-pkg] Validando SHA256 de ${PKG_ARCHIVE}..."
        echo "${PKG_SHA256}  ${ARCHIVE_PATH}" | sha256sum -c -
    else
        echo "[build-pkg] SHA256 observado: $(sha256sum "${ARCHIVE_PATH}")"
    fi
fi

# 2. Extração limpa em /tmp/build/<pkg>
rm -rf "${BUILD_ROOT}"
mkdir -p "${BUILD_ROOT}"

if [[ -n "${PKG_URL}" && "${PKG_EXTRACT}" != "none" ]]; then
    ARCHIVE_PATH="${DOWNLOADS_DIR}/${PKG_ARCHIVE}"
    echo "[build-pkg] Extraindo ${ARCHIVE_PATH} em ${BUILD_ROOT}..."
    case "${ARCHIVE_PATH}" in
        *.tar.gz|*.tgz)   tar -xzf "${ARCHIVE_PATH}" -C "${BUILD_ROOT}" ;;
        *.tar.xz)         tar -xJf "${ARCHIVE_PATH}" -C "${BUILD_ROOT}" ;;
        *.tar.bz2|*.tbz2) tar -xjf "${ARCHIVE_PATH}" -C "${BUILD_ROOT}" ;;
        *.tar)            tar -xf "${ARCHIVE_PATH}" -C "${BUILD_ROOT}" ;;
        *.zip)            unzip -q "${ARCHIVE_PATH}" -d "${BUILD_ROOT}" ;;
        *)                cp "${ARCHIVE_PATH}" "${BUILD_ROOT}/" ;;
    esac
elif [[ -n "${PKG_URL}" && "${PKG_EXTRACT}" == "none" ]]; then
    cp "${DOWNLOADS_DIR}/${PKG_ARCHIVE}" "${BUILD_ROOT}/"
fi

# Determina diretório-raiz do código-fonte extraído
if [[ -n "${PKG_SRC_SUBDIR}" ]]; then
    export SRC_DIR="${BUILD_ROOT}/${PKG_SRC_SUBDIR}"
else
    mapfile -t top_entries < <(find "${BUILD_ROOT}" -mindepth 1 -maxdepth 1)
    if [[ ${#top_entries[@]} -eq 1 && -d "${top_entries[0]}" ]]; then
        export SRC_DIR="${top_entries[0]}"
    else
        export SRC_DIR="${BUILD_ROOT}"
    fi
fi
export BUILD_DIR="${BUILD_ROOT}"
export ARCHIVE_FILE="${DOWNLOADS_DIR}/${PKG_ARCHIVE}"

echo "[build-pkg] SRC_DIR=${SRC_DIR}"

# 3. Substituição preventiva de config.sub e config.guess
if [[ -f /usr/share/misc/config.sub && -f /usr/share/misc/config.guess ]]; then
    while IFS= read -r -d '' cfg; do
        echo "[build-pkg] Atualizando $(basename "${cfg}") em ${cfg}"
        cp -f "/usr/share/misc/$(basename "${cfg}")" "${cfg}"
        chmod 755 "${cfg}"
    done < <(find "${SRC_DIR}" -type f \( -name "config.sub" -o -name "config.guess" \) -print0)
fi

# 4. Aplicação ordenada de patches/<pkg>/*.patch
if [[ -d "${PATCHES_DIR}" ]]; then
    shopt -s nullglob
    patch_files=("${PATCHES_DIR}"/*.patch)
    shopt -u nullglob
    if [[ ${#patch_files[@]} -gt 0 ]]; then
        for p in "${patch_files[@]}"; do
            echo "[build-pkg] Aplicando patch: ${p}"
            patch -d "${SRC_DIR}" -p1 < "${p}"
        done
    fi
fi

# 5. Snapshot pré-instalação de ${SYSROOT_PREFIX}
SNAP_BEFORE="${BUILD_ROOT}/.snap_before"
SNAP_AFTER="${BUILD_ROOT}/.snap_after"
python3 - "${SYSROOT_PREFIX}" "${SNAP_BEFORE}" <<'PYEOF'
import os, sys
root, out_path = sys.argv[1], sys.argv[2]
entries = {}
for dirpath, _, filenames in os.walk(root):
    for fn in filenames:
        full = os.path.join(dirpath, fn)
        rel = os.path.relpath(full, root)
        st = os.lstat(full)
        entries[rel] = f"{st.st_mtime_ns}:{st.st_size}:{st.st_ino}"
with open(out_path, "w", encoding="utf-8") as fh:
    for k in sorted(entries):
        fh.write(f"{k}\t{entries[k]}\n")
PYEOF

# 6. Execução das etapas build() e install_staging() da receita
cd "${SRC_DIR}"
echo "[build-pkg] Executando build()..."
build

cd "${SRC_DIR}"
echo "[build-pkg] Executando install_staging()..."
install_staging

# 7. Calcula lista de arquivos novos ou modificados instalados por este pacote
python3 - "${SYSROOT_PREFIX}" "${SNAP_BEFORE}" "${SNAP_AFTER}" "${FILES_LIST}" <<'PYEOF'
import os, sys
root, before_path, after_path, diff_path = sys.argv[1:5]
before = {}
with open(before_path, "r", encoding="utf-8") as fh:
    for line in fh:
        k, v = line.rstrip("\n").split("\t", 1)
        before[k] = v

after = {}
for dirpath, _, filenames in os.walk(root):
    for fn in filenames:
        full = os.path.join(dirpath, fn)
        rel = os.path.relpath(full, root)
        st = os.lstat(full)
        after[rel] = f"{st.st_mtime_ns}:{st.st_size}:{st.st_ino}"

with open(after_path, "w", encoding="utf-8") as fh:
    for k in sorted(after):
        fh.write(f"{k}\t{after[k]}\n")

changed = sorted(k for k, v in after.items() if before.get(k) != v)
with open(diff_path, "w", encoding="utf-8") as fh:
    for rel in changed:
        fh.write(f"{rel}\n")
PYEOF

NEW_COUNT="$(wc -l < "${FILES_LIST}")"
echo "[build-pkg] Arquivos instalados/atualizados por ${PKG_NAME}: ${NEW_COUNT}"

# 8. Auditoria de Host Leakage em arquivos instalados (.pc, .la, scripts em bin/sbin)
LEAK_FOUND=0
while IFS= read -r rel; do
    [[ -z "${rel}" ]] && continue
    full="${SYSROOT_PREFIX}/${rel}"
    [[ -f "${full}" && ! -L "${full}" ]] || continue
    case "${rel}" in
        *.pc|*.la|bin/*|sbin/*|etc/*)
            # Checa apenas arquivos de texto (ignora ELFs binários já validados no verify-elf.sh)
            if file -b "${full}" | grep -qiE '(text|script|ASCII|UTF-8)'; then
                if grep -nE "(${STAGING}|/workspace/staging|/home/antigravity|/usr/lib/x86_64)" "${full}" >/dev/null 2>&1; then
                    echo "[build-pkg] FALHA [HOST-LEAK] Caminho do host detectado em ${rel}:" >&2
                    grep -nE "(${STAGING}|/workspace/staging|/home/antigravity|/usr/lib/x86_64)" "${full}" >&2
                    LEAK_FOUND=1
                fi
            fi
            ;;
    esac
done < "${FILES_LIST}"

if [[ "${LEAK_FOUND}" -ne 0 ]]; then
    on_error "Host leakage detectado nos arquivos instalados de ${PKG_NAME}"
fi

# 9. Invocação obrigatória de scripts/verify-elf.sh sobre todos os novos arquivos instalados
declare -a NEW_ABS_FILES=()
while IFS= read -r rel; do
    [[ -z "${rel}" ]] && continue
    full="${SYSROOT_PREFIX}/${rel}"
    if [[ -f "${full}" && ! -L "${full}" ]]; then
        NEW_ABS_FILES+=("${full}")
    fi
done < "${FILES_LIST}"

if [[ ${#NEW_ABS_FILES[@]} -gt 0 ]]; then
    echo "[build-pkg] Executando scripts/verify-elf.sh em ${#NEW_ABS_FILES[@]} artefatos de ${PKG_NAME}..."
    "${SCRIPT_DIR}/verify-elf.sh" "${NEW_ABS_FILES[@]}"
fi

# 10. Registra sucesso no manifesto parcial e limpa erro anterior
rm -f "${ERR_FILE}"
write_pkg_meta "SUCCESS" ""
echo "[build-pkg] SUCESSO: ${PKG_ID}-${PKG_NAME} (${PKG_VER}) validado."
