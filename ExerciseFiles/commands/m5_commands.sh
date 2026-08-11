# Make updates to the code

# Run terraform fmt and validate to make sure you can
# run terraform console
terraform fmt && terraform validate

# Launch terraform console to test functions
terraform console

min(4,5,16)

lower("TACOCAT")

local.common_tags

exit

# Update code to use functions
# Test the merge function
merge(local.common_tags, { Name = "${local.naming_prefix}-vpc"})

# Test the lower function
merge(local.common_tags, { Name = lower("${local.naming_prefix}-vpc")})

# Update the output and run fmt and validate again
terraform fmt && terraform validate

# Now we can run the plan command to see the changes
terraform plan -out m5.tfplan

# Now apply the changes
terraform apply m5.tfplan