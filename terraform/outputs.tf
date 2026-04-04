output "arashi_ip" {
  value = oci_core_instance.arashi.public_ip
}

output "mizore_ip" {
  value = oci_core_instance.mizore.public_ip
}

output "proxy_1_ip" {
  value = oci_core_instance.proxy_1.public_ip
}
