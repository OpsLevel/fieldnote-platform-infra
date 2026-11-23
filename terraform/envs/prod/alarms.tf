# Paging topic. The PagerDuty "Fieldnote Prod" service is subscribed to it.
resource "aws_sns_topic" "pager" {
  name = "${var.environment}-pager"
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-rds-cpu-high"
  alarm_description   = "RDS CPU above 80% for 15 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.main.identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.pager.arn]
  ok_actions          = [aws_sns_topic.pager.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.environment}-rds-free-storage-low"
  alarm_description   = "RDS free storage below 20 GiB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.main.identifier }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 21474836480
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_sns_topic.pager.arn]
  ok_actions          = [aws_sns_topic.pager.arn]
}
