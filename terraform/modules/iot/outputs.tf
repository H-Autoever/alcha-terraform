output "iot_thing_name" {
  description = "IoT Thing name"
  value       = aws_iot_thing.main.name
}

output "iot_thing_arn" {
  description = "IoT Thing ARN"
  value       = aws_iot_thing.main.arn
}

output "iot_rule_name" {
  description = "IoT Rule name"
  value       = aws_iot_topic_rule.msk.name
}

output "iot_rule_arn" {
  description = "IoT Rule ARN"
  value       = aws_iot_topic_rule.msk.arn
}

output "vpc_destination_arn" {
  description = "VPC destination ARN"
  value       = aws_iot_topic_rule_destination.msk.arn
}
