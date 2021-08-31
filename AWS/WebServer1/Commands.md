## Commands
- 1. Destroy single resource  
`
terraform destroy -target aws_instance.web-server-ubuntu1 --auto-approve
`

- 2. Create/Update single instant  
`
terraform apply -target aws_instance.web-server-ubuntu1 --auto-approve
`
- 3. List all deployed resources  
`
terraform state list
`
- 4. Display properties of the deployed resource  
`
terraform state show aws_eip.web-server-public-ip1
`