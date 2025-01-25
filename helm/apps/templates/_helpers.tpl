{{/*
Returns the name of the vanilla Kubernetes secret where external-secrets.io stores all the secrets.
*/}}
{{- define "doppler.syncedSecretName" -}}doppler-synced-secrets{{- end }}
