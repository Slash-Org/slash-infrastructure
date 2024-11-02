output "fashion_assistant_security_group_id" {
  value = aws_security_group.fashion_assistant.id
}

output "instance_ami" {
  value = aws_instance.fashion_assistant.ami
}

output "instance_arn" {
  value = aws_instance.fashion_assistant.arn
}

output "instance_public_ip" {
  value = aws_instance.fashion_assistant.public_ip
}

