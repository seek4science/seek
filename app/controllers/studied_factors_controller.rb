class StudiedFactorsController < ApplicationController
  before_filter :login_required
  before_filter :find_study
  before_filter :create_new_studied_factor, :only=>[:index]

  def index
    respond_to do |format|
      format.html
      format.xml {render :xml=>@study.studied_factors}
    end
  end

  def create
    @studied_factor=StudiedFactor.new(params[:studied_factor])
    @studied_factor.study=@study

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

  def find_study
    begin
      @study = Study.find(params[:study_id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the Study"
        format.html { redirect_to studies_path }
      end
      return false
    end
  end

  def create_new_studied_factor
    @studied_factor=StudiedFactor.new(:study=>@study)
  end


  
end
