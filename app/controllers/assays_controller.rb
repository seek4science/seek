class AssaysController < ApplicationController

  include DotGenerator
  include IndexPager
  include Seek::AnnotationCommon

  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_authorize_requested_item, :only=>[:edit, :update, :destroy, :show]

  include Seek::Publishing::PublishingCommon

  include Seek::BreadCrumbs

   def new_object_based_on_existing_one
    @existing_assay =  Assay.find(params[:id])
    @assay = @existing_assay.clone_with_associations
    params[:data_file_ids]=@existing_assay.data_file_masters.collect{|d|"#{d.id},None"}
    params[:related_publication_ids]= @existing_assay.related_publications.collect{|p| "#{p.id},None"}

    unless @assay.study.can_edit?
      @assay.study = nil
      flash.now[:notice] = "The #{t('study')} of the existing #{t('assays.assay')} cannot be viewed, please specify your own #{t('study')}! <br/>".html_safe
    end

    @existing_assay.data_file_masters.each do |d|
      if !d.can_view?
       flash.now[:notice] << "Some or all #{t('data_file').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>".html_safe
        break
      end
    end
    @existing_assay.sop_masters.each do |s|
       if !s.can_view?
       flash.now[:notice] << "Some or all #{t('sop').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>".html_safe
        break
      end
    end
    @existing_assay.model_masters.each do |m|
       if !m.can_view?
       flash.now[:notice] << "Some or all #{t('model').pluralize} of the existing #{t('assays.assay')} cannot be viewed, you may specify your own! <br/>".html_safe
        break
      end
    end

    render :action=>"new"
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

    investigations = Investigation.all.select &:can_view?
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
    @assay        = Assay.new(params[:assay])

    organisms     = params[:assay_organism_ids] || []
    sop_ids       = params[:assay_sop_ids] || []
    data_file_ids = params[:data_file_ids] || []
    model_ids     = params[:model_ids] || []

     Array(organisms).each do |text|
      o_id, strain, culture_growth_type_text=text.split(",")
      culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
      @assay.associate_organism(o_id, strain, culture_growth)
    end

    @assay.owner=current_user.person

    @assay.policy.set_attributes_with_sharing params[:sharing], @assay.projects

    update_annotations @assay #this saves the assay
    update_scales @assay


      if @assay.save
        Array(data_file_ids).each do |text|
          a_id, r_type = text.split(",")
          d = DataFile.find(a_id)
          @assay.relate(d, RelationshipType.find_by_title(r_type)) if d.can_view?
        end
        Array(model_ids).each do |a_id|
          m = Model.find(a_id)
          @assay.relate(m) if m.can_view?
        end
        Array(sop_ids).each do |a_id|
          s = Sop.find(a_id)
          @assay.relate(s) if s.can_view?
        end

        # update related publications
        Relationship.create_or_update_attributions(@assay, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?

        #required to trigger the after_save callback after the assets have been associated
        @assay.save
        if @assay.create_from_asset =="true"
          render :action=>:update_assays_list
        else
          respond_to do |format|
          flash[:notice] = "#{t('assays.assay')} was successfully created."
          format.html { redirect_to(@assay) }
          format.xml { render :xml => @assay, :status => :created, :location => @assay }
          end
        end
      else
        respond_to do |format|
        format.html { render :action => "new" }
        format.xml { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    #FIXME: would be better to resolve the differences, rather than keep clearing and reading the assets and organisms
    #DOES resolve differences for assets now
    organisms             = params[:assay_organism_ids]||[]

    organisms             = params[:assay_organism_ids] || []
    sop_ids               = params[:assay_sop_ids] || []
    data_file_ids         = params[:data_file_ids] || []
    model_ids             = params[:model_ids] || []
    publication_params    = params[:related_publication_ids].nil?? [] : params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first]}

    @assay.assay_organisms = []
    Array(organisms).each do |text|
          o_id, strain, culture_growth_type_text=text.split(",")
          culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
          @assay.associate_organism(o_id, strain, culture_growth)
        end

    update_annotations @assay
    update_scales @assay

    assay_assets_to_keep = [] #Store all the asset associations that we are keeping in this
    @assay.attributes = params[:assay]
    if params[:sharing]
      @assay.policy_or_default
      @assay.policy.set_attributes_with_sharing params[:sharing], @assay.projects
    end

    respond_to do |format|
      if @assay.save
        Array(data_file_ids).each do |text|
          a_id, r_type = text.split(",")
          d = DataFile.find(a_id)
          assay_assets_to_keep << @assay.relate(d, RelationshipType.find_by_title(r_type)) if d.can_view?
        end
        Array(model_ids).each do |a_id|
          m = Model.find(a_id)
          assay_assets_to_keep << @assay.relate(m) if m.can_view?
        end
        Array(sop_ids).each do |a_id|
          s = Sop.find(a_id)
          assay_assets_to_keep << @assay.relate(s) if s.can_view?
        end
        #Destroy AssayAssets that aren't needed
        (@assay.assay_assets - assay_assets_to_keep.compact).each { |a| a.destroy }

        # update related publications

        Relationship.create_or_update_attributions(@assay,publication_params, Relationship::RELATED_TO_PUBLICATION)

        #FIXME: required to update timestamp. :touch=>true on AssayAsset association breaks acts_as_trashable
        @assay.updated_at=Time.now
        @assay.save!

        flash[:notice] = "#{t('assays.assay')} was successfully updated."
        format.html { redirect_to(@assay) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
    end
  end

  def destroy

    respond_to do |format|
      if @assay.can_delete?(current_user) && @assay.destroy
        format.html { redirect_to(assays_url) }
        format.xml { head :ok }
      else
        flash.now[:error]="Unable to delete the assay" if !@assay.study.nil?
        format.html { render :action=>"show" }
        format.xml { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_types
    render :update do |page|
      page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
    end
  end

  def preview
    element=params[:element]
    assay  =Assay.find_by_id(params[:id])

    render :update do |page|
      if assay.try :can_view?
        page.replace_html element, :partial=>"assays/preview_for_associate", :locals=>{:resource=>assay}
      else
        page.replace_html element, :text=>"Nothing is selected to preview."
      end
    end
  end
end
