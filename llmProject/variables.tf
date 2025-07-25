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

variable "ssh_source_ranges" {
  description = "A list of IP address or ranges allowed to SSH. Default: [\"0.0.0.0/0\"]"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_username" {
  description = "Username to SSH into the instance"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your local public SSH key file"
  type        = string
}

variable "repo_name" {
  description = "Artifact Registry repository name"
  type        = string
}

variable "image_name" {
  description = "Docker image name"
  type        = string
}

variable "discord_webhook" {
  description = "The discord webhook to send logging to"
  type = string
  default = ""
}
