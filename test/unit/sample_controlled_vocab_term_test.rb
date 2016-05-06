require 'test_helper'

class SampleControlledVocabTermTest < ActiveSupport::TestCase

  test 'validation' do
    term = SampleControlledVocabTerm.new
    refute term.valid?
    term.label='fish'
    assert term.valid?
  end

end
