{% import "makina-states/services/monitoring/circus/macros.jinja" as circus with context %}

{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

include:
  - makina-states.services.monitoring.circus
# inconditionnaly reboot circus & nginx upon deployments

{% set circus_data = {
  'manager_force_reload': true,
  'cmd': '../rvm.sh bundle exec puma -e production -p {0}'.format(cfg.data.port),
  'environment': {'RAILS_ENV': 'production'},
  'uid': cfg.user,
  'gid': cfg.group,
  'copy_env': True,
  'working_dir': cfg.project_root+'/redmine',
  'warmup_delay': "10",
  'max_age': 24*60*60}%}
{{ circus.circusAddWatcher(cfg.name, **circus_data) }}
