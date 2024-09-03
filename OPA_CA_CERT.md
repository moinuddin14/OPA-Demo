# Setting Up a Validating Webhook with OPA (optional section if you want to use your own CA certificate)

## Generating the CA and Certificates

### Generate the CA (if not already available)
```openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=opa-ca" -days 365 -out ca.crt
```

### Generate the OPA Service Certificate

```
openssl genrsa -out opa.key 2048
openssl req -new -key opa.key -subj "/CN=opa.default.svc" -out opa.csr
openssl x509 -req -in opa.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out opa.crt -days 365
```
---    
    ca.crt is the CA certificate.
    opa.crt is the OPA service certificate, signed by the CA.
---

## Deploying the OPA Service with the Certificate

```
# The OPA service is secured using the opa.crt and opa.key files.
apiVersion: v1
kind: Service
metadata:
  name: opa
  namespace: default
spec:
  selector:
    app: opa
  ports:
  - protocol: TCP
    port: 443
    targetPort: 443
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opa
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
    spec:
      containers:
      - name: opa
        image: openpolicyagent/opa:latest
        ports:
        - containerPort: 443
        volumeMounts:
        - name: opa-tls
          mountPath: /tls
          readOnly: true
        args:
        - "run"
        - "--server"
        - "--tls-cert-file=/tls/opa.crt"
        - "--tls-private-key-file=/tls/opa.key"
      volumes:
      - name: opa-tls
        secret:
          secretName: opa-tls-secret
```

---

## Configuring the Webhook with caBundle

### Base64 Encode the CA Certificate
This command outputs the base64-encoded CA certificate, which you'll use in the webhook configuration.
```
cat ca.crt | base64 | tr -d '\n'
```

### Create the Webhook Configuration
```
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: opa-validating-webhook
webhooks:
- name: validating-webhook.openpolicyagent.org
  clientConfig:
    service:
      namespace: default
      name: opa
    caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJWakNDQWJhZ0F3SUJBZ0lCQWpBTkJna3Foa2lHOXcwQkFRc0ZBVEVMTUFrR0ExVUVCaE1DVXpFWE1CVUcKQ0NzR0FRVUZCd0lCQmpBTkJna3Foa2lHOXcwQkFRc0ZBVEVMTUFrR0ExVUVCaE1DVXpFWE1CVUdDd0F3RUFZSgpBNElCQVFCU3Mxd0ZaZlFqSkxGUk96S0tBaGVuNmFhMGk4Q3Q3WW1hRUkrSlZJc0gycXlZVGdVTDYzNDFRdzM2CjNyNHhLbGRyOWRXaDVGbE41SUZTZC9SVXVsclNCckFvNGFQTU9HbktCYldNeDdvOHk4NUNmcXpmemdtRnFqQkcKTzJmUUtNRXNTeFR5Z0N6WkFqR3ZCeVRxNk5PUnlyYkpsa3dHT0VnUHlRSUVST3diNmFFQVhhTEtUNENleGpkcQpjajZuM3kwMFlDQU5VQ0F3RUFBYU1LZ1lMMHNCMzBxbkVhRnM2ODNmZFpPbnFPTGF2dDN5WUJNdHd3anE2a0NlCnJQKzFzWE9HclJpRXlCZWw1MWZDRTh5Z1RYK3YzRTVOT0htemhUUGlqZ1k3VWdPQVV0OU1PTjFpeUZIVG5tdFgKekdZOGI5T0VYYXkrSldzR3F6QUttdkpXR3FkRThxNklIb3JlZjVvcU5nTjM1RGNmTXRud2ljckZkaThWZURJRQo1ajFMazZKa0tqc0hyREJXZ2RqbDBzRzRQdEhHOUJXK1VBSXJVb0xMS2ZObHhyQ3hCZ1F3WmlyU3pIb2dVUEhRCk1EMkt1WUJlb1Q5UlcrYVZBd0VBQVRBTkJna3Foa2lHOXcwQkFRc0ZBVEVMTUFrR0ExVUVCaE1DVXpFWE1CVUcKQ0NzR0FRVUZCd0lCQmpBTkJna3Foa2lHOXcwQkFRc0ZBVEVMTUFrR0ExVUVCaE1DVXpFWE1CVUdDd0F3RUFZSgoBNElCQVFCU3Mxd0ZaZlFqSkxGUk96S0tBaGVuNmFhMGk4Q3Q3WW1hRUkrSlZJc0gycXlZVGdVTDYzNDFRdzM2CjNyNHhLbGRyOWRXaDVGbE41SUZTZC9SVXVsclNCckFvNGFQTU9HbktCYldNeDdvOHk4NUNmcXpmemdtRnFqQkcKTzJmUUtNRXNTeFR5Z0N6WkFqR3ZCeVRxNk5PUnlyYkpsa3dHT0VnUHlRSUVST3diNmFFQVhhTEtUNENleGpkcQpjajZuM3kwMFlDQU5VQ0F3RUFBYU1LZ1lMMHNCMzBxbkVhRnM2ODNmZFpPbnFPTGF2dDN5WUJNdHd3anE2a0NlCnJQKzFzWE9HclJpRXlCZWw1MWZDRTh5Z1RYK3YzRTVOT0htemhUUGlqZ1k3VWdPQVV0OU1PTjFpeUZIVG5tdFgKekdZOGI5T0VYYXkrSldzR3F6QUttdkpXR3FkRThxNklIb3JlZjVvcU5nTjM1RGNmTXRud2ljckZkaThWZURJRQo1ajFMazZKa0tqc0hyREJXZ2RqbDBzRzRQdEhHOUJXK1VBSXJVb0xMS2ZObHhyQ3hCZ1F3WmlyU3pIb2dVUEhRCk1EMkt1WUJlb1Q5UlcrYVZBd0VBQVRBTkJna3Foa2lHOXcwQkFRc0ZBVEVMTUFrR0ExVUVCaE1DVXpFWE1CVUcKQ0NzR0FRVUZCd0lCQmpBTkJna3Foa2lHOXcwQkFRc0ZBVEVMTU
```