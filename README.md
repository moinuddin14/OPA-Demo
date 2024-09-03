# OPA Guide

### Prerequisites

1. Have a Kubernetes cluster
2. Follow the instructions in the [OPA Installation Guide](INSTALL_OPA.md) to install OPA in the cluster
3. Have the `kubectl` CLI installed with valid credentials and permissions to create resources in the cluster
4. Have the `jq` CLI installed (optional, but useful)
5. Have the `curl` CLI installed (optional, but useful)

### Development

1. Make necessary changes to the policies in the `policies` folder
2. Test the policies locally using the `OPA` CLI
    ``` 
    opa eval --input input.json --data policy.rego "data.example.allow" 
    ```

3. Run `./sync_policy.sh` to sync the policies with the Kubernetes cluster
4. This creates a temporary file inside `test-env` folder with the name `kubernetes_temp.yaml.temp`

### Production environment 
1. Replace the contents inside `k8s/opa-configmap.yaml` with the contents of the temporary file `kubernetes_temp.yaml.temp`
2. Apply the changes to the Kubernetes cluster
```
kubectl apply -f k8s/
```

