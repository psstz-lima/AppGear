import sys
from pathlib import Path

import yaml


def main() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    print(f"[INFO] Raiz do repo: {repo_root}")

    mod_yaml = repo_root / "docs" / "architecture" / "interoperability" / "resources" / "modulos.yaml"
    if not mod_yaml.exists():
        print(f"[ERRO] Arquivo 'modulos.yaml' nao encontrado em: {mod_yaml}")
        sys.exit(1)

    print(f"[INFO] Lendo modulos.yaml em: {mod_yaml}")
    data = yaml.safe_load(mod_yaml.read_text(encoding="utf-8"))

    # Suportar dois formatos:
    # 1) lista na raiz: [ {{id: M00, ...}}, ... ]
    # 2) dict com chave 'modulos': {{ modulos: [ ... ] }}
    if isinstance(data, list):
        modulos = data
    elif isinstance(data, dict):
        modulos = data.get("modulos", [])
    else:
        modulos = []

    if not modulos:
        print("[ERRO] Nenhum modulo encontrado em modulos.yaml (lista vazia).")
        sys.exit(1)

    # Mapeamento Mxx -> pasta GitOps em gitops/apps
    mapping = {
        "M00": "m00-fundamentos",
        "M01": "m01-gitops-argo",
        "M02": "m02-borda",
        "M03": "m03-observabilidade",
        "M04": "m04-bancos-core",
        "M05": "m05-seguranca-segredos",
        "M06": "m06-identidade-sso",
        "M07": "m07-portal-backstage",
        "M08": "m08-apps-core",
        "M09": "m09-factory",
        "M10": "m10-brain",
        "M11": "m11-operations",
        "M12": "m12-guardian",
        "M13": "m13-workspaces-vcluster",
        "M14": "m14-pipelines-ai-first",
        "M15": "m15-dr-backup",
        "M16": "m16-conectividade-hibrida",
        "M17": "m17-politicas-operacionais",
    }

    errors: list[str] = []

    for modulo in modulos:
        if not isinstance(modulo, dict):
            continue

        mid = str(modulo.get("id", "")).strip()  # ex.: "M02"
        if not mid:
            continue

        folder = mapping.get(mid)
        if not folder:
            errors.append(
                f"Modulo {mid} nao possui mapeamento GitOps definido no script (ajustar mapping em modules_gitops_checks.py)."
            )
            continue

        base_dir = repo_root / "gitops" / "apps" / folder
        if not base_dir.exists():
            errors.append(f"Diretorio GitOps nao encontrado para {mid}: {base_dir}")
            continue

        kustom = base_dir / "kustomization.yaml"
        if not kustom.exists():
            errors.append(f"kustomization.yaml nao encontrado em {base_dir} para {mid}")

        ns = base_dir / "namespace.yaml"
        if not ns.exists():
            errors.append(f"namespace.yaml nao encontrado em {base_dir} para {mid}")

    if errors:
        print("\n[FAIL] Inconsistencias GitOps de modulos:\n")
        for e in errors:
            print(" -", e)
        sys.exit(1)

    print("\n[OK] Checks GitOps de modulos passaram sem erros.")


if __name__ == "__main__":
    main()
