require 'test_helper'

class ObservationUnitTest < ActiveSupport::TestCase

  test 'max factory' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    refute_nil obs_unit.created_at
    refute_nil obs_unit.updated_at
    refute_empty obs_unit.projects
    refute_empty obs_unit.creators
    refute_nil obs_unit.other_creators
    refute_nil obs_unit.extended_metadata
    refute_nil obs_unit.extended_metadata.extended_metadata_type
    refute_nil obs_unit.study
    refute_empty obs_unit.study.observation_units
    refute_empty obs_unit.samples
    refute_empty obs_unit.data_files
  end


  test 'to rdf' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    assert obs_unit.rdf_supported?
    rdf = obs_unit.to_rdf
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(rdf) {|reader| graph << reader}
    end
    assert graph.statements.count > 1
    assert_equal RDF::URI.new("http://localhost:3000/observation_units/#{obs_unit.id}"), graph.statements.first.subject
    type = graph.statements.detect{|s| s.predicate == RDF.type}
    assert_equal RDF::URI('http://purl.org/ppeo/PPEO.owl#observation_unit'), type.object

  end

  test 'policy' do
    obs_unit = FactoryBot.create(:observation_unit)
    contributor = obs_unit.contributor
    person2 = FactoryBot.create(:person)
    refute_nil obs_unit.policy

    assert obs_unit.can_manage?(contributor)

    obs_unit.policy = FactoryBot.create(:public_policy)
    assert obs_unit.can_view?(nil)
    assert obs_unit.can_view?(contributor)
    assert obs_unit.can_view?(person2)

    obs_unit.policy = FactoryBot.create(:private_policy)
    refute obs_unit.can_view?(nil)
    assert obs_unit.can_view?(contributor)
    refute obs_unit.can_view?(person2)
  end

  test 'can destroy' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    refute_empty obs_unit.data_files
    assert_difference('ObservationUnit.count', -1) do
      assert_difference('ObservationUnitAsset.count', -3) do
        assert_difference('ExtendedMetadata.count', -1) do
          assert_difference('AssetsCreator.count', -1) do
            assert_difference('Policy.count', -1) do
              User.with_current_user(obs_unit.contributor) do
                obs_unit.destroy
              end
            end
          end
        end
      end
    end
  end

  test 'validation' do
    obs_unit = FactoryBot.build(:observation_unit)
    assert obs_unit.valid?

    obs_unit.title = ''
    refute obs_unit.valid?

    obs_unit = FactoryBot.build(:observation_unit)
    obs_unit.study = nil
    refute obs_unit.valid?
  end

  test 'assays, studies, investigations' do
    contributor = FactoryBot.create(:person)
    assay = FactoryBot.create(:experimental_assay, contributor: contributor)
    study = assay.study
    sample = FactoryBot.create(:sample, assays: [assay], contributor: contributor)
    obs_unit = FactoryBot.create(:observation_unit, study: study, samples: [sample], contributor: contributor)

    assert_equal [assay], sample.assays
    assert_equal [assay], obs_unit.related_assays
    assert_equal study, obs_unit.study
    assert_equal study.investigation, obs_unit.investigation

    # observation unit without an assay
    obs_unit = FactoryBot.create(:observation_unit, study: study)
    assert_empty obs_unit.related_assays
    assert_equal study, obs_unit.study
    assert_equal study.investigation, obs_unit.investigation

    # doesn't have these
    refute obs_unit.respond_to?(:studies)
    refute obs_unit.respond_to?(:investigations)

  end

  test 'validate study matches with assay' do
    obs_unit = FactoryBot.create(:observation_unit)
    assert obs_unit.valid?

    assay = FactoryBot.create(:experimental_assay, contributor: obs_unit.contributor)
    sample = FactoryBot.create(:sample, assays: [assay], contributor: obs_unit.contributor)
    refute_equal obs_unit.study, assay.study
    obs_unit.samples << sample
    disable_authorization_checks { obs_unit.samples << sample }
    assert_equal 1, obs_unit.samples.size
    refute obs_unit.valid?
    assert_equal 'Study must match the associated assay', obs_unit.errors.full_messages.first

    obs_unit = FactoryBot.create(:observation_unit, samples: [sample], study: assay.study, contributor: assay.contributor)
    assert_equal obs_unit.study, assay.study
    assert obs_unit.valid?
  end

  test 'must be member of study project' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    project = person.projects.first
    inv = FactoryBot.create(:investigation, projects:[project])
    study = FactoryBot.create(:study, investigation: inv, contributor: person, policy: FactoryBot.create(:public_policy))
    obs_unit = FactoryBot.build(:observation_unit, study: study)
    User.with_current_user(person.user) do
      assert obs_unit.valid?
      assert obs_unit.save
    end

    obs_unit = FactoryBot.build(:observation_unit, study: study)
    User.with_current_user(other_person.user) do
      refute obs_unit.valid?
      refute obs_unit.save
    end




  end

end