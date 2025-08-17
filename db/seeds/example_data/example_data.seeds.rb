# Project, Institution, Workgroup
program = Programme.where(title: 'Default Programme').first_or_create(web_page: 'http://www.seek4science.org', funding_details: 'Funding H2020X01Y001', description: 'This is a test programme for the SEEK sandbox.')
project = Project.where(title: 'Default Project').first_or_create(:programme_id => program.id, description: 'A description for the default project') # TODO this link is not working
institution = Institution.where(title: 'Default Institution').first_or_create(country: 'United Kingdom')
workgroup = WorkGroup.where(project_id: project.id, institution_id: institution.id).first_or_create


# Create a strain
strain = Strain.where(title: 'Sulfolobus solfataricus strain 98/2').first_or_create()
strain.projects = [project]
strain.policy = Policy.create(name: 'default policy', access_type: 1)
strain.organism = Organism.where(title: 'Sulfolobus solfataricus').first_or_create()
strain.provider_name = 'BacDive'
strain.provider_id = '123456789'
strain.synonym = '98/2'
strain.comment = 'This is a test strain.'
strain.save!
puts 'Seeded 1 strain.'

# Create an organism
organism = Organism.where(title: 'Sulfolobus solfataricus').first_or_create()
organism.projects = [project]
organism.strains = [strain]
organism.save!
puts 'Seeded 1 organism.'

## Create an admin and a guest user

# Admin
admin_user = User.where(login: 'admin').first_or_create(
  login: 'admin',
  email: 'admin@test1000.com',
  password: 'adminadmin', password_confirmation: 'adminadmin'
)

admin_user.activate
admin_user.build_person(first_name: 'Admin', last_name: 'User', email: 'admin@test1000.com') unless admin_user.person
admin_user.save!
admin_user.person.work_groups << workgroup
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
guest_user.person.work_groups << workgroup
guest_person = guest_user.person
guest_person.save
puts 'Seeded 1 guest.'

# Update project
disable_authorization_checks do
  project.description = 'This is a test project for the SEEK sandbox.'
  project.web_page = 'http://www.seek4science.org'
  project.pals = [guest_person]
  project.save!
  puts 'Seeded 1 project.'
end

# Update institution
disable_authorization_checks do
  institution.country = 'United Kingdom'
  institution.city = 'Manchester' # Overridden by ROR
  institution.web_page = 'http://www.seek4science.org' # Overridden by ROR
  institution.ror_id = '027m9bs27'
  institution.address = '10 Downing Street' # Stays the same
  institution.department = 'Department of SEEK for Science'
  # Logo?
  institution.save!
  puts 'Seeded 1 institution.'
end

# ISA
investigation = Investigation.new(title: 'Central Carbon Metabolism of Sulfolobus solfataricus',
                                  description: 'An investigation in the CCM of S. solfataricus with a focus on the unique temperature adaptations and regulation; using a combined modelling and experimental approach.')
investigation.projects = [project]
investigation.contributor = guest_person
investigation.policy = Policy.create(name: 'default policy', access_type: 1)
investigation.annotate_with(['metabolism', 'thermophile'], 'tag', guest_person)
investigation.save
puts 'Seeded 1 investigation.'

study = Study.new(title: 'Carbon loss at high T')
study.contributor = guest_person
study.policy = Policy.create(name: 'default policy', access_type: 1)
study.investigation = investigation
study.annotate_with(['thermophile', 'high temperature'], 'tag', guest_person)
study.save
puts 'Seeded 1 study.'

## Observation unit
observation_unit = ObservationUnit.new(title: 'Large scale bioreactor')
observation_unit.description = 'A large scale bioreactor with a 1000 mL reservoir.'
observation_unit.other_creators = [admin_person.name, 'Jane Doe']
observation_unit.contributor = guest_person
observation_unit.policy = Policy.create(name: 'default policy', access_type: 1)
observation_unit.annotate_with(['bioreactor'], 'tag', guest_person)
observation_unit.study = study
disable_authorization_checks { observation_unit.save }
puts 'Seeded 1 observation unit'

## Assays ##

## Experimental assay?
exp_assay = Assay.new(title: 'Reconstituted system reference state',
                      description: 'The four purified enzymes were incubated in assay buffer and consumption of 3PG and production of F6P were measured in time, together with GAP and DHAP concentrations.')
exp_assay.contributor = guest_person
exp_assay.policy = Policy.create(name: 'default policy', access_type: 1)
exp_assay.study = study
# exp_assay.observation_units = [observation_unit] # TODO ActiveRecord::HasManyThroughNestedAssociationsAreReadonly: Cannot modify association 'Assay#observation_units' because it goes through more than one other association. (ActiveRecord::HasManyThroughNestedAssociationsAreReadonly)
exp_assay.assay_class = AssayClass.experimental
exp_assay.organisms = [organism]
exp_assay.save
puts "exp_assay: Seeded 1 #{exp_assay.assay_class.long_key.downcase}."

# Modeling assay?
model_assay = Assay.new(title: 'Model reconstituted system',
                        description: 'Mathematical model for the reconstituted system with PGK, GAPDH, TPI and FBPAase.')
model_assay.contributor = guest_person
model_assay.policy = Policy.create(name: 'default policy', access_type: 1)
model_assay.study = study
model_assay.assay_class = AssayClass.modelling
model_assay.save
puts "Seeded 1 #{model_assay.assay_class.long_key.downcase}."

# Assay stream
assay_stream = Assay.new(title: 'Assay stream',
                         description: 'A stream of assays? This is a test assay stream for the example data.',)
assay_stream.contributor = guest_person
assay_stream.policy = Policy.create(name: 'default policy', access_type: 1)
assay_stream.study = study
assay_stream.assay_class = AssayClass.assay_stream
assay_stream.save
puts "Seeded 1 assay stream #{model_assay.assay_class.long_key.downcase}."

#######
# Assets
# TODO check filesize
data_file1 = DataFile.new(title: 'Metabolite concentrations during reconstituted enzyme incubation',
                          description: 'The purified enzymes, PGK, GAPDH, TPI and FBPAase were incubated at 70 C en conversion of 3PG to F6P was followed.')
data_file1.contributor = guest_person
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
data_file2.contributor = guest_person
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
model.contributor = guest_person
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
AssetsCreator.create(asset_id: model.id, creator_id: guest_person.id, asset_type: model.class.name)
# copy file
model.content_blobs.each do |blob|
  FileUtils.cp File.dirname(__FILE__) + '/' + blob.original_filename, blob.filepath
  blob.save
end
puts 'Seeded 1 model.'

# Sop creation
sop = Sop.new(title: 'Reconstituted Enzyme System Protocol',
              description: 'Standard operating procedure for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus to study metabolic pathway efficiency at high temperatures.')
sop.contributor = guest_person
sop.projects = [project]
sop.assays = [exp_assay, model_assay]
sop.policy = Policy.create(name: 'default policy', access_type: 1)
sop.content_blob = ContentBlob.new(original_filename: 'test_sop.txt',
                                   content_type: 'text')
AssetsCreator.create(asset_id: sop.id, creator_id: guest_person.id, asset_type: sop.class.name)
FileUtils.cp File.dirname(__FILE__) + '/' + sop.content_blob.original_filename, sop.content_blob.filepath

disable_authorization_checks {sop.save!}
sop.annotate_with(['protocol', 'enzymology', 'thermophile'], 'tag', guest_person)
puts 'Seeded 1 SOP.'


# publication
publication = Publication.new(
  publication_type_id: PublicationType.where(title:"Journal").first.id,
  pubmed_id: '23865479',
  title: 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
  abstract: "Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus were purified and kinetically characterized. The enzymes were reconstituted in vitro to quantify the contribution of temperature instability of the pathway intermediates to carbon loss from the system.
             The reconstituted system, consisting of phosphoglycerate kinase, glyceraldehyde 3-phosphate dehydrogenase, triose phosphate isomerase and the fructose 1,6-bisphosphate aldolase/phosphatase, maintained a constant consumption rate of 3-phosphoglycerate and production of
             fructose 6-phosphate over a 1-h period. Cofactors ATP and NADPH were regenerated via pyruvate kinase and glucose dehydrogenase. A mathematical model was constructed on the basis of the kinetics of the purified enzymes and the measured half-life times of the pathway intermediates.
             The model quantitatively predicted the system fluxes and metabolite concentrations. Relative enzyme concentrations were chosen such that half the carbon in the system was lost due to degradation of the thermolabile intermediates dihydroxyacetone phosphate, glyceraldehyde 3-phosphate
             and 1,3-bisphosphoglycerate, indicating that intermediate instability at high temperature can significantly affect pathway efficiency.",
  published_date: '2015',
  journal: 'FEBS J'
)

# Set contributor and projects
publication.contributor = guest_person
publication.projects << project

# Build policy through the association
publication.build_policy(name: 'default policy', access_type: 1)
# Publication date
publication.published_date = Date.today.to_s
# Build publication authors
authors = [
  { first_name: 'T.', last_name: 'Kouril', author_index: 1 },
  { first_name: 'D.', last_name: 'Esser', author_index: 2 },
  { first_name: 'J.', last_name: 'Kort', author_index: 3 },
  { first_name: 'H. V.', last_name: 'Westerhoff', author_index: 4 },
  { first_name: 'B.', last_name: 'Siebers', author_index: 5 },
  { first_name: 'J.', last_name: 'Snoep', author_index: 6 }
]
# Citation
publication.citation = "Kouril, T. et al. Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus. FEBS J. 2015;687:100-108."

authors.each do |author_attrs|
  publication.publication_authors.build(author_attrs)
end

# Save publication with all associations
disable_authorization_checks do
  publication.save!  # raises an error if something is invalid
  publication.associate(exp_assay)
  publication.associate(model_assay)
end

# Create asset
AssetsCreator.create(asset_id: publication.id, creator_id: guest_person.id, asset_type: publication.class.name)

puts 'Seeded 1 publication.'

# Log activity
[project, investigation, study, exp_assay, model_assay, data_file1, data_file2, model, publication].each do |item|
  ActivityLog.create(action: 'create',
                     culprit: guest_user,
                     controller_name: item.class.name.underscore.pluralize,
                     activity_loggable: item,
                     data: item.title)
end

# Updating programme
disable_authorization_checks do
  program.programme_administrators = [guest_person, admin_person]
  program.projects = [project]
  # program.funding_codes_as_text = ['123456789'] # TODO cannot set funding codes
  # Discussion links...
  program.save!
  end


Seek::Config.home_description = '<p style="text-align:center;font-size:larger;font-weight:bolder">Welcome to the SEEK Sandbox</p>
<p style="text-align:center;font-size:larger;font-weight:bolder">You can log in with the username: <em>guest</em> and password: <em>guest</em></p>
<p style="text-align:center">For more information about SEEK and to see a video, please visit our <a href="http://www.seek4science.org">Website</a>.</p>'

Seek::Config.solr_enabled = true
Seek::Config.isa_enabled = true
Seek::Config.observation_units_enabled = true
Seek::Config.programmes_enabled = true
Seek::Config.programme_user_creation_enabled = true
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
