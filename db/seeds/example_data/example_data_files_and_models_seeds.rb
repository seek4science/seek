# Assets - Data files, Models, SOPs
# TODO check filesize
data_file1 = DataFile.new(title: 'Metabolite concentrations during reconstituted enzyme incubation',
                          description: 'The purified enzymes, PGK, GAPDH, TPI and FBPAase were incubated at 70 C en conversion of 3PG to F6P was followed.')
data_file1.contributor = $guest_person
data_file1.projects = [$project]
relationship = RelationshipType.where(title: 'Validation data').first
data_file1.policy = Policy.create(name: 'default policy', access_type: 1)
data_file1.content_blob = ContentBlob.new(original_filename: 'ValidationReference.xlsx',
                                          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
disable_authorization_checks do
  data_file1.save
  $exp_assay.associate(data_file1)
  $model_assay.associate(data_file1, relationship: relationship)
end
AssetsCreator.create(asset_id: data_file1.id, creator_id: $guest_user.id, asset_type: data_file1.class.name)
# copy file
FileUtils.cp File.dirname(__FILE__) + '/' + data_file1.content_blob.original_filename, data_file1.content_blob.filepath
disable_authorization_checks { data_file1.content_blob.save }
puts 'Seeded data file 1.'

data_file2 = DataFile.new(title: 'Model simulation and Exp data for reconstituted system',
                          description: 'Experimental data for the reconstituted system are plotted together with the model prediction.')
data_file2.contributor = $guest_person
data_file2.projects = [$project]
data_file2.policy = Policy.create(name: 'default policy', access_type: 1)
data_file2.content_blob = ContentBlob.new(original_filename: 'combinedPlot.jpg',
                                          content_type: 'image/jpeg')
disable_authorization_checks do
  data_file2.save
  $exp_assay.associate(data_file2)
  $model_assay.associate(data_file2, relationship: relationship)
end

AssetsCreator.create(asset_id: data_file2.id, creator_id: $guest_user.id, asset_type: data_file2.class.name)
# copy file
FileUtils.cp File.dirname(__FILE__) + '/' + data_file2.content_blob.original_filename, data_file2.content_blob.filepath
disable_authorization_checks { data_file2.content_blob.save }
puts 'Seeded data file 2.'

# model
model = Model.new(title: 'Mathematical model for the combined four enzyme system',
                  description: 'The PGK, GAPDH, TPI and FBPAase were modelled together using the individual rate equations. Closed system.')
model.model_format = ModelFormat.find_by_title('SBML')
model.contributor = $guest_person
model.projects = [$project]
model.assays = [$model_assay]
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
AssetsCreator.create(asset_id: model.id, creator_id: $guest_person.id, asset_type: model.class.name)
# copy file
model.content_blobs.each do |blob|
  FileUtils.cp File.dirname(__FILE__) + '/' + blob.original_filename, blob.filepath
  blob.save
end
puts 'Seeded 1 model.'

# Sop creation
sop = Sop.new(title: 'Reconstituted Enzyme System Protocol',
              description: 'Standard operating procedure for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus to study metabolic pathway efficiency at high temperatures.')
sop.contributor = $guest_person
sop.projects = [$project]
sop.assays = [$exp_assay, $model_assay]
sop.policy = Policy.create(name: 'default policy', access_type: 1)
sop.content_blob = ContentBlob.new(original_filename: 'test_sop.txt',
                                   content_type: 'text')
AssetsCreator.create(asset_id: sop.id, creator_id: $guest_person.id, asset_type: sop.class.name)
FileUtils.cp File.dirname(__FILE__) + '/' + sop.content_blob.original_filename, sop.content_blob.filepath

disable_authorization_checks {sop.save!}
sop.annotate_with(['protocol', 'enzymology', 'thermophile'], 'tag', $guest_person)
puts 'Seeded 1 SOP.'

# Store references for other seed files
$data_file1 = data_file1
$data_file2 = data_file2
$model = model
$sop = sop