{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
{% import "makina-states/localsettings/rvm.sls" as rvm with context %}

{% macro project_rvm() %}
{% do kwargs.setdefault('gemset', cfg.name)%}
{% do kwargs.setdefault('version', data.rversion)%}
{{rvm.rvm(*varargs, **kwargs)}}
    - env:
      - RAILS_ENV: production
{% endmacro%}

{{cfg.name}}-rvm-wrapper-env:
  file.managed:
    - name: {{cfg.project_root}}/rvm-env.sh
    - mode: 750
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - contents: |
                #!/usr/bin/env bash
                set -e

                CWD="${PWD}";
                GEMSET="${GEMSET:-"{{data.gemset}}"}";
                RVERSION="${RVERSION:-"{{data.rversion.strip()}}"}"

                . /etc/profile
                . /usr/local/rvm/scripts/rvm
                rvm --create use ${RVERSION}@${GEMSET}

{{cfg.name}}-rvm-wrapper:
  file.managed:
    - name: {{cfg.project_root}}/rvm.sh
    - mode: 750
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - require:
      - file: {{cfg.name}}-rvm-wrapper-env
    - contents: |
                #!/usr/bin/env bash
                set -e
                w="$(dirname "${0}")"
                cd "${w}"
                CWD="${PWD}"
                cd "${CWD}"
                . ./rvm-env.sh
                exec "${@}"

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
 'rake generate_secret_token'.format(cfg.data_root),
 state=cfg.name+'-install-session')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name+'-install-redmine'}}

{{project_rvm(
 'rake db:migrate --trace'.format(cfg.data_root), state=cfg.name+'-migrate')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name+'-install-session'}}


{{project_rvm(
 'rake redmine:plugins:migrate --trace'.format(cfg.data_root), state=cfg.name+'-plugins-migrate')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
      - cmd: {{cfg.name+'-migrate'}}


{{project_rvm(
 'rake tmp:cache:clear --trace'
 '&& rake tmp:sessions:clear --trace'.format(cfg.data_root), state=cfg.name+'-clear')}}
    - cwd: {{cfg.project_root}}/redmine
    - user: {{cfg.user}}
    - require:
       - cmd: {{cfg.name+'-plugins-migrate'}}
