# Create an admin and a guest user

# Admin
admin_user = User.where(login: 'admin').first_or_create(
  login: 'admin',
  email: 'admin@test1000.com',
  password: 'adminadmin', password_confirmation: 'adminadmin'
)

admin_user.activate
# TODO, check if admin really has access to the admin environment
admin_user.build_person(first_name: 'Admin', last_name: 'User', email: 'admin@test1000.com') unless admin_user.person
admin_user.save!
admin_user.person.work_groups << $workgroup
admin_person = admin_user.person
admin_person.save
puts 'Seeded 1 admin.'

## Guest
guest_user = User.where(login: 'guest').first_or_create(
  login: 'guest',
  email: 'guest@test1000.com',
  password: 'guestguest', password_confirmation: 'guestguest'
)
guest_user.activate
guest_user.build_person(first_name: 'Guest', last_name: 'User', email: 'guest@example.com') unless guest_user.person
guest_user.save!
guest_user.person.work_groups << $workgroup
guest_person = guest_user.person
guest_person.save
puts 'Seeded 1 guest.'

# Update project
disable_authorization_checks do
  $project.description = 'This is a test project for the SEEK sandbox.'
  $project.web_page = 'http://www.seek4science.org'
  $project.pals = [guest_person]
  $project.save!
  puts 'Seeded 1 project.'
end

# Update institution
disable_authorization_checks do
  $institution.country = 'United Kingdom'
  $institution.city = 'Manchester' # Overridden by ROR
  $institution.web_page = 'http://www.seek4science.org' # Overridden by ROR
  # $institution.ror_id = '027m9bs27' # Only works with active internet connection
  $institution.address = '10 Downing Street' # Stays the same
  $institution.department = 'Department of SEEK for Science'
  # Logo?
  $institution.save!
  puts 'Seeded 1 institution.'
end

# Store references for other seed files
$admin_user = admin_user
$admin_person = admin_person
$guest_user = guest_user
$guest_person = guest_person