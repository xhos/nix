variable "region" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "arm_image_path" {
  type    = string
  default = "../nixos-image-oci-26.05.20260223.2fc6539-aarch64-linux.qcow2"
}

variable "x86_image_path" {
  type    = string
  default = "../nixos-image-oci-26.05.20260223.2fc6539-x86_64-linux.qcow2"
}
