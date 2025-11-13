require 'test_helper'
require 'minitest/mock'

class SchemaLdGenerationTest < ActiveSupport::TestCase

  include MockHelper
  def setup
    @person = FactoryBot.create(:max_person, description: 'a lovely person')
    @project = @person.projects.first
    @current_time = Time.now.utc
  end

  test 'data catalogue' do
    ActivityLog.destroy_all
    travel_to(@current_time) do
      FactoryBot.create :activity_log, activity_loggable: FactoryBot.create(:person), action: 'create', controller_name: 'people'
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'DataCatalog',
      '@id' => 'http://fairyhub.org',
      'dct:conformsTo' => {'@id' => Seek::BioSchema::ResourceDecorators::DataCatalog::DATACATALOG_PROFILE },
      'name' => 'Sysmo SEEK',
      'url' => 'http://fairyhub.org',
      'dataset' => [
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/collections', 'name' => 'Collections' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/data_files', 'name' => 'Data files' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/documents', 'name' => 'Documents' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/events', 'name' => 'Events' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/human_diseases', 'name' => 'Human diseases' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/institutions', 'name' => 'Institutions' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/organisms', 'name' => 'Organisms' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/people', 'name' => 'People' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/presentations', 'name' => 'Presentations' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/programmes', 'name' => 'Programmes' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/projects', 'name' => 'Projects' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/samples', 'name' => 'Samples' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/workflows', 'name' => 'Workflows' }
      ],
      'description' => 'a lovely project',
      'keywords' => 'a, b, c, d',
      'provider' => {
        '@type' => 'Organization',
        'name' => 'SysMO-DB',
        'url' => 'http://www.sysmo-db.org',
        '@id' => 'http://www.sysmo-db.org'
      },
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601
    }

    with_config_value(:instance_description, 'a lovely project') do
      with_config_value(:instance_keywords, 'a,  b, ,,c,d') do
        with_config_value(:site_base_host, 'http://fairyhub.org') do
          json = JSON.parse(Seek::BioSchema::DataCatalogMockModel.new.to_schema_ld)
          assert_equal expected, json
        end
      end
    end
  end

  test 'data catalogue only contains enabled types' do
    ActivityLog.destroy_all
    travel_to(@current_time) do
      FactoryBot.create :activity_log, activity_loggable: FactoryBot.create(:person), action: 'create', controller_name: 'people'
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'DataCatalog',
      '@id' => 'http://fairyhub.org',
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::DataCatalog::DATACATALOG_PROFILE },
      'name' => 'Sysmo SEEK',
      'url' => 'http://fairyhub.org',
      'dataset' => [
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/institutions', 'name' => 'Institutions' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/people', 'name' => 'People' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/projects', 'name' => 'Projects' },
        { '@type' => 'Dataset', '@id' => 'http://fairyhub.org/workflows', 'name' => 'Workflows' }
      ],
      'description' => 'a lovely project',
      'keywords' => 'a, b, c, d',
      'provider' => {
        '@type' => 'Organization',
        'name' => 'SysMO-DB',
        'url' => 'http://www.sysmo-db.org',
        '@id' => 'http://www.sysmo-db.org'
      },
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601
    }

    with_config_values(collections_enabled: false,
                       data_files_enabled: false,
                       documents_enabled: false,
                       events_enabled: false,
                       human_diseases_enabled: false,
                       organisms_enabled: false,
                       presentations_enabled: false,
                       programmes_enabled: false,
                       samples_enabled: false,
                       instance_description: 'a lovely project',
                       instance_keywords: 'a,  b, ,,c,d',
                       site_base_host: 'http://fairyhub.org') do
      json = JSON.parse(Seek::BioSchema::DataCatalogMockModel.new.to_schema_ld)
      assert_equal expected, json
    end
  end

  test 'person' do
    @person.avatar = FactoryBot.create(:avatar)
    disable_authorization_checks { @person.save! }
    institution = @person.institutions.first
    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@id' => "http://localhost:3000/people/#{@person.id}",
      '@type' => 'Person',
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Person::PERSON_PROFILE },
      'name' => @person.name,
      'givenName' => @person.first_name,
      'familyName' => @person.last_name,
      'url' => 'http://www.website.com',
      'description' => 'a lovely person',
      'image' => "http://localhost:3000/people/#{@person.id}/avatars/#{@person.avatar.id}?size=250",
      'memberOf' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title }
      ],
      'worksFor' => [
        { '@type' => 'ResearchOrganization', '@id' => "http://localhost:3000/institutions/#{institution.id}",
          'name' => institution.title }
      ],
      'orcid' => 'https://orcid.org/0000-0001-9842-9718'
    }

    json = JSON.parse(@person.to_schema_ld)
    assert_equal expected, json
  end

  test 'data file' do
    df = travel_to(@current_time) do
      df = FactoryBot.create(:max_data_file, description: 'short desc', contributor: @person, projects: [@project],
                                   policy: FactoryBot.create(:public_policy), doi: '10.10.10.10/test.1')
      df.add_annotations('keyword', 'tag', User.first)
      disable_authorization_checks { df.save! }
      df
    end

    assert df.can_download?
    refute df.content_blob.show_as_external_link?

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Dataset',
      '@id' => "http://localhost:3000/data_files/#{df.id}",
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::DataFile::DATASET_PROFILE },
      'name' => df.title,
      'description' => df.description.ljust(50, '.'),
      'keywords' => 'keyword',
      'version' => 1,
      'url' => "http://localhost:3000/data_files/#{df.id}",
      'creator' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{df.assets_creators.first.creator_id}",
          'name' => 'Some One' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Blogs')}", 'name' => 'Blogs' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Joe')}", 'name' => 'Joe' }
      ],
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title }
      ],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'application/pdf',
      'identifier' => 'https://doi.org/10.10.10.10/test.1',
      'subjectOf' => [
        { '@type' => 'Event', '@id' => "http://localhost:3000/events/#{df.events.first.id}",
          'name' => df.events.first.title }
      ],
      'isPartOf' => [],
      'distribution' => {
        '@type' => 'DataDownload',
        'contentSize' => '8.62 KB',
        'contentUrl' => "http://localhost:3000/data_files/#{df.id}/content_blobs/#{df.content_blob.id}/download",
        'encodingFormat' => 'application/pdf',
        'name' => 'a_pdf_file.pdf'
      }
    }

    json = JSON.parse(df.to_schema_ld)
    assert_equal expected, json
    check_version(df.latest_version, expected)
  end

  test 'data file without content blob' do
    df = travel_to(@current_time) do
      df = FactoryBot.create(:max_data_file, contributor: @person, projects: [@project], policy: FactoryBot.create(:public_policy),
                                   doi: '10.10.10.10/test.1')
      df.add_annotations('keyword', 'tag', User.first)
      disable_authorization_checks do
        df.content_blob = nil
        df.save!
      end
      df
    end

    df.reload
    assert_nil df.content_blob

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Dataset',
      '@id' => "http://localhost:3000/data_files/#{df.id}",
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::DataFile::DATASET_PROFILE },
      'name' => df.title,
      'description' => df.description,
      'keywords' => 'keyword',
      'version' => 1,
      'url' => "http://localhost:3000/data_files/#{df.id}",
      'creator' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{df.assets_creators.first.creator_id}",
          'name' => 'Some One' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Blogs')}", 'name' => 'Blogs' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Joe')}", 'name' => 'Joe' }
      ],
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title }
      ],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'identifier' => 'https://doi.org/10.10.10.10/test.1',
      'isPartOf' => [],
      'subjectOf' => [
        { '@type' => 'Event', '@id' => "http://localhost:3000/events/#{df.events.first.id}",
          'name' => df.events.first.title }
      ]
    }

    json = JSON.parse(df.to_schema_ld)
    assert_equal expected, json
    check_version(df.latest_version, expected)
  end

  test 'dataset with weblink' do
    df = travel_to(@current_time) do
      df = FactoryBot.create(:max_data_file, content_blob: FactoryBot.create(:website_content_blob),
                                   contributor: @person, projects: [@project],
                                   policy: FactoryBot.create(:public_policy), doi: '10.10.10.10/test.1')
      df.add_annotations('keyword', 'tag', User.first)
      disable_authorization_checks { df.save! }
      df
    end

    assert df.can_download?
    assert df.content_blob.show_as_external_link?

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Dataset',
      '@id' => "http://localhost:3000/data_files/#{df.id}",
      'dct:conformsTo' => { '@id' => 'https://bioschemas.org/profiles/Dataset/1.0-RELEASE' },
      'name' => df.title,
      'description' => df.description,
      'keywords' => 'keyword',
      'version' => 1,
      'creator' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{df.assets_creators.first.creator_id}",
          'name' => 'Some One' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Blogs')}", 'name' => 'Blogs' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Joe')}", 'name' => 'Joe' }
      ],
      'url' => 'http://www.abc.com',
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title }
      ],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'text/html',
      'identifier' => 'https://doi.org/10.10.10.10/test.1',
      'isPartOf' => [],
      'subjectOf' => [
        { '@type' => 'Event', '@id' => "http://localhost:3000/events/#{df.events.first.id}",
          'name' => df.events.first.title }
      ]
    }

    json = JSON.parse(df.to_schema_ld)
    assert_equal expected, json
    check_version(df.latest_version, expected)
  end

  test 'project' do
    @project.avatar = FactoryBot.create(:avatar)
    @project.web_page = 'http://testing.com'
    @project.description = 'a lovely project'
    disable_authorization_checks { @project.save! }
    institution = @project.institutions.first
    event = @project.events.first
    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => %w[Project Organization],
      '@id' => "http://localhost:3000/projects/#{@project.id}",
      'name' => @project.title,
      'description' => 'a lovely project',
      'logo' => "http://localhost:3000/projects/#{@project.id}/avatars/#{@project.avatar.id}?size=250",
      'image' => "http://localhost:3000/projects/#{@project.id}/avatars/#{@project.avatar.id}?size=250",
      'url' => @project.web_page,
      'keywords' => '',
      'member' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{@person.id}", 'name' => @person.name },
        { '@type' => 'ResearchOrganization', '@id' => "http://localhost:3000/institutions/#{institution.id}",
          'name' => institution.title }
      ],
      'funder' => [],
      'event' => [
        { '@type' => 'Event', '@id' => "http://localhost:3000/events/#{event.id}", 'name' => event.title }
      ]
    }

    json = JSON.parse(@project.to_schema_ld)
    assert_equal expected, json
  end

  test 'sample' do
    sample = Sample.new(contributor: @person, projects: @person.projects, sample_type: FactoryBot.create(:schema_org_sample_type))
    sample.add_annotations('keyword', 'tag', User.first)
    sample.set_attribute_value('title', 'The Title')
    sample.set_attribute_value('description', 'The Description')
    sample.set_attribute_value('enzyme', 'EC 4.1.2.13')
    sample.set_attribute_value('weight', '88700.2')
    disable_authorization_checks { sample.save! }

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Sample',
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Sample::SAMPLE_PROFILE },
      '@id' => "http://localhost:3000/samples/#{sample.id}",
      'name' => 'The Title',
      'url' => "http://localhost:3000/samples/#{sample.id}",
      'keywords' => 'keyword',
      'additionalProperty' => [
        { '@type' => 'PropertyValue', 'name' => 'title', 'propertyId' => 'dc:title', 'value' => 'The Title' },
        { '@type' => 'PropertyValue', 'name' => 'description', 'propertyId' => 'dc:description', 'value' => 'The Description' },
        { '@type' => 'PropertyValue', 'name' => 'enzyme', 'propertyId' => 'http://purl.uniprot.org/core/enzyme', 'value' => 'EC 4.1.2.13' },
        { '@type' => 'PropertyValue', 'name' => 'weight', 'value' => '88700.2', 'unitCode' => 'g',
          'unitText' => 'gram' },
      ]
    }

    json = JSON.parse(sample.to_schema_ld)
    assert_equal expected, json
  end

  test 'event' do
    event = FactoryBot.create(:max_event, contributor: @person)
    data_file = event.data_files.first
    presentation = event.presentations.first
    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@id' => "http://localhost:3000/events/#{event.id}",
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Event::EVENT_PROFILE },
      '@type' => 'Event',
      'name' => 'A Maximal Event',
      'description' => 'All you ever wanted to know about headaches',
      'url' => "http://localhost:3000/events/#{event.id}",
      'contact' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{@person.id}", 'name' => 'Maximilian Maxi-Mum' }
      ],
      'startDate' => '2017-01-01T00:20:00Z',
      'endDate' => '2017-01-01T00:22:00Z',
      'eventType' => [],
      'location' => 'Sofienstr 2, Heidelberg, Germany',
      'hostInstitution' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{event.projects.first.id}",
          'name' => event.projects.first.title }
      ],
      'about' => [
        { '@type' => 'Dataset', '@id' => "http://localhost:3000/data_files/#{data_file.id}",
          'name' => data_file.title },
        { '@type' => 'PresentationDigitalDocument', '@id' => "http://localhost:3000/presentations/#{presentation.id}",
          'name' => presentation.title }
      ],
      'dateCreated' => event.created_at&.iso8601,
      'dateModified' => event.updated_at&.iso8601
    }

    json = JSON.parse(event.to_schema_ld)
    assert_equal expected, json
  end

  test 'document' do
    document = travel_to(@current_time) do
      document = FactoryBot.create(:document, contributor: @person, doi: '10.10.10.10/test.1')
      document.add_annotations('wibble', 'tag', User.first)
      disable_authorization_checks { document.save! }
      document
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'DigitalDocument',
      '@id' => "http://localhost:3000/documents/#{document.id}",
      'name' => 'This Document',
      'url' => "http://localhost:3000/documents/#{document.id}",
      'keywords' => 'wibble',
      'version' => 1,
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'application/pdf',
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{document.projects.first.id}",
          'name' => document.projects.first.title }
      ],
      'identifier' => 'https://doi.org/10.10.10.10/test.1',
      'isPartOf' => [],
      'subjectOf' => []
    }

    json = JSON.parse(document.to_schema_ld)
    assert_equal expected, json
    check_version(document.latest_version, expected)
  end

  test 'presentation' do
    presentation = travel_to(@current_time) do
      presentation = FactoryBot.create(:presentation, title: 'This presentation', contributor: @person)
      presentation.add_annotations('wibble', 'tag', User.first)
      disable_authorization_checks { presentation.save! }
      presentation
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'PresentationDigitalDocument',
      '@id' => "http://localhost:3000/presentations/#{presentation.id}",
      'name' => 'This presentation',
      'url' => "http://localhost:3000/presentations/#{presentation.id}",
      'keywords' => 'wibble',
      'version' => 1,
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'application/pdf',
      'producer' => [
        { '@type' => %w[Project Organization],
          '@id' => "http://localhost:3000/projects/#{presentation.projects.first.id}", 'name' => presentation.projects.first.title }
      ],
      'isPartOf' => [],
      'subjectOf' => []
    }

    json = JSON.parse(presentation.to_schema_ld)
    assert_equal expected, json
    check_version(presentation.latest_version, expected)
  end

  test 'workflow' do
    creator2 = FactoryBot.create(:person)
    workflow = travel_to(@current_time) do
      workflow = FactoryBot.create(:cwl_packed_workflow,
                         title: 'This workflow',
                         description: 'This is a test workflow for bioschema generation',
                         contributor: @person,
                         license: 'APSL-2.0', doi: '10.10.10.10/test.1')

      workflow.assets_creators.create!(creator: @person, pos: 1)
      workflow.assets_creators.create!(creator: creator2, pos: 2)
      workflow.assets_creators.create!(given_name: 'Fred', family_name: 'Bloggs', pos: 3)
      workflow.assets_creators.create!(given_name: 'Steve', family_name: 'Smith',
                                       orcid: 'https://orcid.org/0000-0002-1694-233X', pos: 4)
      workflow.assets_creators.create!(given_name: 'Bob', family_name: 'Colon:', pos: 5)

      workflow.internals = workflow.extractor.metadata[:internals]

      workflow.add_annotations('wibble', 'tag', User.first)
      disable_authorization_checks { workflow.save! }
      workflow
    end

    expected_wf_prefix = workflow.title.downcase.gsub(/[^0-9a-z]/i, '_')

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => %w[SoftwareSourceCode ComputationalWorkflow],
      '@id' => "http://localhost:3000/workflows/#{workflow.id}",
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::WORKFLOW_PROFILE },
      'description' => 'This is a test workflow for bioschema generation',
      'name' => 'This workflow',
      'url' => "http://localhost:3000/workflows/#{workflow.id}",
      'keywords' => 'wibble',
      'license' => Seek::License.find('APSL-2.0')&.url,
      'identifier' => 'https://doi.org/10.10.10.10/test.1',
      'creator' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{@person.id}", 'name' => @person.name },
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{creator2.id}", 'name' => creator2.name },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Fred Bloggs')}", 'name' => 'Fred Bloggs' },
        { '@type' => 'Person', '@id' => 'https://orcid.org/0000-0002-1694-233X', 'name' => 'Steve Smith' },
        { '@type' => 'Person', '@id' => '#Bob%20Colon:', 'name' => 'Bob Colon:' }
      ],
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title }
      ],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'application/x-yaml',
      'sdPublisher' => {
        '@type' => 'Organization',
        '@id' => Seek::Config.instance_admins_link,
        'name' => Seek::Config.instance_admins_name,
        'url' => Seek::Config.instance_admins_link
      },
      'version' => 1,
      'programmingLanguage' => {
        '@id' => '#cwl',
        '@type' => 'ComputerLanguage',
        'name' => 'Common Workflow Language',
        'alternateName' => 'CWL',
        'identifier' => { '@id' => 'https://w3id.org/cwl/v1.0/' },
        'url' => { '@id' => 'https://www.commonwl.org/' }
      },
      'isPartOf' => [],
      'input' => [
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-inputs-%23main/max-steps',
          'name' => '#main/max-steps',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE }
        },
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-inputs-%23main/reverse',
          'name' => '#main/reverse',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE }
        },
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-inputs-%23main/rulesfile',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE },
          'name' => '#main/rulesfile'
        },
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-inputs-%23main/sinkfile',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE },
          'name' => '#main/sinkfile'
        },
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-inputs-%23main/sourcefile',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE },
          'name' => '#main/sourcefile'
        }
      ],
      'output' => [
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-outputs-%23main/compounds',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE },
          'name' => '#main/compounds'
        },
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-outputs-%23main/reactions',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE },
          'name' => '#main/reactions'
        },
        {
          '@type' => 'FormalParameter',
          '@id' => '#this_workflow-outputs-%23main/sinks',
          'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Workflow::FORMALPARAMETER_PROFILE },
          'name' => '#main/sinks'
        }
      ]
    }

    json = JSON.parse(workflow.to_schema_ld)
    fine_json_comparison expected, json
    assert_equal expected, json
    check_version(workflow.latest_version, expected)
  end

  test 'collection' do
    collection = travel_to(@current_time) do
      collection = FactoryBot.create(:max_collection)
      disable_authorization_checks { collection.save! }
      collection
    end

    project = collection.projects.first
    sel_assets = []
    collection.assets.each do |a|
      next if a.blank?
      next unless a.schema_org_supported?
      next if a.respond_to?(:public?) && !a.public?

      sel_assets << a
    end

    doc1 = sel_assets[0]
    df1 = sel_assets[1]
    df2 = sel_assets[2]

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Collection',
      '@id' => "http://localhost:3000/collections/#{collection.id}",
      'description' => 'A collection of very interesting things',
      'name' => 'A Maximal Collection',
      'url' => "http://localhost:3000/collections/#{collection.id}",
      'keywords' => 'Collection-tag1, Collection-tag2, Collection-tag3, Collection-tag4, Collection-tag5',
      'creator' => [
        { '@type' => 'Person',
          '@id' => "http://localhost:3000/people/#{collection.assets_creators.first.creator_id}",
          'name' => 'Some One' },
        { '@type' => 'Person',
          '@id' => '#Joe%20Bloggs',
          'name' => 'Joe Bloggs' }
      ],
      'producer' => [
        { '@type' => %w[Project Organization],
          '@id' => "http://localhost:3000/projects/#{project.id}",
          'name' => project.title.to_s }
      ],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'isPartOf' => [],
      'hasPart' => [
        { '@type' => 'DigitalDocument', '@id' => "http://localhost:3000/documents/#{doc1.id}",
          'name' => doc1.title.to_s },
        { '@type' => 'Dataset', '@id' => "http://localhost:3000/data_files/#{df1.id}", 'name' => df1.title.to_s },
        { '@type' => 'Dataset', '@id' => "http://localhost:3000/data_files/#{df2.id}", 'name' => df2.title.to_s }
      ]
    }

    json = JSON.parse(collection.to_schema_ld)
    assert_equal expected, json
  end

  test 'human_disease' do
    human_disease = travel_to(@current_time) do
      human_disease = FactoryBot.create(:max_human_disease)
      disable_authorization_checks { human_disease.save! }
      human_disease
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Taxon',
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::HumanDisease::TAXON_PROFILE },
      '@id' => "http://localhost:3000/human_diseases/#{human_disease.id}",
      'name' => 'A Maximal Human Disease',
      'url' => "http://localhost:3000/human_diseases/#{human_disease.id}",
      'alternateName' => [],
      'sameAs' => 'http://purl.bioontology.org/ontology/NCBITAXON/1909'
    }

    json = JSON.parse(human_disease.to_schema_ld)
    assert_equal expected, json
  end

  test 'institution' do
    institution = VCR.use_cassette('ror/max_institution') do
      travel_to(@current_time) do
        institution = FactoryBot.create(:max_institution)
        disable_authorization_checks { institution.save! }
        institution
      end
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'ResearchOrganization',
      '@id' => "http://localhost:3000/institutions/#{institution.id}",
      'name'=>'University of Manchester',
      'department'=>{'@type'=>'Organization', 'name'=>'Manchester Institute of Biotechnology'},
      'url' => 'http://www.manchester.ac.uk/',
      'identifier' => 'https://ror.org/027m9bs27',
      'address'=>{'@type'=>'PostalAddress','addressCountry'=>'GB', 'addressLocality'=>'Manchester', 'streetAddress'=>'Manchester Centre for Integrative Systems Biology, MIB/CEAS, The University of Manchester Faraday Building, Sackville Street, Manchester M60 1QD United Kingdom'}
    }

    json = JSON.parse(institution.to_schema_ld)
    assert_equal expected, json

    # check without ror_id and department
    institution.update_columns(department:'', ror_id:nil)
    json = JSON.parse(institution.to_schema_ld)
    expected.delete('department')
    expected.delete('identifier')
    assert_equal expected, json
  end

  test 'organism' do
    organism = travel_to(@current_time) do
      organism = FactoryBot.create(:max_organism)
      disable_authorization_checks { organism.save! }
      organism
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Taxon',
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Organism::TAXON_PROFILE },
      '@id' => "http://localhost:3000/organisms/#{organism.id}",
      'name' => 'A Maximal Organism',
      'url' => "http://localhost:3000/organisms/#{organism.id}",
      'alternateName' => [],
      'sameAs' => 'http://purl.bioontology.org/ontology/NCBITAXON/9606'
    }

    json = JSON.parse(organism.to_schema_ld)
    assert_equal expected, json
  end

  test 'programme' do
    programme = travel_to(@current_time) do
      programme = FactoryBot.create(:max_programme)
      disable_authorization_checks { programme.save! }
      programme
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'FundingScheme',
      '@id' => "http://localhost:3000/programmes/#{programme.id}",
      'description' => 'A very exciting programme',
      'name' => 'A Maximal Programme',
      'url' => 'http://www.synbiochem.co.uk'
    }

    json = JSON.parse(programme.to_schema_ld)
    assert_equal expected, json
  end

  test 'version of data file' do
    df = travel_to(@current_time) do
      df = FactoryBot.create(:max_data_file, description: 'version 1 description', title: 'version 1 title',
                                   contributor: @person, projects: [@project], policy: FactoryBot.create(:public_policy), doi: '10.10.10.10/test.1')
      df.add_annotations('keyword', 'tag', User.first)
      disable_authorization_checks do
        df.save!
        df.save_as_new_version
        df.update(description: 'version 2 description', title: 'version 2 title')
        FactoryBot.create(:image_content_blob, asset: df, asset_version: 2)
        df.latest_version.update_column(:doi, '10.10.10.10/test.2')
      end
      df
    end

    assert df.can_download?
    refute df.content_blob.show_as_external_link?

    v1_expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Dataset',
      '@id' => "http://localhost:3000/data_files/#{df.id}?version=1",
      'dct:conformsTo' => {'@id' => Seek::BioSchema::ResourceDecorators::DataFile::DATASET_PROFILE },
      'name' => 'version 1 title',
      'description' => 'version 1 description'.ljust(50, '.'),
      'keywords' => 'keyword',
      'url' => "http://localhost:3000/data_files/#{df.id}?version=1",
      'creator' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{df.assets_creators.first.creator_id}",
          'name' => 'Some One' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Blogs')}", 'name' => 'Blogs' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Joe')}", 'name' => 'Joe' }
      ],
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title }
      ],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'application/pdf',
      'version' => 1,
      'isPartOf' => [],
      # 'identifier' => 'https://doi.org/10.10.10.10/test.1', # Should not have a DOI, since it was defined on the parent resource
      'subjectOf' => [
        { '@type' => 'Event', '@id' => "http://localhost:3000/events/#{df.events.first.id}",
          'name' => df.events.first.title }
      ],
      'distribution' => {
        '@type' => 'DataDownload',
        'contentSize' => '8.62 KB',
        'contentUrl' => "http://localhost:3000/data_files/#{df.id}/content_blobs/#{df.find_version(1).content_blob.id}/download",
        'encodingFormat' => 'application/pdf',
        'name' => 'a_pdf_file.pdf'
      }
    }

    v2_expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Dataset',
      '@id' => "http://localhost:3000/data_files/#{df.id}?version=2",
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::DataFile::DATASET_PROFILE },
      'name' => 'version 2 title',
      'description' => 'version 2 description'.ljust(50, '.'),
      'keywords' => 'keyword',
      'url' => "http://localhost:3000/data_files/#{df.id}?version=2",
      'creator' => [
        { '@type' => 'Person', '@id' => "http://localhost:3000/people/#{df.assets_creators.first.creator_id}",
          'name' => 'Some One' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Blogs')}", 'name' => 'Blogs' },
        { '@type' => 'Person', '@id' => "##{ROCrate::Entity.format_id('Joe')}", 'name' => 'Joe' }
      ],
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title }
      ],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'image/png',
      'version' => 2,
      'isPartOf' => [],
      'identifier' => 'https://doi.org/10.10.10.10/test.2', # This DOI was added to the version itself
      'isBasedOn' => "http://localhost:3000/data_files/#{df.id}?version=1",
      'subjectOf' => [
        { '@type' => 'Event', '@id' => "http://localhost:3000/events/#{df.events.first.id}",
          'name' => df.events.first.title }
      ],
      'distribution' => {
        '@type' => 'DataDownload',
        'contentSize' => '2.66 KB',
        'contentUrl' => "http://localhost:3000/data_files/#{df.id}/content_blobs/#{df.find_version(2).content_blob.id}/download",
        'encodingFormat' => 'image/png',
        'name' => 'image_file.png'
      }
    }

    json = JSON.parse(df.find_version(1).to_schema_ld)
    assert_equal v1_expected, json
    json = JSON.parse(df.find_version(2).to_schema_ld)
    assert_equal v2_expected, json
  end

  test 'dataset without data dump' do
    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Dataset',
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Dataset::DATASET_PROFILE },
      '@id' => 'http://localhost:3000/workflows',
      'description' => 'Workflows in Sysmo SEEK.',
      'name' => 'Workflows',
      'url' => 'http://localhost:3000/workflows',
      'keywords' => [],
      'license' => 'https://spdx.org/licenses/CC0-1.0',
      'creator' => [{'@type' => 'Organization',
                     '@id' => 'http://www.sysmo-db.org',
                     'name' => 'SysMO-DB',
                     'url' => 'http://www.sysmo-db.org'}],
      'includedInDataCatalog' => {'@id' => 'http://localhost:3000'}
    }

    resource = Seek::BioSchema::Dataset.new(Workflow)
    dump = Workflow.public_schema_ld_dump
    refute dump.exists?
    with_config_value(:metadata_license, 'CC0-1.0') do
      json = JSON.parse(resource.to_schema_ld)
      assert_equal expected, json
    end
  end

  test 'dataset with data dump' do
    Workflow.delete_all
    FactoryBot.create(:public_workflow)
    FactoryBot.create(:workflow)
    dump = Workflow.public_schema_ld_dump
    dump.write
    size = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.new(dump.size, {}).convert

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'Dataset',
      'dct:conformsTo' => { '@id' => Seek::BioSchema::ResourceDecorators::Dataset::DATASET_PROFILE },
      '@id' => 'http://localhost:3000/workflows',
      'description' => 'Workflows in Sysmo SEEK.',
      'name' => 'Workflows',
      'url' => 'http://localhost:3000/workflows',
      'keywords' => [],
      'license' => 'https://spdx.org/licenses/CC-BY-4.0',
      'creator' => [{ '@type' => 'Organization',
                      '@id' => 'http://www.sysmo-db.org',
                      'name' => 'SysMO-DB',
                      'url' => 'http://www.sysmo-db.org' }],
      'distribution' => { '@type' => 'DataDownload',
                          'contentSize' => size,
                          'contentUrl' => 'http://localhost:3000/workflows.jsonld?dump=true',
                          'encodingFormat' => 'application/ld+json',
                          'name' => 'workflows-bioschemas-dump.jsonld',
                          'description' => 'A collection of public Workflows in Sysmo SEEK, serialized as an array of JSON-LD objects conforming to Bioschemas profiles.',
                          'dateModified' => @current_time.iso8601 },
      'includedInDataCatalog' => { '@id' => 'http://localhost:3000' }
    }

    File.stub(:mtime, @current_time) do
      resource = Seek::BioSchema::Dataset.new(Workflow)
      assert dump.exists?
      json = JSON.parse(resource.to_schema_ld)
      assert_equal expected, json
    end
  end

  test 'sop' do
    sop = travel_to(@current_time) do
      sop = FactoryBot.create(:max_sop)
      disable_authorization_checks { sop.save! }
      sop
    end

    expected = {
      '@context' => Seek::BioSchema::Serializer::SCHEMA_ORG,
      '@type' => 'LabProtocol',
      '@id' => "http://localhost:3000/sops/#{sop.id}",
      'description' => 'How to run a simulation in GROMACS',
      'name' => 'A Maximal Sop',
      'url' => "http://localhost:3000/sops/#{sop.id}",
      'keywords' => 'Sop-tag1, Sop-tag2, Sop-tag3, Sop-tag4, Sop-tag5',
      'version' => 1,
      'creator' => [{ '@type' => 'Person', '@id' => "http://localhost:3000/people/#{sop.assets_creators.first.creator_id}", 'name' => 'Some One' },
                    { '@type' => 'Person', '@id' => '#Blogs', 'name' => 'Blogs' },
                    { '@type' => 'Person', '@id' => '#Joe', 'name' => 'Joe' }],
      'producer' => [{ '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{sop.projects.first.id}", 'name' => 'A Maximal Project' }],
      'dateCreated' => @current_time.iso8601,
      'dateModified' => @current_time.iso8601,
      'encodingFormat' => 'application/pdf',
      'isPartOf' => [],
      'computationalTool' => [{ '@type' => %w[SoftwareSourceCode ComputationalWorkflow], '@id' => "http://localhost:3000/workflows/#{sop.workflows.first.id}", 'name' => 'This Workflow' }]
    }

    json = JSON.parse(sop.to_schema_ld)
    assert_equal expected, json
  end

  private

  def check_version(version, expected)
    json = JSON.parse(version.to_schema_ld)
    expected['@id'] += "?version=#{version.version}"
    expected['url'] += "?version=#{version.version}" if expected['url'].include?(Seek::Config.site_base_host)
    expected.delete('identifier') unless version.respond_to?(:doi) && version.doi.present?
    fine_json_comparison expected, json
    assert_equal expected, json
  end

  def fine_json_comparison(expected, json)
    expected.each { |k, v| assert_equal v, json[k], "mismatch with key #{k}" }
    json.each { |k, v| assert_equal v, expected[k], "mismatch with key #{k}" }
  end
end
