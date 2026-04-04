locals {
  ad = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

resource "oci_core_instance" "arashi" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.ad
  display_name        = "arashi"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.nixos_arm.id
    boot_volume_size_in_gbs = 100
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "arashi-vnic"
  }

  launch_options {
    network_type     = "PARAVIRTUALIZED"
    boot_volume_type = "PARAVIRTUALIZED"
  }

  depends_on = [
    oci_core_shape_management.nixos_arm_a1,
    oci_core_compute_image_capability_schema.nixos_arm,
  ]
}

resource "oci_core_instance" "mizore" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.ad
  display_name        = "mizore"
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.nixos_x86.id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "mizore-vnic"
  }

  launch_options {
    network_type     = "PARAVIRTUALIZED"
    boot_volume_type = "PARAVIRTUALIZED"
  }

  depends_on = [oci_core_compute_image_capability_schema.nixos_x86]
}

resource "oci_core_instance" "proxy_1" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.ad
  display_name        = "proxy-1"
  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.nixos_x86.id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "proxy1-vnic"
  }

  launch_options {
    network_type     = "PARAVIRTUALIZED"
    boot_volume_type = "PARAVIRTUALIZED"
  }

  depends_on = [oci_core_compute_image_capability_schema.nixos_x86]
}
