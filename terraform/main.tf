To create Terraform files from a YAML input as described, I'll need to assume a general structure for the JSON since I don't have the actual content of `input/infra.json`. Below are the example contents for `main.tf`, `variables.tf`, and `outputs.tf` based on a hypothetical infrastructure setup described in YAML format.

### Hypothetical Example JSON Structure
Let's assume the JSON looks like this:

```json
{
  "name": "my_vpc",
  "region": "us-west-1",
  "cidr_block": "10.0.0.0/16",
  "subnets": [
    {
      "name": "public_subnet",
      "cidr_block": "10.0.1.0/24",
      "availability_zone": "us-west-1a"
    },
    {
      "name": "private_subnet",
      "cidr_block": "10.0.2.0/24",
      "availability_zone": "us-west-1b"
    }
  ]
}
```

### Terraform Files

#### `main.tf`
```hcl
provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.subnets)
  vpc_id                 = aws_vpc.main.id
  cidr_block             = var.subnets[count.index].cidr_block
  availability_zone      = var.subnets[count.index].availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnets[count.index].name
  }
}
```

#### `variables.tf`
```hcl
variable "name" {
  description = "The name of the VPC"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy in"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "subnets" {
  description = "A list of subnets to create"
  type = list(object({
    name               = string
    cidr_block         = string
    availability_zone  = string
  }))
}
```

#### `outputs.tf`
```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "The IDs of the created subnets"
  value       = aws_subnet.public[*].id
}
```

### Explanation:
1. **`main.tf`**: Defines the AWS provider, creates a VPC, and the subnets according to the given configuration.
2. **`variables.tf`**: Declares variables to be used in the Terraform configuration. It captures the VPC configuration and subnet details.
3. **`outputs.tf`**: Specifies outputs for the VPC ID and subnet IDs for easy access after deployment.

### Conclusion
You can modify the above Terraform configurations to adapt to your specific infrastructure requirements. If you have the actual content of `input/infra.json`, I can help refine these Terraform files further!
