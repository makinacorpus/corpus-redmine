{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% set scfg = salt['mc_utils.json_dump'](cfg) %}
{% set project_root=cfg.project_root%}
include:
  - makina-states.services.http.nginx
  - makina-states.localsettings.rvm

prepreqs-{{cfg.name}}:
  pkg.installed:
    - pkgs:
      - unzip
      - imagemagick
      - libmagick++-dev
      - xsltproc
      - curl
      - uuid-dev
      - e2fslibs-dev
      - sqlite3
      - libmysqlclient-dev
      - libldap2-dev
      - libsqlite3-dev
      - mysql-client
      - apache2-utils
      - autoconf
      - automake
      - build-essential
      - bzip2
      - gettext
      - git
      - groff
      - libbz2-dev
      - libcurl4-openssl-dev
      - libdb-dev
      - libgdbm-dev
      - libreadline-dev
      - libfreetype6-dev
      - libsigc++-2.0-dev
      - libsqlite0-dev
      - libsqlite3-dev
      - libtiff5
      - libtiff5-dev
      - libwebp5
      - libwebp-dev
      - libssl-dev
      - libtool
      - libxml2-dev
      - libxslt1-dev
      - libopenjpeg-dev
      - m4
      - man-db
      - pkg-config
      - poppler-utils
      - python-dev
      - python-imaging
      - python-setuptools
      - tcl8.4
      - tcl8.4-dev
      - tcl8.5
      - tcl8.5-dev
      - tk8.5-dev
      - zlib1g-dev
      - imagemagick
      - ruby-rmagick
{{cfg.name}}-download-redmine:
  cmd.run:
    - name: |

            if test ! -e redmine-{{data.version}}.tar.gz;then
              wget http://www.redmine.org/releases/redmine-{{data.version}}.tar.gz
            fi
            if test ! -e redmine-{{data.version}};then
              tar xzvf redmine-{{data.version}}.tar.gz
            fi
            if [ "x$(readlink {{project_root}}/redmine)" != "x{{project_root}}/redmine-{{data.version}}" ];then
              rm -vf {{project_root}}/redmine
              ln -svf {{project_root}}/redmine-{{data.version}} {{project_root}}/redmine
            fi
    - use_vt: true
    - cwd: {{cfg.project_root}}
    - user: {{cfg.user}}

{% for plugin, data  in data.plugins.items() %}
{{cfg.name}}-{{plugin}}-plugin:
{% if 'git' in data %}
   mc_git.latest:
    - name: {{data.git}}
    - target: "{{cfg.project_root}}/redmine/plugins/{{plugin}}"
    - user: {{cfg.user}}
    - rev: {{ data.get('rev', 'master')}}
{% endif%}
{% if 'url' in data %}
  cmd.run:
    - name: |
            if test ! -e {{plugin}};then
              mkdir {{plugin}}
            fi
            cd {{plugin}}
            wget -c {{data.url}}
            tar xzvf *tar.gz
            for i in *;do
              if test -d "$i";then
                ln -sf "$PWD/$i" "{{cfg.project_root}}/redmine/plugins/{{plugin}}"
              fi
            done
    - cwd: {{cfg.project_root}}
    - user: {{cfg.user}}
{% endif %}
    - require:
      - cmd: {{cfg.name}}-download-redmine
{% endfor %}

{{cfg.name}}-dirs:
  file.directory:
    - makedirs: true
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 770
    - watch:
      - pkg: prepreqs-{{cfg.name}}
    - names:
      - {{cfg.data.files}}
