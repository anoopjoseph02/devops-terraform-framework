#!/bin/bash

echo "⚠️ Error detected. Attempting AI fix..."

ERROR=$(terraform plan 2>&1)

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gpt-4o-mini\",
    \"messages\": [{
      \"role\": \"user\",
      \"content\": \"Fix this Terraform error:\\n$ERROR\"
    }]
  }")

echo "$RESPONSE" | jq -r '.choices[0].message.content' > terraform/main.tf

git add .
git commit -m "Auto fix Terraform error"
git push