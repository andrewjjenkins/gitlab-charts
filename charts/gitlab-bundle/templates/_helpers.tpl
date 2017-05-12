{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "gitlab-bundle.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "gitlab-bundle.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the postReconfigureScript value
*/}}
{{- define "gitlab.postReconfigureScript" -}}
read -r -d '' GITLAB_POST_RECONFIGURE_CODE <<-EOM
  include Gitlab::CurrentSettings
  Doorkeeper::Application.where(uid: ENV["MATTERMOST_APP_UID"]).first_or_create(
    name: "GitLab Mattermost",
    secret: ENV["MATTERMOST_APP_SECRET"],
    redirect_uri: "{{- .Values.global.mattermostExternalUrl -}}/signup/gitlab/complete\r\n{{- .Values.global.mattermostExternalUrl -}}/login/gitlab/complete")
EOM
/opt/gitlab/bin/gitlab-rails runner -e production "$GITLAB_POST_RECONFIGURE_CODE"
{{ default "" .Values.postReconfigureScript -}}
{{- end -}}


{{/*
Return the omnibusConfigRuby value
*/}}
{{- define "gitlab.omnibusConfigRuby" -}}
registry_external_url "{{- .Values.global.registryExternalUrl -}}";
{{ default "" .Values.omnibusConfigRuby -}}
{{- end -}}
