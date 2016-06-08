#default project and institution
project = Project.find_or_create_by_title('Default Project')
institution = Institution.find_or_create_by_title('Default Institution', country: 'United Kingdom')

if project.new_record? || institution.new_record?
  project.institutions=[institution]
  project.save!
  puts 'Created default project'
end

