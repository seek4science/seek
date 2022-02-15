require 'test_helper'

class HasEdamAnnotationsTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper

  def setup
    @person = Factory(:person)
    User.current_user = @person.user
    @workflow = Factory(:workflow, contributor: @person)
  end

  def teardown
    User.current_user = nil
  end

  test 'supports edam annotations' do
    assert @workflow.supports_edam_annotations?
    refute Factory(:institution).supports_edam_annotations?
  end

  test 'annotate with label' do
    Factory(:edam_topics_controlled_vocab)
    Factory(:edam_operations_controlled_vocab)

    refute @workflow.edam_annotations?

    # mixture of arrays and comma separated, including an unknown one
    @workflow.edam_topics = ['Chemistry', 'Sample collections', 'Unknown']
    @workflow.edam_operations = 'Correlation, Clustering, Unknown'

    assert_difference('Annotation.count', 4) do
      assert @workflow.save
    end

    assert_equal ['http://edamontology.org/topic_3314', 'http://edamontology.org/topic_3277'], @workflow.edam_topics
    assert_equal ['http://edamontology.org/operation_3465', 'http://edamontology.org/operation_3432'],
                 @workflow.edam_operations

    assert_equal ['Chemistry', 'Sample collections'], @workflow.edam_topic_labels
    assert_equal %w[Correlation Clustering], @workflow.edam_operation_labels

    assert @workflow.edam_annotations?
  end

  test 'annotate with iri' do
    Factory(:edam_topics_controlled_vocab)
    Factory(:edam_operations_controlled_vocab)

    refute @workflow.edam_annotations?

    @workflow.edam_topics = ['http://edamontology.org/topic_3314', 'http://edamontology.org/topic_3277']
    @workflow.edam_operations = 'http://edamontology.org/operation_3465, http://edamontology.org/operation_3432'

    assert_difference('Annotation.count', 4) do
      assert @workflow.save
    end

    assert_equal ['http://edamontology.org/topic_3314', 'http://edamontology.org/topic_3277'], @workflow.edam_topics
    assert_equal ['http://edamontology.org/operation_3465', 'http://edamontology.org/operation_3432'],
                 @workflow.edam_operations

    assert_equal ['Chemistry', 'Sample collections'], @workflow.edam_topic_labels
    assert_equal %w[Correlation Clustering], @workflow.edam_operation_labels

    assert @workflow.edam_annotations?
  end

  test 'edam vocab present' do
    refute @workflow.edam_topics_vocab
    refute @workflow.edam_operations_vocab

    topics_vocab = Factory(:edam_topics_controlled_vocab)
    operations_vocab = Factory(:edam_operations_controlled_vocab)

    assert_equal topics_vocab, @workflow.edam_topics_vocab
    assert_equal operations_vocab, @workflow.edam_operations_vocab
  end
end
