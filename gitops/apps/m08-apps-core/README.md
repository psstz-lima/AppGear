# GitOps – M08 (apps-core)

Este diretório contém a camada GitOps/Kustomize para o módulo **M08** da AppGear (v0.3).

- Namespace alvo: `appgear-apps`
- Imagem base utilizada neste módulo: `n8nio/n8n:latest` (ajuste conforme a versão/repositorio real desejado)
- Documento normativo do módulo: `development/v0.3/module-08-v0.3.md`
- Contrato de arquitetura: `docs/architecture/contract/contract-v0.md`
- Diretriz de auditoria: `docs/architecture/audit/audit-v0.md`
- Diretriz de interoperabilidade: `docs/architecture/interoperability/interoperability-v0.md`

Componentes previstos para este módulo (INTENDED_COMPONENTS):
`litellm,flowise,n8n,directus,appsmith,metabase,tika,gotenberg`

Arquivos principais:

- `namespace.yaml` – namespace e labels padrão do módulo.
- `deployment.yaml` – deployment do controlador do módulo, com uma imagem base aderente ao domínio do módulo.
- `service.yaml` – service ClusterIP expondo o controlador na porta 80.
- `kustomization.yaml` – entrada principal do Kustomize para este módulo.

Observação:

- A imagem configurada em `deployment.yaml` é uma sugestão e pode exigir ajuste de tag ou de repositório
  para o ambiente real (por exemplo, pinagem de versão, repositório privado ou imagem hardenizada).
- Os componentes listados em `INTENDED_COMPONENTS` devem ser detalhados em manifests adicionais,
  que podem ser adicionados a este diretório e referenciados em `kustomization.yaml`.
