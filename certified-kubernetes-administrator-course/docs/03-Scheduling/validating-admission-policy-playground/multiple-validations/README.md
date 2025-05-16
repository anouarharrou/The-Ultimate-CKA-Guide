# Multiple validations example

This example demonstrates multiple validation in a single policy. Validations are executed sequentially and will exit upon encountering the first failing validation.

## Usage

Create all necessary resources:

```bash
k apply -f namespace.yaml -f policy.yaml -f binding.yaml
```

Attempt to create a deployment that violates the validation:

```bash
$ k apply -f deployment.yaml
The deployments "nginx" is invalid: : ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: failed expression: object.spec.replicas <= 3
```

Reduce number of replicas to a valid value (say 3) and try again:

```bash
$ sed -i 's/replicas: 10/replicas: 3/' deployment.yaml

$ k apply -f deployment.yaml
The deployments "nginx" is invalid: : ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: failed expression: object.spec.template.spec.containers.all(c, c.image.startsWith('europe-west1-docker.pkg.dev/test-eyal/'))
```

Now we can see that it's failing the next expression. Let's fix the image name (replace `nginx` with `europe-west1-docker.pkg.dev/test-eyal/nginx/nginx`):

```bash
$ sed -i 's#image: nginx#image: europe-west1-docker.pkg.dev/test-eyal/nginx/nginx#' deployment.yaml

$ k apply -f deployment.yaml
The deployments "nginx" is invalid: : ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: failed expression: !has(object.spec.template.spec.volumes) || object.spec.template.spec.volumes.all(v, !has(v.emptyDir))
```

Now we can see that it's failing the last validation - deployments are not allowed to use `emptyDir` volumes. Let's remove the volumes altogether and try again:

```bash
$ sed -i '/volumes:/,+2 d' deployment.yaml

$ k apply -f deployment.yaml
deployment.apps/nginx created
```

Success!

```bash
$ k get po
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7b9784645c-555bz   1/1     Running   0          19s
nginx-7b9784645c-7mfzs   1/1     Running   0          19s
nginx-7b9784645c-kg4dr   1/1     Running   0          19s
```
