require 'test_helper'

class SparqlHelperTest < ActionView::TestCase
  test 'an IRI is shown within <> and linked' do
    html = Nokogiri::HTML.fragment(sparql_result_value(RDF::URI('https://example.com/thing')))
    span = html.at_css('span.sparql-iri')
    assert_equal '<https://example.com/thing>', span.text
    assert_equal 'IRI (node)', span['title']
    assert_equal 'https://example.com/thing', span.at_css('a.external-link')['href']
  end

  test 'an IRI that is not an http URL is not linked' do
    span = Nokogiri::HTML.fragment(sparql_result_value(RDF::URI('urn:example:thing'))).at_css('span.sparql-iri')
    assert_equal '<urn:example:thing>', span.text
    assert_nil span.at_css('a')
  end

  test 'a blank node is shown with its label' do
    span = Nokogiri::HTML.fragment(sparql_result_value(RDF::Node('b1'))).at_css('span.sparql-bnode')
    assert_equal '_:b1', span.text
    assert_equal 'Blank node', span['title']
  end

  test 'a literal is shown as its value, and linked without <> if it is a URL' do
    span = Nokogiri::HTML.fragment(sparql_result_value(RDF::Literal('a name'))).at_css('span.sparql-literal')
    assert_equal 'a name', span.text
    assert_equal 'Literal', span['title']
    assert_nil span.at_css('a')

    span = Nokogiri::HTML.fragment(sparql_result_value(RDF::Literal('https://example.com/thing')))
                   .at_css('span.sparql-literal')
    assert_equal 'https://example.com/thing', span.text
    assert_equal 'https://example.com/thing', span.at_css('a.external-link')['href']
  end

  test "a literal's title gives its language or datatype" do
    assert_equal 'Literal (@en)', literal_title(RDF::Literal('a name', language: :en))
    assert_equal 'Literal (xsd:integer)', literal_title(RDF::Literal(3))
  end

  test 'a plain value, such as the result of an ASK query, is shown as a literal' do
    span = Nokogiri::HTML.fragment(sparql_result_value('true')).at_css('span.sparql-literal')
    assert_equal 'true', span.text
  end

  private

  def literal_title(literal)
    Nokogiri::HTML.fragment(sparql_result_value(literal)).at_css('span.sparql-literal')['title']
  end
end
