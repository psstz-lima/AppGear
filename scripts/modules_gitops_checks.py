# scripts/modules_gitops_checks.py (esqueleto conceitual)

import yaml
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[1]

def main():
    mod_yaml = REPO_ROOT / "docs/architecture/interoperability/resources/modulos.yaml"
    data = yaml.safe_load(mod_yaml.read_text(encoding="utf-8"))

    errors = []
    for modulo in data.get("modulos", []):
        mid = modulo["id"]  # ex: M02
        mnum = mid[1:]      # "02"
        # mapeamento simples Mxx -> pasta
        # (mantém mesmo padrão que o ApplicationSet)
        mapping = {
            "00": "m00-fundamentos",
            "01": "m01-gitops-argo",
            "02": "m02-borda",
            "03": "m03-observabilidade",
            "04": "m04-bancos-core",
            "05": "m05-seguranca-segredos",
            "06": "m06-identidade-sso",
            "07": "m07-portal-backstage",
            "08": "m08-apps-core",
            "09": "m09-factory",
            "10": "m10-brain",
            "11": "m11-operations",
            "12": "m12-guardian",
            "13": "m13-workspaces-vcluster",
            "14": "m14-pipelines-ai-first",
            "15": "m15-dr-backup",
            "16": "m16-conectividade-hibrida",
            "17": "m17-politicas-operacionais",
        }
        folder = mapping.get(mnum)
        if not folder:
            errors.append(f"Modulo {mid} nao possui mapeamento GitOps.")
            continue

        path = REPO_ROOT / "gitops" / "apps" / folder
        if not path.exists():
            errors.append(f"Diretorio GitOps nao encontrado para {mid}: {path}")
            continue

        kustom = path / "kustomization.yaml"
        if not kustom.exists():
            errors.append(f"kustomization.yaml nao encontrado em {path} para {mid}")

    if errors:
        print("\n[FAIL] Inconsistencias GitOps de modulos:\n")
        for e in errors:
            print(" -", e)
        sys.exit(1)

    print("[OK] Checks GitOps de modulos passaram sem erros.")

if __name__ == "__main__":
    main()
