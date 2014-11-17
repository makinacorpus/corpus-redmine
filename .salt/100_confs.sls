{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% for i in ['redmine/Gemfile.local',
             'redmine/config/environments/production.rb',
             'redmine/config/additional_environment.rb',
             'redmine/config/database.yml',
             'redmine/config/configuration.yml',] %}
{{cfg.name}}-{{i}}:
  file.managed:
    - makedirs: true
    - source: salt://makina-projects/{{cfg.name}}/files/{{i}}
    - name:  {{cfg.project_root}}/{{i}}
    - template: jinja
    - mode: 770
    - user: "{{cfg.user}}"
    - group: "root"
    - defaults:
        project: {{cfg.name}}
        cfg: |
             {{scfg}}
{% endfor %}
