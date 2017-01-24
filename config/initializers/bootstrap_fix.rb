Rails.configuration.assets.paths.reject! do |path|
  path =~ /rails-assets-bootstrap-[0-9]/
end
