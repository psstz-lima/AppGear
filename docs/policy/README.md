# Políticas OPA para manifests Kubernetes

As políticas deste diretório devem ser usadas em `conftest`/OPA para bloquear commits de manifests sem as labels de governança `appgear.io/*` exigidas pela plataforma.

## Como validar localmente

1. Instale o [OPA](https://www.openpolicyagent.org/docs/latest/#install-opa) ou o [Conftest](https://www.conftest.dev/).
2. Rode os testes de unidade das políticas:

   ```bash
   opa test policy/kubernetes
   ```

3. Valide seus manifests antes de commitar:

   ```bash
   conftest test path/para/seus/manifests/*.yaml --policy policy/kubernetes
   ```

A política `labels_required.rego` nega qualquer `Deployment`, `StatefulSet`, `Service` (entre outros objetos comuns) que não contenha as labels obrigatórias:

- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/part-of`
- `app.kubernetes.io/managed-by`
- `appgear.io/tier`
- `appgear.io/suite`
- `appgear.io/topology`
- `appgear.io/tenant-id`
- `appgear.io/workspace-id`

Erros são exibidos no formato `<Kind> <nome> sem label obrigatória <label>`, permitindo corrigir antes do commit.
