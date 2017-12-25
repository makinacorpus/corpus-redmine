{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}

{{cfg.name}}-rvm-wrapper-env:
  file.managed:
    - name: {{cfg.project_root}}/rvm-env.sh
    - mode: 750
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - contents: |
            #!/usr/bin/env bash
            . /etc/profile
            . /usr/local/rvm/scripts/rvm
            if ! ( bundle --version; );then
              rvm $R do gem install bundler rake rvm;
            fi
            rvm --create use $R

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
                ww="$(pwd)"
                w="$(dirname "${0}")"
                cd "${w}"
                CWD="$(pwd)"
                cd "$(pwd)"
                . "${CWD}/rvm-env.sh"
                cd "${ww}"
                exec "${@}"
