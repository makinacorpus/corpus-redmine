{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm/init.sls" as rvm with context %}

include:
  - makina-projects.{{cfg.name}}.task_rvm

{% macro project_rvm() %}
{% do kwargs.setdefault('gemset', cfg.data.gemset)%}
{% do kwargs.setdefault('version', data.rversion)%}
{{rvm.rvm(*varargs, **kwargs)}}
    - env:
      - RAILS_ENV: production
{% endmacro%}

{{cfg.name}}-add-to-rvm:
  user.present:
    - name: {{cfg.user}}
    - optional_groups: [rvm]
    - remove_groups: false

{{cfg.name}}-rubyversion:
  file.managed:
    - name: {{cfg.project_root}}/redmine/.ruby-version
    - contents: "ruby-{{data.rversion}}"
    - mode: 750
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - template: jinja

{{project_rvm(
     'gem install bundler rake rvm && gem regenerate_binstubs',
      state=cfg.name+'-bundler')}}
    - onlyif: test ! -e /usr/local/rvm/gems/ruby-{{data.rversion}}*@redmine/bin/bundle
    - user: {{cfg.user}}
    - require:
      - user: {{cfg.name}}-add-to-rvm
      - file: {{cfg.name}}-rubyversion
      - file: {{cfg.name}}-rvm-wrapper

{{project_rvm(
 'bundle install --path {0}/gems '
 '--without development test'.format(cfg.data_root),
 state=cfg.name+'-install-redmine')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name+'-bundler'}}

{{project_rvm(
 'bundle exec rake generate_secret_token'.format(cfg.data_root),
 state=cfg.name+'-install-session')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name+'-install-redmine'}}

{{project_rvm(
 'bundle exec rake db:migrate --trace'.format(cfg.data_root), state=cfg.name+'-migrate')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name+'-install-session'}}


{{project_rvm(
 'bundle exec rake redmine:plugins:migrate --trace'.format(cfg.data_root), state=cfg.name+'-plugins-migrate')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name+'-migrate'}}


{{project_rvm(
 'bundle exec rake tmp:cache:clear --trace'
 '&& bundle exec rake tmp:sessions:clear --trace'.format(cfg.data_root), state=cfg.name+'-clear')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
       - cmd: {{cfg.name+'-plugins-migrate'}}
