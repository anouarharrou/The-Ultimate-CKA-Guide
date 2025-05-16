# Parameterized policy example

This example demonstrates [parameterized policies](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/#parameter-resources).

Using parameters allows you to separate the policy and configuration, thus allowing you to reuse policies for multiple cases by supplying different parameters.

Parameters currently requires a Custom Resource Definition (CRD) to be created by the cluster operator. This means that you have full control of the schema for that CRD.

`crd.yaml` contains a basic example for a `Parameters` CRD that can be easily extended and adapted to your needs. Read more about that parameters CRD in the Kubernetes Enhancement Proposal for this feature [KEP-3488](https://github.com/kubernetes/enhancements/blob/master/keps/sig-api-machinery/3488-cel-admission-control/README.md#policy-definition-and-configuration-separation-alternatives).

## Usage

Create all necessary resources:

```bash
k apply -f .
```

Attempt to create a deployment that violates the validation:

```bash
$ k create deployment nginx --image=nginx --replicas=6
error: failed to create deployment: deployments.apps "nginx" is forbidden: ValidatingAdmissionPolicy 'demo-policy.example.com' with binding 'demo-binding-test.example.com' denied request: Deployments cannot have more than 3 replicas, this one has 6
```

Note that the `messageExpression` for this validation in the policy uses the parameter as well, thus preventing the need to hard-code values.
