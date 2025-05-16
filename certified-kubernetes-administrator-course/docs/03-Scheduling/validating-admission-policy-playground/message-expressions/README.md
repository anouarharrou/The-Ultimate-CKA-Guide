# Custom message and message expressions example

This example demonstrates custom validation message and [message expressions](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#message-expression). These will be presented to the client in case of an error and can be used to make the returned validation failure clearer.
It's identical to the `multiple-validations` example, except for the returned error messages.

Use `spec.validations[].message` when you want to return a fixed message to the client.
Use `spec.validations[].messageExpression` when you want to perform some interpolation (using CEL) of parameters/attributes into the message returned to the client. A message expression has access to `object`, `oldObject`, `request`, and `params`.

## Usage

Create all necessary resources:

```bash
k apply -f namespace.yaml -f policy.yaml -f binding.yaml
```

Attempt to create a deployment that violates the validation:

```bash
$ k apply -f deployment.yaml
The deployments "nginx" is invalid: : ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: Deployments cannot have more than 3 replicas, this one has 10
```

Reduce number of replicas to a valid value (say 3) and try again:

```bash
$ sed -i 's/replicas: 10/replicas: 3/' deployment.yaml

$ k apply -f deployment.yaml
The deployments "nginx" is invalid: : ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: Deployment containers must be using images hosted in europe-west1 Artifact Registry in project test-eyal
```

Now we can see that it's failing the next expression. Let's fix the image name (replace `nginx` with `europe-west1-docker.pkg.dev/test-eyal/nginx/nginx`):

```bash
$ sed -i 's#image: nginx#image: europe-west1-docker.pkg.dev/test-eyal/nginx/nginx#' deployment.yaml

$ k apply -f deployment.yaml
The deployments "nginx" is invalid: : ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: Deployment cannot use emptyDir volumes, change the following volume: empty
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
