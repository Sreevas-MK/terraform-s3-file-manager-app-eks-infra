test_pod:
  enabled: true
  image: bats/bats:1.8.2
  pullPolicy: IfNotPresent

loki:
  enabled: true
  isDefault: false
  image:
    repository: grafana/loki
    tag: 2.9.0
    pullPolicy: IfNotPresent
  service:
    port: 3100
  url: http://monitoring-stack-loki:3100

  serviceAccount:
    create: true
    name: ${loki_service_account}
    annotations:
      eks.amazonaws.com/role-arn: ${loki_iam_role_arn}

  persistence:
    enabled: false
    size: 1Gi
    storageClassName: loki-local

  podSecurityContext:
    fsGroup: 10001

  securityContext:
    runAsUser: 10001
    runAsGroup: 10001


  config:

    auth_enabled: false

    server:
      http_listen_port: 3100

    common:
      path_prefix: /tmp/loki
      replication_factor: 1
      storage:
        s3:
          bucketnames: ${loki_bucket_name}
          region: ${aws_region}

    schema_config:
      configs:
        - from: 2023-01-01
          store: boltdb-shipper
          object_store: s3
          schema: v13
          index:
            prefix: loki_index_
            period: 24h

    storage_config:
      aws:
        s3: s3://${loki_bucket_name}
        region: ${aws_region}
        s3forcepathstyle: true  # optional, depends on bucket
      boltdb_shipper:
        active_index_directory: /tmp/loki/index
        cache_location: /tmp/loki/cache
        shared_store: s3

    table_manager:
      retention_deletes_enabled: true
      retention_period: 24h

    limits_config:
      retention_period: 24h


  readinessProbe:
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 45
  livenessProbe:
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 45
  datasource:
    jsonData: "{}"
    uid: ""

promtail:
  enabled: true
  image:
    repository: grafana/promtail
    tag: 2.9.0
    pullPolicy: IfNotPresent

  config:
    logLevel: info
    serverPort: 3101
    clients:
      - url: http://monitoring-stack-loki:3100/loki/api/v1/push

    snippets:
      pipelineStages:
        - cri: {}     

    scrape_configs:
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names: []   # empty array = all namespaces
        relabel_configs:
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod

fluent-bit:
  enabled: false

grafana:
  enabled: true
  sidecar:
    datasources:
      label: grafana_datasource  # ""
      labelValue: "1"
      searchNamespace: monitoring
      enabled: true
      maxLines: 1000
  image:
    tag: latest

prometheus:
  enabled: true
  isDefault: true
  server:
    service:
      type: ClusterIP
      servicePort: 9090
    extraScrapeConfigs:
      - job_name: 'kubernetes-pods-all'
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names: []
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod
          - source_labels: [__meta_kubernetes_node_name]
            target_label: node

      - job_name: 'kubernetes-services-all'
        kubernetes_sd_configs:
          - role: service
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
          - source_labels: [__meta_kubernetes_service_name]
            target_label: service

      - job_name: 'kubernetes-nodes-all'
        kubernetes_sd_configs:
          - role: node
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - source_labels: [__meta_kubernetes_node_name]
            target_label: node

      - job_name: 'kubernetes-cluster-components'
        kubernetes_sd_configs:
          - role: endpoints
        relabel_configs:
          - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
            separator: ;
            regex: default;kubernetes;https
            action: keep


alertmanager:
  enabled: true
  persistence:
    enabled: false
  service:
    type: ClusterIP
    servicePort: 9093

prometheus-node-exporter:
  enabled: true
  service:
    type: ClusterIP
    port: 9100
  tolerations:
#     - key: "node-role.kubernetes.io/control-plane"
#       operator: "Exists"
#       effect: "NoSchedule"
      # optional: effect: "NoSchedule" for full control-plane nodes
    - key: "node.kubernetes.io/not-ready"
      operator: "Exists"
      effect: "NoExecute"
    - key: "node.kubernetes.io/unreachable"
      operator: "Exists"
      effect: "NoExecute"
#   nodeSelector:
#     node-role.kubernetes.io/worker: "true"

filebeat:
  enabled: false

logstash:
  enabled: false

proxy:
  http_proxy: ""
  https_proxy: ""
  no_proxy: ""
