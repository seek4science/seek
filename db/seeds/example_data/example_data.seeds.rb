# Project, Institution, Workgroup
project = Project.where(title: 'Default Project').first_or_create
institution = Institution.where(title: 'Default Institution').first_or_create(country: 'United Kingdom')
workgroup = WorkGroup.where(project_id: project.id, institution_id: institution.id).first_or_create

admin_user = User.where(login: 'admin').first_or_create(
  login: 'admin',
  email: 'admin@test1000.com',
  password: 'adminadmin', password_confirmation: 'adminadmin'
)

# Admin and guest
admin_user.activate
admin_user.build_person(first_name: 'Admin', last_name: 'User', email: 'admin@test1000.com') unless admin_user.person
admin_user.save!
admin_user.person.work_groups << workgroup
admin_person = admin_user.person
admin_person.save
puts 'Seeded 1 admin.'

guest_user = User.where(login: 'guest').first_or_create(
  login: 'guest',
  email: 'guest@test1000.com',
  password: 'guestguest', password_confirmation: 'guestguest'
)
guest_user.activate
guest_user.build_person(first_name: 'Guest', last_name: 'User', email: 'guest@example.com') unless guest_user.person
guest_user.save!
guest_user.person.work_groups << workgroup
guest_person = guest_user.person
guest_person.save
puts 'Seeded 1 guest.'

# ISA
investigation = Investigation.new(title: 'Central Carbon Metabolism of Sulfolobus solfataricus',
                                  description: 'An investigation in the CCM of S. solfataricus with a focus on the unique temperature adaptations and regulation; using a combined modelling and experimental approach.')
investigation.projects = [project]
investigation.contributor = guest_user
investigation.policy = Policy.create(name: 'default policy', access_type: 1)
investigation.save
puts 'Seeded 1 investigation.'

study = Study.new(title: 'Carbon loss at high T')
study.contributor = guest_user
study.policy = Policy.create(name: 'default policy', access_type: 1)
study.investigation = investigation
study.save
puts 'Seeded 1 study.'

exp_assay = Assay.new(title: 'Reconstituted system reference state',
                      description: 'The four purified enzymes were incubated in assay buffer and consumption of 3PG and production of F6P were measured in time, together with GAP and DHAP concentrations.')
exp_assay.contributor = guest_person
exp_assay.policy = Policy.create(name: 'default policy', access_type: 1)
exp_assay.study = study
exp_assay.assay_class = AssayClass.first
exp_assay.save
puts 'Seeded 1 experimental assay.'

model_assay = Assay.new(title: 'Model reconstituted system',
                        description: 'Mathematical model for the reconstituted system with PGK, GAPDH, TPI and FBPAase.')
model_assay.contributor = guest_person
model_assay.policy = Policy.create(name: 'default policy', access_type: 1)
model_assay.study = study
model_assay.assay_class = AssayClass.last
model_assay.save
puts 'Seeded 1 modelling analysis.'

# Assets
# TODO check filesize
data_file1 = DataFile.new(title: 'Metabolite concentrations during reconstituted enzyme incubation',
                          description: 'The purified enzymes, PGK, GAPDH, TPI and FBPAase were incubated at 70 C en conversion of 3PG to F6P was followed.')
data_file1.contributor = guest_user
data_file1.projects = [project]
relationship = RelationshipType.where(title: 'Validation data').first
data_file1.policy = Policy.create(name: 'default policy', access_type: 1)
data_file1.content_blob = ContentBlob.new(original_filename: 'ValidationReference.xlsx',
                                          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
disable_authorization_checks do
  data_file1.save
  exp_assay.associate(data_file1)
  model_assay.associate(data_file1, relationship: relationship)
end
AssetsCreator.create(asset_id: data_file1.id, creator_id: guest_user.id, asset_type: data_file1.class.name)
# copy file
FileUtils.cp File.dirname(__FILE__) + '/' + data_file1.content_blob.original_filename, data_file1.content_blob.filepath
disable_authorization_checks { data_file1.content_blob.save }
puts 'Seeded data file 1.'

data_file2 = DataFile.new(title: 'Model simulation and Exp data for reconstituted system',
                          description: 'Experimental data for the reconstituted system are plotted together with the model prediction.')
data_file2.contributor = guest_user
data_file2.projects = [project]
data_file2.policy = Policy.create(name: 'default policy', access_type: 1)
data_file2.content_blob = ContentBlob.new(original_filename: 'combinedPlot.jpg',
                                          content_type: 'image/jpeg')
disable_authorization_checks do
  data_file2.save
  exp_assay.associate(data_file2)
  model_assay.associate(data_file2, relationship: relationship)
end

AssetsCreator.create(asset_id: data_file2.id, creator_id: guest_user.id, asset_type: data_file2.class.name)
# copy file
FileUtils.cp File.dirname(__FILE__) + '/' + data_file2.content_blob.original_filename, data_file2.content_blob.filepath
disable_authorization_checks { data_file2.content_blob.save }
puts 'Seeded data file 2.'

# model
model = Model.new(title: 'Mathematical model for the combined four enzyme system',
                  description: 'The PGK, GAPDH, TPI and FBPAase were modelled together using the individual rate equations. Closed system.')
model.model_format = ModelFormat.find_by_title('SBML')
model.contributor = guest_user
model.projects = [project]
model.assays = [model_assay]
model.policy = Policy.create(name: 'default policy', access_type: 1)
model.model_type = ModelType.where(title: 'Ordinary differential equations (ODE)').first
model.model_format = ModelFormat.where(title: 'SBML').first
model.recommended_environment = RecommendedModelEnvironment.where(title: 'JWS Online').first
model.organism = Organism.where(title: 'Sulfolobus solfataricus').first
cb1 = ContentBlob.new(original_filename: 'ssolfGluconeogenesisOpenAnn.dat',
                      content_type: 'text/x-uuencode')
cb2 = ContentBlob.new(original_filename: 'ssolfGluconeogenesisOpenAnn.xml',
                      content_type: 'text/xml')
cb3 = ContentBlob.new(original_filename: 'ssolfGluconeogenesisOpenAnn.xml',
                      content_type: 'text/xml')
cb4 = ContentBlob.new(original_filename: 'ssolfGluconeogenesisAnn.xml',
                      content_type: 'text/xml')
cb5 = ContentBlob.new(original_filename: 'ssolfGluconeogenesisClosed.xml',
                      content_type: 'text/xml')
cb6 = ContentBlob.new(original_filename: 'ssolfGluconeogenesis.xml',
                      content_type: 'text/xml')
model.content_blobs = [cb1, cb2, cb3, cb4, cb5, cb6]
disable_authorization_checks { model.save }
AssetsCreator.create(asset_id: model.id, creator_id: guest_user.id, asset_type: model.class.name)
# copy file
model.content_blobs.each do |blob|
  FileUtils.cp File.dirname(__FILE__) + '/' + blob.original_filename, blob.filepath
  blob.save
end
puts 'Seeded 1 model.'

# sop
=begin
sop = Sop.new(title: "Default title",
                  description: "Default description"
)
sop.contributor = guest_user
sop.projects = [project]
sop.assays = [exp_assay]
sop.policy = Policy.create(name: 'default policy', access_type: 1)
sop.content_blob = ContentBlob.new(original_filename: 'test_sop.txt',
                                      content_type: 'text'
)
disable_authorization_checks {sop.save}
AssetsCreator.create(asset_id: sop.id, creator_id: guest_user.id, asset_type: sop.class.name)
#copy file
FileUtils.cp File.dirname(__FILE__) + '/' + sop.content_blob.original_filename, sop.content_blob.filepath
puts "Seeded 1 sop."
=end

# publication
publication = Publication.new(pubmed_id: '23865479',
                              title: 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
                              abstract: "Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus were purified and kinetically characterized. The enzymes were reconstituted in vitro to quantify the contribution of temperature instability of the pathway intermediates to carbon loss from the system.
                                         The reconstituted system, consisting of phosphoglycerate kinase, glyceraldehyde 3-phosphate dehydrogenase, triose phosphate isomerase and the fructose 1,6-bisphosphate aldolase/phosphatase, maintained a constant consumption rate of 3-phosphoglycerate and production of
                                         fructose 6-phosphate over a 1-h period. Cofactors ATP and NADPH were regenerated via pyruvate kinase and glucose dehydrogenase. A mathematical model was constructed on the basis of the kinetics of the purified enzymes and the measured half-life times of the pathway intermediates.
                                         The model quantitatively predicted the system fluxes and metabolite concentrations. Relative enzyme concentrations were chosen such that half the carbon in the system was lost due to degradation of the thermolabile intermediates dihydroxyacetone phosphate, glyceraldehyde 3-phosphate
                                         and 1,3-bisphosphoglycerate, indicating that intermediate instability at high temperature can significantly affect pathway efficiency.",
                              published_date: '2015',
                              journal: 'FEBS J')

publication.contributor = guest_user
publication.projects = [project]
publication.policy = Policy.create(name: 'default policy', access_type: 1)
publication_author1 = PublicationAuthor.new(first_name: 'T.',
                                            last_name: 'Kouril',
                                            author_index: 1)
publication_author2 = PublicationAuthor.new(first_name: 'D.',
                                            last_name: 'Esser',
                                            author_index: 1)
publication_author3 = PublicationAuthor.new(first_name: 'J.',
                                            last_name: 'Kort',
                                            author_index: 1)
publication_author4 = PublicationAuthor.new(first_name: 'H. V.',
                                            last_name: 'Westerhoff',
                                            author_index: 1)
publication_author5 = PublicationAuthor.new(first_name: 'B.',
                                            last_name: 'Siebers',
                                            author_index: 1)
publication_author6 = PublicationAuthor.new(first_name: 'J.',
                                            last_name: 'Snoep',
                                            author_index: 1)

publication.publication_authors = [publication_author1, publication_author2, publication_author3, publication_author4, publication_author5, publication_author6]
disable_authorization_checks do
  publication.save
  publication.associate(exp_assay)
  publication.associate(model_assay)
end
AssetsCreator.create(asset_id: publication.id, creator_id: guest_user.id, asset_type: publication.class.name)
puts 'Seeded 1 publication.'

[project, investigation, study, exp_assay, model_assay, data_file1, data_file2, model, publication].each do |item|
  ActivityLog.create(action: 'create',
                     culprit: guest_user,
                     controller_name: item.class.name.underscore.pluralize,
                     activity_loggable: item,
                     data: item.title)
end

Seek::Config.home_description = '<p style="text-align:center;font-size:larger;font-weight:bolder">Welcome to the SEEK Sandbox</p>
<p style="text-align:center;font-size:larger;font-weight:bolder">You can log in with the username: <em>guest</em> and password: <em>guest</em></p>
<p style="text-align:center">For more information about SEEK and to see a video, please visit our <a href="http://www.seek4science.org">Website</a>.</p>'

Seek::Config.solr_enabled = true
Seek::Config.programmes_enabled = true
Seek::Config.programme_user_creation_enabled = true
Seek::Config.front_page_buttons_enabled = true
Seek::Config.noreply_sender = 'no-reply@fair-dom.org'
Seek::Config.instance_name = 'SEEK SANDBOX'
Seek::Config.application_name = 'FAIRDOM-SEEK'
Seek::Config.exception_notification_enabled = true
Seek::Config.exception_notification_recipients = ['errors@fair-dom.org']
Seek::Config.datacite_url = 'https://mds.test.datacite.org/'
Seek::Config.doi_prefix = '10.5072'
Seek::Config.doi_suffix = 'seek.5'
puts 'Finish configuration'
puts 'Please visit admin site for further configuration, e.g. site_base_host, pubmed_api_email, crossref_api_email, bioportal_api_key, email, doi, admin email'
puts 'Admin account: username admin, password adminadmin. You might want to change admin password.'
puts 'Then make sure solr, workers are running'
