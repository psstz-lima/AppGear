package appgear.k8s.labels

# Labels appgear.io/* e app.kubernetes.io/* obrigatórias para workloads e serviços.
required_labels := [
  "app.kubernetes.io/name",
  "app.kubernetes.io/instance",
  "app.kubernetes.io/part-of",
  "app.kubernetes.io/managed-by",
  "appgear.io/tier",
  "appgear.io/suite",
  "appgear.io/topology",
  "appgear.io/tenant-id",
  "appgear.io/workspace-id",
]

# Conjunto de kinds para os quais a política deve ser aplicada.
# Inclui workloads, serviços e objects de rede comuns em GitOps.
covered_kinds := {
  "Deployment",
  "StatefulSet",
  "DaemonSet",
  "Job",
  "CronJob",
  "Pod",
  "Service",
  "Ingress",
  "IngressRoute",
  "IngressRouteTCP",
  "IngressRouteUDP",
  "HTTPRoute",
  "Gateway",
  "PersistentVolumeClaim",
  "ConfigMap",
  "Secret",
  "ServiceAccount",
  "Role",
  "RoleBinding",
  "ClusterRole",
  "ClusterRoleBinding",
  "Namespace",
}

metadata_name := input.metadata.name

applicable {
  input.kind
  input.metadata
  covered_kinds[input.kind]
}

missing_label[label] {
  applicable
  label := required_labels[_]
  not input.metadata.labels[label]
}

deny[msg] {
  label := missing_label[_]
  msg := sprintf("%s %s sem label obrigatória %s", [input.kind, metadata_name, label])
}
