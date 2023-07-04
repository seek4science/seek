require 'test_helper'

class HumanDiseaseTest < ActiveSupport::TestCase
  fixtures :all

  test 'validate concept uri' do
    hd = FactoryBot.build(:human_disease, bioportal_concept: FactoryBot.build(:bioportal_concept, concept_uri: 'blablabla'))
    refute hd.valid?
    assert hd.errors.added?(:concept_uri, :url, value: 'blablabla')
  end
end
