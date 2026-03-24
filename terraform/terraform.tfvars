```hcl
resource_group = "aj-rg"
location       = "eastus"
storage = {
  name = "ajstorageacct"
}
```

### Explanation:
1. **Provider**: The Azure provider is defined with necessary features.
2. **Resource Group**: A resource group is created using the name and location provided in the input JSON.
3. **Storage Account**: A storage account is created within the resource group. The name is dynamically pulled from the input JSON.
4. **Variables**: The `variables.tf` file includes definitions for the resource group, location, and storage account, allowing for dynamic input.
5. **Outputs**: Outputs provide the storage account ID and its primary blob endpoint, which can be useful for other infrastructure or for outputs to the user.
6. **Terraform Variables File**: The `terraform.tfvars` file contains the actual values that will be utilized when running Terraform, corresponding directly to the input JSON.

Everything is structured according to best practices, ensuring that it is clear, maintainable, and production-ready.
