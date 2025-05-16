# Validating Admission Policy playground

This repo contains some examples for the new [Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy) feature for Kubernetes.


### Cluster creation

All examples in this repository can be tested with [kind](https://kind.sigs.k8s.io/):

```bash
kind create cluster --config cluster.yaml
```

To clean up:

```bash
kind delete cluster
```

### Examples in this repository

- [basic](./basic) - a simple example policy
- [resource-filters](./resource-filters) - an example for matching many resources for the policy check and filtering out those we don't want to check
- [multiple-validations](./multiple-validations) - an example policy containing multiple validation
- [message-expressions](./message-expressions) - an example policy containing multiple validations that have a human readable message returned to the client in case of failure
- [parameters](./parameters) - an example of a parameterized policy
