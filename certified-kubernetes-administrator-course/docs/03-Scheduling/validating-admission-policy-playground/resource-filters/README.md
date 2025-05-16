# Resource filtering example

This example demonstrates a policy that matches _all_ `CREATE`/`UPDATE` requests and then applies filtering in 2 ways:
1. The binding filters resources in the `rbac.authorization.k8s.io` API group and `Lease` resource in the `coordination.k8s.io` API groups - these requests wil be dropped without reaching the policy.
2. The policy performs additional matching (using CEL) to ignore any requests coming from the nodes (kubelet).


## Usage

Create all resources:

```bash
k apply -f .
```

Attempt to create a deployment that violates the validation:

```bash
$ k create deployment nginx --image=nginx
error: failed to create deployment: deployments.apps "nginx" is forbidden: ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: failed expression: object.metadata.name.startsWith("demo-")
```

Create a valid deployment:

```bash
$ k create deployment demo-nginx --image=nginx
deployment.apps/demo-nginx created
```

Attempt to create a Job that violates the validation:

```bash
$ k create job test --image=busybox
error: failed to create job: jobs.batch "test" is forbidden: ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: failed expression: object.metadata.name.startsWith("demo-")
```

Create a role that violates the name validation (but still goes through as we skip validation for any resource in the `rbac.authorization.k8s.io` API group):

```bash
$ k create role test --verb=get --resource=pods
role.rbac.authorization.k8s.io/test created
```
