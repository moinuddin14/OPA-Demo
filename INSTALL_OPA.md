# Set Up Helm (If Not Already Installed)

### For macOS
```
brew install helm
```

### For Linux

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh

./get_helm.sh
```

# Add the Helm Repository for OPA
```
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

# Install OPA using Helm
```
helm install opa stable/opa --namespace opa --create-namespace
```

# Verify the Installation
```
kubectl get pods -n opa
```

### You should see an OPA pod running

```
NAME                   READY   STATUS    RESTARTS   AGE
opa-xxxxxx-xxxxx       1/1     Running   0          1m
```

# Expose the OPA Service

### Option 1: Port Forwarding
```
kubectl port-forward svc/opa 8181:8181 -n opa
```

### Option 2: Create a NodePort Service
```
apiVersion: v1
kind: Service
metadata:
  name: opa
  namespace: opa
spec:
  selector:
    app: opa
  ports:
    - protocol: TCP
      port: 8181
      targetPort: 8181
      nodePort: 30081 # You can specify any available port here
  type: NodePort
```
Apply the service configuration

```
kubectl apply -f opa-service.yaml
```

### Note: In our case we are using opa-deployment.yaml to deploy the OPA server. So, if you have followed the above steps, you can skip the last step of applying the `opa-deployment.yaml` and `opa-service.yaml` files.