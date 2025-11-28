import sys
from pathlib import Path

import yaml

# Raiz do repositório (scripts/check_docs.py -> raiz é o pai da pasta scripts)
ROOT = Path(__file__).resolve().parents[2]

MODULOS = ROOT / "docs/architecture/interoperability/resources/modulos.yaml"
THIRD_PARTY = ROOT / "docs/architecture/interoperability/resources/third_party.yaml"


def load_yaml(path: Path, name: str):
    if not path.exists():
        print(f"[ERRO] Arquivo '{name}' nao encontrado em: {path}")
        sys.exit(1)
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[ERRO] Falha ao ler/parsear '{name}' ({path}): {e}")
        sys.exit(1)


def check_modulos_ids_unicos(modulos):
    ids = [m.get("id") for m in modulos]
    duplicados = sorted({mid for mid in ids if ids.count(mid) > 1 and mid is not None})
    errors = []
    if duplicados:
        errors.append(
            f"IDs de modulo duplicados em modulos.yaml: {', '.join(duplicados)}"
        )
    return errors


def check_third_party_ids_unicos(third_party):
    ids = [c.get("id") for c in third_party]
    duplicados = sorted({cid for cid in ids if ids.count(cid) > 1 and cid is not None})
    errors = []
    if duplicados:
        errors.append(
            f"IDs de componente duplicados em third_party.yaml: {', '.join(duplicados)}"
        )
    return errors


def check_modulos_exist(third_party, modulos):
    mod_ids = {m["id"] for m in modulos if "id" in m}
    errors = []

    for comp in third_party:
        cid = comp.get("id")
        rel = comp.get("modulos_relacionados") or []
        for mid in rel:
            if mid not in mod_ids:
                errors.append(
                    f"Componente '{cid}' referencia modulo inexistente: {mid}"
                )

    return errors


def main():
    print("[INFO] Raiz do repo:", ROOT)

    print(f"[INFO] Lendo modulos.yaml em: {MODULOS}")
    modulos = load_yaml(MODULOS, "modulos.yaml")
    print(f"[INFO] {len(modulos)} modulos carregados.")

    print(f"[INFO] Lendo third_party.yaml em: {THIRD_PARTY}")
    third_party = load_yaml(THIRD_PARTY, "third_party.yaml")
    print(f"[INFO] {len(third_party)} componentes de terceiros carregados.")

    errors = []

    # 1) IDs únicos
    errors += check_modulos_ids_unicos(modulos)
    errors += check_third_party_ids_unicos(third_party)

    # 2) Relações componente -> módulo
    errors += check_modulos_exist(third_party, modulos)

    if errors:
        print("\n[FAIL] Inconsistencias encontradas:\n")
        for e in errors:
            print(f" - {e}")
        sys.exit(1)
    else:
        print("\n[OK] Checks de consistencia passaram sem erros.")


if __name__ == "__main__":
    main()
