# platform-infra

Infrastructure for the Fieldnote production platform.

| Path | What lives there |
|------|------------------|
| `terraform/envs/prod` | AWS resources for production: VPC, EKS, RDS, S3, IAM |
| `charts/` | Helm charts for services deployed to the `prod` EKS cluster |
| `.github/workflows` | CI: `terraform fmt`/`validate` and `helm lint` |

## Conventions

- **Exposing a service.** Public traffic enters through the shared ALB via a
  Kubernetes `Ingress` (`ingressClassName: alb`, TLS terminated with the
  `*.fieldnote.io` ACM cert). Services themselves are `ClusterIP`.
- **AWS access from pods.** Use IRSA: one IAM role per service, trust scoped to
  that service's Kubernetes service account, permissions scoped to the exact
  actions and resources the service needs.
- **Network.** Security groups allow traffic from inside the VPC or from other
  security groups, never from the internet directly.
- **S3.** Buckets are private, versioned, encrypted (SSE-KMS), and protected with
  `prevent_destroy`.

Cluster add-ons (AWS Load Balancer Controller, external-dns, cert-manager) are
managed in the `platform-addons` repo.

## Applying

Terraform is applied by the platform team from `terraform/envs/prod` after the
PR merges. Helm releases are deployed by Argo CD from `main`.
