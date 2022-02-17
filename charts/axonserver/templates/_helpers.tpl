{{- define "generateSystemToken" -}}
printf "%s-%s-%s-%s-%s" {{randAlphaNum 8 }} {{ randAlphaNum 4 }} {{ randAlphaNum 4 }} {{ randAlphaNum 4 }} {{ randAlphaNum 12}}
{{- end -}}

{{- define "log.path" -}}
printf "%s/log"  {{.Values.container.workdir }}
{{- end -}}

{{- define "data.path" -}}
printf "%s/data"  {{.Values.container.workdir }}
{{- end -}}

{{- define "snapshots.path" -}}
printf "%s/snapshots"  {{.Values.container.workdir }}
{{- end -}}

{{- define "events.path" -}}
printf "%s/events"  {{.Values.container.workdir }}
{{- end -}}

{{- define "config.path" -}}
printf "%s/config"  {{.Values.container.workdir }}
{{- end -}}

{{- define "systemToken.path" -}}
printf "%s/security"  {{.Values.container.workdir }}
{{- end -}}

{{- define "license.path" -}}
printf "%s/license"  {{.Values.container.workdir }}
{{- end -}}

{{/* Expand 'axonserver.properties' */}}
{{- define "axonserver-properties" -}}
axoniq.axonserver.event.storage={{ include "events.path" . }}
axoniq.axonserver.snapshot.storage={{ include "snapshots.path" . }}
axoniq.axonserver.replication.log-storage-folder={{ include "log.path" . }}
axoniq.axonserver.controldb-path={{ include "data.path" . }}
axoniq.axonserver.pid-file-location={{ include "data.path" . }}

logging.file={{ include "log.path" . }}/axonserver.log
logging.file.max-history={{ .Values.axoniq.axonserver.properties.logging.maxHistory | default "10"}}
logging.file.max-size={{ .Values.axoniq.axonserver.properties.logging.maxSize | default "10MB"}}

axoniq.axonserver.clustertemplate.path={{ include "config.path" . }}/cluster-template.yaml
axoniq.axonserver.domain={{.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local
axoniq.axonserver.internal-domain={{.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local
axoniq.axonserver.accesscontrol.enabled=true
axoniq.axonserver.accesscontrol.systemtokenfile={{ include "systemToken.path" . }}/axoniq.token
axoniq.axonserver.port={{.Values.service.ports.grpc}}
axoniq.axonserver.server.port={{.Values.service.ports.gui}}
# axoniq.axonserver.internal-port=8224

#  This the token used for the communication between axonserver nodes. This is not the System admin token.
#  https://docs.axoniq.io/reference-guide/axon-server/security/access-control-ee
axoniq.axonserver.accesscontrol.internal-token={{randAlphaNum 8 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 12}}
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
