ssh aen@c1-cp1
cd ~/content/course/03/demos

#Get a list of all the namespaces in our cluster
kubectl get namespaces

#get a list of all the API resources and if they can be in a namespace
kubectl api-resources --namespaced=true | head
kubectl api-resources --namespaced=false | head

#Namespaces have state, Active and Terminating (when it's deleting)
kubectl describe namespaces

#Describe the details of an indivdual namespace
kubectl describe namespaces kube-system

#Get all the pods in our cluster across all namespaces. Right now, only system pods, no user workload.
#You can shorten --all-namespaces to -A
kubectl get pods --all-namespaces

#Get all the resource across all of our namespaces
kubectl get all --all-namespaces

#Get a list of the pods in the kube-system namespace
kubectl get pods --namespace kube-system

#Imperatively create a namespace
kubectl create namespace playground1

#Imperatively create a namespace...but there's some character restrictions. Lower case and only dashes.
kubectl create namespace Playground1

#Declaratively create a namespace
more namespace.yaml
kubectl apply -f namespace.yaml

#Get a list of all the current namespaces
kubectl get namespaces

#Start a deployment into our playground1 namespace
more deployment.yaml
kubectl apply -f deployment.yaml

#Creating a resource imperatively...the generator parameter is deprecated and removed from the demo. 
kubectl run hello-world-pod \
    --image=psk8s.azurecr.io/hello-app:1.0 \
    --namespace playground1

#Where are the pods?
kubectl get pods

#List all the pods on our namespace
kubectl get pods --namespace playground1
kubectl get pods -n playground1

#Get a list of all of the resources in our namespace...Deployment, ReplicaSet and Pods
kubectl get all --namespace=playground1

#Try to delete all the pods in our namespace...this will delete the single pod.
#But the pods under the Deployment controller will be recreated.
kubectl delete pods --all --namespace playground1

#Get a list of all of the *new* pods in our namespace
kubectl get pods -n playground1

#Delete all of the resources in our namespace and the namespace and delete our other created namespace.
#This deletes the Deployment controller, the Pods...or really ALL resources in the namespaces
kubectl delete namespaces playground1
kubectl delete namespaces playgroundinyaml

#List all resources in all namespaces, now our Deployment is gone.
kubectl get all
kubectl get all --all-namespaces
