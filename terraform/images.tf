resource "oci_objectstorage_bucket" "images" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "nixos-images"
  access_type    = "NoPublicAccess"
}

# --- ARM image (A1.Flex) -------------------------------------------

resource "oci_objectstorage_object" "nixos_arm" {
  bucket    = oci_objectstorage_bucket.images.name
  namespace = data.oci_objectstorage_namespace.ns.namespace
  object    = "nixos-aarch64.qcow2"
  source    = var.arm_image_path
}

resource "oci_core_image" "nixos_arm" {
  compartment_id = var.compartment_ocid
  display_name   = "NixOS aarch64"

  image_source_details {
    source_type    = "objectStorageTuple"
    namespace_name = data.oci_objectstorage_namespace.ns.namespace
    bucket_name    = oci_objectstorage_bucket.images.name
    object_name    = oci_objectstorage_object.nixos_arm.object
  }

  launch_mode = "PARAVIRTUALIZED"
  timeouts { create = "60m" }
}

resource "oci_core_shape_management" "nixos_arm_a1" {
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.nixos_arm.id
  shape_name     = "VM.Standard.A1.Flex"
}

resource "oci_core_compute_image_capability_schema" "nixos_arm" {
  compartment_id                                      = var.compartment_ocid
  image_id                                            = oci_core_image.nixos_arm.id
  compute_global_image_capability_schema_version_name = "a5bfdad8-4867-48be-85e5-5082e94bce9d"

  schema_data = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })
    "Compute.LaunchMode" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "EMULATED", "CUSTOM", "NATIVE"]
    })
    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "ISCSI", "SCSI", "IDE", "NVME"]
    })
    "Network.AttachmentType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "E1000", "VFIO", "VDPA"]
    })
  }
}

# --- x86_64 image (E2.1.Micro) -------------------------------------

resource "oci_objectstorage_object" "nixos_x86" {
  bucket    = oci_objectstorage_bucket.images.name
  namespace = data.oci_objectstorage_namespace.ns.namespace
  object    = "nixos-x86_64.qcow2"
  source    = var.x86_image_path
}

resource "oci_core_image" "nixos_x86" {
  compartment_id = var.compartment_ocid
  display_name   = "NixOS x86_64"

  image_source_details {
    source_type    = "objectStorageTuple"
    namespace_name = data.oci_objectstorage_namespace.ns.namespace
    bucket_name    = oci_objectstorage_bucket.images.name
    object_name    = oci_objectstorage_object.nixos_x86.object
  }

  launch_mode = "PARAVIRTUALIZED"
  timeouts { create = "60m" }
}

resource "oci_core_compute_image_capability_schema" "nixos_x86" {
  compartment_id                                      = var.compartment_ocid
  image_id                                            = oci_core_image.nixos_x86.id
  compute_global_image_capability_schema_version_name = "a5bfdad8-4867-48be-85e5-5082e94bce9d"

  schema_data = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })
    "Compute.LaunchMode" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "EMULATED", "CUSTOM", "NATIVE"]
    })
    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "ISCSI", "SCSI", "IDE", "NVME"]
    })
    "Network.AttachmentType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED", "E1000", "VFIO", "VDPA"]
    })
  }
}
