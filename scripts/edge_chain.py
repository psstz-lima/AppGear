from __future__ import annotations

import re
from pathlib import Path
from typing import Iterable, List

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
EDGE_CHAIN_SEQUENCE = ["traefik", "coraza", "kong"]
ALLOWED_EDGE_SERVICE_KEYWORDS = ("traefik", "coraza", "kong", "istio")
WAF_KEYWORDS = ("coraza", "waf")


def _iter_yaml_files() -> Iterable[Path]:
    """Yield all YAML/YML files under the repository root."""
    for extension in ("*.yml", "*.yaml"):
        for path in REPO_ROOT.rglob(extension):
            yield path


def _split_documents(content: str) -> List[str]:
    return [doc for doc in re.split(r"\n---\s*\n", content) if doc.strip()]


def _read_yaml_documents(path: Path) -> List[str]:
    try:
        content = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        pytest.fail(f"Arquivo {path} não pôde ser lido como UTF-8.")
    return _split_documents(content)


def _extract_top_field(doc: str, field: str) -> str | None:
    match = re.search(rf"^{re.escape(field)}:\s*(.+)$", doc, flags=re.MULTILINE)
    if match:
        return match.group(1).strip().strip("'\"")
    return None


def _extract_metadata_name(doc: str) -> str | None:
    meta_match = re.search(r"^metadata:\s*(\n(?:[ \t]+.+\n?)*)", doc, flags=re.MULTILINE)
    if not meta_match:
        return None
    meta_block = meta_match.group(1)
    name_match = re.search(r"name:\s*([A-Za-z0-9._-]+)", meta_block)
    return name_match.group(1) if name_match else None


def _extract_ingress_class(doc: str) -> str | None:
    match = re.search(r"ingressClassName:\s*([A-Za-z0-9._-]+)", doc)
    return match.group(1) if match else None


def _extract_service_type(doc: str) -> str | None:
    spec_match = re.search(r"^spec:\s*(\n(?:[ \t]+.+\n?)*)", doc, flags=re.MULTILINE)
    if not spec_match:
        return None
    spec_block = spec_match.group(1)
    type_match = re.search(r"type:\s*([A-Za-z0-9]+)", spec_block)
    return type_match.group(1) if type_match else None


def _extract_route_services(doc: str) -> List[str]:
    services: List[str] = []
    for match in re.finditer(r"services:\s*(\n[ \t]+-.+?)(?=\n[^ \t-]|$)", doc, flags=re.DOTALL):
        block = match.group(1)
        services.extend(re.findall(r"name:\s*([A-Za-z0-9._-]+)", block))
        services.extend(re.findall(r"service:\s*([A-Za-z0-9._-]+)", block))
    return services


def _edge_pipeline_order(text: str) -> List[str]:
    order: List[str] = []
    in_edge = False
    in_order = False
    edge_indent = order_indent = 0
    for line in text.splitlines():
        stripped = line.strip()
        indent = len(line) - len(line.lstrip(" "))
        if stripped.startswith("edge_pipeline:"):
            in_edge = True
            edge_indent = indent
            continue
        if in_edge and indent <= edge_indent and stripped:
            in_edge = False
            in_order = False
        if in_edge and stripped.startswith("order:"):
            in_order = True
            order_indent = indent
            inline_values = stripped.split(":", 1)[1].strip()
            if inline_values.startswith("[") and inline_values.endswith("]"):
                for item in inline_values.strip("[]").split(","):
                    cleaned = item.strip().strip('"')
                    if cleaned:
                        order.append(cleaned)
                in_order = False
            continue
        if in_edge and in_order:
            if indent <= order_indent and stripped:
                in_order = False
                continue
            if stripped.startswith("-"):
                item = stripped.lstrip("-").strip().strip('"')
                if item:
                    order.append(item)
    return order


def test_edge_pipeline_sequence_documented():
    """
    Garante que o manifesto principal continue documentando a cadeia Traefik → Coraza → Kong.

    Isso evita que futuras alterações no baseline removam a ordem obrigatória da borda,
    o que poderia mascarar rotas diretas.
    """
    stack_file = REPO_ROOT / "development" / "v0.3" / "stack-unificada-v0.3.yaml"
    assert stack_file.exists(), "Manifesto base v0.3 ausente; não é possível validar a cadeia de borda."
    documents = _read_yaml_documents(stack_file)
    assert documents, "Manifesto base vazio ou não legível."
    documented_order = [item.split()[0].lower() for item in _edge_pipeline_order(documents[0])]
    assert documented_order[:3] == EDGE_CHAIN_SEQUENCE, (
        "A ordem documentada da cadeia de borda diverge do padrão Traefik → Coraza → Kong."
    )


def test_ingress_objects_use_kong_class():
    """Ingressos precisam usar a ingressClassName 'kong' para manter o fluxo via gateway."""
    failures = []
    for path in _iter_yaml_files():
        for doc in _read_yaml_documents(path):
            if _extract_top_field(doc, "kind") == "Ingress":
                ingress_class = _extract_ingress_class(doc)
                if ingress_class != "kong":
                    name = _extract_metadata_name(doc) or "<sem-nome>"
                    failures.append(f"{path} :: ingress '{name}' usa ingressClassName '{ingress_class}'")
    assert not failures, (
        "Ingress fora da cadeia detectados (ingressClassName diferente de 'kong'):\n- "
        + "\n- ".join(failures)
    )


def test_ingressroutes_only_target_waf():
    """
    Traefik deve encaminhar apenas para o WAF (Coraza).

    Rotas que apontam direto para serviços de aplicação indicam bypass do WAF/Kong.
    """
    failures = []
    for path in _iter_yaml_files():
        for doc in _read_yaml_documents(path):
            if _extract_top_field(doc, "kind") in {"IngressRoute", "IngressRouteTCP"}:
                route_services = _extract_route_services(doc)
                bypass = [svc for svc in route_services if not any(key in svc.lower() for key in WAF_KEYWORDS)]
                if bypass:
                    name = _extract_metadata_name(doc) or "<sem-nome>"
                    failures.append(
                        f"{path} :: IngressRoute '{name}' expõe serviços sem passar pelo WAF: {', '.join(bypass)}"
                    )
    assert not failures, (
        "IngressRoutes apontando para serviços sem Coraza detectados:\n- " + "\n- ".join(failures)
    )


def test_services_not_exposed_directly():
    """
    Serviços tipo LoadBalancer/NodePort devem ser apenas os componentes da cadeia de borda.
    """
    failures = []
    for path in _iter_yaml_files():
        for doc in _read_yaml_documents(path):
            if _extract_top_field(doc, "kind") == "Service":
                service_type = _extract_service_type(doc) or "ClusterIP"
                if service_type in {"LoadBalancer", "NodePort"}:
                    name = (_extract_metadata_name(doc) or "").lower()
                    if not any(keyword in name for keyword in ALLOWED_EDGE_SERVICE_KEYWORDS):
                        failures.append(
                            f"{path} :: Service '{name}' exposto como {service_type} fora da cadeia de borda"
                        )
    assert not failures, (
        "Services expostos diretamente detectados (LoadBalancer/NodePort fora de Traefik/Coraza/Kong/Istio):\n- "
        + "\n- ".join(failures)
    )

if __name__ == "__main__":
    # Permite rodar este arquivo diretamente com:
    #   python scripts/test_edge_chain.py
    # em vez de chamar pytest manualmente.
    import pytest as _pytest
    _pytest.main([str(Path(__file__))])

