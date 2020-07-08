require 'test_helper'

class SchemaLdGenerationTest < ActiveSupport::TestCase

  def setup
    @person = Factory(:max_person, description: 'a lovely person')
    @project = @person.projects.first
    @current_time = Time.now.utc
  end

  test 'data catalogue' do
    ActivityLog.destroy_all
    travel_to(@current_time) do
      Factory :activity_log, activity_loggable: Factory(:person), action: 'create', controller_name: 'people'
    end

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'DataCatalog',
      'name' => 'Sysmo',
      'url' => 'http://fairyhub.org',
      'description' => 'a lovely project',
      'keywords' => 'a, b, c, d',
      'provider' => {
        '@type' => 'Organization',
        'name' => 'SysMO-DB',
        'url' => 'http://www.sysmo-db.org'
      },
      'dateCreated' => @current_time.to_s
    }
    with_config_value(:project_description, 'a lovely project') do
      with_config_value(:project_keywords, 'a,  b, ,,c,d') do
        with_config_value(:site_base_host, 'http://fairyhub.org') do
          json = JSON.parse(Seek::BioSchema::DataCatalogMockModel.new.to_schema_ld)
          assert_equal expected, json
        end
      end
    end
  end

  test 'person' do
    @person.avatar = Factory(:avatar)
    disable_authorization_checks { @person.save! }
    expected = {
      '@context' => 'http://schema.org',
      '@id' => "http://localhost:3000/people/#{@person.id}",
      '@type' => 'Person',
      'name' => @person.name,
      'givenName' => @person.first_name,
      'familyName' => @person.last_name,
      'url' => 'http://www.website.com',
      'description' => 'a lovely person',
      'image' => "http://localhost:3000/people/#{@person.id}/avatars/#{@person.avatar.id}?size=250",
      'memberOf' => [
        {
          '@type' => %w[Project Organization],
          '@id' => "http://localhost:3000/projects/#{@project.id}",
          'name' => @project.title
        }
      ],
      'orcid' => 'https://orcid.org/0000-0001-9842-9718'
    }

    json = JSON.parse(@person.to_schema_ld)
    assert_equal expected, json
  end

  test 'dataset' do
    df = travel_to(@current_time) do
      df = Factory(:max_data_file, contributor: @person, projects: [@project], policy: Factory(:public_policy), doi: '10.10.10.10/test.1')
      df.add_annotations('keyword', 'tag', User.first)
      disable_authorization_checks { df.save! }
      df
    end

    assert df.can_download?
    refute df.content_blob.show_as_external_link?

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'DataSet',
      '@id' => "http://localhost:3000/data_files/#{df.id}",
      'name' => df.title,
      'description' => df.description,
      'keywords' => 'keyword',
      'creator' => [{ '@type' => 'Person', 'name' => 'Blogs' }, { '@type' => 'Person', 'name' => 'Joe' }],
      'url' => "http://localhost:3000/data_files/#{df.id}",
      'producer' => [{
        '@type' => %w[Project Organization],
        '@id' => "http://localhost:3000/projects/#{@project.id}",
        'name' => @project.title
      }],
      'dateCreated' => @current_time.to_s,
      'dateModified' => @current_time.to_s,
      'encodingFormat' => 'application/pdf',
      'identifier' => 'https://doi.org/10.10.10.10/test.1',
      'subjectOf' => [
        { '@type' => 'Event',
          '@id' => "http://localhost:3000/events/#{df.events.first.id}",
          'name' => df.events.first.title }
      ],
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
  end

  test 'dataset with weblink' do
    df = travel_to(@current_time) do
      df = Factory(:max_data_file, content_blob: Factory(:website_content_blob),
                                  contributor: @person, projects: [@project],
                                  policy: Factory(:public_policy), doi: '10.10.10.10/test.1')
      df.add_annotations('keyword', 'tag', User.first)
      disable_authorization_checks { df.save! }
      df
    end

    assert df.can_download?
    assert df.content_blob.show_as_external_link?

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'DataSet',
      '@id' => "http://localhost:3000/data_files/#{df.id}",
      'name' => df.title,
      'description' => df.description,
      'keywords' => 'keyword',
      'creator' => [{ '@type' => 'Person', 'name' => 'Blogs' }, { '@type' => 'Person', 'name' => 'Joe' }],
      'url' => 'http://www.abc.com',
      'producer' => [{
        '@type' => %w[Project Organization],
        '@id' => "http://localhost:3000/projects/#{@project.id}",
        'name' => @project.title
      }],
      'dateCreated' => @current_time.to_s,
      'dateModified' => @current_time.to_s,
      'encodingFormat' => 'text/html',
      'identifier' => 'https://doi.org/10.10.10.10/test.1',
      'subjectOf' => [
        { '@type' => 'Event',
          '@id' => "http://localhost:3000/events/#{df.events.first.id}",
          'name' => df.events.first.title }
      ]
    }

    json = JSON.parse(df.to_schema_ld)
    assert_equal expected, json
  end

  test 'taxon' do
    organism = Factory(:organism, bioportal_concept: Factory(:bioportal_concept))

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'Taxon',
      '@id' => "http://localhost:3000/organisms/#{organism.id}",
      'name' => 'An Organism',
      'url' => "http://localhost:3000/organisms/#{organism.id}",
      'sameAs' => 'http://purl.bioontology.org/ontology/NCBITAXON/2287',
      'alternateName' => []
    }

    json = JSON.parse(organism.to_schema_ld)
    assert_equal expected, json
  end

  test 'project' do
    @project.avatar = Factory(:avatar)
    @project.web_page = 'http://testing.com'
    @project.description = 'a lovely project'
    disable_authorization_checks { @project.save! }
    expected = {
      '@context' => 'http://schema.org',
      '@type' => %w[Project Organization],
      '@id' => "http://localhost:3000/projects/#{@project.id}",
      'name' => @project.title,
      'description' => 'a lovely project',
      'logo' => "http://localhost:3000/projects/#{@project.id}/avatars/#{@project.avatar.id}?size=250",
      'url' => @project.web_page,
      'member' => [
        { '@type' => 'Person',
          '@id' => "http://localhost:3000/people/#{@person.id}",
          'name' => @person.name }
      ]
    }
    json = JSON.parse(@project.to_schema_ld)
    assert_equal expected, json
  end

  test 'sample' do
    sample = Factory(:patient_sample, contributor: @person)
    sample.add_annotations('keyword', 'tag', User.first)
    sample.set_attribute_value('postcode', 'M13 4PP')
    sample.set_attribute_value('weight', '88700.2')
    disable_authorization_checks { sample.save! }

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'Sample',
      '@id' => "http://localhost:3000/samples/#{sample.id}",
      'name' => 'Fred Bloggs',
      'url' => "http://localhost:3000/samples/#{sample.id}",
      'keywords' => 'keyword',
      'additionalProperty' => [
        { '@type' => 'PropertyValue', 'name' => 'full name', 'value' => 'Fred Bloggs' },
        { '@type' => 'PropertyValue', 'name' => 'age', 'value' => '44' },
        { '@type' => 'PropertyValue', 'name' => 'weight', 'value' => '88700.2', 'unitCode' => 'g', 'unitText' => 'gram' },
        { '@type' => 'PropertyValue', 'name' => 'address', 'value' => '' },
        { '@type' => 'PropertyValue', 'name' => 'postcode', 'value' => 'M13 4PP' }
      ]
    }
    json = JSON.parse(sample.to_schema_ld)
    assert_equal expected, json
  end

  test 'event' do
    event = Factory(:max_event, contributor: @person)
    expected = {
      '@context' => 'http://schema.org',
      '@id' => "http://localhost:3000/events/#{event.id}",
      '@type' => 'Event',
      'name' => 'A Maximal Event',
      'description' => 'All you ever wanted to know about headaches',
      'url' => "http://localhost:3000/events/#{event.id}",
      'contact' => [{
        '@type' => 'Person',
        '@id' => "http://localhost:3000/people/#{@person.id}",
        'name' => 'Maximilian Maxi-Mum'
      }],
      'startDate' => '2017-01-01 00:20:00 UTC',
      'endDate' => '2017-01-01 00:22:00 UTC',
      'eventType' => [],
      'location' => 'Sofienstr 2, Heidelberg, Germany',
      'hostInstitution' => [
        {
          '@type' => %w[Project Organization],
          '@id' => "http://localhost:3000/projects/#{event.projects.first.id}",
          'name' => event.projects.first.title
        }
      ]
    }
    json = JSON.parse(event.to_schema_ld)
    assert_equal expected, json
  end

  test 'document' do
    document = travel_to(@current_time) do
      document = Factory(:document, contributor: @person)
      document.add_annotations('wibble', 'tag', User.first)
      disable_authorization_checks { document.save! }
      document
    end

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'DigitalDocument',
      '@id' => "http://localhost:3000/documents/#{document.id}",
      'name' => 'This Document',
      'url' => "http://localhost:3000/documents/#{document.id}",
      'keywords' => 'wibble',
      'dateCreated' => @current_time.to_s,
      'dateModified' => @current_time.to_s,
      'encodingFormat' => 'application/pdf',
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{document.projects.first.id}", 'name' => document.projects.first.title }
      ]
    }

    json = JSON.parse(document.to_schema_ld)
    assert_equal expected, json
  end

  test 'presentation' do
    presentation = travel_to(@current_time) do
      presentation = Factory(:presentation, title: 'This presentation', contributor: @person)
      presentation.add_annotations('wibble', 'tag', User.first)
      disable_authorization_checks { presentation.save! }
      presentation
    end

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'PresentationDigitalDocument',
      '@id' => "http://localhost:3000/presentations/#{presentation.id}",
      'name' => 'This presentation',
      'url' => "http://localhost:3000/presentations/#{presentation.id}",
      'keywords' => 'wibble',
      'dateCreated' => @current_time.to_s,
      'dateModified' => @current_time.to_s,
      'encodingFormat' => 'application/pdf',
      'producer' => [
        { '@type' => %w[Project Organization], '@id' => "http://localhost:3000/projects/#{presentation.projects.first.id}", 'name' => presentation.projects.first.title }
      ]
    }

    json = JSON.parse(presentation.to_schema_ld)
    assert_equal expected, json
  end

  test 'workflow' do
    creator2 = Factory(:person)
    workflow = travel_to(@current_time) do
      workflow = Factory(:cwl_packed_workflow,
                         title: 'This workflow',
                         description: 'This is a test workflow for bioschema generation',
                         creators: [@person, creator2],
                         other_creators: 'Fred Bloggs, Steve Smith',
                         contributor: @person,
                         license: 'APSL-2.0')

      workflow.internals = workflow.extractor.metadata[:internals]

      workflow.add_annotations('wibble', 'tag', User.first)
      disable_authorization_checks { workflow.save! }
      workflow
    end

    expected = { '@context' => 'http://schema.org',
                 '@type' => 'Workflow',
                 '@id' => "http://localhost:3000/workflows/#{workflow.id}",
                 'description' => 'This is a test workflow for bioschema generation',
                 'name' => 'This workflow',
                 'url' => "http://localhost:3000/workflows/#{workflow.id}",
                 'keywords' => 'wibble',
                 'license' => 'https://opensource.org/licenses/APSL-2.0',
                 'creator' =>
                    [{ '@type' => 'Person',
                       '@id' => "http://localhost:3000/people/#{@person.id}",
                       'name' => @person.name },
                     { '@type' => 'Person',
                       '@id' => "http://localhost:3000/people/#{creator2.id}",
                       'name' => creator2.name },
                     { '@type' => 'Person',
                       'name' => 'Fred Bloggs' },
                     { '@type' => 'Person',
                       'name' => 'Steve Smith' }],
                 'producer' =>
                    [{ '@type' => %w[Project Organization],
                       '@id' => "http://localhost:3000/projects/#{@project.id}",
                       'name' => @project.title }],
                 'dateCreated' => @current_time.to_s,
                 'dateModified' => @current_time.to_s,
                 'encodingFormat' => 'application/x-yaml',
                 'sdPublisher' =>
                    [{ '@type' => 'Person',
                       '@id' => "http://localhost:3000/people/#{@person.id}",
                       'name' => @person.name }],
                 'version' => 1,
                 'programmingLanguage' => 'CWL workflow',
                 'inputs' => [
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.cofsfile' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.dmax' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.dmin' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.max-steps' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.mwmax-cof' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.mwmax-source' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.rulesfile' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.sinkfile' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.sourcefile' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.std_mode' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.stereo_mode' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/input.topx' }
                 ],
                 'outputs' => [
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/solutionfile' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/sourceinsinkfile' },
                   { '@type' => 'PropertyValueSpecification',
                     'name' => '#main/stdout' }
                 ] }

    json = JSON.parse(workflow.to_schema_ld)
    assert_equal expected, json
  end
end
