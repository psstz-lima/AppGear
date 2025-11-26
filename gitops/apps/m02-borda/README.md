# GitOps – M02 (m02-borda)

Este diretório contém a camada GitOps/Kustomize para o módulo **M02** da AppGear.

- Namespace alvo: `appgear-edge`
- Documento normativo do módulo: `development/v0.3/module-02-v0.3.md`
- Contrato de arquitetura: `docs/architecture/contract/contract-v0.md`
- Diretriz de auditoria: `docs/architecture/audit/audit-v0.md`
- Diretriz de interoperabilidade: `docs/architecture/interoperability/interoperability-v0.md`

Arquivos principais:

- `namespace.yaml` – namespace e labels padrão do módulo.
- `kustomization.yaml` – entrada principal do Kustomize para este módulo.

Próximos passos:

- Adicionar aqui os manifests reais (Deployments, Services, CRDs, etc.) que implementam o módulo **M02**, referenciando-os em `kustomization.yaml`.
