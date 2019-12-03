Gitlab Runner Mutating Admission Controller for Kubernetes
==========================================================

Mission: patch CI Pods created by Gitlab Runner Kubernetes Executor with custom configuration. 

## Installation

Set labels in Gitlab runner helm chart config:
```yaml
runners:
  podLabels:
    "cc.mgit.cz/admission": gitlab-mutatating-webhook
```
https://gitlab.com/gitlab-org/charts/gitlab-runner/blob/master/values.yaml#L260

## Kubernetes <1.17 configuration

```
# Deprecated in v1.16 in favor of admissionregistration.k8s.io/v1
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: "gitlab-runner-jobs-admission"
webhooks:
- name: "gitlab-runner.example.com"
  matchPolicy: Equivalent
  sideEffects: None
  reinvocationPolicy: IfNeeded
  failurePolicy: Ignore
  objectSelector:
    matchLabels:
      "cc.mgit.cz/admission": gitlab-mutatating-webhook
  rules:
  - apiGroups:   [""]
    apiVersions: ["v1"]
    operations:  ["CREATE"]
    resources:   ["pods"]
    scope:       "Namespaced"
  clientConfig:
    service:
      namespace: "gitlab-ci"
      name: "gitlab-runner-jobs-webhook"
      path: "/mutate"
    caBundle: $base64encodedCa
  admissionReviewVersions: ["v1beta1"]
  timeoutSeconds: 2

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: gitlab-runner-jobs-webhook
  namespace: gitlab-ci
  labels:
    app: gitlab-runner-jobs-webhook
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: gitlab-runner-jobs-webhook
    spec:
      containers:
        - name: gitlab-runner-jobs-webhook
          image: ~
          imagePullPolicy: Always
          args:
            - -tls-cert-file=/etc/webhook/certs/cert.pem
            - -tls-key-file=/etc/webhook/certs/key.pem
          volumeMounts:
            - name: webhook-certs
              mountPath: /etc/webhook/certs
              readOnly: true
      volumes:
        - name: webhook-certs
          secret:
            secretName: gitlab-runner-jobs-webhook-certs
---

apiVersion: v1
kind: Service
metadata:
  namespace: gitlab-ci
  name: gitlab-runner-jobs-webhook
  labels:
    app: gitlab-runner-jobs-webhook
spec:
  ports:
  - port: 443
    targetPort: 8080
  selector:
    app: gitlab-runner-jobs-webhook

---

apiVersion: v1
kind: Secret
metadata:
  namespace: gitlab-ci
  name: gitlab-runner-jobs-webhook-certs
data:
  cert.pem: $base64encodedCert
  key.pem: $base64encodedKey
```
