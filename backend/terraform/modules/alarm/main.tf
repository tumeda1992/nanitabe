variable "stage" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "notification_email" {
  type      = string
  sensitive = true
}

module "values" {
  source = "../../values"
}

locals {
  topic_name = "${module.values.appname}_${var.stage}_alarm"
}

resource "aws_sns_topic" "alarm" {
  name = local.topic_name
}

data "aws_iam_policy_document" "topic_policy" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.alarm.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "alarm" {
  arn    = aws_sns_topic.alarm.arn
  policy = data.aws_iam_policy_document.topic_policy.json
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "task_running_too_long" {
  alarm_name          = "${module.values.appname}_${var.stage}_task_running_too_long"
  alarm_description   = "review backend task が停止し忘れている可能性がある（45分連続でdata pointが存在）"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "SampleCount"
  period              = 300
  evaluation_periods  = 9
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
}

output "topic_arn" { value = aws_sns_topic.alarm.arn }
output "subscription_arn" { value = aws_sns_topic_subscription.email.arn }
