# This demo will be run from c1-cp1 since kubectl is already installed there.
# This can be run from any system that has the Azure CLI client installed.

#Ensure Azure CLI command line utilitles are installed
#https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list


#Install the gpg key for Microsoft's repository
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null


sudo apt-get update
sudo apt-get install azure-cli


#Log into our subscription
#Free account - https://azure.microsoft.com/en-us/free/
az login
az account set --subscription "Demonstration Account"


#Create a resource group for the serivces we're going to create
az group create --name "Kubernetes-Cloud" --location centralus


#Let's get a list of the versions available to us
az aks get-versions --location centralus -o table


#Let's create our AKS managed cluster. Use --kubernetes-version to specify a version.
az aks create \
    --resource-group "Kubernetes-Cloud" \
    --generate-ssh-keys \
    --name CSCluster \
    --node-count 3 #default Node count is 3


#If needed, we can download and install kubectl on our local system.
az aks install-cli


#Get our cluster credentials and merge the configuration into our existing config file.
#This will allow us to connect to this system remotely using certificate based user authentication.
az aks get-credentials --resource-group "Kubernetes-Cloud" --name CSCluster


#List our currently available contexts
kubectl config get-contexts


#set our current context to the Azure context
kubectl config use-context CSCluster


#run a command to communicate with our cluster.
kubectl get nodes


#Get a list of running pods, we'll look at the system pods since we don't have anything running.
#Since the API Server is HTTP based...we can operate our cluster over the internet...esentially the same as if it was local using kubectl.
kubectl get pods --all-namespaces


#Let's set to the kubectl context back to our local custer
kubectl config use-context kubernetes-admin@kubernetes


#use kubectl get nodes
kubectl get nodes

#az aks delete --resource-group "Kubernetes-Cloud" --name CSCluster #--yes --no-wait
