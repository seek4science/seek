FactoryBot.define do
  # User
  factory(:brand_new_user, class: User) do
    sequence(:login) { |n| "user#{n}" }
    test_password = generate_user_password
    password { test_password }
    password_confirmation { test_password }
  end
  
  # activated_user mainly exists for :person to use in its association
  factory(:activated_user, parent: :brand_new_user) do
    after(:create) do |u|
      u.update_column(:activated_at,Time.now.utc)
      u.update_column(:activation_code, nil)
    end
  end
  
  factory(:user_not_in_project, parent: :activated_user) do
    association :person, factory: :brand_new_person
  end
  
  factory(:user, parent: :activated_user) do
    association :person, factory: :person_in_project
  end
  
  # OauthSession
  factory(:oauth_session) do
    association :user, factory: :user
    provider { 'Zenodo' }
    access_token { '123' }
    refresh_token { 'ref' }
    expires_at { (Time.now + 1.hour) }
  end
  
  factory(:sha1_pass_user, parent: :brand_new_user) do
    test_password = generate_user_password
    after(:create) do |user|
      user.update_column(:crypted_password, user.sha1_encrypt(test_password))
    end
  end
  
  # Identity
  factory(:identity) do
    association :user, factory: :user
    provider { 'ldap' }
    sequence(:uid) { |n| "ldap-user-#{n}" }
  end
  
  # ApiToken
  factory(:api_token) do
    title { 'Test API token' }
    association :user, factory: :user
  end
end
