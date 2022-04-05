output "natip" {
  value = google_compute_address.example.*.address
}

output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "ssh_public_key" {
  value     = tls_private_key.ssh.public_key_openssh
  sensitive = true
}
