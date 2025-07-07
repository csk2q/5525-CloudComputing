output "vpc_name" {
  value = google_compute_network.llm_vpc_net.name
}

output "subnet_name" {
  value = google_compute_subnetwork.llm_subnet.name
}

output "firewall_rules" {
  value = [
    google_compute_firewall.allow_ssh.name,
    google_compute_firewall.allow_http_https.name,
    google_compute_firewall.allow_internal.name
  ]
}

output "llm_vm_public_ip" {
  description = "Public IP address of the llm-vm instance"
  value       = google_compute_instance.llm_vm.network_interface[0].access_config[0].nat_ip
}

output "llm_vm_internal_ip" {
  description = "Internal IP address of the llm-vm instance"
  value       = google_compute_instance.llm_vm.network_interface[0].network_ip
}

output "llm_vm_internal_dns" {
  description = "Internal DNS hostname of the llm-vm instance"
  value       = google_compute_instance.llm_vm.instance_id != "" ? "${google_compute_instance.llm_vm.name}.c.${var.project_id}.internal" : null
}

output "startup_script" {
  description = "The startup script used for the VM"
  sensitive = true
  value = data.template_file.startup_script
}


