# Work around a limitation in TF, keep it an ordered list of
# regions indexed at 0, must match what is being built as an
# Artifact. WARNING: brittleness!
variable "atlas_region_map" {
  default = {
    "us-east-1" = 0
    "us-west-2" = 1
  }
}

resource "atlas_artifact" "jumphost" {
  name = "nubisproject/nubis-jumphost"
  type = "amazon.image"
  version = "any"
  metadata = {
    project_version = "0.73"
    #nubis_version = "${var.stacks_version}" #XXX: Metadata not there yet
  }
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_cloudformation_stack" "jumphost" {
  #count = "${length(split(",",var.environments))}"
  # Should work, but doesn't
  count = "${var.environments_cnt}"

  name = "nubis-jumphost-${element(split(",",var.environments), count.index)}"
  capabilities = [ "CAPABILITY_IAM" ]
  template_body = "${file("${path.module}/../cloudformation/main.json")}"
  on_failure = "DELETE"
  
  parameters = {
    Environment = "${element(split(",",var.environments), count.index)}"
    ServiceName = "jumphost"
    SSHKeyName = "${var.ssh_key_name}"
    TechnicalOwner = "${var.technical_owner}"
    StacksVersion = "${var.stacks_version}"
    AmiId = "${element(split(":", element(split(",", atlas_artifact.jumphost.id), lookup(var.atlas_region_map, var.aws_region))), 1)}"
  }
}
