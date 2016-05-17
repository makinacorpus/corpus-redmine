{% set cfg = salt['mc_project.get_configuration'](project) %}
{% set data = cfg.data %}
# Settings specified here will take precedence over those in config/application.rb
RedmineApp::Application.configure do
  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true
  {% if data.version[0] > '2' %}
  config.log_level = :info
  {% endif %}

  {% if data.version[0] > '2' %}
  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

   # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  {% endif %}
  #####
  # Customize the default logger
  # http://www.ruby-doc.org/stdlib-1.8.7/libdoc/logger/rdoc/Logger.html
  #
  # Use a different logger for distributed setups
  # config.logger        = SyslogLogger.new
  #
  # Rotate logs bigger than 1MB, keeps no more than 7 rotated logs around.
  # When setting a new Logger, make sure to set it's log level too.
  #
  config.logger = Logger.new("{{cfg.project_root}}/redmine/log/production.log", 7, 1048576)
  config.logger.level = {{cfg.data.log_level}}

  # Full error reports are disabled and caching is turned on
  config.action_controller.perform_caching = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host                  = "http://assets.example.com"

  # Disable delivery errors if you bad email addresses should just be ignored
  config.action_mailer.raise_delivery_errors = false

  # No email in production log
  config.action_mailer.logger = nil


  config.active_support.deprecation = :log

  {% if data.version[0] > '2' %}
  config.secret_token = '{{salt['mc_utils.generate_stored_password'](cfg.name+"-rails_pw", 96)}}'
  config.active_record.raise_in_transactional_callbacks = true
  config.active_record.whitelist_attributes = false
  {% endif %}
end
