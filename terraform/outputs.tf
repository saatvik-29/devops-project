output "instance_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.chess_eip.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.chess_app.id
}

output "instance_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.chess_app.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.chess_sg.id
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "http://${aws_eip.chess_eip.public_ip}:5173"
}

output "backend_websocket_url" {
  description = "Backend WebSocket URL"
  value       = "ws://${aws_eip.chess_eip.public_ip}:8181"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.chess_vpc.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.chess_public_subnet.id
}