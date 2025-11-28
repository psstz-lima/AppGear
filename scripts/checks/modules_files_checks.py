import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]

MODULOS_YAML = ROOT / "docs/architecture/interoperability/resources/modulos.yaml"
MAPA_MD = ROOT / "docs/architecture/interoperability/resources/mapa-global.md"


def _load_yaml(path: Path, name: str):
    if not path.exists():
        print(f"[ERRO] Arquivo '{name}' nao encontrado em: {path}")
        sys.exit(1)
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[ERRO] Falha ao ler/parsear '{name}' ({path}): {e}")
        sys.exit(1)


def _load_text(path: Path, name: str) -> str:
    if not path.exists():
        print(f"[ERRO] Arquivo '{name}' nao encontrado em: {path}")
        sys.exit(1)
    try:
        return path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"[ERRO] Falha ao ler '{name}' ({path}): {e}")
        sys.exit(1)


def _extract_module_ids_from_yaml(modulos_yaml) -> set[str]:
    ids: set[str] = set()
    if not isinstance(modulos_yaml, list):
        return ids
    for item in modulos_yaml:
        if isinstance(item, dict) and "id" in item:
            ids.add(str(item["id"]))
    return ids


def _expected_module_relpath(mid: str) -> str:
    """
    Convensao:
      - M00 -> development/v0.3/core-module-v0.3.md
      - M01..M99 -> development/v0.3/module-XX-v0.3.md
    """
    num = mid[1:]
    if num == "00":
        return "development/v0.3/core-module-v0.3.md"
    return f"development/v0.3/module-{num}-v0.3.md"


def main() -> None:
    print("[INFO] Raiz do repo:", ROOT)

    print(f"[INFO] Lendo modulos.yaml em: {MODULOS_YAML}")
    modulos_yaml = _load_yaml(MODULOS_YAML, "modulos.yaml")
    mod_ids = _extract_module_ids_from_yaml(modulos_yaml)
    print(f"[INFO] {len(mod_ids)} IDs de modulo encontrados: {', '.join(sorted(mod_ids))}")

    print(f"[INFO] Lendo mapa-global.md em: {MAPA_MD}")
    mapa_text = _load_text(MAPA_MD, "mapa-global.md")

    errors: list[str] = []

    for mid in sorted(mod_ids):
        relpath = _expected_module_relpath(mid)
        full_path = ROOT / relpath

        # 1) Checar existencia do arquivo fisico
        if not full_path.exists():
            errors.append(
                f"Modulo {mid} nao possui arquivo de modulo encontrado em: {relpath}"
            )

        # 2) Checar se o caminho aparece em mapa-global.md
        if relpath not in mapa_text:
            errors.append(
                f"Modulo {mid} nao referencia caminho '{relpath}' em mapa-global.md"
            )

    if errors:
        print("\n[FAIL] Inconsistencias encontradas:\n")
        for e in errors:
            print(f" - {e}")
        sys.exit(1)

    print("\n[OK] Checks de arquivos de modulo e referencias em mapa-global.md passaram sem erros.")


if __name__ == "__main__":
    main()
