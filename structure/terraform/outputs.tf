## Output values

output "instance_group_masters_public_ips" {
  description = "Public IP addresses for master-nodes"
  value       = yandex_compute_instance_group.k8s-masters.instances.*.network_interface.0.nat_ip_address
}

output "instance_group_workers_public_ips" {
  description = "Public IP addresses for worder-nodes"
  value       = yandex_compute_instance_group.k8s-workers.instances.*.network_interface.0.nat_ip_address
}

output "instance_group_haproxy_public_ips" {
  description = "Public IP addresses for haproxy-nodes"
  value       = yandex_compute_instance_group.k8s-haproxy.instances.*.network_interface.0.nat_ip_address
}