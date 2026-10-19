require 'test_helper'

class HelpDocumentTest < ActiveSupport::TestCase

  test 'redcloth markup working' do
    doc = help_documents(:example)
    assert doc.body_html.start_with?('<p><em>')
  end
end
