ssh aen@c1-cp1
cd ~/content/course/04/demos/

#Start up kubectl get events --watch and background it.
kubectl get events --watch &
clear

#Create a pod...we can see the scheduling, container pulling and container starting.
kubectl apply -f pod.yaml

#We've used exec to launch a shell before, but we can use it to launch ANY program inside a container.
#Let's use killall to kill the hello-app process inside our container
kubectl exec -it hello-world-pod -- /bin/sh 
ps
exit

#We still have our kubectl get events running in the background, so we see if re-create the container automatically.
kubectl exec -it hello-world-pod -- /usr/bin/killall hello-app

#Our restart count increased by 1 after the container needed to be restarted.
kubectl get pods

#Look at Containers->State, Last State, Reason, Exit Code, Restart Count and Events
#This is because the container restart policy is Always by default
kubectl describe pod hello-world-pod

#Cleanup time
kubectl delete pod hello-world-pod

#Kill our watch
fg
ctrl+c

#Remember...we can ask the API server what it knows about an object, in this case our restartPolicy
kubectl explain pods.spec.restartPolicy

#Create our pods with the restart policy
more pod-restart-policy.yaml
kubectl apply -f pod-restart-policy.yaml

#Check to ensure both pods are up and running, we can see the restarts is 0
kubectl get pods 

#Let's kill our apps in both our pods and see how the container restart policy reacts
kubectl exec -it hello-world-never-pod -- /usr/bin/killall hello-app
kubectl get pods

#Review container state, reason, exit code, ready and contitions Ready, ContainerReady
kubectl describe pod hello-world-never-pod

#let's use killall to terminate the process inside our container. 
kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app

#We'll see 1 restart on the pod with the OnFailure restart policy.
kubectl get pods 

#Let's kill our app again, with the same signal.
kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app

#Check its status, which is now Error too...why? The backoff.
kubectl get pods 

#Let's check the events, we hit the backoff loop. 10 second wait. Then it will restart.
#Also check out State and Last State.
kubectl describe pod hello-world-onfailure-pod 

#Check its status, should be Running...after the Backoff timer expires.
kubectl get pods 

#Now let's look at our Pod statuses
kubectl delete pod hello-world-never-pod
kubectl delete pod hello-world-onfailure-pod
