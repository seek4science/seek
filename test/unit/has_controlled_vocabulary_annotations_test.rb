require 'test_helper'

class HasControlledVocabularyAnnotationsTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper

  def setup
    @person = FactoryBot.create(:person)
    User.current_user = @person.user
    @workflow = FactoryBot.create(:workflow, contributor: @person)
  end

  def teardown
    User.current_user = nil
  end

  test 'supports controlled vocab annotations' do
    assert @workflow.supports_controlled_vocab_annotations?
    refute FactoryBot.create(:institution).supports_controlled_vocab_annotations?
  end

  test 'annotate with label' do
    FactoryBot.create(:topics_controlled_vocab)
    FactoryBot.create(:operations_controlled_vocab)

    refute @workflow.controlled_vocab_annotations?

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

    assert @workflow.controlled_vocab_annotations?
  end

  test 'annotate with iri' do
    FactoryBot.create(:topics_controlled_vocab)
    FactoryBot.create(:operations_controlled_vocab)

    refute @workflow.controlled_vocab_annotations?

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

    assert @workflow.controlled_vocab_annotations?
  end

  test 'annotation controlled vocab present' do
    refute @workflow.annotation_controlled_vocab(:topics)
    refute @workflow.annotation_controlled_vocab(:operations)

    topics_vocab = FactoryBot.create(:topics_controlled_vocab)
    operations_vocab = FactoryBot.create(:operations_controlled_vocab)

    assert_equal topics_vocab, @workflow.annotation_controlled_vocab(:topics)
    assert_equal operations_vocab, @workflow.annotation_controlled_vocab(:operations)
  end
end
