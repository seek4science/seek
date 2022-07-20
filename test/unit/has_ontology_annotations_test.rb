require 'test_helper'

class HasOntologyAnnotationsTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper

  def setup
    @person = Factory(:person)
    User.current_user = @person.user
    @workflow = Factory(:workflow, contributor: @person)
  end

  def teardown
    User.current_user = nil
  end

  test 'supports ontology annotations' do
    assert @workflow.supports_ontology_annotations?
    refute Factory(:institution).supports_ontology_annotations?
  end

  test 'annotate with label' do
    Factory(:topics_controlled_vocab)
    Factory(:operations_controlled_vocab)

    refute @workflow.ontology_annotations?

    # mixture of arrays and comma separated, including an unknown one
    @workflow.topic_annotations = ['Chemistry', 'Sample collections', 'Unknown']
    @workflow.operation_annotations = 'Correlation, Clustering, Unknown'

    assert_difference('Annotation.count', 4) do
      assert @workflow.save
    end

    assert_equal ['http://edamontology.org/topic_3314', 'http://edamontology.org/topic_3277'], @workflow.topic_annotations
    assert_equal ['http://edamontology.org/operation_3465', 'http://edamontology.org/operation_3432'],
                 @workflow.operation_annotations

    assert_equal ['Chemistry', 'Sample collections'], @workflow.topic_annotation_labels
    assert_equal %w[Correlation Clustering], @workflow.operation_annotation_labels

    assert @workflow.ontology_annotations?
  end

  test 'annotate with iri' do
    Factory(:topics_controlled_vocab)
    Factory(:operations_controlled_vocab)

    refute @workflow.ontology_annotations?

    @workflow.topic_annotations = ['http://edamontology.org/topic_3314', 'http://edamontology.org/topic_3277']
    @workflow.operation_annotations = 'http://edamontology.org/operation_3465, http://edamontology.org/operation_3432'

    assert_difference('Annotation.count', 4) do
      assert @workflow.save
    end

    assert_equal ['http://edamontology.org/topic_3314', 'http://edamontology.org/topic_3277'], @workflow.topic_annotations
    assert_equal ['http://edamontology.org/operation_3465', 'http://edamontology.org/operation_3432'],
                 @workflow.operation_annotations

    assert_equal ['Chemistry', 'Sample collections'], @workflow.topic_annotation_labels
    assert_equal %w[Correlation Clustering], @workflow.operation_annotation_labels

    assert @workflow.ontology_annotations?
  end

  test 'ontology annotation vocab present' do
    refute @workflow.send(:ontology_annotation_vocab, :topics)
    refute @workflow.send(:ontology_annotation_vocab, :operations)

    topics_vocab = Factory(:topics_controlled_vocab)
    operations_vocab = Factory(:operations_controlled_vocab)

    assert_equal topics_vocab, @workflow.send(:ontology_annotation_vocab, :topics)
    assert_equal operations_vocab, @workflow.send(:ontology_annotation_vocab, :operations)
  end
end
