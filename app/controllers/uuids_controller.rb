class UuidsController < ApplicationController
  before_filter :login_required
  
  @@uuid_models = nil
  
  def show 
    uuid=params[:id]
    obj=nil
    uuid_models.each do |m|
      obj=m.find_by_uuid(uuid)
      break if obj
    end
    respond_to do |format|
      format.html {redirect_to obj}
      format.xml {redirect_to obj,:format=>"xml"}
    end
  end
  
  private
  
  def uuid_models
    return @@uuid_models if @@uuid_models
    models = Dir.glob("#{RAILS_ROOT}/app/models/*.rb").map { |path| File.basename(path, ".rb").camelize.constantize }
    @@uuid_models = models.select{|m| m.respond_to?("find_by_uuid")}
    return @@uuid_models
  end
end
