package appgear.k8s.labels_test

import data.appgear.k8s.labels

valid_metadata := {
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "name": "demo",
    "labels": {
      "app.kubernetes.io/name": "demo",
      "app.kubernetes.io/instance": "demo",
      "app.kubernetes.io/part-of": "appgear",
      "app.kubernetes.io/managed-by": "argocd",
      "appgear.io/tier": "core",
      "appgear.io/suite": "core",
      "appgear.io/topology": "B",
      "appgear.io/tenant-id": "global",
      "appgear.io/workspace-id": "global",
    },
  },
}

# Certifica que um manifesto completo não gera negações.
test_deployment_with_all_required_labels_passes {
  not labels.deny with input as valid_metadata
}

# Garante que a ausência de qualquer label obrigatória dispare negação.
test_missing_tenant_label_denied {
  manifest := valid_metadata with "metadata.labels.appgear.io/tenant-id" as null
  labels.deny[msg] with input as manifest
  msg == "Deployment demo sem label obrigatória appgear.io/tenant-id"
}
