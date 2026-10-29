# Remote state in S3. The bucket name is NOT written here: each person passes it
# with a backend.hcl file (see backend.hcl.example), so nobody commits account details.
#   terraform init -backend-config=backend.hcl
#
# use_lockfile = true enables S3 native state locking: if two people run
# terraform apply at the same time, the second one waits.
terraform {
  backend "s3" {
    key          = "bytelab/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
