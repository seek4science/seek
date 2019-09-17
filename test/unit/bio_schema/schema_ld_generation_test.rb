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
      '@type' => 'DataCatalogue',
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
          json = JSON.parse(Seek::BioSchema::DataCatalogueMockModel.new.to_schema_ld)
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
          '@type' => 'Project',
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
      Factory(:max_datafile, contributor: @person, projects: [@project], policy: Factory(:public_policy), doi: '10.10.10.10/test.1')
    end

    assert df.can_download?

    expected = {
      '@context' => 'http://schema.org',
      '@type' => 'DataSet',
      '@id' => "http://localhost:3000/data_files/#{df.id}",
      'name' => df.title,
      'description' => df.description,
      'keywords' => '',
      'url' => "http://localhost:3000/data_files/#{df.id}",
      'provider' => [{
        '@type' => 'Project',
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

  test 'taxon' do
    organism = Factory(:organism, bioportal_concept: Factory(:bioportal_concept))

    expected = {
        "@context"=>"http://schema.org",
        "@type"=>"Taxon",
        "@id"=>"http://localhost:3000/organisms/#{organism.id}",
        "name"=>"An Organism",
        "url"=>"http://localhost:3000/organisms/#{organism.id}",
        "sameAs"=>"http://purl.bioontology.org/ontology/NCBITAXON/2287",
        "alternateName"=>[]
    }

    json = JSON.parse(organism.to_schema_ld)
    assert_equal expected, json
  end

  test 'project' do
    @project.avatar=Factory(:avatar)
    @project.web_page="http://testing.com"
    @project.description="a lovely project"
    disable_authorization_checks { @project.save! }
    expected = {
        "@context"=>"http://schema.org",
        "@type"=>"Project",
        "@id"=>"http://localhost:3000/projects/#{@project.id}",
        "name"=>@project.title,
        "description"=>"a lovely project",
        "logo"=>"http://localhost:3000/projects/#{@project.id}/avatars/#{@project.avatar.id}?size=250",
        "url"=>@project.web_page,
        "member"=>[
            {"@type"=>"Person",
            "@id"=>"http://localhost:3000/people/#{@person.id}",
            "name"=>@person.name}
        ]
    }
    json = JSON.parse(@project.to_schema_ld)
    assert_equal expected, json

  end

end
