class QueueNames
  SAMPLES = 'samples'.freeze
  REMOTE_CONTENT = 'remotecontent'.freeze
  AUTH_LOOKUP = 'authlookup'.freeze
  DEFAULT = Delayed::Worker.default_queue_name
  MAILERS = SEEK::Application.config.action_mailer.deliver_later_queue_name
end
