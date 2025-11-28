import sys
import subprocess
from pathlib import Path


def run_step(repo_root: Path, descricao: str, script_rel: str) -> None:
    """Executa um script de check e aborta em caso de erro."""
    python_exe = sys.executable
    script_path = repo_root / script_rel

    print(f"\n[STEP] {descricao} ({script_rel})")
    print(f"[CMD ] {python_exe} {script_rel}")

    result = subprocess.run([python_exe, str(script_path)], cwd=repo_root, check=False)
    if result.returncode != 0:
        print(f"[FAIL] Etapa falhou: {descricao}")
        sys.exit(result.returncode)

    print(f"[OK  ] {descricao} concluida com sucesso.")


def main() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    print(f"[INFO] Raiz do repo: {repo_root}")

    # 1) Matriz de modulos x componentes terceiros
    run_step(
        repo_root,
        "Validar matriz de modulos e componentes terceiros (check_docs.py)",
        "scripts/checks/check_docs.py",
    )

    # 2) Cadeia de borda (Traefik -> Coraza -> Kong -> Istio)
    run_step(
        repo_root,
        "Validar cadeia de borda (Traefik → Coraza → Kong → Istio) (edge_chain.py)",
        "scripts/checks/edge_chain.py",
    )

    # 3) Cruzamento de modulos com fluxos/mapa e cabecalhos normativos
    run_step(
        repo_root,
        "Validar cruzamento de modulos com fluxos/mapa e cabecalhos normativos (docs_semantic_checks.py)",
        "scripts/checks/docs_semantic_checks.py",
    )

    # 4) Existencia de arquivos de modulo e suas referencias em mapa-global
    run_step(
        repo_root,
        "Validar existencia de arquivos de modulo e suas referencias em mapa-global (modules_files_checks.py)",
        "scripts/checks/modules_files_checks.py",
    )

    # 5) GitOps por modulo (NOVO)
    run_step(
        repo_root,
        "Validar estrutura GitOps/Kustomize por modulo (modules_gitops_checks.py)",
        "scripts/checks/modules_gitops_checks.py",
    )

    print("\n[ALL OK] Todos os checks passaram sem erros.")


if __name__ == "__main__":
    main()
