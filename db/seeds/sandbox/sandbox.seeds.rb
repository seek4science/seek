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
investigation = Investigation.new(title: "Central Carbon Metabolism of Sulfolobus solfataricus",
                                  description: "An investigation in the CCM of S. solfataricus with a focus on the unique temperature adaptations and regulation; using a combined modelling and experimental approach."
                                 )
investigation.projects = [project]
investigation.contributor = admin_user
investigation.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
investigation.save
puts "Seeded 1 investigation."

study = Study.new(title: "Carbon loss at high T"
)
study.contributor = admin_user
study.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
study.investigation = investigation
study.save
puts "Seeded 1 study."

assay1 = Assay.new(title: "Reconstituted system reference state",
                  description: "The four purified enzymes were incubated in assay buffer and consumption of 3PG and production of F6P were measured in time, together with GAP and DHAP concentrations."
)
assay1.owner = admin_person
assay1.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
assay1.study = study
assay1.assay_class = AssayClass.first
assay1.save
puts "Seeded 1 experimental assay."

assay2 = Assay.new(title: "Model reconstituted system",
                   description: "Mathematical model for the reconstituted system with PGK, GAPDH, TPI and FBPAase."
)
assay2.owner = admin_person
assay2.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
assay2.study = study
assay2.assay_class = AssayClass.last
assay2.save
puts "Seeded 1 modelling analysis."

#Assets
#TODO check filesize
data_file1 = DataFile.new(title: "Metabolite concentrations during reconstituted enzyme incubation",
                         description: "The purified enzymes, PGK, GAPDH, TPI and FBPAase were incubated at 70 C en conversion of 3PG to F6P was followed."
)
data_file1.contributor = admin_user
data_file1.projects = [project]
data_file1.assays = [assay1, assay2]
data_file1.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
data_file1.content_blob = ContentBlob.new(original_filename: 'ValidationReference.xlsx',
                                         content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
)
disable_authorization_checks {data_file1.save}
AssetsCreator.create(asset_id: data_file1.id, creator_id: admin_user.id, asset_type: data_file1.class.name)
#copy file
FileUtils.cp File.dirname(__FILE__) + '/' + data_file1.content_blob.original_filename, data_file1.content_blob.filepath
disable_authorization_checks {data_file1.content_blob.save}
puts "Seeded data file 1."


data_file2 = DataFile.new(title: "Metabolite concentrations during reconstituted enzyme incubation",
                          description: "The purified enzymes, PGK, GAPDH, TPI and FBPAase were incubated at 70 C en conversion of 3PG to F6P was followed."
)
data_file2.contributor = admin_user
data_file2.projects = [project]
data_file2.assays = [assay1, assay2]
data_file2.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
data_file2.content_blob = ContentBlob.new(original_filename: 'combinedPlot.jpg',
                                          content_type: 'image/jpeg'
)
disable_authorization_checks {data_file2.save}
AssetsCreator.create(asset_id: data_file2.id, creator_id: admin_user.id, asset_type: data_file2.class.name)
#copy file
FileUtils.cp File.dirname(__FILE__) + '/' + data_file2.content_blob.original_filename, data_file2.content_blob.filepath
disable_authorization_checks {data_file2.content_blob.save}
puts "Seeded data file 2."


#model
model = Model.new(title: "Mathematical model for the combined four enzyme system",
                  description: "The PGK, GAPDH, TPI and FBPAase were modelled together using the individual rate equations. Closed system."
)
model.model_format = ModelFormat.find_by_title('SBML')
model.contributor = admin_user
model.projects = [project]
model.assays = [assay2]
model.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
cb1 = ContentBlob.new(original_filename: 'ssolfGluconeogenesisOpenAnn.dat',
                      content_type: 'text/x-uuencode'
)
cb2 = ContentBlob.new(original_filename: 'ssolfGluconeogenesisOpenAnn.xml',
                      content_type: 'text/xml'
)
model.content_blobs = [cb1,cb2]
disable_authorization_checks {model.save}
AssetsCreator.create(asset_id: model.id, creator_id: admin_user.id, asset_type: model.class.name)
#copy file
model.content_blobs.each do |blob|
  FileUtils.cp File.dirname(__FILE__) + '/' + blob.original_filename, blob.filepath
  blob.save
end
puts "Seeded 1 model."

#sop
=begin
sop = Sop.new(title: "Default title",
                  description: "Default description"
)
sop.contributor = admin_user
sop.projects = [project]
sop.assays = [assay1]
sop.policy = Policy.create(name: 'default policy', sharing_scope: 2, access_type: 3)
sop.content_blob = ContentBlob.new(original_filename: 'test_sop.txt',
                                      content_type: 'text'
)
disable_authorization_checks {sop.save}
AssetsCreator.create(asset_id: sop.id, creator_id: admin_user.id, asset_type: sop.class.name)
#copy file
FileUtils.cp File.dirname(__FILE__) + '/' + sop.content_blob.original_filename, sop.content_blob.filepath
puts "Seeded 1 sop."
=end

#publication
publication = Publication.new(pubmed_id: "23865479",
                              title: 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
                              abstract: "Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus were purified and kinetically characterized. The enzymes were reconstituted in vitro to quantify the contribution of temperature instability of the pathway intermediates to carbon loss from the system.
                                         The reconstituted system, consisting of phosphoglycerate kinase, glyceraldehyde 3-phosphate dehydrogenase, triose phosphate isomerase and the fructose 1,6-bisphosphate aldolase/phosphatase, maintained a constant consumption rate of 3-phosphoglycerate and production of
                                         fructose 6-phosphate over a 1-h period. Cofactors ATP and NADPH were regenerated via pyruvate kinase and glucose dehydrogenase. A mathematical model was constructed on the basis of the kinetics of the purified enzymes and the measured half-life times of the pathway intermediates.
                                         The model quantitatively predicted the system fluxes and metabolite concentrations. Relative enzyme concentrations were chosen such that half the carbon in the system was lost due to degradation of the thermolabile intermediates dihydroxyacetone phosphate, glyceraldehyde 3-phosphate
                                         and 1,3-bisphosphoglycerate, indicating that intermediate instability at high temperature can significantly affect pathway efficiency.",
                              published_date: '2015',
                              journal: 'FEBS J'
)

publication.contributor = admin_user
publication.projects = [project]
publication.policy = Policy.create(name: 'default policy', sharing_scope: 4, access_type: 1)
publication_author1 = PublicationAuthor.new(first_name: 'T.',
                                            last_name: 'Kouril',
                                            author_index: 1
                                            )
publication_author2 = PublicationAuthor.new(first_name: 'D.',
                                            last_name: 'Esser',
                                            author_index: 1
)
publication_author3 = PublicationAuthor.new(first_name: 'J.',
                                            last_name: 'Kort',
                                            author_index: 1
)
publication_author4 = PublicationAuthor.new(first_name: 'H. V.',
                                            last_name: 'Westerhoff',
                                            author_index: 1
)
publication_author5 = PublicationAuthor.new(first_name: 'B.',
                                            last_name: 'Siebers',
                                            author_index: 1
)
publication_author6 = PublicationAuthor.new(first_name: 'J.',
                                            last_name: 'Snoep',
                                            author_index: 1
)

publication.publication_authors = [publication_author1,publication_author2,publication_author3,publication_author4,publication_author5,publication_author6]
disable_authorization_checks do
  publication.save
  publication.associate(assay1)
  publication.associate(assay2)
end
AssetsCreator.create(asset_id: publication.id, creator_id: admin_user.id, asset_type: publication.class.name)
puts "Seeded 1 publication."