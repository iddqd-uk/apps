{{/*
Returns the name of the Kubernetes Secret that stores the Doppler API authentication token.
*/}}
{{- define "doppler.secretName" -}}doppler-token-auth-api{{- end }}

{{/*
Returns the name of the key used for the Doppler API authentication token in the default Kubernetes Secret.
*/}}
{{- define "doppler.secretKeyName" -}}dopplerToken{{- end }}
