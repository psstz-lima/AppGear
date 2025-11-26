# GitOps – M01 (m01-gitops-argo)

Este diretório contém a camada GitOps/Kustomize para o módulo **M01** da AppGear.

- Namespace alvo: `appgear-gitops`
- Documento normativo do módulo: `development/v0.3/module-01-v0.3.md`
- Contrato de arquitetura: `docs/architecture/contract/contract-v0.md`
- Diretriz de auditoria: `docs/architecture/audit/audit-v0.md`
- Diretriz de interoperabilidade: `docs/architecture/interoperability/interoperability-v0.md`

Arquivos principais:

- `namespace.yaml` – namespace e labels padrão do módulo.
- `kustomization.yaml` – entrada principal do Kustomize para este módulo.

Próximos passos:

- Adicionar aqui os manifests reais (Deployments, Services, CRDs, etc.) que implementam o módulo **M01**, referenciando-os em `kustomization.yaml`.
