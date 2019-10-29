# activated_user mainly exists for :person to use in its association
Factory.define(:activated_user_hu, parent: :user_hu) do |f|
  f.after_create do |u|
    u.activate
  end
end

Factory.define(:activated_user_ina, parent: :user_ina) do |f|
  f.after_create do |u|
    u.activate
  end
end


Factory.define(:user_hu, class: User) do |f|
  f.login "huxg"
  test_password = "99iloveniuniu11"
  f.password test_password
  f.password_confirmation test_password
end


Factory.define(:user_ina, class: User) do |f|
  f.login "ina"
  test_password = "1111111111"
  f.password test_password
  f.password_confirmation test_password
end



# User_hu
Factory.define(:hu, class: Person) do |f|
  f.first_name "Xiaoming"
  f.last_name "Hu"
  f.description "Software Developer"
  f.web_page "https://www.h-its.org/de/"
  f.orcid "https://orcid.org/0000-0001-9842-9718"
  f.email "xiaoming.hu@h-its.org"
  f.phone "+49 (0)6221–533–218"
  f.skype_name "xiaoming.hu"
  f.association :user, factory: :activated_user_hu
  f.group_memberships { [Factory.build(:sdbv_group_membership)] }
  #f.group_memberships { [Factory.build(:mcm_group_membership)] }
end

Factory.define(:ina, class: Person) do |f|
  f.first_name "Ina"
  f.last_name "Poehner"
  f.description "System Admin"
  f.web_page "https://www.h-its.org/de/"
  f.email "ina.poehner@h-its.org"
  f.association :user, factory: :activated_user_ina
  #f.group_memberships { [Factory.build(:mcm_group_membership)] }
end

