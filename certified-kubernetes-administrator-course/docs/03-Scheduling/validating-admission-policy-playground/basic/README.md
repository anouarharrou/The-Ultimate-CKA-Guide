# Basic example

This example is copied almost verbatim from the [official documentation](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#creating-a-validatingadmissionpolicy).
It demonstrates a basic policy and binding that requires deployments to have no more than 5 replicas.

## Usage

Create all resources:

```bash
k apply -f .
```

Attempt to create a deployment that violates the validation:

```bash
$ k -n demo create deployment nginx --image=nginx --replicas=10
error: failed to create deployment: deployments.apps "nginx" is forbidden: ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: failed expression: object.spec.replicas <= 5
```
