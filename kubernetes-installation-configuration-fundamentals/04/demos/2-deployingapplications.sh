#Log into the control plane node c1-cp1/master node c1-master1 
ssh aen@c1-cp1


#Deploying resources imperatively in your cluster.
#kubectl create deployment, creates a Deployment with one replica in it.
#This is pulling a simple hello-world app container image from a container registry.
kubectl create deployment hello-world --image=psk8s.azurecr.io/hello-app:1.0


#But let's deploy a single "bare" pod that's not managed by a controller...
kubectl run hello-world-pod --image=psk8s.azurecr.io/hello-app:1.0


#Let's see of the Deployment creates a single replica and also see if that bare pod is created. 
#You should have two pods here...
# - the one managed by our controller has a the pod template hash in it's name and a unique identifier
# - the bare pod
kubectl get pods
kubectl get pods -o wide


#Remember, k8s is a container orchestrator and it's starting up containers on Nodes.
#Open a second terminal and ssh into the node that hello-world pod is running on.
ssh aen@c1-node[XX]


#When containerd is your container runtime, use crictl to get a listing of the containers running
#Check out this for more details https://kubernetes.io/docs/tasks/debug-application-cluster/crictl
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps

#Log out of the Node and back into the Control Plane node, c1-cp1
exit


#Back on c1-cp1, we can pull the logs from the container. Which is going to be anything written to stdout. 
#Maybe something went wrong inside our app and our pod won't start. This is useful for troubleshooting.
kubectl logs hello-world-pod


#Starting a process inside a container inside a pod.
#We can use this to launch any process as long as the executable/binary is in the container.
#Launch a shell into the container. Callout that this is on the *pod* network.
kubectl exec -it  hello-world-pod -- /bin/sh
hostname
ip addr
exit


#Remember that first kubectl create deployment we executed, it created a deployment for us.
#Let's look more closely at that deployment
#Deployments are made of ReplicaSets and ReplicaSets create Pods!
kubectl get deployment hello-world
kubectl get replicaset
kubectl get pods


#Let's take a closer look at our Deployment and it's Pods.
#Name, Replicas, and Events. In Events, notice how the ReplicaSet is created by the deployment.
#Deployments are made of ReplicaSets!
kubectl describe deployment hello-world | more


#The ReplicaSet creates the Pods...check out...Name, Controlled By, Replicas, Pod Template, and Events.
#In Events, notice how the ReplicaSet create the Pods
kubectl describe replicaset hello-world | more


#Check out the Name, Node, Status, Controlled By, IPs, Containers, and Events.
#In Events, notice how the Pod is scheduled, the container image is pulled, 
#and then the container is created and then started.
kubectl describe pod hello-world-[tab][tab] | more


#For a deep dive into Deployments check out 'Managing Kubernetes Controllers and Deployments'
#https://www.pluralsight.com/courses/managing-kubernetes-controllers-deployments





#Expose the Deployment as a Service. This will create a Service for the Deployment
#We are exposing our Service on port 80, connecting to an application running on 8080 in our pod.
#Port: Internal Cluster Port, the Service's port. You will point cluster resources here.
#TargetPort: The Pod's Service Port, your application. That one we defined when we started the pods.
kubectl expose deployment hello-world \
     --port=80 \
     --target-port=8080


#Check out the CLUSTER-IP and PORT(S), that's where we'll access this service, from inside the cluster.
kubectl get service hello-world


#We can also get that information from using describe
#Endpoints are IP:Port pairs for each of Pods that that are a member of the Service.
#Right now there is only one...later we'll increase the number of replicas and more Endpoints will be added.
kubectl describe service hello-world


#Access the Service inside the cluster
curl http://$SERVCIEIP:$PORT


#Access a single pod's application directly, useful for troubleshooting.
kubectl get endpoints hello-world
curl http://$ENDPOINT:$TARGETORT


#Using kubectl to generate yaml or json for your deployments
#This includes runtime information...which can be useful for monitoring and config management
#but not as source mainifests for declarative deployments
kubectl get deployment hello-world -o yaml | more 
kubectl get deployment hello-world -o json | more 



#Let's remove everything we created imperatively and start over using a declarative model
#Deleting the deployment will delete the replicaset and then the pods
#We have to delete the bare pod manually since it's not managed by a contorller. 
kubectl get all
kubectl delete service hello-world
kubectl delete deployment hello-world
kubectl delete pod hello-world-pod
kubectl get all



#Deploying resources declaratively in your cluster.
#We can use apply to create our resources from yaml.
#We could write the yaml by hand...but we can use dry-run=client to build it for us
#This can be used a a template for move complex deployments.
kubectl create deployment hello-world \
     --image=psk8s.azurecr.io/hello-app:1.0 \
     --dry-run=client -o yaml | more 


#Let's write this deployment yaml out to file
kubectl create deployment hello-world \
     --image=psk8s.azurecr.io/hello-app:1.0 \
     --dry-run=client -o yaml > deployment.yaml


#The contents of the yaml file show the definition of the Deployment
more deployment.yaml


#Create the deployment...declaratively...in code
kubectl apply -f deployment.yaml


#Generate the yaml for the service
kubectl expose deployment hello-world \
     --port=80 --target-port=8080 \
     --dry-run=client -o yaml | more


#Write the service yaml manifest to file
kubectl expose deployment hello-world \
     --port=80 --target-port=8080 \
     --dry-run=client -o yaml > service.yaml 


#The contents of the yaml file show the definition of the Service
more service.yaml 


#Create the service declaratively
kubectl apply -f service.yaml 


#Check out our current state, Deployment, ReplicaSet, Pod and a Service
kubectl get all


#Scale up our deployment...in code
vi deployment.yaml
Change spec.replicas from 1 to 20
     replicas: 20


#Update our configuration with apply to make that code to the desired state
kubectl apply -f deployment.yaml


#And check the current configuration of our deployment...you should see 20/20
kubectl get deployment hello-world
kubectl get pods | more 


#Repeat the curl access to see the load balancing of the HTTP request
kubectl get service hello-world
curl http://$SERVICEIP:PORT


#We can edit the resources "on the fly" with kubectl edit. But this isn't reflected in our yaml. 
#But this change is persisted in the etcd...cluster store. Change 20 to 30.
kubectl edit deployment hello-world

#The deployment is scaled to 30 and we have 30 pods
kubectl get deployment hello-world


#You can also scale a deployment using scale
kubectl scale deployment hello-world --replicas=40
kubectl get deployment hello-world


#Let's clean up our deployment and remove everything
kubectl delete deployment hello-world
kubectl delete service hello-world
kubectl get all
