To generate Terraform files from YAML, we need to understand the structure of the input. However, since you've provided a command that reads a JSON file, and you're looking for Terraform files (main.tf, variables.tf, outputs.tf), we can utilize that JSON structure instead. 

I will create an example based on typical infrastructure components. Here’s how you might convert a given infrastructure described in JSON into Terraform files.

### Example JSON (input/infra.json)
This is a sample input structure you could have in your JSON:

```json
{
  "provider": {
    "aws": {
      "region": "us-east-1"
    }
  },
  "resource": {
    "aws_instance": {
      "web": {
        "ami": "ami-0c55b159cbfafe1f0",
        "instance_type": "t2.micro",
        "tags": {
          "Name": "terraform-instance"
        }
      }
    }
  },
  "output": {
    "instance_ip": {
      "value": "${aws_instance.web.public_ip}"
    }
  }
}
```

### Generate Terraform Files

Below are the Terraform files based on the above structure.

**main.tf**

```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}

output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

**variables.tf**

```hcl
variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

variable "ami" {
  description = "The AMI to use for the instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" 
}

variable "instance_type" {
  description = "The type of instance to create"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "The name of the instance"
  type        = string
  default     = "terraform-instance"
}
```

**outputs.tf**

```hcl
output "instance_ip" {
  description = "The public IP of the web instance"
  value       = aws_instance.web.public_ip
}
```

### Explanation
1. **main.tf**: Contains the main configuration for the AWS provider, the resource declaration for an EC2 instance, and an output for the public IP.
2. **variables.tf**: Manages the variables used in `main.tf` for better flexibility and management.
3. **outputs.tf**: Defines outputs that Terraform will display after applying the configuration.

Make sure to adapt the variable defaults, tags, and any specifics according to your infrastructure requirements. You can generate these files with a simple command or script in your environment.
