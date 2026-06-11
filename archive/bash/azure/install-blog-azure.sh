function waitForCatalogToBeRunning() {

}

echo "Installing Service-Catalog (ALPHA)..."
helm install svc-cat/catalog --name catalog --namespace catalog --set rbacEnable=false

echo "Waiting until all pods in catalog namespace are up and running..."
waitForCatalogToBeRunning

echo "Getting Azure Subscription Id (GUID)..."
export AZURE_SUBSCRIPTION_ID=$(az account show --query id | sed s/\"//g)
echo "AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID"

echo "Creating new Service Principal for RBAC..."
servicePrincipal=$(az ad sp create-for-rbac)
export AZURE_TENANT_ID=$(echo $servicePrincipal | jq -r .tenant)
export AZURE_CLIENT_ID=$(echo $servicePrincipal | jq -r .appId)
export AZURE_CLIENT_SECRET=$(echo $servicePrincipal | jq -r .password)
echo "AZURE_TENANT_ID=$AZURE_TENANT_ID"
echo "AZURE_CLIENT_ID=$AZURE_CLIENT_ID"
echo "AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET"


AZURE_SUBSCRIPTION_ID=75f175d3-867d-4d01-a817-4b36b9dd91a5
AZURE_TENANT_ID=0fb6f05a-ff98-4b93-9c92-9390825ee170
AZURE_CLIENT_ID=c22e9e0b-e4cc-4bbd-921e-7d1a59f34a59
AZURE_CLIENT_SECRET=e9bb47be-6edb-4e2c-931a-c60f20177536
echo "Installing Open Service Broker For Azure (ALPHA)..."
helm install azure/open-service-broker-azure --name osba --namespace osba \
   --set azure.subscriptionId=$AZURE_SUBSCRIPTION_ID \
   --set azure.tenantId=$AZURE_TENANT_ID \
   --set azure.clientId=$AZURE_CLIENT_ID \
   --set azure.clientSecret=$AZURE_CLIENT_SECRET

#To verify the service broker has been deployed and show installed service classes and plans:
# kubectl get clusterservicebroker -o yaml
# kubectl get clusterserviceclasses -o=custom-columns=NAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName
# kubectl get clusterserviceplans -o=custom-columns=NAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName,SERVICE\ CLASS:.spec.clusterServiceClassRef.name --sort-by=.spec.clusterServiceClassRef.name

#read -s -p "Password for Ghost: " password
#echo
