require 'test_helper'

class RoCrateExploringTest < ActiveSupport::TestCase

  test 'basic ro_crate' do

    assay = FactoryBot.create(:max_assay)
    data_file = assay.data_files.first

    ro_crate = ::ROCrate::Crate.new

    file_entity = ::ROCrate::DataEntity.new(ro_crate,
                                            data_file.content_blob.filepath,
                                            data_file.content_blob.original_filename,
                                            '@type': ['File', 'Dataset'], name: data_file.title, description: data_file.description, encodingFormat: data_file.content_blob.content_type
    )

    assay_entity = ::ROCrate::DataEntity.new(ro_crate)
    assay_entity.id = 'an_assay'
    assay_entity.type = 'Dataset'
    assay_entity['additionalType'] = 'https://jermontology.org/ontology/JERMOntology#Assay'

    assay_entity['name'] = assay.title
    assay_entity['description'] = assay.description
    assay_entity['hasPart'] = [{ '@id': file_entity.id }]

    ro_crate.add_data_entity(assay_entity)
    ro_crate.add_data_entity(file_entity)

    metadata = ro_crate.metadata
    json = metadata.generate
    puts json

  end


end