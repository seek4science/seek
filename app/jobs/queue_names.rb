class QueueNames
  SAMPLES = 'samples'.freeze
  DATAFILES = 'datafiles'.freeze
  REMOTE_CONTENT = 'remotecontent'.freeze
  AUTH_LOOKUP = 'authlookup'.freeze
  DEFAULT = 'default'.freeze
  MAILERS = SEEK::Application.config.action_mailer.deliver_later_queue_name
  INDEXING = 'indexing'.freeze
  TEMPLATES = 'templates'.freeze
end
