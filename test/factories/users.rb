# User
Factory.define(:brand_new_user, class: User) do |f|
  f.sequence(:login) { |n| "user#{n}" }
  test_password = generate_user_password
  f.password test_password
  f.password_confirmation test_password
end

Factory.define(:avatar) do |f|
  f.original_filename "#{Rails.root}/test/fixtures/files/file_picture.png"
  f.image_file File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb')
  f.association :owner, factory: :person
end

# activated_user mainly exists for :person to use in its association
Factory.define(:activated_user, parent: :brand_new_user) do |f|
  f.after_create do |u|
    u.activate
  end
end

Factory.define(:user_not_in_project, parent: :activated_user) do |f|
  f.association :person, factory: :brand_new_person
end

Factory.define(:user, parent: :activated_user) do |f|
  f.association :person, factory: :person_in_project
end

# OauthSession
Factory.define(:oauth_session) do |f|
  f.association :user, factory: :user
  f.provider 'Zenodo'
  f.access_token '123'
  f.refresh_token 'ref'
  f.expires_at (Time.now + 1.hour)
end

Factory.define(:sha1_pass_user, parent: :brand_new_user) do |f|
  test_password = generate_user_password
  f.after_create do |user|
    user.update_column(:crypted_password, user.sha1_encrypt(test_password))
  end
end
