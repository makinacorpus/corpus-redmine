{% import "makina-states/services/http/nginx/init.sls" as nginx %}

{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

include:
  - makina-states.services.http.nginx

{{ nginx.virtualhost(
  vhost_basename='corpusops-'+cfg.name,
  domain=data.domain,
  force_reload=true,
  doc_root=cfg.project_root+'/redmine/public',
  vh_top_source=data.nginx_upstreams,
  vh_content_source=data.nginx_vhost,
  cfg=cfg.name)}}
