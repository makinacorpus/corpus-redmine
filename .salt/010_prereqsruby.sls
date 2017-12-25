include:
  - makina-states.localsettings.rvm.hooks

{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}
{{ rvm.install_ruby(data.rversion, suf=cfg.name) }}
