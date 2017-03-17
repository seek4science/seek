require 'test_helper'

class StudiedFactorLinkTest < ActiveSupport::TestCase
  fixtures :all

  test 'should create a studied_factor_link' do
    studied_factor_link = StudiedFactorLink.new(substance: compounds(:compound_glucose), studied_factor: studied_factors(:studied_factor_concentration_glucose))
    assert studied_factor_link.save!
  end

  test 'should not create studied_factor link without substance or studied_factor' do
    studied_factor_link = StudiedFactorLink.new(substance: compounds(:compound_glucose))
    assert !studied_factor_link.save
    studied_factor_link = StudiedFactorLink.new(studied_factor: studied_factors(:studied_factor_concentration_glucose))
    assert !studied_factor_link.save
  end
end
