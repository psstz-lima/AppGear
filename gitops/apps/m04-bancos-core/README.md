# GitOps – M04 (bancos-core)

Este diretório contém a camada GitOps/Kustomize para o módulo **M04** da AppGear (v0.3).

- Namespace alvo: `appgear-data`
- Documento normativo do módulo: `development/v0.3/module-04-v0.3.md`
- Contrato de arquitetura: `docs/architecture/contract/contract-v0.md`
- Diretriz de auditoria: `docs/architecture/audit/audit-v0.md`
- Diretriz de interoperabilidade: `docs/architecture/interoperability/interoperability-v0.md`

Componentes previstos para este módulo (INTENDED_COMPONENTS):
`postgres,redis,qdrant,redpanda,ceph,meilisearch`

Arquivos principais:

- `namespace.yaml` – namespace e labels padrão do módulo.
- `deployment.yaml` – deployment placeholder do controlador do módulo (`nginx:stable`), com envs descrevendo os componentes previstos.
- `service.yaml` – service ClusterIP expondo o controlador na porta 80.
- `kustomization.yaml` – entrada principal do Kustomize para este módulo.

Próximos passos:

- Substituir e/ou complementar o `deployment.yaml` com os manifests reais (Deployments, CRDs, Helm charts, Argo Applications, etc.) que implementam o módulo **M04**, mantendo os labels e o padrão de namespace.
