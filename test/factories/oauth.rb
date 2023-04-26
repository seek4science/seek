FactoryBot.define do
  factory(:oauth_application, class: Doorkeeper::Application) do
    sequence(:name) { |n| "Test OAuth Application #{n}" }
    sequence(:redirect_uri) { |n| "https://localhost:3000/oauth_#{n}" }
    association :owner, factory: :user
    scopes { 'read' }
  end
  
  factory(:oauth_access_token, class: Doorkeeper::AccessToken) do
    association :application, factory: :oauth_application
    expires_in { 3600 }
    scopes { 'read' }
  end
end
