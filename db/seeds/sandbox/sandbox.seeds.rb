#Project, Institution, Workgroup
project = Project.find_or_create_by_title('Default Project')
institution = Institution.find_or_create_by_title('Default Institution', country: 'United Kingdom')
workgroup = WorkGroup.find_or_create_by_project_id_and_institution_id( project.id, institution.id)

admin_user = User.find_or_create_by_login(
    :login => 'admin',
    :email => 'admin@example.com',
    :password => 'admin', :password_confirmation => 'admin'
)

#Admin and guest
admin_user.activate
admin_user.person ||= Person.create(:first_name => 'Admin', :last_name => 'User', :email => 'admin@example.com')
admin_user.save
admin_user.person.work_groups << workgroup
admin_person = admin_user.person
admin_person.save
puts "Seeded 1 admin."

guest_user = User.find_or_create_by_login(
    :login => 'guest',
    :email => 'guest@example.com',
    :password => 'guest', :password_confirmation => 'guest'
)
guest_user.activate
guest_user.person ||= Person.create(:first_name => 'Guest', :last_name => 'User', :email => 'guest@example.com')
guest_user.save
guest_user.person.work_groups << workgroup
guest_person = guest_user.person
guest_person.save
puts "Seeded 1 guest."

#ISA
investigation = Investigation.new(title: "Default title",
                     description: "Default description"
)
investigation.projects = [project]
investigation.contributor = admin_user
investigation.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
investigation.save
puts "Seeded 1 investigation."

study = Study.new(title: "Default title",
                  description: "Default description"
)
study.contributor = admin_user
study.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
study.investigation = investigation
study.save
puts "Seeded 1 study."

assay = Assay.new(title: "Default title",
                  description: "Default description"
)
assay.owner = admin_person
assay.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
assay.study = study
assay.assay_class = AssayClass.first
assay.save
puts "Seeded 1 assay."

#Assets
#TODO check filesize
data_file = DataFile.new(title: "Default title",
                         description: "Default description"
)
data_file.contributor = admin_user
data_file.projects = [project]
data_file.assays = [assay]
data_file.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
data_file.content_blob = ContentBlob.new(original_filename: 'test_data_file.txt',
                                         content_type: 'text',
                                         file_size: 100
)
disable_authorization_checks {data_file.save}
#copy file
FileUtils.cp File.dirname(__FILE__) + '/' + data_file.content_blob.original_filename, File.join(Seek::Config.filestore_path, 'assets', data_file.content_blob.uuid + '.dat')
puts "Seeded 1 data file."

#model
model = Model.new(title: "Default title",
                  description: "Default description"
)
model.model_format = ModelFormat.find_by_title('SBML')
model.contributor = admin_user
model.projects = [project]
model.assays = [assay]
model.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
model.content_blobs = [ContentBlob.new(original_filename: 'test_model.txt',
                                         content_type: 'text',
                                         file_size: 100
)]
disable_authorization_checks {model.save}
#copy file
FileUtils.cp File.dirname(__FILE__) + '/' + model.content_blobs.first.original_filename, File.join(Seek::Config.filestore_path, 'assets', model.content_blobs.first.uuid + '.dat')
puts "Seeded 1 model."

#sop
sop = Sop.new(title: "Default title",
                  description: "Default description"
)
sop.contributor = admin_user
sop.projects = [project]
sop.assays = [assay]
sop.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
sop.content_blob = ContentBlob.new(original_filename: 'test_sop.txt',
                                      content_type: 'text',
                                      file_size: 100
)
disable_authorization_checks {sop.save}
#copy file
FileUtils.cp File.dirname(__FILE__) + '/' + sop.content_blob.original_filename, File.join(Seek::Config.filestore_path, 'assets', sop.content_blob.uuid + '.dat')
puts "Seeded 1 sop."

#publication
publication = Publication.new(pubmed_id: "12345",
                              title: 'Default title',
                              abstract: "Default description",
                              published_date: '2015',
                              journal: 'Default journal'
)

publication.contributor = admin_user
publication.projects = [project]
publication.policy = Policy.create(name: 'default policy', sharing_scope: 4, access_type: 3)
publication_author1 = PublicationAuthor.new(first_name: 'First',
                                            last_name: 'Author',
                                            author_index: 1
                                            )
publication.publication_authors = [publication_author1]
disable_authorization_checks {publication.save}
disable_authorization_checks {publication.associate(assay)}
puts "Seeded 1 publication."