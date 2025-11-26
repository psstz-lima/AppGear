import sys
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run_step(description: str, args: list[str]) -> None:
    print(f"\n[STEP] {description}")
    print(f"[CMD ] {' '.join(args)}\n")

    result = subprocess.run(args, cwd=ROOT)
    if result.returncode != 0:
        print(f"[FAIL] Etapa falhou: {description}")
        sys.exit(result.returncode)

    print(f"[OK  ] {description} concluida com sucesso.")


def main() -> None:
    print("[INFO] Raiz do repo:", ROOT)

    # 1) Check de documentacao (modulos.yaml + third_party.yaml)
    run_step(
        "Validar matriz de modulos e componentes terceiros (check_docs.py)",
        [sys.executable, "scripts/check_docs.py"],
    )

    # 2) Check da cadeia de borda (Ingress/IngressRoute/Services/stack-unificada)
    run_step(
        "Validar cadeia de borda (Traefik → Coraza → Kong → Istio) (edge_chain.py)",
        [sys.executable, "scripts/edge_chain.py"],
    )

    print("\n[ALL OK] Todos os checks passaram sem erros.")


if __name__ == "__main__":
    main()
