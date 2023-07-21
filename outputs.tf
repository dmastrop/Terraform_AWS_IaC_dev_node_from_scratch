# https://developer.hashicorp.com/terraform/language/values/outputs
output "dev_ip" {
    value = aws_instance.dev_node.public_ip
}