class AssaysController < ApplicationController

  include DotGenerator
  include IndexPager
  include Seek::TaggingCommon

  before_filter :find_assets, :only=>[:index]
  before_filter :find_and_auth, :only=>[:edit, :update, :destroy, :show]

  def new
    @assay=Assay.new
    study = Study.find(params[:study_id]) if params[:study_id]
    @assay.study = study if params[:study_id] if study.try :can_edit?
    @assay_class=params[:class]
    @assay.assay_class=AssayClass.for_type(@assay_class) unless @assay_class.nil?
    respond_to do |format|
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
    @assay        = Assay.new(params[:assay])

    organisms     = params[:assay_organism_ids] || []
    sop_ids       = params[:assay_sop_ids] || []
    data_file_ids = params[:data_file_ids] || []
    model_ids     = params[:assay_model_ids] || []

    update_tags @assay

    @assay.owner=current_user.person

    @assay.policy.set_attributes_with_sharing params[:sharing]

    respond_to do |format|
      if @assay.save
        data_file_ids.each do |text|
          a_id, r_type = text.split(",")
          d = DataFile.find(a_id)
          @assay.relate(d, RelationshipType.find_by_title(r_type)) if d.can_view?
        end
        model_ids.each do |a_id|
          m = Model.find(a_id)
          @assay.relate(m) if m.can_view?
        end
        sop_ids.each do |a_id|
          s = Sop.find(a_id)
          @assay.relate(s) if s.can_view?
        end
        organisms.each do |text|
          o_id, strain, culture_growth_type_text=text.split(",")
          culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
          @assay.associate_organism(o_id, strain, culture_growth)
        end

        # update related publications
        Relationship.create_or_update_attributions(@assay, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?
        flash[:notice] = 'Assay was successfully created.'
        format.html { redirect_to(@assay) }
        format.xml { render :xml => @assay, :status => :created, :location => @assay }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    #FIXME: would be better to resolve the differences, rather than keep clearing and reading the assets and organisms
    #DOES resolve differences for assets now
    @assay.assay_organisms=[]

    organisms             = params[:assay_organism_ids] || []
    sop_ids               = params[:assay_sop_ids] || []
    data_file_ids         = params[:data_file_ids] || []
    model_ids             = params[:assay_model_ids] || []

    update_tags @assay

    assay_assets_to_keep = [] #Store all the asset associations that we are keeping in this

    @assay.policy_or_default
    @assay.policy.set_attributes_with_sharing params[:sharing]

    respond_to do |format|
      if @assay.update_attributes(params[:assay])
        data_file_ids.each do |text|
          a_id, r_type = text.split(",")
          d = DataFile.find(a_id)
          assay_assets_to_keep << @assay.relate(d, RelationshipType.find_by_title(r_type)) if d.can_view?
        end
        model_ids.each do |a_id|
          m = Model.find(a_id)
          assay_assets_to_keep << @assay.relate(m) if m.can_view?
        end
        sop_ids.each do |a_id|
          s = Sop.find(a_id)
          assay_assets_to_keep << @assay.relate(s) if s.can_view?
        end
        #Destroy AssayAssets that aren't needed
        (@assay.assay_assets - assay_assets_to_keep.compact).each { |a| a.destroy }

        organisms.each do |text|
          o_id, strain, culture_growth_type_text=text.split(",")
          culture_growth=CultureGrowthType.find_by_title(culture_growth_type_text)
          @assay.associate_organism(o_id, strain, culture_growth)
        end

        # update related publications
        Relationship.create_or_update_attributions(@assay, params[:related_publication_ids].collect { |i| ["Publication", i.split(",").first] }, Relationship::RELATED_TO_PUBLICATION) unless params[:related_publication_ids].nil?

        #FIXME: required to update timestamp. :touch=>true on AssayAsset association breaks acts_as_trashable
        @assay.updated_at=Time.now
        @assay.save!

        flash[:notice] = 'Assay was successfully updated.'
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
      format.svg { render :text=>to_svg(@assay.study, params[:deep]=='true', @assay) }
      format.dot { render :text=>to_dot(@assay.study, params[:deep]=='true', @assay) }
      format.png { render :text=>to_png(@assay.study, params[:deep]=='true', @assay) }
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
        page.replace_html element, :partial=>"assays/associate_resource_list_item", :locals=>{:resource=>assay}
      else
        page.replace_html element, :text=>"Nothing is selected to preview."
      end
    end
  end
end
