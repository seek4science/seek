require 'test_helper'


#tests that are general to the ontology reader base class, rather than specific to the assay, modelling anaylsis, and technology type sub-classes
class OntologyReaderTest < ActiveSupport::TestCase

  test "handles a uri to ontology" do
    class URIOntologyReader < Seek::Ontologies::OntologyReader

      def default_parent_class_uri
        RDF::URI.new("http://www.mygrid.org.uk/ontology/JERMOntology#informatics_analysis_type")
      end

      def ontology_file
        "https://raw.github.com/SysMO-DB/JERMOntology/eb70107ecb1e0a5f7d26dc968e176bf4f782834d/JERM_alpha1.6.rdf"
      end
    end

    WebMock.allow_net_connect!

    reader = URIOntologyReader.new
    assert_not_nil reader.ontology
    assert_equal 1360,reader.ontology.count
    classes = reader.class_hierarchy
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#informatics_analysis_type",classes.uri.to_s
    assert_equal 2,classes.subclasses.count
    assert_equal 1,classes.subclasses.select{|c| c.uri.fragment=="Bioinformatics_analysis"}.count
  end


end