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
                set -e
                GEMSET="${GEMSET:-"{{data.gemset}}"}";
                RVERSION="${RVERSION:-"{{data.rversion.strip()}}"}"
                . /etc/profile
                . /usr/local/rvm/scripts/rvm
                rvm --create use "${RVERSION}@${GEMSET}"

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
                ww="${PWD}"
                w="$(dirname "${0}")"
                cd "${w}"
                CWD="${PWD}"
                cd "${CWD}"
                . "${CWD}/rvm-env.sh"
                cd "${ww}"
                exec "${@}"
