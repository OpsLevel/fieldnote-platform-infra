resource "aws_security_group" "jobs" {
  name        = "${var.environment}-jobs"
  description = "Valkey job queue"
  vpc_id      = module.vpc.vpc_id
}

# Allow Valkey clients from inside the VPC.
resource "aws_vpc_security_group_ingress_rule" "jobs" {
  security_group_id = aws_security_group.jobs.id
  description       = "Valkey from VPC"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 6379
  to_port           = 6379
  ip_protocol       = "tcp"
}

resource "aws_elasticache_subnet_group" "jobs" {
  name       = "${var.environment}-jobs"
  subnet_ids = module.vpc.database_subnets
}

resource "aws_elasticache_replication_group" "jobs" {
  replication_group_id = "${var.environment}-jobs"
  description          = "Background job queue"
  engine               = "valkey"
  engine_version       = "8.1"
  node_type            = "cache.t4g.small"
  port                 = 6379

  num_cache_clusters         = 1
  automatic_failover_enabled = false

  subnet_group_name  = aws_elasticache_subnet_group.jobs.name
  security_group_ids = [aws_security_group.jobs.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}
