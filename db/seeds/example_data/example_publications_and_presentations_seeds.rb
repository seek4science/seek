# Publications, Presentations and Events

# publication
publication = Publication.new(
  publication_type_id: PublicationType.where(title: 'Journal').first_or_create!(title: 'Journal').id,
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
publication.contributor = $guest_person
publication.projects << $project
publication.registered_mode = 2
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
# Tags
User.with_current_user($guest_user) { publication.annotate_with(['metabolism', 'thermophile'], 'tag', $guest_person) }

# Save publication with all associations
disable_authorization_checks do
  publication.save!  # raises an error if something is invalid
  publication.associate($exp_assay)
  publication.associate($model_assay)
end

# Create asset
AssetsCreator.create(asset_id: publication.id, creator_id: $guest_person.id, asset_type: publication.class.name)
puts 'Seeded 1 publication.'

# Presentation
presentation = Presentation.new(
  title: 'Intermediate instability at high temperature leads to low pathway efficiency for an in vitro reconstituted system of gluconeogenesis in Sulfolobus solfataricus',
  description: "Four enzymes of the gluconeogenic pathway in Sulfolobus solfataricus were purified and kinetically characterized. The enzymes were reconstituted in vitro to quantify the contribution of temperature instability of the pathway intermediates to carbon loss from the system.
             The reconstituted system, consisting of phosphoglycerate kinase, glyceraldehyde 3-phosphate dehydrogenase, triose phosphate isomerase and the fructose 1,6-bisphosphate aldolase/phosphatase, maintained a constant consumption rate of 3-phosphoglycerate and production of
  ",
)
presentation.projects = [$project]
presentation.contributor = $guest_person
presentation.policy = Policy.create(name: 'default policy', access_type: 1)
presentation.content_blob = ContentBlob.new(original_filename: 'presentation.pptx', content_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation')
disable_authorization_checks { presentation.save! }
AssetsCreator.create(asset_id: presentation.id, creator_id: $guest_person.id, asset_type: presentation.class.name)
FileUtils.cp File.dirname(__FILE__) + '/presentation.pptx', presentation.content_blob.filepath
disable_authorization_checks { presentation.content_blob.save }
puts 'Seeded 1 presentation.'

# Create an event
event = Event.new(title: 'Event for publication', description: 'Event for publication', start_date: Date.today, end_date: Date.today + 1.day)
event.projects = [$project]
event.contributor = $guest_person
event.policy = Policy.create(name: 'default policy', access_type: 1)
event.url = 'http://www.seek4science.org'
event.city = 'London'
event.country = 'United Kingdom'
event.address = 'Dunmore Terrace 123'

event.save!
puts 'Seeded 1 event.'

# Document
document = Document.new(
  title: 'Experimental setup for the reconstituted gluconeogenic enzyme system',
  description: 'This document describes the experimental setup and procedures used for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus.'
)
document.projects = [$project]
document.contributor = $guest_person
document.license = 'CC-BY-4.0'
document.policy = Policy.create(name: 'default policy', access_type: 1)
document.content_blob = ContentBlob.new(original_filename: 'example_document.txt', content_type: 'text/plain')
User.with_current_user($guest_user) { document.annotate_with(['gluconeogenesis', 'protocol', 'thermophile'], 'tag', $guest_person) }
disable_authorization_checks { document.save! }
AssetsCreator.create(asset_id: document.id, creator_id: $admin_person.id, asset_type: document.class.name)
FileUtils.cp File.dirname(__FILE__) + '/example_document.txt', document.content_blob.filepath
disable_authorization_checks { document.content_blob.save }
puts 'Seeded 1 document.'

# Collection
collection = Collection.new(
  title: 'Gluconeogenesis in Sulfolobus solfataricus',
  description: 'A collection of data files, models, SOPs and publications related to the reconstituted gluconeogenic enzyme system from Sulfolobus solfataricus.'
)
collection.projects = [$project]
collection.contributor = $guest_person
collection.license = 'CC-BY-4.0'
collection.policy = Policy.create(name: 'default policy', access_type: 1)
User.with_current_user($guest_user) { collection.annotate_with(['gluconeogenesis', 'thermophile', 'metabolism'], 'tag', $guest_person) }
disable_authorization_checks { collection.save! }
[
  { asset: $data_file1,   comment: 'Metabolite concentration data', order: 1 },
  { asset: $data_file2,   comment: 'Model simulation vs experimental data plot', order: 2 },
  { asset: $model,        comment: 'Mathematical model of the four-enzyme system', order: 3 },
  { asset: $sop,          comment: 'Protocol for reconstituting the enzyme system', order: 4 },
  { asset: document,      comment: 'Experimental setup description', order: 5 },
  { asset: publication,   comment: 'Key publication for this work', order: 6 },
  { asset: presentation,  comment: 'Conference presentation', order: 7 },
].each do |item|
  CollectionItem.create!(collection: collection, asset: item[:asset], comment: item[:comment], order: item[:order])
end
puts 'Seeded 1 collection.'

# Store references for other seed files
$publication = publication
$presentation = presentation
$event = event
$document = document
$collection = collection