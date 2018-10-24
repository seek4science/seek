class UuidsController < ApplicationController
  before_action :login_required

  def show
    uuid = params[:id]
    obj = nil
    Seek::Util.uuid_types.each do |m|
      obj = m.find_by_uuid(uuid)
      break if obj
    end
    if obj
      respond_to do |format|
        format.html { redirect_to obj }
        format.json { redirect_to obj }
        format.xml { redirect_to obj, format: 'xml' }
      end
    else
      error('Not Found', "No resource found with UUID: #{uuid}", 404)
    end
  end
end
