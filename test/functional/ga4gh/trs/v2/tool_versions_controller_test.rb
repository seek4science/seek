require 'test_helper'
module Ga4gh
  module Trs
    module V2
      class ToolVersionsControllerTest < ActionController::TestCase
        include AuthenticatedTestHelper
        fixtures :users, :people

        test 'should list workflow versions as tool versions' do
          workflow = FactoryBot.create(:workflow, policy: FactoryBot.create(:public_policy))
          disable_authorization_checks do
            workflow.save_as_new_version
            workflow.save_as_new_version
          end
          assert 3, workflow.reload.versions.count

          get :index, params: { id: workflow.id }

          assert_response :success
          ids = JSON.parse(@response.body).map { |t| t['id'] }
          assert_includes ids, '1'
          assert_includes ids, '2'
          assert_includes ids, '3'
        end

        test 'should get workflow version as tool version' do
          workflow = FactoryBot.create(:workflow, policy: FactoryBot.create(:publicly_viewable_policy))
          assert 1, workflow.reload.versions.count

          get :show, params: { id: workflow.id, version_id: 1 }

          assert_response :success
        end

        test 'should 404 for private tool version' do
          workflow = FactoryBot.create(:workflow, policy: FactoryBot.create(:private_policy))
          assert 1, workflow.reload.versions.count

          get :show, params: { id: workflow.id, version_id: 1 }

          assert_response :not_found
        end

        test 'should 404 for non-existent tool version' do
          workflow = FactoryBot.create(:workflow, policy: FactoryBot.create(:public_policy))
          assert 1, workflow.reload.versions.count

          get :show, params: { id: workflow.id, version_id: 1337 }

          assert_response :not_found
        end

        test 'should list tool version files for correct descriptor' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 5, r.length
          galaxy = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga' }
          diagram = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg' }
          assert galaxy
          assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
          assert diagram
          assert_equal 'OTHER', diagram['file_type']
        end

        test 'should get zip of all files' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY', format: 'zip' }

          assert_response :success
          assert_equal 'application/zip', @response.headers['Content-Type']

          Dir.mktmpdir do |dir|
            t = Tempfile.new('the.crate.zip')
            t.binmode
            t << response.body
            t.close
            crate = ROCrate::WorkflowCrateReader.read_zip(t.path, target_dir: dir)
            assert crate.main_workflow
          end
        end

        test 'should not list tool version files for wrong descriptor' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'NFL' }

          assert_response :not_found
        end

        test 'should not list tool version files for private tool' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:private_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :not_found
        end

        test 'should not list tool version files for non-downloadable tool' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:publicly_viewable_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :not_found
          r = JSON.parse(@response.body)
          assert r['message'].include?('authorized')
        end

        test 'should get main workflow as primary descriptor' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :success
          assert @response.body.include?('a_galaxy_workflow')
        end

        test 'should get descriptor file via relative path' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY', relative_path: 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga' }

          assert_response :success
          assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
          assert @response.body.include?('a_galaxy_workflow')
        end

        test 'should get nested descriptor file via relative path' do
          workflow = FactoryBot.create(:nf_core_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'NFL', relative_path: 'docs/images/nfcore-ampliseq_logo.png' }, format: :text

          assert_response :success
          assert_equal 'text/plain; charset=utf-8', @response.headers['Content-Type']
          assert @response.body.start_with?("\x89PNG\r\n")
        end

        test 'should get plain descriptor file via relative path' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'PLAIN_GALAXY', relative_path: 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg' }

          assert_response :success
          assert_equal "text/plain; charset=utf-8", @response.headers['Content-Type']
          assert @response.body.start_with?('<?xml version="1')
        end

        test 'should 404 on descriptor for private tool' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:private_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :not_found
          refute @response.body.include?('a_galaxy_workflow')
        end

        test 'should 404 on descriptor for non-downloadable tool' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:publicly_viewable_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :not_found
          refute @response.body.include?('a_galaxy_workflow')
          r = JSON.parse(@response.body)
          assert r['message'].include?('authorized')
        end

        test 'should 404 on missing descriptor file via relative path' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY', relative_path: '../..' }

          assert_response :not_found
        end

        test 'should 404 on missing descriptor file via relative path as text' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'PLAIN_GALAXY', relative_path: '../..' }, format: :text

          assert_response :not_found
          assert response.body.include?('404')
          assert response.body.include?('found')
        end

        test 'should get containerfile if Dockerfile present' do
          workflow = FactoryBot.create(:nf_core_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'NFL' }

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 32, r.length
          main_wf = r.detect { |f| f['path'] == 'main.nf' }
          dockerfile = r.detect { |f| f['path'] == 'Dockerfile' }
          config = r.detect { |f| f['path'] == 'nextflow.config' }
          deep_file = r.detect { |f| f['path'] == 'docs/images/nfcore-ampliseq_logo.png' }
          assert main_wf
          assert_equal 'PRIMARY_DESCRIPTOR', main_wf['file_type']
          assert dockerfile
          assert_equal 'CONTAINERFILE', dockerfile['file_type']
          assert config
          assert_equal 'OTHER', config['file_type']
          assert deep_file
          assert_equal 'OTHER', deep_file['file_type']

          get :containerfile, params: { id: workflow.id, version_id: 1 }

          assert_response :success
          assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
          r = JSON.parse(@response.body)
          assert r.first['content'].include?('matplotlib')

          get :containerfile, params: { id: workflow.id, version_id: 1 }, format: :text

          assert_response :success
          assert_equal 'text/plain; charset=utf-8', @response.headers['Content-Type']
          assert @response.body.start_with?('FROM nfcore/base:1.7')
        end

        test 'should 404 if no containerfile' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :containerfile, params: { id: workflow.id, version_id: 1 }

          assert_response :not_found
          r = JSON.parse(@response.body)
          assert r['message'].include?('No container')
        end

        test 'should 404 for containerfile of non-downloadable tool' do
          workflow = FactoryBot.create(:nf_core_ro_crate_workflow, policy: FactoryBot.create(:publicly_viewable_policy))

          get :containerfile, params: { id: workflow.id, version_id: 1 }

          assert_response :not_found
          r = JSON.parse(@response.body)
          assert r['message'].include?('authorized')
        end

        test 'should return empty array if no tests' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :tests, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          r = JSON.parse(@response.body)
          assert_equal [], r
        end

        test 'should return 404 when accessing tests of non-downloadable tool' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:publicly_viewable_policy))

          get :tests, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :not_found
          r = JSON.parse(@response.body)
          assert r['message'].include?('authorized')
        end

        test 'should list tool version files for given version' do
          workflow = FactoryBot.create(:generated_galaxy_ro_crate_workflow, policy: FactoryBot.create(:public_policy))
          disable_authorization_checks do
            workflow.save_as_new_version
            FactoryBot.create(:generated_galaxy_no_diagram_ro_crate, asset: workflow, asset_version: 2)
          end

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 5, r.length
          galaxy = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga' }
          diagram = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg' }
          assert galaxy
          assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
          assert diagram
          assert_equal 'OTHER', diagram['file_type']

          get :files, params: { id: workflow.id, version_id: 2, type: 'GALAXY' }

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 5, r.length
          galaxy = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.ga' }
          orig_diagram = r.detect { |f| f['path'] == 'Genomics-1-PreProcessing_without_downloading_from_SRA.svg' }
          generated_diagram = r.detect { |f| f['path'] == "workflow-#{workflow.id}-2-diagram.svg" }
          assert galaxy
          assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
          refute orig_diagram
          assert generated_diagram
          assert_equal 'OTHER', generated_diagram['file_type']
        end

        # Git
        test 'should list tool version files for correct descriptor on git workflow' do
          workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:public_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 6, r.length
          galaxy = r.detect { |f| f['path'] == 'concat_two_files.ga' }
          diagram = r.detect { |f| f['path'] == 'diagram.png' }
          assert galaxy
          assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
          assert diagram
          assert_equal 'OTHER', diagram['file_type']
        end

        test 'should get main workflow as primary descriptor on git workflow' do
          workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :success
          assert @response.body.include?('a_galaxy_workflow')
        end

        test 'should not get primary descriptor for non-downloadable tool' do
          workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:publicly_viewable_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :not_found
          r = JSON.parse(@response.body)
          assert r['message'].include?('authorized')
        end

        test 'should get descriptor file via relative path on git workflow' do
          workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY', relative_path: 'concat_two_files.ga' }

          assert_response :success
          assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
          assert @response.body.include?('a_galaxy_workflow')
        end

        test 'should not get descriptor via relative path for non-downloadable tool' do
          workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:publicly_viewable_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY', relative_path: 'concat_two_files.ga' }

          assert_response :not_found
          r = JSON.parse(@response.body)
          assert r['message'].include?('authorized')
        end

        test 'should list tool version files for correct version on git workflow' do
          workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:public_policy))
          disable_authorization_checks do
            s = workflow.save_as_new_git_version(
              ref: 'refs/tags/v0.01',
              git_repository_id: workflow.git_version.git_repository_id,
              main_workflow_path: 'concat_two_files.ga'
            )
            assert s
          end

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 6, r.length
          galaxy = r.detect { |f| f['path'] == 'concat_two_files.ga' }
          diagram = r.detect { |f| f['path'] == 'diagram.png' }
          assert galaxy
          assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
          assert diagram
          assert_equal 'OTHER', diagram['file_type']

          get :files, params: { id: workflow.id, version_id: 2, type: 'GALAXY' }

          assert_response :success
          r = JSON.parse(@response.body)
          assert_equal 4, r.length
          galaxy = r.detect { |f| f['path'] == 'concat_two_files.ga' }
          diagram = r.detect { |f| f['path'] == 'diagram.png' }
          assert galaxy
          assert_equal 'PRIMARY_DESCRIPTOR', galaxy['file_type']
          refute diagram
        end

        test 'should work with snakemake' do
          workflow = FactoryBot.create(:workflow, workflow_class: FactoryBot.create(:unextractable_workflow_class, key: 'snakemake', title: 'Snakemake'), policy: FactoryBot.create(:public_policy))

          get :files, params: { id: workflow.id, version_id: 1, type: 'SMK' }

          assert_response :success
        end

        test 'should get descriptor containing URL for binary file' do
          workflow = FactoryBot.create(:nf_core_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'NFL', relative_path: 'docs/images/nfcore-ampliseq_logo.png' }, format: :json

          assert_response :success
          assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
          h = JSON.parse(@response.body)
          assert_nil h['content']
          assert_equal "http://localhost:3000/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/PLAIN_NFL/descriptor/docs/images/nfcore-ampliseq_logo.png", h['url']
        end

        test 'should get raw descriptor for binary file' do
          workflow = FactoryBot.create(:nf_core_ro_crate_workflow, policy: FactoryBot.create(:public_policy))

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'PLAIN_NFL', relative_path: 'docs/images/nfcore-ampliseq_logo.png' }
          assert_response :success
          assert_equal 'PNG', @response.body.force_encoding('ASCII-8BIT')[1..3]
        end

        test 'should get descriptor containing URL for binary file on git workflow' do
          workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
          disable_authorization_checks do
            c = workflow.git_version.add_file('dir/binary.bin', StringIO.new(SecureRandom.random_bytes(50)))
            workflow.git_version.update_column(:commit, c)
          end

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY', relative_path: 'dir/binary.bin' }

          assert_response :success
          assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
          h = JSON.parse(@response.body)
          assert_nil h['content']
          assert_equal "http://localhost:3000/ga4gh/trs/v2/tools/#{workflow.id}/versions/1/PLAIN_GALAXY/descriptor/dir/binary.bin", h['url']
        end

        test 'should get raw descriptor for binary file on git workflow' do
          bytes = SecureRandom.random_bytes(20)
          workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
          disable_authorization_checks do
            c = workflow.git_version.add_file('binary.bin', StringIO.new(bytes))
            workflow.git_version.update_column(:commit, c)
          end

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'PLAIN_GALAXY', relative_path: 'binary.bin' }
          assert_response :success
          assert_equal bytes, @response.body.force_encoding('ASCII-8BIT')
        end

        test 'should get file list for workflow with missing main workflow' do
          workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
          disable_authorization_checks do
            v = workflow.git_version
            v.remove_file('concat_two_files.ga')
            v.save!
          end

          get :files, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :success
          r = JSON.parse(@response.body)
          refute r.detect { |f| f['path'] == 'concat_two_files.ga' }
          refute r.detect { |f| f['file_type'] == 'PRIMARY_DESCRIPTOR' }
        end

        test 'should 404 on descriptor for workflow with missing main workflow' do
          workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
          disable_authorization_checks do
            v = workflow.git_version
            v.remove_file('concat_two_files.ga')
            v.save!
          end

          get :descriptor, params: { id: workflow.id, version_id: 1, type: 'GALAXY' }

          assert_response :not_found
        end

        test 'should serialize JSON for file with non-ASCII characters' do
          workflow = FactoryBot.create(:nfcore_git_workflow, policy: FactoryBot.create(:public_policy))
          gv = workflow.git_version
          gv.update_column(:mutable, true)
          gv.add_file('non-ascii.cwl', StringIO.new("# Non-ASCII stuff ↳ 🐈"))
          # Needed because "special" files in repo are serialized differently in RO-Crate/TRS response
          gv.abstract_cwl_path = 'non-ascii.cwl'
          disable_authorization_checks { gv.save! }

          assert_nothing_raised do
            get :descriptor, params: { id: workflow.id, version_id: 1, type: 'NFL', relative_path: 'non-ascii.cwl' },
                format: :json
          end

          assert_response :success
          assert_equal 'application/json; charset=utf-8', @response.headers['Content-Type']
          assert @response.body.include?("# Non-ASCII stuff ↳ 🐈")
        end
      end
    end
  end
end
