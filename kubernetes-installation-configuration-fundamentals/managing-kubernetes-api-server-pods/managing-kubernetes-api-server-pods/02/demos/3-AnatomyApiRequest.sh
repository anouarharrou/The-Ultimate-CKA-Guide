#Anatomy of an API Request
#Creating a pod with YAML
kubectl apply -f pod.yaml

#Get a list of our currently running Pods
kubectl get pod hello-world

#We can use the -v option to increase the verbosity of our request.
#Display requested resource URL. Focus on VERB, API Path and Response code
kubectl get pod hello-world -v 6 

#Same output as 6, add HTTP Request Headers. Focus on application type, and User-Agent
kubectl get pod hello-world -v 7 

#Same output as 7, adds Response Headers and truncated Response Body.
kubectl get pod hello-world -v 8 

#Same output as 8, add full Response. Focus on the bottom, look for metadata
kubectl get pod hello-world -v 9 

#Start up a kubectl proxy session, this will authenticate use to the API Server
#Using our local kubeconfig for authentication and settings, updated head to only return 10 lines.
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world | head -n 10

fg
ctrl+c

#Watch, Exec and Log Requests
#A watch on Pods will watch on the resourceVersion on api/v1/namespaces/default/Pods
kubectl get pods --watch -v 6 &

#We can see kubectl keeps the TCP session open with the server...waiting for data.
netstat -plant | grep kubectl

#Delete the pod and we see the updates are written to our stdout. Watch stays, since we're watching All Pods in the default namespace.
kubectl delete pods hello-world

#But let's bring our Pod back...because we have more demos.
kubectl apply -f pod.yaml

#And kill off our watch
fg
ctrl+c

#Accessing logs
kubectl logs hello-world
kubectl logs hello-world -v 6

#Start kubectl proxy, we can access the resource URL directly.
kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods/hello-world/log 

#Kill our kubectl proxy, fg then ctrl+c
fg
ctrl+c

#Authentication failure Demo
cp ~/.kube/config  ~/.kube/config.ORIG

#Make an edit to our username changing user: kubernetes-admin to user: kubernetes-admin1
vi ~/.kube/config

#Try to access our cluster, and we see GET https://172.16.94.10:6443/api?timeout=32s 403 Forbidden in 5 milliseconds
#Enter in incorrect information for username and password
kubectl get pods -v 6

#Let's put our backup kubeconfig back
cp ~/.kube/config.ORIG ~/.kube/config

#Test out access to the API Server
kubectl get pods 

#Missing resources, we can see the response code for this resources is 404...it's Not Found.
kubectl get pods nginx-pod -v 6

#Let's look at creating and deleting a deployment. 
#We see a query for the existence of the deployment which results in a 404, then a 201 OK on the POST to create the deployment which suceeds.
kubectl apply -f deployment.yaml -v 6

#Get a list of the Deployments
kubectl get deployment 

#Clean up when we're finished. We see a DELETE 200 OK and a GET 200 OK.
kubectl delete deployment hello-world -v 6
kubectl delete pod hello-world
