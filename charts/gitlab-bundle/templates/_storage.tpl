{{/* vim: set filetype=mustache: */}}
{{- if .Values.global.useStorageClass -}}
{{- set .Values.gitlab.persistence.gitlabEtc "storageClass" .Values.global.useStorageClass -}}
{{- set .Values.gitlab.persistence.gitlabData "storageClass" .Values.global.useStorageClass -}}
{{- set .Values.gitlab.persistence.gitlabRegistry "storageClass" .Values.global.useStorageClass -}}
{{- set .Values.gitlab.postgresql.persistence "storageClass" .Values.global.useStorageClass -}}
{{- set .Values.gitlab.redis.persistence "storageClass" .Values.global.useStorageClass -}}
{{- end -}}
