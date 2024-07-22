class QueueNames
  SAMPLES = 'samples'.freeze
  REMOTE_CONTENT = 'remotecontent'.freeze
  AUTH_LOOKUP = 'authlookup'.freeze
  DEFAULT = Delayed::Worker.default_queue_name
  MAILERS = SEEK::Application.config.action_mailer.deliver_later_queue_name
  INDEXING = 'indexing'.freeze
  TEMPLATES = 'templates'.freeze
  EXTENDED_METADATA_TYPES = 'extended_metadata_types'.freeze
end
