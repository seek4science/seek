#default project and institution
unless Project.find_by_title('Default Project') && Institution.find_by_title('Default Institution')
  project = Project.find_or_create_by(title:'Default Project')
  institution = Institution.find_or_create_by(title:'Default Institution', country: 'United Kingdom')

  project.institutions << institution
  project.save!
  puts 'Seeded default project'
end
