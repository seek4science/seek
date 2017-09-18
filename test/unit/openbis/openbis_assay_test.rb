require 'test_helper'
require 'tmpdir'


class OpenbisAssayTest < ActiveSupport::TestCase
  fixtures :all

  test 'can create openbisassay' do
    assay = new_valid_openbis_assay
    assert assay
    assert assay.save
  end

  test 'finds only openbis assays' do
    assert Assay.count > 0

    assay = new_valid_openbis_assay

    assert_difference('OpenbisAssay.count', 1) do
      assert assay.save
    end

    OpenbisAssay.all.each do |a|
      assert_same OpenbisAssay, a.class
    end

    assert_includes OpenbisAssay.all, assay

    assay = assays(:metabolomics_assay)
    refute OpenbisAssay.exists?(assay.id)
  end

  test 'openbisassy is an assay' do
    assay = new_valid_openbis_assay
    assert_difference('Assay.count', 1) do
      assert assay.save
    end

    assert_includes Assay.all, assay
    assert Assay.find(assay.id)
  end

  test 'fixture works' do
    assert OpenbisAssay.where(title: 'Openbis Sample Assay').exists?
  end


  def new_valid_openbis_assay
    OpenbisAssay.new(title: 'test',
              assay_type_uri: 'http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics',
              technology_type_uri: 'http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography',
              study: studies(:metabolomics_study),
              contributor: people(:person_for_model_owner),
              assay_class: assay_classes(:experimental_assay_class),
              policy: Factory(:private_policy)
    )
  end

end
