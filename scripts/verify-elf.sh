#!/usr/bin/env bash
# scripts/verify-elf.sh — Validador automático de binários ELF para BlackBerry Q5 / QNX Neutrino (armv7le)
# Checagens obrigatórias:
#   1. Arquitetura: ELF 32-bit LSB + ARM (falha imediata se x86-64 ou outra arquitetura)
#   2. Contaminação Linux: ausência de libc.so.6, ld-linux, libpthread.so.0, libdl.so.2
#   3. Resolução de dependências: toda biblioteca NEEDED deve existir em ${SYSROOT_PREFIX}/lib ou no sysroot QNX
#   4. Host leakage em RPATH/RUNPATH: ausência de $STAGING, /workspace/staging, /usr/lib ou /home/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
PREFIX="${PREFIX:-/accounts/1000/shared/misc/berrycore}"
STAGING="${STAGING:-${WORKSPACE_ROOT}/staging}"
SYSROOT_PREFIX="${SYSROOT_PREFIX:-${STAGING}${PREFIX}}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-/opt/bb10-gcc9}"
QNX_TARGET="${QNX_TARGET:-${TOOLCHAIN_DIR}/arm-blackberry-qnx8eabi}"

# Seleciona readelf (prefere readelf da toolchain QNX, com fallback para readelf do host)
if [[ -n "${READELF:-}" && -x "${READELF}" ]]; then
    READELF_BIN="${READELF}"
elif [[ -x "${TOOLCHAIN_DIR}/bin/arm-blackberry-qnx8eabi-readelf" ]]; then
    READELF_BIN="${TOOLCHAIN_DIR}/bin/arm-blackberry-qnx8eabi-readelf"
elif command -v readelf >/dev/null 2>&1; then
    READELF_BIN="$(command -v readelf)"
else
    echo "[verify-elf] ERRO: readelf não encontrado no ambiente." >&2
    exit 1
fi

if ! command -v file >/dev/null 2>&1; then
    echo "[verify-elf] ERRO: comando 'file' não encontrado no ambiente." >&2
    exit 1
fi

# Constrói índice de diretórios de bibliotecas válidos (sysroot da toolchain QNX + ${SYSROOT_PREFIX}/lib)
declare -a LIB_SEARCH_DIRS=()
for candidate in \
    "${SYSROOT_PREFIX}/lib" \
    "${QNX_TARGET}/lib" \
    "${QNX_TARGET}/usr/lib" \
    "${QNX_TARGET}/armle-v7/lib" \
    "${QNX_TARGET}/armle-v7/usr/lib" \
    "${TOOLCHAIN_DIR}/lib" \
    "${TOOLCHAIN_DIR}/arm-blackberry-qnx8eabi/lib" \
    "${TOOLCHAIN_DIR}/target/qnx6/armle-v7/lib" \
    "${TOOLCHAIN_DIR}/target/qnx6/armle-v7/usr/lib"; do
    if [[ -d "${candidate}" ]]; then
        LIB_SEARCH_DIRS+=("${candidate}")
    fi
done

is_elf_file() {
    local path="$1"
    [[ -f "${path}" && ! -L "${path}" ]] || return 1
    # Verifica magic bytes 0x7f 'E' 'L' 'F' de forma rápida sem depender de extensão
    local magic
    magic="$(head -c 4 "${path}" 2>/dev/null | od -An -tx1 | tr -d ' \n')"
    [[ "${magic}" == "7f454c46" ]]
}

lib_exists_in_sysroots() {
    local soname="$1"
    local dir
    for dir in "${LIB_SEARCH_DIRS[@]}"; do
        if [[ -e "${dir}/${soname}" ]]; then
            return 0
        fi
        # Permite bibliotecas em subdiretórios imediatos (ex.: openssl engines, python)
        if find "${dir}" -maxdepth 3 \( -type f -o -type l \) -name "${soname}" -print -quit 2>/dev/null | grep -q .; then
            return 0
        fi
    done
    return 1
}

verify_one_elf() {
    local elf="$1"
    local pkg_errors=0
    local file_desc hdr dyn interp needed rpaths

    file_desc="$(file -b "${elf}")"
    hdr="$("${READELF_BIN}" -h "${elf}" 2>/dev/null || true)"
    dyn="$("${READELF_BIN}" -d "${elf}" 2>/dev/null || true)"
    interp="$("${READELF_BIN}" -l "${elf}" 2>/dev/null | grep -i 'Requesting program interpreter' || true)"

    # Checagem 1: Arquitetura ELF 32-bit LSB + ARM
    if ! grep -q "Class:[[:space:]]*ELF32" <<< "${hdr}" || \
       ! grep -q "Data:.*little endian" <<< "${hdr}" || \
       ! grep -q "Machine:[[:space:]]*ARM" <<< "${hdr}"; then
        echo "[verify-elf] FALHA [ARCH] ${elf}: esperado ELF 32-bit LSB ARM; obtido: ${file_desc}" >&2
        pkg_errors=$((pkg_errors + 1))
    fi

    # Checagem 2: Contaminação Linux (glibc / ld-linux / libpthread.so.0 / libdl.so.2)
    local combined_dyn="${dyn}"$'\n'"${interp}"
    if grep -qE '(libc\.so\.6|ld-linux|libpthread\.so\.0|libdl\.so\.2)' <<< "${combined_dyn}"; then
        local bad_refs
        bad_refs="$(grep -oE '(libc\.so\.6|ld-linux[^][:space:]]*|libpthread\.so\.0|libdl\.so\.2)' <<< "${combined_dyn}" | sort -u | tr '\n' ' ')"
        echo "[verify-elf] FALHA [LINUX-LEAK] ${elf}: referências glibc/Linux proibidas detectadas: ${bad_refs}" >&2
        pkg_errors=$((pkg_errors + 1))
    fi

    # Checagem 3: Resolução de todas as bibliotecas NEEDED
    needed="$(awk -F'[][]' '/\(NEEDED\)/ {print $2}' <<< "${dyn}")"
    if [[ -n "${needed}" ]]; then
        if [[ ${#LIB_SEARCH_DIRS[@]} -eq 0 ]]; then
            echo "[verify-elf] FALHA [SYSROOT] ${elf}: nenhum diretório de sysroot QNX ou \${SYSROOT_PREFIX}/lib disponível para resolver NEEDED." >&2
            pkg_errors=$((pkg_errors + 1))
        else
            local lib
            while IFS= read -r lib; do
                [[ -z "${lib}" ]] && continue
                if ! lib_exists_in_sysroots "${lib}"; then
                    echo "[verify-elf] FALHA [MISSING-NEEDED] ${elf}: biblioteca '${lib}' não encontrada no sysroot QNX nem em ${SYSROOT_PREFIX}/lib" >&2
                    pkg_errors=$((pkg_errors + 1))
                fi
            done <<< "${needed}"
        fi
    fi

    # Checagem 4: Proibição de Host Leakage em RPATH / RUNPATH
    rpaths="$(awk -F'[][]' '/\((RPATH|RUNPATH)\)/ {print $2}' <<< "${dyn}")"
    if [[ -n "${rpaths}" ]]; then
        if grep -qE "(${STAGING}|/workspace/staging|/usr/lib|/home/)" <<< "${rpaths}"; then
            echo "[verify-elf] FALHA [HOST-LEAK-RPATH] ${elf}: RPATH/RUNPATH contém caminho do host: ${rpaths}" >&2
            pkg_errors=$((pkg_errors + 1))
        fi
    fi

    return "${pkg_errors}"
}

declare -a TARGETS=()
if [[ $# -eq 0 ]]; then
    TARGETS=("${SYSROOT_PREFIX}")
else
    TARGETS=("$@")
fi

SCANNED=0
PASSED=0
FAILED=0

for target in "${TARGETS[@]}"; do
    if [[ ! -e "${target}" ]]; then
        echo "[verify-elf] ERRO: alvo inexistente: ${target}" >&2
        FAILED=$((FAILED + 1))
        continue
    fi

    if [[ -f "${target}" ]]; then
        if is_elf_file "${target}"; then
            SCANNED=$((SCANNED + 1))
            if verify_one_elf "${target}"; then
                PASSED=$((PASSED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        fi
    elif [[ -d "${target}" ]]; then
        while IFS= read -r -d '' file_path; do
            if is_elf_file "${file_path}"; then
                SCANNED=$((SCANNED + 1))
                if verify_one_elf "${file_path}"; then
                    PASSED=$((PASSED + 1))
                else
                    FAILED=$((FAILED + 1))
                fi
            fi
        done < <(find "${target}" -type f -print0)
    fi
done

echo "[verify-elf] Resumo: analisados=${SCANNED} aprovados=${PASSED} falhas=${FAILED}"
if [[ "${FAILED}" -gt 0 ]]; then
    exit 1
fi
exit 0
