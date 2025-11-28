import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]

MODULOS_YAML = ROOT / "docs/architecture/interoperability/resources/modulos.yaml"
FLUXOS_MD = ROOT / "docs/architecture/interoperability/resources/fluxos-ai-first.md"
MAPA_MD = ROOT / "docs/architecture/interoperability/resources/mapa-global.md"

CONTRACT_MD = ROOT / "docs/architecture/contract/contract-v0.md"
AUDIT_MD = ROOT / "docs/architecture/audit/audit-v0.md"
INTEROP_MD = ROOT / "docs/architecture/interoperability/interoperability-v0.md"


def _load_text(path: Path, name: str) -> str:
    if not path.exists():
        print(f"[ERRO] Arquivo '{name}' nao encontrado em: {path}")
        sys.exit(1)
    try:
        return path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"[ERRO] Falha ao ler '{name}' ({path}): {e}")
        sys.exit(1)


def _load_yaml(path: Path, name: str):
    if not path.exists():
        print(f"[ERRO] Arquivo '{name}' nao encontrado em: {path}")
        sys.exit(1)
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[ERRO] Falha ao ler/parsear '{name}' ({path}): {e}")
        sys.exit(1)


def _extract_module_ids_from_yaml(modulos_yaml) -> set[str]:
    ids: set[str] = set()
    if not isinstance(modulos_yaml, list):
        return ids
    for item in modulos_yaml:
        if isinstance(item, dict) and "id" in item:
            ids.add(str(item["id"]))
    return ids


def _extract_module_ids_from_md(text: str) -> set[str]:
    # Módulos no formato M00, M01, ..., M17
    return set(re.findall(r"\bM\d{2}\b", text))


def check_modules_vs_docs(mod_ids: set[str], fluxos_text: str, mapa_text: str) -> list[str]:
    errors: list[str] = []

    fluxos_ids = _extract_module_ids_from_md(fluxos_text)
    mapa_ids = _extract_module_ids_from_md(mapa_text)

    # 1) Cada módulo definido deve aparecer em fluxos e mapa
    for mid in sorted(mod_ids):
        if mid not in fluxos_ids:
            errors.append(f"Modulo {mid} nao esta referenciado em fluxos-ai-first.md")
        if mid not in mapa_ids:
            errors.append(f"Modulo {mid} nao esta referenciado em mapa-global.md")

    # 2) Nenhum modulo fantasma nos .md
    for mid in sorted(fluxos_ids - mod_ids):
        errors.append(f"Modulo {mid} aparece em fluxos-ai-first.md mas nao existe em modulos.yaml")

    for mid in sorted(mapa_ids - mod_ids):
        errors.append(f"Modulo {mid} aparece em mapa-global.md mas nao existe em modulos.yaml")

    return errors


def check_normative_docs_headers() -> list[str]:
    errors: list[str] = []

    for path, name in [
        (CONTRACT_MD, "contract-v0.md"),
        (AUDIT_MD, "audit-v0.md"),
        (INTEROP_MD, "interoperability-v0.md"),
    ]:
        if not path.exists():
            errors.append(f"Documento normativo '{name}' nao encontrado em: {path}")
            continue

        text = path.read_text(encoding="utf-8")
        if not text.strip():
            errors.append(f"Documento normativo '{name}' esta vazio.")
            continue

        # Verifica se existe um H1 (# Titulo)
        if not re.search(r"^#\s+.+", text, flags=re.MULTILINE):
            errors.append(f"Documento normativo '{name}' nao possui cabecalho H1 (# ...).")

    return errors


def main() -> None:
    print("[INFO] Raiz do repo:", ROOT)

    # Carrega matriz de modulos
    print(f"[INFO] Lendo modulos.yaml em: {MODULOS_YAML}")
    modulos_yaml = _load_yaml(MODULOS_YAML, "modulos.yaml")
    mod_ids = _extract_module_ids_from_yaml(modulos_yaml)
    print(f"[INFO] {len(mod_ids)} IDs de modulo encontrados em modulos.yaml: {', '.join(sorted(mod_ids))}")

    # Carrega textos
    print(f"[INFO] Lendo fluxos-ai-first.md em: {FLUXOS_MD}")
    fluxos_text = _load_text(FLUXOS_MD, "fluxos-ai-first.md")

    print(f"[INFO] Lendo mapa-global.md em: {MAPA_MD}")
    mapa_text = _load_text(MAPA_MD, "mapa-global.md")

    errors: list[str] = []

    # 1) Checks de cruzamento modulos.yaml x fluxos/mapa
    errors += check_modules_vs_docs(mod_ids, fluxos_text, mapa_text)

    # 2) Checks de documentos normativos (cabecalhos H1)
    errors += check_normative_docs_headers()

    if errors:
        print("\n[FAIL] Inconsistencias encontradas:\n")
        for e in errors:
            print(f" - {e}")
        sys.exit(1)

    print("\n[OK] Checks semanticos de documentacao passaram sem erros.")


if __name__ == "__main__":
    main()
