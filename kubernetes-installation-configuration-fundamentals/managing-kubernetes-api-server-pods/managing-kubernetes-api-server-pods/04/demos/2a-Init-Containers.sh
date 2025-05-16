ssh aen@c1-cp1
cd ~/content/course/04/demos/


#Use a watch to watch the progress
#Each init container run to completion then the app container will start and the Pod status changes to Running.
kubectl get pods --watch &


#Create the Pod with 2 init containers...
#each init container will be processed serially until completion before the main application container is started
kubectl apply -f init-containers.yaml


#Review the Init-Containers section and you will see each init container state is 'Teminated and Completed' and the main app container is Running
#Looking at Events...you should see each init container starting, serially...
#and then the application container starting last once the others have completed
kubectl describe pods init-containers | more 


#Delete the pod
kubectl delete -f init-containers.yaml

#Kill the watch
fg
ctrl+c