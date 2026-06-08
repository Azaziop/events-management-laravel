# Infrastructure as Code — Terraform (AWS + ECS)

Automatisation de l'infrastructure cloud pour **Event Management** (Laravel + Docker + PostgreSQL + **ECS Fargate**).

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  VPC 10.0.0.0/16                                        │
│                                                         │
│  Subnets publics                                        │
│    ├── ALB (HTTP:80)                                    │
│    ├── ECS Fargate (nginx + backend PHP-FPM)              │
│    └── EFS (storage Laravel persistant)                 │
│                                                         │
│  Subnets privés                                         │
│    └── RDS PostgreSQL 16                                │
└─────────────────────────────────────────────────────────┘
```

| Composant | Ressource Terraform |
|-----------|---------------------|
| Réseau | VPC, subnets publics/privés, IGW |
| Load balancing | ALB + target group + listener |
| Compute | ECS Fargate cluster, task definition, service |
| Stockage | EFS pour `storage/` Laravel |
| Base de données | RDS PostgreSQL 16 |
| Logs | CloudWatch `/ecs/event-management` |

L'image `azaziop/event-management1` est construite par Jenkins (ARM64) et déployée sur ECS Fargate ARM64.

## Prérequis

- Terraform >= 1.5
- AWS CLI configuré (`aws configure`, région `eu-west-3`)
- Droits IAM : ECS, ECR/Docker Hub pull, ALB, RDS, VPC, EFS, IAM, CloudWatch

### Installation Terraform (macOS)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Déploiement initial

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Éditez : app_key, db_password, docker_image_tag
terraform init
terraform plan
terraform apply
```

Après l'apply :

```bash
terraform output application_url
# ex. http://event-management-alb-123456789.eu-west-3.elb.amazonaws.com
```

Le premier démarrage ECS peut prendre **2–5 minutes** (pull image, migrations, health checks).

## Migration depuis EC2

Si vous aviez l'ancienne stack EC2 :

```bash
terraform apply   # détruit EC2/EIP, crée ECS + ALB
```

L'IP Elastic IP est remplacée par le **DNS de l'ALB**.

### Apply bloqué sur `aws_security_group.web` ?

L'ancien SG EC2 ne peut pas être supprimé tant que le SG RDS y fait référence.

```bash
# 1. Annulez l'apply bloqué (Ctrl+C)
# 2. Retirez le SG web du state (sans le supprimer dans AWS pour l'instant)
terraform state rm aws_security_group.web

# 3. Apply ciblé : met à jour le SG RDS puis crée ECS/ALB
terraform apply \
  -target=aws_security_group.alb \
  -target=aws_security_group.ecs_tasks \
  -target=aws_vpc_security_group_ingress_rule.db_from_ecs \
  -target=aws_security_group.efs \
  -target=aws_efs_mount_target.storage \
  -target=aws_lb.main \
  -target=aws_lb_listener.http \
  -target=aws_ecs_task_definition.app \
  -target=aws_ecs_service.app

# 4. Apply complet (finalise le reste)
terraform apply

# 5. Supprimez l'ancien SG web orphelin (si encore présent)
aws ec2 delete-security-group --group-id sg-05e3ab2b2eec2758e --region eu-west-3
```

## CI/CD Jenkins → ECS

Le pipeline Jenkins pousse l'image sur Docker Hub puis déploie sur ECS via `scripts/ecs-deploy.sh`.

### Credentials Jenkins requis

| ID | Type | Usage |
|----|------|-------|
| `dockerhub-credentials` | Username/Password | Push image |
| `aws-credentials` | Username/Password (username = Access Key ID, password = Secret Access Key) | Déploiement ECS |

### IAM pour Jenkins (utilisateur ou rôle)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource": "*"
    }
  ]
}
```

### Déploiement manuel

```bash
export IMAGE_NAME=azaziop/event-management1
export IMAGE_TAG=16-68b4bdb
export ECS_CLUSTER=event-management-cluster
export ECS_SERVICE=event-management-service
export AWS_REGION=eu-west-3
./scripts/ecs-deploy.sh
```

## Variables importantes

| Variable | Description |
|----------|-------------|
| `app_key` | Clé Laravel |
| `db_password` | Mot de passe RDS |
| `docker_image_tag` | Tag Jenkins pour le 1er déploiement Terraform |
| `ecs_task_cpu` / `ecs_task_memory` | Taille Fargate (défaut 512/1024) |
| `app_url` | `http://localhost` = DNS ALB automatique |

## Destruction

```bash
terraform destroy
```

## Coût estimé

- ECS Fargate 0.5 vCPU / 1 Go + ALB + RDS `db.t4g.micro` + EFS ≈ 40–60 €/mois
- Pensez à `terraform destroy` après les tests du cours
