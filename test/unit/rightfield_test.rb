require 'test_helper'
require 'libxml'

class RightFieldTest < ActiveSupport::TestCase

  include RightField

  test "rdf generation" do
    df=Factory :rightfield_annotated_datafile
    assert_not_nil(df.content_blob)
    rdf = generate_rdf(df)
    assert_not_nil(rdf)
    f=Tempfile.new("rdf")
    f.write(rdf)
    f.flush

    #just checks it is valid rdf/xml and contains some statements for now
    RDF::RDFXML::Reader.open(f.path) do |reader|
      assert_equal 3,reader.statements.count
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
      reader.each_statement do |statement|
        puts statement.inspect
      end
    end
  end

end