cd ../
echo "Working dir"
pwd
ls
echo "============================================="
echo " Initializing Terraform... "
terraform version
terraform init 
terraform plan
