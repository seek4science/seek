class TemplatesController < ApplicationController
  respond_to :html

  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :isa_json_compliance_enabled?
  before_action :find_assets, only: [:index]
  before_action :auth_to_create, only: %i[new create]
  before_action :find_and_authorize_requested_item, only: %i[manage manage_update show edit destroy update]

  before_action :login_required, only: %i[populate_template task_status set_status default_templates]
  before_action :is_user_admin_auth, only: %i[populate_template task_status set_status default_templates]
  before_action :set_status, only: %i[show task_status]

  def show
    respond_to do |format|
      format.html
      format.json { render json: @template }
    end
  end

  def default_templates
    set_status
    respond_to do |format|
      format.html
    end
  end

  def new
    @tab = 'manual'
    @template = setup_new_asset
    @template.organism = 'any'
    respond_with(@template)
  end

  def create
    @template = Template.new(template_params)
    update_sharing_policies @template
    @template.contributor = User.current_user.person

    @tab = 'manual'

    respond_to do |format|
      if @template.save
        format.html { redirect_to @template, notice: 'Template was successfully created.' }
        format.json { render json: @template, include: [params[:include]] }
      else
        format.html { render new_template_path(@template), status: :unprocessable_entity }
        format.json { render json: @template.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to(&:html)
  end

  def update
    @template.update(template_params)
    @template.resolve_inconsistencies

    respond_to do |format|
      if @template.save
        format.html { redirect_to @template, notice: 'Template was successfully updated.' }
        format.json { render json: @template, include: [params[:include]] }
      else
        format.html { render action: :edit, status: :unprocessable_entity }
        format.json { render json: @template.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @template.can_delete? && @template.destroy
        format.html { redirect_to @template, location: templates_path, notice: 'Template was successfully deleted.' }
      else
        format.html do
          redirect_to @template, location: templates_path, notice: 'It was not possible to delete the template.'
        end
      end
    end
  end

  def manage; end

  def task_status
    render partial: 'result'
  end

  def populate_template
    uploaded_file = params[:template_json_file]
    dir = Seek::Config.append_filestore_path('source_types')

    if Dir.exist?(dir)
      `rm #{dir}/*`
    else
      FileUtils.mkdir_p(dir)
    end

    File.open(Rails.root.join(dir, uploaded_file.original_filename), 'wb') do |file|
      file.write(uploaded_file.read)
    end

    return if running?

    begin
      running!
      PopulateTemplatesJob.new.queue_job
    rescue StandardError
      done!
    end
  end

  # post
  def template_attributes
    template = Template.find(params[:id])
    items = template.template_attributes.map { |a| { id: a.id, title: a.title } }
    respond_to do |format|
      format.json { render json: items.to_json }
    end
  end

  def filter_isa_tags_by_level
    level = params[:level]
    all_isa_tags_options = IsaTag.all.map { |it| { text: it.title, value: it.id } }

    case level
    when 'study source'
      isa_tags_options = all_isa_tags_options.select { |tag| %w[source source_characteristic].include?(tag[:text]) }
    when 'study sample'
      isa_tags_options = all_isa_tags_options.select do |tag|
        %w[protocol sample sample_characteristic parameter_value].include?(tag[:text])
      end
    when 'assay - material'
      isa_tags_options = all_isa_tags_options.select do |tag|
        %w[protocol other_material other_material_characteristic parameter_value].include?(tag[:text])
      end
    when 'assay - data file'
      isa_tags_options = all_isa_tags_options.select do |tag|
        %w[protocol data_file data_file_comment parameter_value].include?(tag[:text])
      end
    else
      isa_tags_options = all_isa_tags_options
    end

    puts "ISA Tags: #{isa_tags_options}"
    render json: { result: isa_tags_options }
  end

  private

  def template_params
    params.require(:template).permit(:title, :description, :group, :level, :organism, :pid, :version, :parent_id, *creator_related_params,
                                     { project_ids: [],
                                       template_attributes_attributes: %i[id title pos required description
                                                                          sample_attribute_type_id isa_tag_id is_title
                                                                          sample_controlled_vocab_id pid
                                                                          unit_id _destroy allow_cv_free_text
                                                                          linked_sample_type_id] })
  end

  def find_template
    @template = Template.find(params[:id])
  end

  def set_status
    if File.exist?(lockfile)
      @status = 'working'
    elsif File.exist?(resultfile)
      res = File.read(resultfile)
      @status = res
      `rm #{resultfile}`
    else
      @status = 'not_started'
    end
  end

  def lockfile
    Rails.root.join(Seek::Config.temporary_filestore_path, 'populate_templates.lock')
  end

  def resultfile
    Rails.root.join(Seek::Config.temporary_filestore_path, 'populate_templates.result')
  end

  def running!
    `touch #{lockfile}`
    set_status
  end

  def done!
    `rm -f #{lockfile}`
  end

  def running?
    File.exist?(lockfile)
  end
end
