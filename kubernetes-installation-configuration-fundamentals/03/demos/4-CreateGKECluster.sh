#Instructions from this URL: https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
# Create environment variable for correct distribution
CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"


# Add the Cloud SDK distribution URL as a package source
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list


# Import the Google Cloud Platform public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -


# Update the package list and install the Cloud SDK
sudo apt-get update 
sudo apt-get install google-cloud-sdk


#Authenticate our console session with gcloud
gcloud init --console-only


#Create a named gcloud project
gcloud projects create psdemogke-1 --name="Kubernetes-Cloud"


#Set our current project context
gcloud config set project psdemogke-1


#You may have to adjust your resource limits and enabled billing here based on your subscription here.
#1. Go to https://console.cloud.google.com
#2. Ensure that you are in the project you just created, in the search bar type "Projects" and select the project we just created.
#3. From the Navigation menu on the top left, click Kubernetes Engine
#4. On the Kubernetes Engine landing page click "ENABLE BILLING" and select a billing account from the drop down list. Then click "Set Account" 
#       Then wait until the Kubernete API is enabled, this may take several minutes.


#Tell GKE to create a single zone, three node cluster for us. 3 is the default size.
#We're disabling basic authentication as it's no longer supported after 1.19 in GKE
#For more information on authentication check out this link here:
#   https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication#authenticating_users
gcloud container clusters create cscluster --region us-central1-a --no-enable-basic-auth


#Get our credentials for kubectl, this uses oath rather than certficates.
#See this link for more details on authentication to GKE Clusters
#   https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication#authenticating_users
gcloud container clusters get-credentials cscluster --zone us-central1-a --project psdemogke-1


#Check out out lists of kubectl contexts
kubectl config get-contexts


#set our current context to the GKE context, you may need to update this to your cluster context name.
kubectl config use-context gke_psdemogke-1_us-central1-a_cscluster


#run a command to communicate with our cluster.
kubectl get nodes


#Delete our GKE cluster
#gcloud container clusters delete cscluster --zone=us-central1-a 

#Delete our project.
#gcloud projects delete psdemogke-1


#Get a list of all contexts on this system.
kubectl config get-contexts


#Let's set to the kubectl context back to our local custer
kubectl config use-context kubernetes-admin@kubernetes


#use kubectl get nodes
kubectl get nodes
