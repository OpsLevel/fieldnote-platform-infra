# platform-infra

Infrastructure for the Fieldnote production platform.

## What this serves

Fieldnote is a field-research notebook: teams capture notes, photos and
attachments in shared workspaces.

| Service | What it does |
|---------|--------------|
| `web` | Browser app at `app.fieldnote.io` |
| `api` | REST API at `api.fieldnote.io`. Owns workspaces, notes and file uploads, and generates **Workspace Exports** |

**Workspace Export** lets a workspace admin download a whole workspace as a PDF
report or a CSV bundle with attachments. Customers use it for audits and client
deliverables. We run about 400 exports a day, peaking at month-end.

Data lives in one Postgres instance (RDS) and one S3 bucket for customer
uploads.

## Layout

| Path | What lives there |
|------|------------------|
| `terraform/envs/prod` | AWS resources for production: VPC, EKS, RDS, S3, IAM |
| `charts/` | Helm charts for services deployed to the `prod` EKS cluster |
| `.github/workflows` | CI: `terraform fmt`/`validate` and `helm lint` |
| `Makefile` | Plan, apply and deploy targets (see [Applying](#applying)) |

## Conventions

- **Exposing a service.** Public traffic enters through the shared ALB via a
  Kubernetes `Ingress` (`ingressClassName: alb`). The AWS Load Balancer
  Controller discovers the ACM certificate from the Ingress `tls` hosts, so
  charts don't reference certificate ARNs. Services themselves are `ClusterIP`.
- **AWS access from pods.** Use EKS Pod Identity: one IAM role per service,
  bound to that service's Kubernetes service account with an
  `aws_eks_pod_identity_association` in Terraform, permissions scoped to the
  exact actions and resources the service needs. Charts never carry role ARNs.
- **Network.** Security groups allow traffic from inside the VPC or from other
  security groups, never from the internet directly.
- **S3.** Buckets are private, versioned, encrypted (SSE-KMS), and protected with
  `prevent_destroy`.
- **S3 key layout.** Customer files live under `uploads/`; generated,
  regenerable artifacts live under `exports/`.
- **Infrastructure values in charts.** Endpoints, bucket names and other values
  Terraform knows reach a chart through a `<svc>_helm_values` Terraform output,
  which `make deploy-<svc>` passes to Helm. Charts never hardcode them.
- **Alerting.** Anything on-call must act on gets a CloudWatch alarm in
  `alarms.tf` with `alarm_actions` on the `pager` SNS topic. New data stores and
  async workloads ship their paging alarm in the same PR.

Cluster add-ons (AWS Load Balancer Controller, cluster-autoscaler, external-dns,
cert-manager) are managed in the `platform-addons` repo. Nodes are replaced
regularly: cluster-autoscaler scales down idle nodes and AMI updates roll weekly.

## Applying

There is no CD pipeline. After a PR merges, the platform on-call engineer runs
these from the repo root with AWS credentials for the prod account and network
access to the cluster (Client VPN). The targets are non-interactive and only use
the standard AWS credential chain, so a CI job can run them unchanged.

1. `make plan`, then review the plan output.
2. `make apply` applies exactly the reviewed plan.
3. `make deploy`, or `make deploy-api` / `make deploy-web` for one service.

Tool versions are pinned in `.tool-versions` (mise or asdf).
