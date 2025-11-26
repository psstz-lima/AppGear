# GitOps – M13 (m13-workspaces-vcluster)

Este diretório contém a camada GitOps/Kustomize para o módulo **M13** da AppGear.

- Namespace alvo: `appgear-workspaces`
- Documento normativo do módulo: `development/v0.3/module-13-v0.3.md`
- Contrato de arquitetura: `docs/architecture/contract/contract-v0.md`
- Diretriz de auditoria: `docs/architecture/audit/audit-v0.md`
- Diretriz de interoperabilidade: `docs/architecture/interoperability/interoperability-v0.md`

Arquivos principais:

- `namespace.yaml` – namespace e labels padrão do módulo.
- `kustomization.yaml` – entrada principal do Kustomize para este módulo.

Próximos passos:

- Adicionar aqui os manifests reais (Deployments, Services, CRDs, etc.) que implementam o módulo **M13**, referenciando-os em `kustomization.yaml`.
