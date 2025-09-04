resource "aws_secretsmanager_secret" "msk_scram" {
  name        = "AmazonMSK_${var.msk_scram_username}"
  description = "SCRAM credentials for MSK cluster ${var.project_name}"
  kms_key_id  = var.kms_key_id

  tags = {
    Name    = "AmazonMSK_${var.msk_scram_username}"
    Purpose = "MSK-SCRAM-Authentication"
  }
}

resource "aws_secretsmanager_secret_version" "msk_scram" {
  secret_id = aws_secretsmanager_secret.msk_scram.id
  secret_string = jsonencode({
    username = var.msk_scram_username
    password = var.msk_scram_password
  })
}
