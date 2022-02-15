{{- define "generateSystemToken" -}}
printf "%s-%s-%s-%s-%s" {{randAlphaNum 8 }} {{ randAlphaNum 4 }} {{ randAlphaNum 4 }} {{ randAlphaNum 4 }} {{ randAlphaNum 12}}
{{- end -}}

{{- define "data.path" -}}
{{- "/{{.Values.app.name}}/data" -}}
{{- end -}}

{{- define "events.path" -}}
{{- "/{{.Values.app.name}}/events" -}}
{{- end -}}

{{- define "log.path" -}}
{{- "/{{.Values.app.name}}/log" -}}
{{- end -}}

{{- define "config.path" -}}
{{- "/{{.Values.app.name}}/config" -}}
{{- end -}}

{{- define "systemToken.path" -}}
{{- "/{{.Values.app.name}}/security" -}}
{{- end -}}

{{- define "license.path" -}}
{{- "/{{.Values.app.name}}/license" -}}
{{- end -}}

{{/* Expand 'axonserver.properties' */}}
{{- define "axonserver-properties" -}}
axoniq.{{.Values.app.name}}.event.storage={{ template "events.path" . }}
axoniq.{{.Values.app.name}}.snapshot.storage={{ template "data.path" . }}
axoniq.{{.Values.app.name}}.replication.log-storage-folder={{ template "log.path" . }}
axoniq.{{.Values.app.name}}.controldb-path={{ template "data.path" . }}
axoniq.{{.Values.app.name}}.pid-file-location={{ template "data.path" . }}

logging.file={{ template "log.path" . }}/{{.Values.app.name}}.log
logging.file.max-history={{ .Values.axoniq.axonserver.properties.logging.maxHistory | default "10"}}
logging.file.max-size={{ .Values.axoniq.axonserver.properties.logging.maxSize | default "10MB"}}

axoniq.{{.Values.app.name}}.clustertemplate.path={{ template "config.path" . }}/cluster-template.yaml
axoniq.{{.Values.app.name}}.domain={{.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local
axoniq.{{.Values.app.name}}.internal-domain={{.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local
axoniq.{{.Values.app.name}}.accesscontrol.enabled=true
axoniq.{{.Values.app.name}}.accesscontrol.systemtokenfile={{ template "systemToken.path" . }}/axoniq.token
axoniq.{{.Values.app.name}}.port={{.Values.service.ports.grpc}}
axoniq.{{.Values.app.name}}.server.port={{.Values.service.ports.gui}}
# axoniq.{{.Values.app.name}}.internal-port=8224

#  This the token used for the communication between axonserver nodes. This is not the System admin token.
#  https://docs.axoniq.io/reference-guide/axon-server/security/access-control-ee
axoniq.{{.Values.app.name}}.accesscontrol.internal-token={{randAlphaNum 8 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 12}}
{{- end -}}

{{/* Expand 'cluster-template.yaml' */}}
{{- define "cluster-template" -}}
axoniq:
  {{.Values.app.name}}:
    cluster-template:
      first: {{.Values.app.name}}-0.{{.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local:8224

      users:
      - roles:
        - context: _admin
          roles:
          - ADMIN
        password: '{{.Values.axoniq.axonserver.admin.password}}'
        userName: '{{.Values.axoniq.axonserver.admin.userName}}'

      replicationGroups:
      - roles:
{{- range untilStep 0 (int .Values.statefulset.replicas) 1 }}
        - role: PRIMARY
          node: {{$.Values.app.name}}-{{ . }}
{{- end }}
        name: _admin
        contexts:
        - name: _admin
          metaData:
            event.index-format: JUMP_SKIP_INDEX
            snapshot.index-format: JUMP_SKIP_INDEX
      - roles:
{{- range untilStep 0 (int .Values.statefulset.replicas) 1 }}
        - role: PRIMARY
          node: {{$.Values.app.name}}-{{ . }}
{{- end }}
        name: default
        contexts: []
        applications: []
{{- end -}}
