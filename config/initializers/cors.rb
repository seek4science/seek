Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/ga4gh/trs/v2/*', headers: :any, methods: [:get, :head, :options]
  end
end
