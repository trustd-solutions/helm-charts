{{/* Expand '{{.Values.app.name}}-properties' */}}
{{- define "axonserver-properties" -}}
axoniq.{{.Values.app.name}}.event.storage=/{{.Values.app.name}}/events
axoniq.{{.Values.app.name}}.snapshot.storage=/{{.Values.app.name}}/events
axoniq.{{.Values.app.name}}.replication.log-storage-folder=/{{.Values.app.name}}/log
axoniq.{{.Values.app.name}}.controldb-path=/{{.Values.app.name}}/data
axoniq.{{.Values.app.name}}.pid-file-location=/{{.Values.app.name}}/data

logging.file=/{{.Values.app.name}}/data/{{.Values.app.name}}.log
logging.file.max-history=10
logging.file.max-size=10MB

#axoniq.{{.Values.app.name}}.autocluster.first={{.Values.app.name}}-0.{{.Values.app.name}}-svc.{{.Values.app.name}}-ns.svc.cluster.local
#axoniq.{{.Values.app.name}}.autocluster.contexts=_admin
axoniq.{{.Values.app.name}}.domain={{.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local
axoniq.{{.Values.app.name}}.internal-domain={{.Values.app.name}}-svc.{{ .Release.Namespace }}.svc.cluster.local

axoniq.{{.Values.app.name}}.accesscontrol.enabled=true
axoniq.{{.Values.app.name}}.accesscontrol.systemtokenfile=/{{.Values.app.name}}/security/axoniq.token
axoniq.{{.Values.app.name}}.accesscontrol.internal-token={{ randAlphaNum 8 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 4 }}-{{ randAlphaNum 12 }}
axoniq.{{.Values.app.name}}.clustertemplate.path=/{{.Values.app.name}}/config/cluster-template/cluster-template.yaml
{{- end -}}
s
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
