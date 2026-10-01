#!/bin/bash

case $1 in 
    apply )
        terraform apply --var-file terraform.tfvars --auto-approve ; gcloud compute instances list
    ;;
    plan)
        terraform plan --var-file terraform.tfvars
    ;;
    destroy)
        terraform destroy --auto-approve; gcloud compute instances list
    ;;
    *)
        echo "Syntax Error! : (Only Can Use apply/plan/destroy)"
    ;;
esac


