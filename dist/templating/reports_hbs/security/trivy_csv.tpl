{{- if . }}Library,Vulnerability,Severity,Installed Version,Fixed Version,Description
{{- range . }}
{{- if (gt (len .Vulnerabilities) 0) }}
    {{- range .Vulnerabilities }}
____{{ escapeXML .PkgName }}____,____{{ escapeXML .VulnerabilityID }}____,____{{ escapeXML .Vulnerability.Severity }}____,____{{ escapeXML .InstalledVersion }}____,____{{ escapeXML .FixedVersion }}____,____{{ escapeXML .Description }} ({{- range .Vulnerability.References }} {{ escapeXML . }}{{- end }} )____
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
