class AssaysController < ApplicationController

  include Seek::IndexPager
  include Seek::AssetsCommon

  before_filter :assays_enabled?

  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_authorize_requested_item, :only=>[:edit, :update, :destroy, :show,:new_object_based_on_existing_one]

  #project_membership_required_appended is an alias to project_membership_required, but is necessary to include the actions
  #defined in the application controller
  before_filter :project_membership_required_appended, :only=>[:new_object_based_on_existing_one]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

  include Seek::IsaGraphExtensions

  def new_object_based_on_existing_one
    @existing_assay =  Assay.find(params[:id])
    @assay = @existing_assay.clone_with_associations
    params[:data_file_ids]=@existing_assay.data_files.collect{|d|"#{d.id},None"}
    params[:related_publication_ids]= @existing_assay.publications.collect{|p| "#{p.id},None"}

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
    update_annotations(params[:tag_list], @assay) #this saves the assay
    update_scales @assay

    a = @assay.present?
    b = @assay.save

    if a && b
      update_assets_linked_to_assay @assay, params
      update_relationships(@assay, params)

      #required to trigger the after_save callback after the assets have been associated
      @assay.save
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
        format.html { render :action => "new" }
        format.json { render json: {error: @assay.errors, status: :unprocessable_entity}, status: :unprocessable_entity }

      end
    end
  end

  def update
    set_assay_organisms_from_json if json_api_request?

    update_assay_organisms @assay, params
    update_annotations(params[:tag_list], @assay)
    update_scales @assay
    @assay.update_attributes(assay_params)
    update_sharing_policies @assay

    respond_to do |format|
      if @assay.save           #should use params (e.g. for creators to be updated)
        update_assets_linked_to_assay @assay, params
        update_relationships(@assay, params)

        @assay.save!

        flash[:notice] = "#{t('assays.assay')} was successfully updated."
        format.html { redirect_to(@assay) }
        format.json {render json: @assay}
      else
        format.html { render :action => "edit" }
        format.json { render json: {error: @assay.errors, status: :unprocessable_entity}, status: :unprocessable_entity }
      end
    end
  end

  def update_assay_organisms assay,params
    organisms             = params[:assay_organism_ids] || []
    assay.assay_organisms = []
    Array(organisms).each do |text|
      o_id, strain,strain_id,culture_growth_type_text,t_id,t_title=text.split(",")
      culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
      assay.associate_organism(o_id, strain_id, culture_growth,t_id,t_title)
    end
  end

  def update_assets_linked_to_assay assay,params
    sop_ids               = params[:assay_sop_ids] || []
    data_files            = params[:data_files] || []
    model_ids             = params[:model_ids] || []
    samples               = params[:samples] || []

    assay_assets_to_keep = [] #Store all the asset associations that we are keeping in this
    data_files.each do |data_file|
      d = DataFile.find(data_file[:id])
      assay_assets_to_keep << assay.associate(d, direction: data_file[:direction],
                                              relationship: RelationshipType.find_by_id(data_file[:relationship_type])
      ) if d.can_view?
    end
    Array(model_ids).each do |id|
      m = Model.find(id)
      assay_assets_to_keep << assay.associate(m) if m.can_view?
    end
    Array(sop_ids).each do |id|
      s = Sop.find(id)
      assay_assets_to_keep << assay.associate(s) if s.can_view?
    end
    samples.each do |sample|
      s = Sample.find(sample[:id])
      assay_assets_to_keep << assay.associate(s, :direction => sample[:direction]) if s.can_view?
    end
    #Destroy AssayAssets that aren't needed
    (assay.assay_assets - assay_assets_to_keep.compact).each do |a|
      unless a.asset_type == 'Document' # These are cleaned up automatically
        a.destroy
      end
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

  def update_types
    render :update do |page|
      page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
    end
  end

  private

  def set_assay_organisms_from_json
    if !(params[:assay][:assay_organism_ids].nil?)
      params[:assay_organism_ids] = params[:assay][:assay_organism_ids]
      params[:assay].delete :assay_organism_ids
    end
  end

  def set_creators
    if !(params[:data][:attributes][:creators].nil?)
      params[:creators] = params[:data][:attributes][:creators]
      params[:data][:attributes].delete :creators
    end
  end

  def assay_params
    params.require(:assay).permit(:title, :description, :study_id, :assay_class_id,
                                  :assay_type_uri, :technology_type_uri, :license, :other_creators, :create_from_asset,
                                  { document_ids: []})
  end

  def tweak_json_params
    if params[:assay][:assay_class].present? && params[:assay][:assay_class][:key].present?
      sym = params[:assay][:assay_class][:key].to_sym
      the_class = AssayClass.find_by(key: sym)
      if the_class.blank? then
        raise "No id for class key #{sym}"
      end
      params[:assay][:assay_class_id] = the_class.id
      # if params[:assay][:assay_class] == :EXP
      #   params[:assay][:assay_class_id] = "1"
      # else
      #   params[:assay][:assay_class_id] = "2"
      # end
      params[:assay].delete :assay_class
    end
    if params[:assay][:assay_type].present?
      params[:assay][:assay_type_uri] = params[:assay][:assay_type][:uri]
      params[:assay].delete :assay_type
    end
    if params[:assay][:technology_type].present?
      params[:assay][:technology_type_uri] = params[:assay][:technology_type][:uri]
      params[:assay].delete :technology_type
    end
  end


end
