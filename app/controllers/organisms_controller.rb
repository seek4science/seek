class OrganismsController < ApplicationController
  
  before_filter :login_required
  before_filter :find_organism,:only=>[:show,:info]

  def show
    respond_to do |format|
      format.html
      format.xml {render :xml=>@organism}
    end
  end

  def more_ajax
    @organism=Organism.find(params[:organism])

    node = @organism.concept 1,true
    
    render :update do |page|
      if node
        page.replace_html 'bioportal_more',:partial=>"concept",:object=>node
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
