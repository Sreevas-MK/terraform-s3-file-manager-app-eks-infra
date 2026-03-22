#  GitHub Actions Workflows

This project uses GitHub Actions to automate Terraform validation, planning, deployment, and controlled destruction of the EKS infrastructure.

All workflows authenticate securely to AWS using **OIDC federation** and temporary credentials.  
No long-lived AWS access keys are stored in GitHub.

---

##  Authentication Model (OIDC)

Workflows authenticate using:

- AWS IAM Role: `GitHubActionsWorkflowRole`
- OIDC Provider: `token.actions.githubusercontent.com`
- Temporary STS credentials issued per workflow run

### Authentication Flow

1. Workflow starts on GitHub runner
2. GitHub generates an OIDC token
3. AWS validates identity via IAM Identity Provider
4. Workflow assumes `GitHubActionsWorkflowRole`
5. Terraform runs using temporary credentials

Benefits:

- No AWS access keys
- Short-lived credentials
- Repository-scoped trust policy
- Improved security posture

---

##  1. Terraform Plan (`terraform-plan.yml`)

###  Trigger

Runs automatically on:

- Push to `main`
- Pull requests targeting `main`

Ignored Paths:

- Markdown files
- Images
- `00_eks-bootstrap` directory

---

###  Purpose

This is the **Continuous Integration (CI)** workflow.

It performs validation and preview of infrastructure changes before deployment.

---

###  Workflow Steps

1. **Checkout Code**
2. **Run Gitleaks Scan**
   - Detects exposed secrets or credentials
3. **Configure AWS via OIDC**
4. **Setup Terraform CLI**
5. **Generate SSH Key**
   - Injects `SSH_PUBLIC_KEY` into runtime environment
6. **Terraform Init**
7. **Terraform Validate**
8. **Terraform Plan**
   - Shows infrastructure changes without applying

---

##  2. Terraform Apply (`terraform-apply.yml`)

###  Trigger

Manual only via:

Actions → Run Workflow

---

###  Purpose

This is the controlled deployment workflow used to apply infrastructure changes after review.

It prevents accidental deployments from every push.

---

###  Workflow Steps

1. **Checkout Repository**
2. **Configure AWS Credentials via OIDC**
3. **Setup Terraform**
4. **Generate SSH Key File**
5. **Terraform Init**
6. **Terraform Apply**
   - Executes infrastructure changes automatically

---

##  3. EKS Infrastructure Destroy (`terraform-destroy.yml`)

###  Trigger

Manual only with confirmation input.

---

###  Purpose

Safely destroys all infrastructure when required.

Used for:

- Cost cleanup
- Full environment reset
- Project teardown

---

###  Safety Mechanism

Workflow will fail unless:

```

DESTROY

```

is entered manually.

---

###  Workflow Steps

1. Validate destroy confirmation
2. Checkout repository
3. Setup Terraform
4. Configure AWS via OIDC
5. Generate SSH Key
6. Terraform Init
7. Terraform Destroy

Terraform deletes resources in dependency order:

- Helm resources
- Kubernetes resources
- EKS cluster
- Networking
- Supporting AWS infrastructure

---

##  Required GitHub Secrets & Variables

Configure under:

Settings → Secrets and Variables → Actions

---

###  Secrets

| Name | Description |
| --- | --- |
| `SSH_PUBLIC_KEY` | Public SSH key used for Bastion and node access |

---

###  Variables

| Name | Description |
| --- | --- |
| `AWS_REGION` | AWS deployment region (example: `ap-south-1`) |
| `AWS_ACCOUNT_ID` | AWS Account ID used in role assumption |

---

##  Important Security Notes

- No AWS access keys are used
- All authentication uses OIDC federation
- IAM trust policy restricts repository access
- Credentials are temporary per workflow run
- Gitleaks scanning prevents secret leaks

---

##  Operational Dependencies

Before workflows can run successfully:

1. Bootstrap module must be applied locally:

```

00_eks-bootstrap/

```

This creates:

- Terraform state S3 bucket
- DynamoDB lock table
- GitHub OIDC provider
- GitHub Actions IAM role

---

##  State Locking

Terraform uses:

- S3 backend for state storage
- DynamoDB for state locking

This prevents:

- Concurrent applies
- State corruption
- Race conditions between workflows

---

##  Manual Destroy Procedure

1. Open repository → Actions tab
2. Select:

```

EKS Infrastructure Destroy (MANUAL ONLY)

```

3. Click Run Workflow
4. Enter:

```

DESTROY

```

5. Confirm execution

---

##  Operational Warning

Destroying infrastructure will:

- Remove EKS cluster
- Delete VPC and networking
- Remove databases and caches
- Destroy Kubernetes workloads

Only execute destroy when full teardown is intended.

---

