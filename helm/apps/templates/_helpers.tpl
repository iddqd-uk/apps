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
