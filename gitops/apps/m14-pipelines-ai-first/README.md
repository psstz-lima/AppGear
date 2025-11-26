# GitOps – M14 (pipelines-ai-first)

Este diretório contém a camada GitOps/Kustomize para o módulo **M14** da AppGear (v0.3).

- Namespace alvo: `appgear-pipelines`
- Documento normativo do módulo: `development/v0.3/module-14-v0.3.md`
- Contrato de arquitetura: `docs/architecture/contract/contract-v0.md`
- Diretriz de auditoria: `docs/architecture/audit/audit-v0.md`
- Diretriz de interoperabilidade: `docs/architecture/interoperability/interoperability-v0.md`

Componentes previstos para este módulo (INTENDED_COMPONENTS):
`n8n,argo-events,argo-workflows,argo-cd`

Arquivos principais:

- `namespace.yaml` – namespace e labels padrão do módulo.
- `deployment.yaml` – deployment placeholder do controlador do módulo (`nginx:stable`), com envs descrevendo os componentes previstos.
- `service.yaml` – service ClusterIP expondo o controlador na porta 80.
- `kustomization.yaml` – entrada principal do Kustomize para este módulo.

Próximos passos:

- Substituir e/ou complementar o `deployment.yaml` com os manifests reais (Deployments, CRDs, Helm charts, Argo Applications, etc.) que implementam o módulo **M14**, mantendo os labels e o padrão de namespace.
