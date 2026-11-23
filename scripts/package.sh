#!/usr/bin/env bash
# scripts/package.sh — Strip de símbolos ELF, geração de env.sh, empacotamento .zip modular/consolidado,
#                      SHA256SUMS, manifest.json final e BUILD_REPORT.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

# shellcheck source=scripts/env-cross.sh
source "${SCRIPT_DIR}/env-cross.sh"

DIST_DIR="${WORKSPACE_ROOT}/dist"
PKG_ZIP_DIR="${DIST_DIR}/packages"
META_DIR="${DIST_DIR}/.pkgmeta"
MANIFEST_PATH="${DIST_DIR}/manifest.json"
SHA256_PATH="${DIST_DIR}/SHA256SUMS"
BUNDLE_NAME="berrycore-debian-suite-armv7le.zip"
BUNDLE_PATH="${DIST_DIR}/${BUNDLE_NAME}"
REPORT_PATH="${WORKSPACE_ROOT}/BUILD_REPORT.md"

mkdir -p "${DIST_DIR}" "${PKG_ZIP_DIR}"

if [[ ! -d "${SYSROOT_PREFIX}" ]]; then
    echo "[package] ERRO: diretório de staging inexistente: ${SYSROOT_PREFIX}" >&2
    exit 1
fi

# 1. Otimização: strip --strip-unneeded em executáveis ELF e bibliotecas .so (ignorando scripts shell/Python)
echo "[package] Etapa 1/6: Executando strip em binários ELF e .so em ${SYSROOT_PREFIX}..."
STRIP_BIN="${STRIP}"
if [[ ! -x "${STRIP_BIN}" ]]; then
    echo "[package] ERRO: strip da toolchain não encontrado em ${STRIP_BIN}" >&2
    exit 1
fi

STRIPPED_COUNT=0
while IFS= read -r -d '' fpath; do
    [[ -f "${fpath}" && ! -L "${fpath}" ]] || continue
    magic="$(head -c 4 "${fpath}" 2>/dev/null | od -An -tx1 | tr -d ' \n')"
    if [[ "${magic}" == "7f454c46" ]]; then
        chmod u+w "${fpath}" 2>/dev/null || true
        "${STRIP_BIN}" --strip-unneeded "${fpath}" || true
        STRIPPED_COUNT=$((STRIPPED_COUNT + 1))
    fi
done < <(find "${SYSROOT_PREFIX}" -type f -print0)
echo "[package] Total de arquivos ELF processados pelo strip: ${STRIPPED_COUNT}"

# 2. Validação ELF global pós-strip
echo "[package] Etapa 2/6: Validando integridade ELF pós-strip..."
"${SCRIPT_DIR}/verify-elf.sh" "${SYSROOT_PREFIX}"

# 3. Geração do script de ambiente ${SYSROOT_PREFIX}/env.sh (sem caminhos de host)
echo "[package] Etapa 3/6: Gerando ${SYSROOT_PREFIX}/env.sh..."
cat > "${SYSROOT_PREFIX}/env.sh" <<'EOF'
# BerryCore Debian-to-BerryCore Runtime Environment (BlackBerry Q5 / QNX Neutrino)
# Uso no Term49: source /accounts/1000/shared/misc/berrycore/env.sh

export PREFIX="/accounts/1000/shared/misc/berrycore"
export PATH="$PREFIX/bin:$PREFIX/sbin:$PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export TERMINFO="$PREFIX/share/terminfo"
export SSL_CERT_FILE="$PREFIX/etc/ssl/certs/ca-certificates.crt"
export CURL_CA_BUNDLE="$PREFIX/etc/ssl/certs/ca-certificates.crt"
export MANPATH="$PREFIX/share/man:$MANPATH"
EOF
chmod 644 "${SYSROOT_PREFIX}/env.sh"

# 4. Empacotamento modular: dist/packages/<pacote>-<versao>-bb10-armv7le.zip
echo "[package] Etapa 4/6: Empacotando zips modulares em ${PKG_ZIP_DIR}..."
rm -f "${PKG_ZIP_DIR}"/*.zip "${BUNDLE_PATH}" "${SHA256_PATH}"

if [[ -d "${META_DIR}" ]]; then
    shopt -s nullglob
    meta_files=("${META_DIR}"/*.json)
    shopt -u nullglob

    for meta_file in "${meta_files[@]}"; do
        IFS='|' read -r pkg_name pkg_ver pkg_status < <(
            python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["name"], d["version"], d["status"], sep="|")' "${meta_file}"
        )
        [[ "${pkg_status}" == "SUCCESS" ]] || continue

        files_list="${META_DIR}/${pkg_name}.files"
        [[ -s "${files_list}" ]] || continue

        zip_out="${PKG_ZIP_DIR}/${pkg_name}-${pkg_ver}-bb10-armv7le.zip"
        echo "[package]   -> $(basename "${zip_out}")"
        (
            cd "${SYSROOT_PREFIX}"
            zip -q -y "${zip_out}" -@ < "${files_list}"
        )

        # Recalcula tamanho pós-strip no JSON parcial
        python3 - "${meta_file}" "${files_list}" "${SYSROOT_PREFIX}" "packages/$(basename "${zip_out}")" <<'PYEOF'
import json, os, sys
meta_file, files_list, sysroot, zip_rel = sys.argv[1:5]
with open(meta_file, "r", encoding="utf-8") as fh:
    d = json.load(fh)
total_bytes = 0
with open(files_list, "r", encoding="utf-8") as fh:
    for line in fh:
        rel = line.strip()
        if not rel:
            continue
        full = os.path.join(sysroot, rel)
        if os.path.isfile(full) and not os.path.islink(full):
            total_bytes += os.path.getsize(full)
d["size_kb"] = (total_bytes + 1023) // 1024
d["archive"] = zip_rel
with open(meta_file, "w", encoding="utf-8") as fh:
    json.dump(d, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PYEOF
    done
fi

# 5. Empacotamento consolidado: dist/berrycore-debian-suite-armv7le.zip
echo "[package] Etapa 5/6: Gerando bundle consolidado ${BUNDLE_PATH}..."
(
    cd "${SYSROOT_PREFIX}"
    zip -q -r -y "${BUNDLE_PATH}" .
)

# 6. Geração de SHA256SUMS, manifest.json consolidado e BUILD_REPORT.md
echo "[package] Etapa 6/6: Gerando SHA256SUMS, manifest.json e BUILD_REPORT.md..."
(
    cd "${DIST_DIR}"
    sha256sum "${BUNDLE_NAME}" > "${SHA256_PATH}"
    shopt -s nullglob
    pkg_zips=(packages/*.zip)
    shopt -u nullglob
    if [[ ${#pkg_zips[@]} -gt 0 ]]; then
        sha256sum "${pkg_zips[@]}" >> "${SHA256_PATH}"
    fi
)

python3 - "${META_DIR}" "${MANIFEST_PATH}" "${REPORT_PATH}" "${TARGET}" "${PREFIX}" "${WORKSPACE_ROOT}" "${BUNDLE_NAME}" <<'PYEOF'
import datetime, glob, json, os, sys

meta_dir, manifest_path, report_path, target, prefix, ws_root, bundle_name = sys.argv[1:8]

packages = []
if os.path.isdir(meta_dir):
    for path in sorted(glob.glob(os.path.join(meta_dir, "*.json"))):
        with open(path, "r", encoding="utf-8") as fh:
            packages.append(json.load(fh))

packages.sort(key=lambda p: (int(p.get("layer", 0)), str(p.get("id", "99")), str(p.get("name", ""))))
total = len(packages)
success_pkgs = [p for p in packages if p.get("status") == "SUCCESS"]
blocked_pkgs = [p for p in packages if p.get("status") == "BLOCKED"]
rate = (100.0 * len(success_pkgs) / total) if total else 0.0

now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
manifest = {
    "target": target,
    "prefix": prefix,
    "bundle": bundle_name,
    "generated_at": now_iso,
    "summary": {
        "total": total,
        "success": len(success_pkgs),
        "blocked": len(blocked_pkgs),
        "success_rate_pct": round(rate, 2),
    },
    "packages": packages,
}

with open(manifest_path, "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, indent=2, ensure_ascii=False)
    fh.write("\n")

patches_root = os.path.join(ws_root, "patches")
all_patches = []
if os.path.isdir(patches_root):
    for dirpath, _, filenames in os.walk(patches_root):
        for fn in sorted(filenames):
            if fn.endswith(".patch"):
                all_patches.append(os.path.relpath(os.path.join(dirpath, fn), ws_root))
all_patches.sort()

lines = [
    "# Relatório Final de Build — Debian-to-BerryCore (BlackBerry Q5 / QNX Neutrino)",
    "",
    f"- **Gerado em:** `{now_iso}`",
    f"- **Alvo (Target Triple):** `{target}` (`armv7le`, softfp)",
    f"- **Prefixo no Dispositivo (`PREFIX`):** `{prefix}`",
    f"- **Bundle Consolidado:** `dist/{bundle_name}`",
    f"- **Taxa de Sucesso:** **{len(success_pkgs)}/{total} ({rate:.1f}%)** | Bloqueados: **{len(blocked_pkgs)}**",
    "",
    "## Pacotes Compilados e Status por Camada",
    "",
    "| ID | Camada | Pacote | Versão | Status | Tamanho (KB) | Binários |",
    "| :--- | :---: | :--- | :--- | :---: | ---: | :--- |",
]

for p in packages:
    bins = ", ".join(f"`{os.path.basename(b)}`" for b in p.get("binaries", [])[:6])
    if len(p.get("binaries", [])) > 6:
        bins += f" (+{len(p['binaries']) - 6})"
    lines.append(
        f"| `{p.get('id', '')}` | {p.get('layer', '')} | `{p.get('name', '')}` | `{p.get('version', '')}` | **{p.get('status', '')}** | {p.get('size_kb', 0)} | {bins or '—'} |"
    )

lines += [
    "",
    "## Patches QNX Versionados (`patches/`)",
    "",
]
if all_patches:
    for pf in all_patches:
        lines.append(f"- `{pf}`")
else:
    lines.append("- Nenhum patch customizado foi necessário.")

lines += [
    "",
    "## Pacotes Bloqueados (`BLOCKED`)",
    "",
]
if blocked_pkgs:
    for p in blocked_pkgs:
        lines.append(f"- **`{p['name']}` ({p['version']})** — {p.get('error_summary') or 'Ver log de erro'} (`logs/{p['name']}-error.log`)")
else:
    lines.append("- Nenhum pacote bloqueado.")

lines += [
    "",
    "## Instruções de Instalação no BlackBerry Q5 (Term49)",
    "",
    "1. Copie `dist/berrycore-debian-suite-armv7le.zip` e `dist/SHA256SUMS` para o dispositivo (ex.: `/accounts/1000/shared/downloads/`).",
    "2. No **Term49**, crie o diretório alvo e extraia o bundle mantendo a hierarquia relativa a `$PREFIX`:",
    "",
    "```sh",
    f"mkdir -p {prefix}",
    f"unzip -o /accounts/1000/shared/downloads/{bundle_name} -d {prefix}",
    f"source {prefix}/env.sh",
    "```",
    "",
    "3. Para ativar automaticamente em toda sessão do Term49, adicione ao seu perfil (`~/.profile`):",
    "",
    "```sh",
    f'echo "source {prefix}/env.sh" >> ~/.profile',
    "```",
    "",
    "4. Validação rápida no dispositivo:",
    "",
    "```sh",
    "openssl version",
    "curl --version",
    "ssh -V",
    "```",
    "",
]

with open(report_path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines))
PYEOF

echo "[package] Empacotamento concluído com sucesso:"
echo "  - Bundle:    ${BUNDLE_PATH}"
echo "  - Checksums: ${SHA256_PATH}"
echo "  - Manifesto: ${MANIFEST_PATH}"
echo "  - Relatório: ${REPORT_PATH}"
