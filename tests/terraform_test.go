package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraform(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../terraform",
	}

	terraform.Init(t, opts)

	plan := terraform.InitAndPlan(t, opts)

	if plan == "" {
		t.Fatal("Terraform plan is empty")
	}
}