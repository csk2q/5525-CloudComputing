variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region for the subnet"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone for compute"
  type        = string
  default     = "us-central1-c"
}

variable "ssh_source_range" {
  description = "IP range allowed to SSH (e.g., your IP or 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_username" {
  description = "Username to SSH into the instance"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your local public SSH key file"
  type        = string
}

