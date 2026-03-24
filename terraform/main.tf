To generate Terraform files from a YAML definition, we'll need to first convert the provided JSON content into the appropriate Terraform configuration files. However, since I can't directly view or parse the input you provided via a command, I'll show you an example of how to structure `main.tf`, `variables.tf`, and `outputs.tf` based on a common infrastructure configuration.

Assuming you provided a basic configuration that describes a single AWS EC2 instance, here’s how you might structure those Terraform files.

### Input JSON (example)
For illustration purposes, let's assume your input JSON represents a simple infrastructure to create an AWS EC2 instance:

```json
{
  "aws_instance": {
    "example": {
      "ami": "ami-0c55b159cbfafe1fe",
      "instance_type": "t2.micro",
      "tags": {
        "Name": "example-instance"
      }
    }
  }
}
```

### main.tf
This file will contain the main infrastructure resource definitions.

```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
```

### variables.tf
This file will define the variables used in `main.tf`.

```hcl
variable "aws_region" {
  description = "The AWS region to deploy the instance"
  type        = string
  default     = "us-east-1"
}

variable "ami" {
  description = "The AMI to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The type of instance"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Name of the instance"
  type        = string
  default     = "example-instance"
}
```

### outputs.tf
This file will define the outputs from your infrastructure.

```hcl
output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.example.id
}

output "public_ip" {
  description = "The public IP of the created EC2 instance"
  value       = aws_instance.example.public_ip
}
```

### Steps to Create Terraform Files
1. Create a new directory for your Terraform configuration.
2. Inside the directory, create three files named `main.tf`, `variables.tf`, and `outputs.tf`.
3. Copy the corresponding code blocks provided above into each of those files.
4. Modify the code as necessary to fit your specific infrastructure needs.

### Running Terraform
To deploy your infrastructure, run the following commands:

```bash
terraform init    # Initialize your Terraform configuration
terraform plan    # Review the plan for deployment
terraform apply   # Apply the changes to create resources
```

This structure will properly set up a simple AWS EC2 instance based on user-defined variables. Adjust the resource configuration based on your actual requirements and the specific details contained in `infra.json`. If your YAML input represents something different, please specify, and I can tailor the examples accordingly!
