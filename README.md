# S3 Node App — EKS Infrastructure

Production-grade AWS infrastructure for a Node.js S3 file-manager application, deployed on Amazon EKS. Fully automated from a one-time bootstrap through GitHub Actions CI/CD, GitOps delivery via ArgoCD, and observability via the Grafana/Loki stack — all sitting behind a CloudFront CDN with WAF protection.

---

## Architecture overview

```
Internet users
      │  HTTPS
      ▼
Route 53  ──────────────────────────────────────────────────────────────────────────────────────────────────
      │  Alias A records (app / grafana / argocd)
      ▼
CloudFront distribution  ←── WAFv2 (rate-limit 1 000 req/5 min + AWS Managed Common Rules)
      │  HTTPS-only origin  ←── ACM cert *.sreevasmk.online (us-east-1)
      ▼
┌─────────────────────── VPC 10.0.0.0/16 ────────────────────────────────────┐
│  Public subnets                                                              │
│    Shared ALB (eks-shared-alb)          OpenVPN-AS (t2.micro, admin access) │
│    NAT Gateway                                                               │
│                                                                              │
│  Private subnets                                                             │
│  ┌─────────────── EKS cluster (k8s 1.33) ──────────────────────────────┐   │
│  │  Managed node group  t3.medium · AL2023 · gp3 20 GB                 │   │
│  │  Add-ons: CoreDNS · kube-proxy · vpc-cni · EBS CSI · metrics-server │   │
│  │  AWS Load Balancer Controller (IRSA)                                 │   │
│  │                                                                      │   │
│  │  ns: s3-nodejs-app    Node.js app pod (IRSA → S3 app bucket)        │   │
│  │  ns: argocd           ArgoCD server (GitOps, Helm)                  │   │
│  │  ns: monitoring       Grafana · Loki (IRSA → S3 logs) · Promtail    │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

Supporting services
  S3: app bucket (versioned) · Loki log store · Terraform state · CloudFront logs
  DynamoDB: Terraform state lock table
  GitHub Actions: OIDC → IAM role → Terraform CI/CD
  ACM (ap-south-1): *.sreevasmk.online for ALB
```

---

## Repository layout

```
s3-node-app-project-eks/
├── 00_eks-bootstrap/          # One-time bootstrap (run locally first)
│   ├── 01_variables.tf        # Project vars, bucket/table names, DockerHub, GitHub
│   ├── 02_provider.tf         # AWS + GitHub providers
│   ├── 03_datasource.tf       # TLS cert for OIDC thumbprint
│   ├── 04_dynamodb.tf         # Terraform state lock table
│   ├── 05_s3-bucket.tf        # Terraform remote-state S3 bucket
│   ├── 06_github_iam_policy.tf
│   ├── 07_github_iam_role.tf  # GitHub Actions IAM role (OIDC)
│   ├── 08_github_oidc.tf      # OIDC provider for token.actions.githubusercontent.com
│   └── 09_githubactions_setup.tf  # Inject secrets/vars into GitHub repos
│
├── 01_s3_backend.tf           # S3 remote state config
├── 02_provider.tf             # AWS + Kubernetes + Helm + kubectl providers
├── 03_variables.tf            # All project variables
├── 04_datasource.tf           # ACM cert, Route 53 zone, GitHub OIDC, CloudFront PL, OVPN AMI
├── 05_vpc.tf                  # VPC module (3 public + 3 private subnets, single NAT GW)
├── 06_vpc_outputs.tf
├── 07_key_pair.tf             # EC2 SSH key pair
├── 08_eks.tf                  # EKS cluster + node group + add-ons + IRSA modules + storage class
├── 09_eks_outputs.tf
├── 10_ovpn_security_group.tf  # OpenVPN security group
├── 11_ovpn_server_setup.tf    # OpenVPN-AS EC2 instance (community module)
├── 12_ovpn_user_access.tf     # OVPN IAM role + EKS access entry (ClusterAdmin)
├── 13_monitoring_s3.tf        # Loki S3 bucket + IRSA
├── 14_monitoring_helm.tf      # loki-stack Helm release (Grafana + Loki + Promtail)
├── 15_grafana_ingress.tf      # Grafana ALB ingress
├── 16_argocd.tf               # ArgoCD Helm release
├── 17_argocd_application.tf   # ArgoCD Application CRD (points at Helm chart repo)
├── 18_app_s3bucket.tf         # App S3 bucket + IAM policy + IRSA + Kubernetes SA
├── 19_argocd_ingress.tf       # ArgoCD ALB ingress (HTTPS backend)
├── 20_alb_sg.tf               # Shared ALB security group
├── 21_cleanup_sync.tf         # null_resource destroy-time hook (removes ingress finalizers)
│
├── cloudfront/                # Separate Terraform root — deployed after main infra
│   ├── 01_s3_backend.tf       # Own remote state key
│   ├── 02_variables.tf
│   ├── 03_provider.tf         # aws + aws.us_east_1 alias
│   ├── 04_datasource.tf       # Reads eks-shared-alb DNS name
│   ├── 05_acm_certificate_cdn.tf  # ACM cert in us-east-1 + Route 53 validation
│   ├── 06_cloudfront_distribution.tf  # CDN + WAFv2 Web ACL
│   ├── 07_cloudfront_logs.tf  # Log bucket (1-day lifecycle, log-delivery-write ACL)
│   ├── 08_route_53.tf         # Alias A records for app / grafana / argocd
│   └── 09_output.tf
│
└── files/
    ├── values-s3.yaml.tpl     # Loki Helm values (S3 backend, IRSA annotations)
    ├── monitoring-configmap.yml   # Grafana datasource ConfigMap
    └── s3app-eks-key.pub      # EC2 SSH public key
```

---

## Prerequisites

| Tool | Minimum version |
|---|---|
| Terraform | 1.5.0 |
| AWS CLI | v2 |
| kubectl | 1.33 |
| Helm | 3.x |
| GitHub CLI (optional) | 2.x |

You need an AWS account with administrator access, a Route 53 hosted zone for your domain, a GitHub personal access token (repo scope), and DockerHub credentials.

---

## Deployment steps

### 1. Bootstrap (once)

This step creates the S3 state bucket, DynamoDB lock table, GitHub OIDC provider, and injects the required secrets/variables into your GitHub repositories.

```bash
cd 00_eks-bootstrap
terraform init
terraform apply \
  -var="ssh_public_key=$(cat ../files/s3app-eks-key.pub)" \
  -var="github_token=<your-PAT>" \
  -var="dockerhub_username=<user>" \
  -var="dockerhub_password=<password>"
```

### 2. Main infrastructure

```bash
cd ..           # back to project root
terraform init
terraform plan
terraform apply
```

This creates the VPC, EKS cluster, node group, OpenVPN server, monitoring stack, ArgoCD, the app S3 bucket, and all ingresses. Expect ~15–20 minutes.

After apply, update your kubeconfig:

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name s3-nodejs-app-cluster
```

### 3. CloudFront + WAF

This step reads the ALB DNS name from AWS and provisions the CloudFront distribution in front of it. It must run after step 2 because the ALB is created there.

```bash
cd cloudfront
terraform init
terraform apply
```

### 4. ArgoCD initial login

```bash
# Retrieve the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Open https://argocd.sreevasmk.online
```

ArgoCD will automatically sync the `s3-nodejs-app` Application from the Helm chart repo and deploy the Node.js application.

---

## GitHub Actions CI/CD

The bootstrap step provisions a `GitHubActionsWorkflowRole` IAM role that GitHub Actions assumes via OIDC (no long-lived credentials). Your Terraform workflow in the infra repo needs:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsWorkflowRole
      aws-region: ap-south-1
```

The role is scoped to `repo:Sreevas-MK/terraform-s3-file-manager-app-eks-infra:*`.

---

## Accessing services

| Service | URL |
|---|---|
| Application | https://s3app.sreevasmk.online |
| Grafana | https://grafana.sreevasmk.online |
| ArgoCD | https://argocd.sreevasmk.online |

All traffic flows through CloudFront → WAF → ALB → EKS pods. Direct ALB access is not blocked but all DNS points through CloudFront.

### Admin access via OpenVPN

SSH and kubectl access to EKS worker nodes is available only through the OpenVPN-AS instance. Connect to the VPN first, then use kubectl normally. The OVPN IAM role has `AmazonEKSClusterAdminPolicy` attached via an EKS access entry.

```bash
# After VPN connection
kubectl get nodes
```

---

## Key design decisions

**Shared ALB with group name.** All three ingresses (app, Grafana, ArgoCD) share a single ALB (`eks-alb` group name) to minimise cost and simplify security group management.

**IRSA everywhere.** The Node.js app, Loki, and the AWS Load Balancer Controller all use IAM Roles for Service Accounts. No node-level IAM permissions are required.

**ArgoCD backend protocol HTTPS.** The ArgoCD ingress annotation `alb.ingress.kubernetes.io/backend-protocol: HTTPS` is required because the ArgoCD server only listens on TLS. The ingress points to port 443 on the `argocd-server` service.

**CloudFront in a separate Terraform root.** CloudFront must reference the ALB DNS name, which is only known after EKS and the Load Balancer Controller have created the ALB. Keeping it in a separate root with its own state avoids circular dependencies and makes it easy to redeploy or tear down the CDN layer independently.

**WAF rate limit.** WAFv2 blocks any IP exceeding 1 000 requests per 5-minute window. The AWS Managed Common Rule Set runs in count mode (for visibility) rather than block mode — promote to block once you have confirmed no false positives in CloudWatch.

**Destroy-time cleanup.** `21_cleanup_sync.tf` patches ingress finalizers to empty arrays before Terraform destroys the ALB, preventing the common deadlock where the ALB controller hangs waiting for Kubernetes finalizers that will never fire.

---

## Observability

Loki receives logs from Promtail (running as a DaemonSet on every node) and stores them in the dedicated S3 bucket with IRSA authentication. Grafana is pre-configured with a Loki datasource via the `monitoring-configmap.yml` ConfigMap.

Log retention is managed at the S3 level — add a lifecycle rule to `<project>-loki-logs` if you need automatic expiry.

---

## Teardown

```bash
# 1. Destroy CloudFront first (removes DNS and CDN)
cd cloudfront && terraform destroy

# 2. Destroy main infra (cleanup hook removes ingress finalizers automatically)
cd .. && terraform destroy
```

Do not destroy the bootstrap stack unless you intend to remove the Terraform state bucket, DynamoDB table, and GitHub OIDC provider permanently.

---

## Variable reference

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `ap-south-1` | AWS region for all resources |
| `project_name` | `s3-nodejs-app` | Used as a prefix for resource names |
| `vpc_cidr_block` | `10.0.0.0/16` | VPC CIDR |
| `app_bucket_name` | `sreevas-s3-node-app-2026` | S3 bucket for the application |
| `eks_node_instance_type` | `t3.medium` | EKS worker node instance type |
| `eks_node_disk_size` | `20` | Worker node root volume size (GB) |
| `domain_name` | `sreevasmk.online` | Root domain (must have a Route 53 hosted zone) |
| `app_host` | `s3app.sreevasmk.online` | Application hostname |
| `grafana_url` | `grafana.sreevasmk.online` | Grafana hostname |
| `argocd_url` | `argocd.sreevasmk.online` | ArgoCD hostname |
| `certificate_id` | — | UUID of the ACM cert in ap-south-1 |
| `alb_group_name` | `eks-alb` | ALB ingress group (shared across all ingresses) |
| `my_ip_cidr` | `103.153.105.0/24` | CIDR allowed for SSH and VPN web UI |
| `app_repo_url` | — | Helm chart repo URL watched by ArgoCD |
| `app_namespace` | `s3-nodejs-app` | Kubernetes namespace for the application |

---

## Related repositories

- **Application code + Dockerfile**: `github.com/Sreevas-MK/s3node-app-with-versioning`
- **Helm chart**: `github.com/Sreevas-MK/s3node-app-eks-helm`
- **This infra repo**: `github.com/Sreevas-MK/terraform-s3-file-manager-app-eks-infra`
