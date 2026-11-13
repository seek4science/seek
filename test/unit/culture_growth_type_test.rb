require 'test_helper'

class CultureGrowthTypeTest < ActiveSupport::TestCase
  test 'no rdf, as there is no schema.org description' do
    object = FactoryBot.create(:culture_growth_type)
    refute object.rdf_supported?
    refute RdfGenerationQueue.where(item: object).exists?
  end
end
