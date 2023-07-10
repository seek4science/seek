require 'test_helper'

class GitRepoExtractionTest < ActiveSupport::TestCase
  test 'extracts metadata from CFF' do
    workflow = FactoryBot.create(:remote_git_workflow)

    gv = disable_authorization_checks do
      x = workflow.latest_git_version.next_version(name: 'cff', ref: 'refs/remotes/origin/cff',
                                                   commit: 'bd67097c20eade0e20d796246fbf4dbaedaf4534')

      x.save!
      x
    end

    extractor = Seek::WorkflowExtractors::GitRepo.new(gv)
    metadata = extractor.metadata

    assert_equal "Title from CFF", metadata[:title]
    assert_equal "MIT", metadata[:license]
    assert_equal "10.5072/test", metadata[:doi]
    assert_equal "https://github.com/seek4science/workflow-test-fixture", metadata[:source_link_url]

    author_meta = metadata[:assets_creators_attributes].values
    assert_equal 3, author_meta.length

    first = author_meta.detect { |a| a[:given_name] == 'First' }
    assert first
    assert_equal 'Author', first[:family_name]
    assert_equal 'University of Somewhere', first[:affiliation]
    assert_equal 'https://orcid.org/0000-0002-1825-0097', first[:orcid]
    assert_equal 0, first[:pos]

    second = author_meta.detect { |a| a[:given_name] == 'Second' }
    assert second
    assert_equal 'Author', second[:family_name]
    assert_equal 'University of Somewhere Else', second[:affiliation]
    assert 'https://orcid.org/0000-0001-5109-3700', second[:orcid]
    assert_equal 1, second[:pos]

    third = author_meta.detect { |a| a[:given_name] == 'Someone' }
    assert third
    assert_equal 'Else', third[:family_name]
    assert_equal 'University of Somewhere', third[:affiliation]
    assert third[:orcid].blank?
    assert_equal 2, third[:pos]
  end

  test 'extracts license from LICENSE file' do
    workflow = FactoryBot.create(:local_git_workflow)
    git_version = workflow.git_version
    disable_authorization_checks do
      git_version.add_file('LICENSE', open_fixture_file('MIT-LICENSE'))
      git_version.save!
    end

    extractor = Seek::WorkflowExtractors::GitRepo.new(workflow.git_version)
    metadata = extractor.metadata

    assert_equal 'MIT', metadata[:license]

    git_version = workflow.git_version
    disable_authorization_checks do
      git_version.add_file('LICENSE', open_fixture_file('BSD-LICENSE'))
      git_version.save!
    end

    extractor = Seek::WorkflowExtractors::GitRepo.new(workflow.git_version)
    metadata = extractor.metadata

    assert_equal 'BSD-3-Clause', metadata[:license]
  end
end
