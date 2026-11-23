resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds"
  description = "Postgres access from EKS nodes"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Postgres from EKS nodes"
  referenced_security_group_id = module.eks.node_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-main"
  engine         = "postgres"
  engine_version = "18.6"
  instance_class = "db.r8g.large"

  allocated_storage     = 200
  max_allocated_storage = 1000
  storage_encrypted     = true

  db_name                     = "fieldnote"
  username                    = "fieldnote_admin"
  manage_master_user_password = true

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                  = true
  backup_retention_period   = 14
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.environment}-main-final"
}
