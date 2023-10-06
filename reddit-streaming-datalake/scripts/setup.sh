#!/bin/bash

# Run in Cloud Shell to set up your project and deploy solution.

echo "===================================================="
echo " Setting up environment variables ..."

usage() {
    echo "Usage: [ -i projectId ] [ -r region ] [ -c redditClientId ] [ -u redditUser ]"
}
export -f usage

while getopts ":i:r:c:u:" opt; do
    case $opt in
        i ) projectId="$OPTARG";;
        r ) region="$OPTARG";;
		c ) redditClientId="$OPTARG";;
		u ) redditUser="$OPTARG";;
        \?) echo "Invalid option -$OPTARG"
        usage
        exit 1
        ;;
    esac
done


echo "===================================================="
echo " Inputs ..."
echo " Project ID: ${projectId}" 
echo " Region: ${region}" 
echo " Reddit Client Id: ${redditClientId}"
echo " Reddit User: ${redditUser}" 


# GCP
export APP_BUCKET=${projectId}-reddit-stream-app

# reddit
echo "Please enter reddit client secret:"
read -s -r REDDIT_CLIENT_SECRET
echo "Please enter reddit password:"
read -s -r REDDIT_PASSWORD

echo "===================================================="
echo " Enabling services ..."

gcloud config set project "$projectId"

gcloud services enable storage-component.googleapis.com 
gcloud services enable compute.googleapis.com  
gcloud services enable servicenetworking.googleapis.com 
gcloud services enable iam.googleapis.com 
gcloud services enable cloudbilling.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable dataflow.googleapis.com
gcloud services enable pubsub.googleapis.com

echo "===================================================="
echo " Setting external IP access ..."

echo "{
  \"constraint\": \"constraints/compute.vmExternalIpAccess\",
	\"listPolicy\": {
	    \"allValues\": \"ALLOW\"
	  }
}" > external_ip_policy.json

gcloud resource-manager org-policies set-policy external_ip_policy.json --project="$projectId"

cd terraform || exit

# edit the variables.tf
sed -i "s|%%PROJECT_ID%%|$projectId|g" sample.tfvars
sed -i "s|%%APP_BUCKET%%|$APP_BUCKET|g" sample.tfvars
sed -i "s|%%REDDIT_CLIENT_ID%%|$redditClientId|g" sample.tfvars
sed -i "s|%%REDDIT_CLIENT_SECRET%%|$REDDIT_CLIENT_SECRET|g" sample.tfvars
sed -i "s|%%REDDIT_USERNAME%%|$redditUser|g" sample.tfvars
sed -i "s|%%REDDIT_PASSWORD%%|$REDDIT_PASSWORD|g" sample.tfvars

terraform init
terraform plan -var-file=sample.tfvars
terraform apply -var-file=sample.tfvars