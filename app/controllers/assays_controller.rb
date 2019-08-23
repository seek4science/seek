class AssaysController < ApplicationController

  include Seek::IndexPager
  include Seek::AssetsCommon

  before_action :assays_enabled?

  before_action :find_assets, :only=>[:index]
  before_action :find_and_authorize_requested_item, :only=>[:edit, :update, :destroy, :manage, :manage_update, :show, :new_object_based_on_existing_one]

  #project_membership_required_appended is an alias to project_membership_required, but is necessary to include the actions
  #defined in the application controller
  before_action :project_membership_required_appended, :only=>[:new_object_based_on_existing_one]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  include Seek::IsaGraphExtensions

  def new_object_based_on_existing_one
    @existing_assay =  Assay.find(params[:id])
    @assay = @existing_assay.clone_with_associations

    if @existing_assay.can_view?
      notice_message = ''
      unless @assay.study.can_edit?
        @assay.study = nil
        notice_message << "The #{t('study')} of the existing #{t('assays.assay')} cannot be viewed, please specify your own #{t('study')}! <br/>"
      end

      @existing_assay.data_files.each do |d|
        if !d.can_view?
          notice_message << "Some or all #{t('data_file').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end
      @existing_assay.sops.each do |s|
        if !s.can_view?
          notice_message << "Some or all #{t('sop').pluralize} of the existing #{ t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end
      @existing_assay.models.each do |m|
        if !m.can_view?
          notice_message << "Some or all #{t('model').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end
      @existing_assay.documents.each do |d|
        if !d.can_view?
          notice_message << "Some or all #{t('document').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>"
          break
        end
      end

      unless notice_message.blank?
        flash.now[:notice] = notice_message.html_safe
      end

      render :action=>"new"
    else
      flash[:error]="You do not have the necessary permissions to copy this #{t('assays.assay')}"
      redirect_to @existing_assay
    end


   end

  def new
    @assay=Assay.new
    @assay.create_from_asset = params[:create_from_asset]
    study = Study.find(params[:study_id]) if params[:study_id]
    @assay.study = study if params[:study_id] if study.try :can_edit?
    @assay_class=params[:class]

    #jump straight to experimental if modelling analysis is disabled
    @assay_class ||= "experimental" unless Seek::Config.modelling_analysis_enabled

    @assay.assay_class=AssayClass.for_type(@assay_class) unless @assay_class.nil?

    investigations = Investigation.all.select(&:can_view?)
    studies=[]
    investigations.each do |i|
      studies << i.studies.select(&:can_view?)
    end
    respond_to do |format|
      if investigations.blank?
         flash.now[:notice] = "No #{t('study')} and #{t('investigation')} available, you have to create a new #{t('investigation')} first before creating your #{t('study')} and #{t('assays.assay')}!"
      else
        if studies.flatten.blank?
          flash.now[:notice] = "No #{t('study')} available, you have to create a new #{t('study')} before creating your #{t('assays.assay')}!"
        end
      end

      format.html
      format.xml
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def create
    params[:assay_class_id] ||= AssayClass.for_type("experimental").id
    @assay = Assay.new(assay_params)

    update_assay_organisms @assay, params
    @assay.contributor=current_person
    update_sharing_policies @assay
    update_annotations(params[:tag_list], @assay)
    update_relationships(@assay, params)

    if @assay.save
      if @assay.create_from_asset =="true"
        render :action => :update_assays_list
      else
        respond_to do |format|
          flash[:notice] = "#{t('assays.assay')} was successfully created."
          format.html { redirect_to(@assay) }
          format.json {render json: @assay}
        end
      end
    else
      respond_to do |format|
        format.html { render :action => "new", status: :unprocessable_entity }
        format.json { render json: json_api_errors(@assay), status: :unprocessable_entity }
      end
    end
  end

  def update
    update_assay_organisms @assay, params
    update_annotations(params[:tag_list], @assay)
    update_sharing_policies @assay
    update_relationships(@assay, params)

    respond_to do |format|
      if @assay.update_attributes(assay_params)
        flash[:notice] = "#{t('assays.assay')} was successfully updated."
        format.html { redirect_to(@assay) }
        format.json {render json: @assay}
      else
        format.html { render :action => "edit", status: :unprocessable_entity }
        format.json { render json: json_api_errors(@assay), status: :unprocessable_entity }
      end
    end
  end

  def update_assay_organisms assay,params
    organisms             = params[:assay_organism_ids] || params[:assay][:organism_ids] || []
    assay.assay_organisms = [] # This means new AssayOrganisms are created every time the assay is updated!
    Array(organisms).each do |text|
      # TODO: Refactor this to use proper nested params:
      o_id, strain,strain_id,culture_growth_type_text,t_id,t_title=text.split(",")
      culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
      assay.associate_organism(o_id, strain_id, culture_growth,t_id,t_title)
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
      format.json {render json: @assay}

    end
  end

  private

  def assay_params
    params.require(:assay).permit(:title, :description, :study_id, :assay_class_id, :assay_type_uri, :technology_type_uri,
                                  :license, :other_creators, :create_from_asset, { document_ids: []}, { creator_ids: [] },
                                  { scales: [] }, { sop_ids: [] }, { model_ids: [] },
                                  { samples_attributes: [:asset_id, :direction] },
                                  { data_files_attributes: [:asset_id, :direction, :relationship_type_id] },
                                  { publication_ids: [] }
                                  ).tap do |assay_params|
      assay_params[:document_ids].select! { |id| Document.find_by_id(id).try(:can_view?) } if assay_params.key?(:document_ids)
      assay_params[:sop_ids].select! { |id| Sop.find_by_id(id).try(:can_view?) } if assay_params.key?(:sop_ids)
      assay_params[:model_ids].select! { |id| Model.find_by_id(id).try(:can_view?) } if assay_params.key?(:model_ids)
    end
  end
end
