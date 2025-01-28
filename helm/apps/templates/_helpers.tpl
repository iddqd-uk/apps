{{/*
Returns resources required to fetch secrets from the Doppler provider and store them in the K8s Secret.

The name of the secret to use will be in form of "<appName>-secrets".
*/}}
{{- define "doppler.resourcesToFetchSecrets" -}}

{{- $dopplerServiceToken := .dopplerServiceToken -}}
{{-           $namespace := .namespace           -}}
{{-             $appName := .appName             -}}
{{-         $secretsList := .secretNames         -}}

{{- $dopplerAuthTokenSecretName := printf "%s-doppler-auth-token" $appName -}}
{{- $secretsProviderName := printf "%s-secrets-store" $appName -}}
{{- $appSecrets := printf "%s-secrets" $appName -}}

# Secret with the Doppler token (it required for the external-secrets.io provider)
apiVersion: v1
kind: Secret

metadata:
  name: "{{ $dopplerAuthTokenSecretName }}"
  namespace: "{{ $namespace }}"

type: Opaque
data: {dopplerTokenKey: "{{ $dopplerServiceToken | b64enc }}"}

---

# Configuration of external-secrets.io, specifying the source from which the secrets will be fetched (Doppler provider)
apiVersion: external-secrets.io/v1beta1
kind: SecretStore

metadata:
  name: "{{ $secretsProviderName }}"
  namespace: "{{ $namespace }}"

spec:
  provider:
    doppler:
      auth:
        secretRef:
          dopplerToken:
            name: "{{ $dopplerAuthTokenSecretName }}"
            key: dopplerTokenKey

---

# ExternalSecret will fetch the secrets from the Doppler provider and store them in the K8s Secret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret

metadata:
  name: "{{ $appName }}-external-secret"
  namespace: "{{ $namespace }}"
  annotations: {force-sync: "{{ now | unixEpoch }}"} # force the sync of the secrets

spec: # https://external-secrets.io/latest/api/externalsecret/#example
  secretStoreRef: {kind: SecretStore, name: "{{ $secretsProviderName }}"}
  target: {name: "{{ $appSecrets }}"}
  data: # https://external-secrets.io/latest/provider/doppler/#1-fetch
  {{- range $secretName := $secretsList }}
    - {secretKey: "{{ $secretName }}", remoteRef: {key: "{{ $secretName }}"}}
  {{- end }}

---

# All fetched secrets will be stored in this K8s Secret
apiVersion: v1
kind: Secret

metadata:
  name: "{{ $appSecrets }}"
  namespace: "{{ $namespace }}"
{{- end -}}

{{/*
Prefer running on worker nodes, but allow running on the master node too.
*/}}
{{- define "nodeAffinity.preferWorkersButAllowMaster" -}}
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 10 # scheduler prefers placing pods on worker nodes
    preference: {matchExpressions: [{key: node/role, operator: In, values: [worker]}]}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions: # allows the pod to be scheduled on either the worker or master node
      - {key: node/role, operator: In, values: [worker, master]}
{{- end -}}

{{/*
Simple TCP port probes (liveness + readiness) for a health check.
*/}}
{{- define "healthcheck.tcpPortProbes" -}}
livenessProbe:
  tcpSocket:
    port: {{ . }}        # the port to check
  initialDelaySeconds: 5 # time to wait before starting the probe
  periodSeconds: 10      # frequency of the probe
  timeoutSeconds: 1      # threshold for considering the container unhealthy
readinessProbe:
  tcpSocket:
    port: {{ . }}        # the port to check
  initialDelaySeconds: 5 # time to wait before starting the probe
  periodSeconds: 10      # frequency of the probe
  timeoutSeconds: 1      # threshold for considering the container unhealthy
{{- end -}}
