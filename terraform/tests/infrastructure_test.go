package test

import (
	"testing"
	"regexp"
	"strings"
	"os"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestStorageAccountProvisioned validates that the AI-generated Terraform
// for a storage account produces a correctly named, accessible resource.
func TestStorageAccountProvisioned(t *testing.T) {
	t.Parallel()

	// Only run in CI with real Azure credentials
	if os.Getenv("ARM_SUBSCRIPTION_ID") == "" {
		t.Skip("Skipping: ARM_SUBSCRIPTION_ID not set")
	}

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
	})

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// Validate outputs
	accountName := terraform.Output(t, opts, "storage_account_name")
	require.NotEmpty(t, accountName, "storage_account_name output must not be empty")

	// Azure storage account naming rules: 3-24 chars, lowercase alphanumeric only
	matched, err := regexp.MatchString(`^[a-z0-9]{3,24}$`, accountName)
	require.NoError(t, err)
	assert.True(t, matched, "Storage account name '%s' violates Azure naming rules", accountName)

	rgName := terraform.Output(t, opts, "resource_group_name")
	require.NotEmpty(t, rgName, "resource_group_name output must not be empty")
}

// TestAKSClusterProvisioned validates AKS outputs when the input spec includes AKS.
func TestAKSClusterProvisioned(t *testing.T) {
	t.Parallel()

	if os.Getenv("ARM_SUBSCRIPTION_ID") == "" {
		t.Skip("Skipping: ARM_SUBSCRIPTION_ID not set")
	}

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
		// Use aks_config.json as the variable source
		VarFiles: []string{"../../input/aks_config.json"},
	})

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	clusterName := terraform.Output(t, opts, "aks_cluster_name")
	require.NotEmpty(t, clusterName)
	assert.True(t, len(clusterName) <= 63, "AKS name exceeds 63-char Azure limit")
}

// TestTerraformOutputConsistency verifies that identical inputs produce
// identical terraform plans across multiple runs (determinism requirement).
func TestTerraformOutputConsistency(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
	}

	terraform.Init(t, opts)

	plan1 := terraform.Plan(t, opts)
	plan2 := terraform.Plan(t, opts)

	// Strip timestamps and run-specific metadata before comparing
	clean := func(s string) string {
		s = regexp.MustCompile(`\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}`).ReplaceAllString(s, "TIMESTAMP")
		return strings.TrimSpace(s)
	}

	assert.Equal(t, clean(plan1), clean(plan2),
		"Terraform plans differ between runs — output is non-deterministic")
}

// TestNamingConventions checks that all generated resource names follow
// the pattern derived from the input JSON (no random suffixes injected by AI).
func TestNamingConventions(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
	}

	terraform.Init(t, opts)
	planOutput := terraform.Plan(t, opts)

	// Verify no random suffixes (UUIDs or timestamps) were injected
	uuidPattern := regexp.MustCompile(`[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`)
	assert.False(t,
		uuidPattern.MatchString(planOutput),
		"Plan contains UUID suffixes — AI injected non-deterministic naming",
	)
}
