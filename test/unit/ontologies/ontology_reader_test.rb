require 'test_helper'

# tests that are general to the ontology reader base class, rather than specific to the assay, modelling anaylsis, and technology type sub-classes
class OntologyReaderTest < ActiveSupport::TestCase
  setup do
    stub_request(:get, 'https://somewhere.on.the.web.org/JERM2-alpha-2.1.rdf').to_return(
      body: File.new("#{Rails.root}/test/fixtures/files/JERM2-alpha-2.1.rdf"),
      status: 200)
  end

  test 'handles a uri to ontology' do
    class URIOntologyReader < Seek::Ontologies::OntologyReader
      def default_parent_class_uri
        RDF::URI.new('http://jermontology.org/ontology/JERMOntology#informatics_analysis_type')
      end

      def ontology_file
        'https://somewhere.on.the.web.org/JERM2-alpha-2.1.rdf'
      end
    end

    reader = URIOntologyReader.instance
    assert_not_nil reader.ontology
    assert_equal 1438, reader.ontology.count
    classes = reader.class_hierarchy
    assert_equal 'http://jermontology.org/ontology/JERMOntology#informatics_analysis_type', classes.uri.to_s
    assert_equal 2, classes.subclasses.count
    assert_equal 1, classes.subclasses.count { |c| c.uri.fragment == 'Bioinformatics_analysis' }
  end

  test 'picks up description' do
    class DescOntologyReader < Seek::Ontologies::OntologyReader
      def default_parent_class_uri
        RDF::URI.new('http://jermontology.org/ontology/JERMOntology#2-hybrid_system')
      end

      def ontology_file
        "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      end
    end

    reader = DescOntologyReader.instance
    assert_not_nil reader.ontology
    classes = reader.class_hierarchy
    assert_equal 'http://jermontology.org/ontology/JERMOntology#2-hybrid_system', classes.uri.to_s
    refute_nil classes.description
    assert classes.description.start_with?('Two-hybrid screening')
  end

  test 'picks up label' do
    class LabelOntologyReader < Seek::Ontologies::OntologyReader
      def default_parent_class_uri
        RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Progressive_curve_experiment')
      end

      def ontology_file
        "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      end
    end

    reader = LabelOntologyReader.instance
    assert_not_nil reader.ontology
    classes = reader.class_hierarchy
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Progressive_curve_experiment', classes.uri.to_s
    refute_nil classes.label
    assert_equal 'Prog Rock', classes.label
  end

  test 'subclasses must implement default_parent_class_uri method' do
    class SubOntologyReader < Seek::Ontologies::OntologyReader
      def ontology_file
        'https://somewhere.on.the.web.org/JERM2-alpha-2.1.rdf'
      end
    end
    reader = SubOntologyReader.instance
    begin
      reader.class_hierarchy
    rescue NotImplementedError => error
      assert !error.nil?
    end
  end

  test 'subclasses must implement ontology file method' do
    class SubOntologyReader < Seek::Ontologies::OntologyReader
      def default_parent_class_uri
        RDF::URI.new('http://jermontology.org/ontology/JERMOntology#Progressive_curve_experiment')
      end
    end
    reader = SubOntologyReader.instance
    begin
      reader.class_hierarchy
    rescue NotImplementedError => error
      assert error.present?
    end
  end
end
