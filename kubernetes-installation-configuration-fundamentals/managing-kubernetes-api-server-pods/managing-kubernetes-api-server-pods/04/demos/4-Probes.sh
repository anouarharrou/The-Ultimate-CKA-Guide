ssh aen@c1-cp1
cd ~/content/course/04/demos/

#Start a watch to see the events associated with our probes.
kubectl get events --watch &
clear

#We have a single container pod app, in a Deployment that has both a liveness probe and a readiness probe
more container-probes.yaml

#Send in our deployment, after 10 seconds, our liveness and readiness probes will fail.
#The liveness probe will kill the current pod, and recreate one.
kubectl apply -f container-probes.yaml

#kill our watch
fg
ctrl+c

#We can see that our container isn't ready 0/1 and it's Restarts are increasing.
kubectl get pods

#Let's figure out what's wrong
#1. We can see in the events. The Liveness and Readiness probe failures.
#2. Under Containers, Liveness and Readiness, we can see the current configuration. And the current probe configuration. Both are pointing to 8081.
#3. Under Containers, Ready and Container Contidtions, we can see that the container isn't ready.
#4. Our Container Port is 8080, that's what we want our probes, probings. 
kubectl describe pods

#So let's go ahead and change the probes to 8080
vi container-probes.yaml

#And send that change into the API Server for this deployment.
kubectl apply -f container-probes.yaml

#Confirm our probes are pointing to the correct container port now, which is 8080.
kubectl describe pods

#Let's check our status, a couple of things happened there.
#1. Our Deployment ReplicaSet created a NEW Pod, when we pushed in the new deployment configuration.
#2. It's not immediately ready because of our initialDelaySeconds which is 10 seconds.
#3. If we wait long enough, the livenessProbe will kill the original Pod and it will go away.
#4. Leaving us with the one pod in our Deployment's ReplicaSet
kubectl get pods 

kubectl delete deployment hello-world



#Let's start up a watch on kubectl get events
kubectl get events --watch &
clear

#Create our deployment with a faulty startup probe...
#You'll see failures since the startup probe is looking for 8081...
#but you won't see the liveness or readiness probes executed
#The container will be restarted after 1 failures failureThreshold defaults to 3...this can take up to 30 seconds
#The container restart policy default is Always...so it will restart.
kubectl apply -f container-probes-startup.yaml


#Do you see any container restarts?  You should see 1.
kubectl get pods


#Change the startup probe from 8081 to 8080
kubectl apply -f container-probes-startup.yaml


#Our pod should be up and Ready now.
kubectl get pods

fg
ctrl+c

kubectl delete -f container-probes-startup.yaml
