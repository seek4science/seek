class StudiedFactorsController < ApplicationController
  before_filter :login_required
  before_filter :find_data_file_auth
  before_filter :create_new_studied_factor, :only=>[:index]

  def index
    respond_to do |format|
      format.html
      format.xml {render :xml=>@data_file.studied_factors}
    end
  end

  def create
    @studied_factor=StudiedFactor.new(params[:studied_factor])
    @studied_factor.data_file=@data_file
    @studied_factor.data_file_version = params[:version]
    @studied_factor.substance = find_or_create_substance

    render :update do |page|
      if @studied_factor.save
        page.insert_html :bottom,"studied_factors_rows",:partial=>"factor_row",:object=>@studied_factor,:locals=>{:show_delete=>true}
        page.visual_effect :highlight,"studied_factors"
      else
        page.alert(@studied_factor.errors.full_messages)
      end
    end
  end

  def destroy
    @studied_factor=StudiedFactor.find(params[:id])

    render :update do |page|
      if @studied_factor.destroy
        page.visual_effect :fade,"studied_factor_row_#{@studied_factor.id}"
      else
        page.alert(@studied_factor.errors.full_messages)
      end
    end
  end

  private

  def find_data_file_auth
    begin
      data_file = DataFile.find(params[:data_file_id])
      the_action=action_name
      the_action="edit" if the_action=="destroy" #we are not destroying the sop, just editing its exp conditions
      if Authorization.is_authorized?(the_action, nil, data_file, current_user)
        @data_file = data_file
        @display_data_file = params[:version] ? @data_file.find_version(params[:version]) : @data_file.latest_version
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to sops_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the Data file"
        format.html { redirect_to data_files_path }
      end
      return false
    end
  end

  def create_new_studied_factor
    @studied_factor=StudiedFactor.new(:data_file=>@data_file)
  end

  def find_or_create_substance
    new_substances = params[:tag_autocompleter_unrecognized_items] || []
    known_substances = []
    known_substance_ids_and_types =params[:tag_autocompleter_selected_ids] || []
    known_substance_ids_and_types.each do |text|
      id, type = text.split(',')
      id = id.strip
      type = type.strip.capitalize.constantize
      known_substances.push(type.find(id)) if type.find(id)
    end
    new_substances, known_substances = check_if_new_substances_are_known new_substances, known_substances

    if (new_substances.size + known_substances.size) == 1
      if !known_substances.empty?
        known_substances.first
      else
        c = Compound.new(:name => new_substances.first)
          if  c.save
            c
          else
            nil
          end
      end
    end
  end

  protected

  #double checks and resolves if any new compounds are actually known. This can occur when the compound has been typed completely rather than
  #relying on autocomplete. If not fixed, this could have an impact on preserving compound ownership.
  def check_if_new_substances_are_known new_substances, known_substances
    fixed_new_substances = []
    new_substances.each do |new_substance|
      substance=Compound.find_by_name(new_substance.strip) || Synonym.find_by_name(new_substance.strip)
      if substance.nil?
        fixed_new_substances << new_substance
      else
        known_substances << substance unless known_substances.include?(substance)
      end
    end
    return new_substances, known_substances
  end
end
