{{- define "generateSystemToken" -}}
"{{randAlphaNum 8 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 12}}"
{{- end -}}

{{- define "generateInternalToken" -}}
"{{randAlphaNum 8 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 12}}"
{{- end -}}

{{/* Expand 'axonserver.properties' */}}
{{- define "axonserver-properties" -}}
axoniq.axonserver.devmode.enabled={{ .Values.axoniq.axonserver.devmode.enabled }}
axoniq.axonserver.event.storage={{.Values.statefulset.container.workdir }}/events
axoniq.axonserver.snapshot.storage={{.Values.statefulset.container.workdir }}/snapshots
axoniq.axonserver.replication.log-storage-folder={{.Values.statefulset.container.workdir }}/log
axoniq.axonserver.controldb-path={{.Values.statefulset.container.workdir }}/data
axoniq.axonserver.pid-file-location={{.Values.statefulset.container.workdir }}/data

logging.file={{.Values.statefulset.container.workdir }}/log/axonserver.log
logging.file.max-history={{ .Values.axoniq.axonserver.properties.logging.maxHistory | default "10"}}
logging.file.max-size={{ .Values.axoniq.axonserver.properties.logging.maxSize | default "10MB"}}

axoniq.axonserver.clustertemplate.path={{.Values.statefulset.container.workdir }}/config/cluster-template.yaml

axoniq.axonserver.domain={{$.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local
axoniq.axonserver.internal-domain={{$.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local
axoniq.axonserver.port={{.Values.service.ports.grpc}}
axoniq.axonserver.server.port={{.Values.service.ports.gui}}
#axoniq.axonserver.internal-port=8224
axoniq.axonserver.heartbeat.enabled=true

axoniq.axonserver.accesscontrol.enabled=true
axoniq.axonserver.accesscontrol.systemtokenfile={{.Values.statefulset.container.workdir }}/security/axoniq.token
#This the token used for the communication between axonserver nodes. This is not the System admin token.
#https://docs.axoniq.io/reference-guide/axon-server/security/access-control-ee
axoniq.axonserver.accesscontrol.internal-token={{ include "generateInternalToken" . }}
{{- end -}}

{{/* Expand 'cluster-template.yaml' */}}
{{- define "cluster-template" -}}
axoniq:
  {{.Values.app.name}}:
    cluster-template:
      first: {{.Values.app.name}}-0-0.{{$.Values.app.name}}-svc.{{ $.Release.Namespace }}.svc.cluster.local:8224
      replicationGroups:
      - name: _admin
        roles:
        {{- range untilStep 0 (int .Values.statefulset.count) 1 }}
        - role: PRIMARY
          node: {{$.Values.app.name}}-{{ . }}-0
        {{- end }}
        contexts:
        - name: _admin
          metaData:
            event.index-format: JUMP_SKIP_INDEX
            snapshot.index-format: JUMP_SKIP_INDEX 

      - name: {{ .Values.axoniq.axonserver.defaultReplicationGroupName }}
        roles:
        {{- range untilStep 0 (int .Values.statefulset.count) 1 }}
        - role: PRIMARY
          node: {{$.Values.app.name}}-{{ . }}-0
        {{- end }}
        contexts:
        - name: {{ .Values.axoniq.axonserver.defaultContextName }}
          metaData:
            event.index-format: JUMP_SKIP_INDEX
            snapshot.index-format: JUMP_SKIP_INDEX
      
      applications: []
      
      users:
      - password: '{{.Values.axoniq.axonserver.admin.password}}'
        userName: '{{.Values.axoniq.axonserver.admin.userName}}'
        roles:
        - context: _admin
          roles:
          - ADMIN
        - context: {{ .Values.axoniq.axonserver.defaultContextName }}
          roles:
          - CONTEXT_ADMIN
          - USE_CONTEXT
          - ADMIN
{{- end -}}
