# Start by redeploying the code in the globo_web_app directory
cd globo_web_app
terraform apply

# Now make changes to the code
# Next we'll run terraform fmt to format the code
terraform fmt -check
terraform fmt

# Now validate the code to ensure there are no syntax errors
# Add an error to the code to test the validation
terraform validate

# Add the terraform.tfvars file to set the variables
# Then run the plan command to see the changes
terraform plan -out m4.tfplan

# Now apply the changes
terraform apply m4.tfplan