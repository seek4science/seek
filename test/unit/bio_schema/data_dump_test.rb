require 'test_helper'

class DataDumpTest < ActiveSupport::TestCase
  fixtures :all

  test 'can write dump and access via file object' do
    dump = create_workflow_dump
    assert_raises(Errno::ENOENT) do
      dump.file
    end

    dump.write
    file = dump.file

    assert file
    json = JSON.parse(dump.file.read)
    assert_equal @workflows.length, json.length
    @workflows.each do |workflow|
      bioschemas = json.detect { |w| w['@id'] == "http://localhost:3000/workflows/#{workflow.id}"}
      assert bioschemas
      assert_equal "http://localhost:3000/workflows/#{workflow.id}", bioschemas['@id']
      assert_equal workflow.title, bioschemas['name']
    end
    @private_workflows.each do |workflow|
      bioschemas = json.detect { |w| w['@id'] == "http://localhost:3000/workflows/#{workflow.id}"}
      refute bioschemas, 'Should not include private resources'
    end
  end

  test 'can overwrite existing dump' do
    dump = create_workflow_dump
    dump.write
    assert dump.exists?
    old_size = dump.size
    old_length = dump.bioschemas.length
    file_path = dump.file.path

    new_workflow = FactoryBot.create(:public_workflow, title: 'New workflow!')
    updated_dump = Seek::BioSchema::DataDump.new(Workflow)
    updated_dump.write

    assert updated_dump.exists?
    assert_equal file_path, updated_dump.file.path
    assert updated_dump.size > old_size
    assert_equal old_length + 1, updated_dump.bioschemas.length

    json = JSON.parse(updated_dump.file.read)
    assert_equal old_length + 1, json.length
    @workflows.each do |workflow|
      # Remove the original workflows from the JSON
      i = json.index { |w| w['@id'] == "http://localhost:3000/workflows/#{workflow.id}"}
      bioschemas = json.delete_at(i)
      assert bioschemas
      assert_equal "http://localhost:3000/workflows/#{workflow.id}", bioschemas['@id']
      assert_equal workflow.title, bioschemas['name']
    end

    # New workflow should be the one left
    assert_equal 1, json.length
    assert_equal "http://localhost:3000/workflows/#{new_workflow.id}", json[0]['@id']
    assert_equal 'New workflow!', json[0]['name']
  end

  test 'can access bioschemas array from dump' do
    dump = create_workflow_dump

    array = dump.bioschemas

    assert_equal @workflows.length, array.length
    @workflows.each do |workflow|
      bioschemas = array.detect { |w| w['url'] == "http://localhost:3000/workflows/#{workflow.id}"}
      assert bioschemas
      assert_equal "http://localhost:3000/workflows/#{workflow.id}", bioschemas['@id']
      assert_equal workflow.title, bioschemas['name']
    end
    @private_workflows.each do |workflow|
      bioschemas = array.detect { |w| w['url'] == "http://localhost:3000/workflows/#{workflow.id}"}
      refute bioschemas, 'Should not include private resources'
    end
  end

  test 'can iterate bioschemas from dump' do
    dump = create_workflow_dump

    count = 0
    dump.bioschemas do |bioschemas|
      workflow = @workflows.detect { |w| w.id == bioschemas['@id'].split('/').last.to_i }
      assert workflow
      assert_equal bioschemas['name'], workflow.title
      count += 1
    end
    assert_equal @workflows.length, count
  end

  test 'can read dump metadata' do
    dump = create_workflow_dump
    dump.write

    assert_equal 'workflows-bioschemas-dump.jsonld', dump.file_name
    assert dump.exists?
    assert_in_delta 3800, dump.size, 500
    assert_in_delta Time.now, dump.date_modified, 60
  end

  test 'can read dump metadata even if file does not yet exist' do
    dump = create_workflow_dump

    assert_equal 'workflows-bioschemas-dump.jsonld', dump.file_name
    refute dump.exists?
    assert_nil dump.size
    assert_nil dump.date_modified
  end

  test 'can generate dumps for all types' do
    Seek::Util.clear_cached
    types = Seek::Util.searchable_types.select(&:schema_org_supported?)
    assert types.length > 3
    types.each do |type|
      refute Seek::BioSchema::DataDump.new(type).exists?
      if type.method_defined?(:policy=)
        public_resource = FactoryBot.create(type.name.underscore.to_sym, policy: FactoryBot.create(:public_policy))
        private_resource = FactoryBot.create(type.name.underscore.to_sym, policy: FactoryBot.create(:private_policy))
      else
        resource = FactoryBot.create(type.name.underscore.to_sym)
      end
    end

    dumps = Seek::BioSchema::DataDump.generate_dumps

    assert_equal dumps.length, types.length
    types.each do |type|
      dump = dumps.detect { |d| d.name == type.model_name.plural }
      assert dump.exists?
      assert dump.size > 1
      json = JSON.parse(dump.file.read)
      assert json.any?
      json.each do |i|
        id = i['@id'].split('/').last
        item = type.find_by_id(id)
        assert item, "#{type.name} #{id} included in dump but does not exist!"
        assert !item.respond_to?(:public?) || item.public?, "#{type.name} #{id} included in dump even though it is not public!"
      end

    end
  end

  test 'can generate dump for single type' do
    type = Workflow
    refute Seek::BioSchema::DataDump.new(type).exists?

    d = Seek::BioSchema::DataDump.generate_dump(type)

    assert d.exists?
    assert d.size > 1
  end

  private

  def create_workflow_dump
    Workflow.delete_all
    @workflows = FactoryBot.create_list(:public_workflow, 3)
    @private_workflows = [FactoryBot.create(:workflow, policy: FactoryBot.create(:private_policy)),
                          FactoryBot.create(:workflow, policy: FactoryBot.create(:all_sysmo_viewable_policy))]

    Seek::BioSchema::DataDump.new(Workflow)
  end
end
