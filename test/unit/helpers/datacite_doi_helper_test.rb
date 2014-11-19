require 'test_helper'

class DataciteDoiHelperTest < ActionView::TestCase
  test 'generate_doi_for' do
    doi = '10.5072/Sysmo.SEEK.DataFile.1.1'
    generating_doi = generate_doi_for 'DataFile', 1, 1
    assert_equal doi, generating_doi
  end

end