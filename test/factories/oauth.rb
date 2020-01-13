Factory.define(:oauth_application, class: Doorkeeper::Application) do |f|
  f.sequence(:name) { |n| "Test OAuth Application #{n}" }
  f.sequence(:redirect_uri) { |n| "https://localhost:3000/oauth_#{n}" }
  f.association :owner, factory: :user
  f.scopes 'read'
end

Factory.define(:oauth_access_token, class: Doorkeeper::AccessToken) do |f|
  f.association :application, factory: :oauth_application
  f.expires_in { 2.weeks.from_now }
  f.scopes 'read'
end
