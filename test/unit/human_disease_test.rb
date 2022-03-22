require 'test_helper'

class HumanDiseaseTest < ActiveSupport::TestCase
  fixtures :all

  test 'validate concept uri' do
    hd = Factory.build(:human_disease, bioportal_concept: Factory.build(:bioportal_concept, concept_uri: 'blablabla'))
    refute hd.valid?
    assert hd.errors.added?(:concept_uri, :url, value: 'blablabla')
  end
end
