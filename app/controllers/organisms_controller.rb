class OrganismsController < ApplicationController
  
  before_filter :login_required
  before_filter :find_organism,:only=>[:show,:info,:more_ajax,:search_ajax]

  include BioPortal::RestAPI

  def show
    respond_to do |format|
      format.html
      format.xml {render :xml=>@organism}
    end
  end

  def search_ajax
    results,pages = search "0",@organism.title,1
    render :update do |page|
      if results
        page.replace_html 'search_results',:partial=>"search_results",:object=>results
      else
        page.replace_html 'search_results',:text=>"Nothing found"
      end
    end
  end

  def more_ajax
    concept = @organism.concept 1,true
    
    render :update do |page|
      if concept
        page.replace_html 'bioportal_more',:partial=>"concept",:object=>concept
      else
        page.replace_html 'bioportal_more',:text=>"Nothing found"
      end
    end

  end

  def update
    @organism = Organism.find(params[:id])

    respond_to do |format|
      if @organism.update_attributes(params[:organism])
        flash[:notice] = 'Organism was successfully updated.'
        format.html { redirect_to(@organism) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end

  def info
    respond_to do |format|
      format.html
      format.xml {render :xml=>@organism}
    end
  end

  private

  def find_organism
    begin
      @organism=Organism.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "The Organism selected does not exist"
        format.html { redirect_to root_path }
      end    
    end
  end
  
end
