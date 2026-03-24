To generate the Terraform files `main.tf`, `variables.tf`, and `outputs.tf` from a JSON input, we can convert the JSON into the corresponding Terraform configurations. However, it looks like your initial command seems to have some issues, particularly with `sed` not being properly formatted.

Instead, let's assume you're starting from a well-defined JSON input structure and we will manually create the Terraform files based on assumed content from that JSON. For this example, I'll create a sample JSON structure that represents some AWS infrastructure (e.g., an EC2 instance and a security group).

Here’s how you might structure your JSON (`infra.json`):

```json
{
  "region": "us-west-2",
  "instance_type": "t2.micro",
  "ami": "ami-0c55b159cbfafe1f0",
  "security_group": {
    "name": "web_server_sg",
    "description": "Security group for web server",
    "ingress": [
      {
        "from_port": 80,
        "to_port": 80,
        "protocol": "tcp",
        "cidr_blocks": ["0.0.0.0/0"]
      }
    ]
  }
}
```

Based on this JSON input, we can create the Terraform files as follows:

### main.tf

```hcl
provider "aws" {
  region = var.region
}

resource "aws_security_group" "web_server_sg" {
  name        = var.security_group.name
  description = var.security_group.description

  ingress {
    from_port   = var.security_group.ingress[0].from_port
    to_port     = var.security_group.ingress[0].to_port
    protocol    = var.security_group.ingress[0].protocol
    cidr_blocks  = var.security_group.ingress[0].cidr_blocks
  }
}

resource "aws_instance" "web_server" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = [aws_security_group.web_server_sg.name]
}
```

### variables.tf

```hcl
variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "instance_type" {
  description = "The type of the EC2 instance"
  type        = string
}

variable "ami" {
  description = "The AMI to use for the EC2 instance"
  type        = string
}

variable "security_group" {
  description = "The security group configuration"
  type = object({
    name        = string
    description = string
    ingress     = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks  = list(string)
    }))
  })
}
```

### outputs.tf

```hcl
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.web_server_sg.id
}
```

### Note
1. Modify the JSON content to fit your actual use case, and ensure that the data types in the `variables.tf` match your JSON structure.
2. This is a simple example and does not include error handling, valid configurations, or Terraform best practices.
3. You should run `terraform init` and `terraform plan` to validate that your Terraform configurations work as intended before applying them.
