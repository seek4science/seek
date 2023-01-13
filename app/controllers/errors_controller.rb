class ErrorsController < ApplicationController
  layout 'errors'

  skip_forgery_protection

  def error_404
    respond_to_error(404)
  end

  def error_406
    respond_to_error(406)
  end

  def error_500
    respond_to_error(500)
  end

  def error_422
    respond_to_error(422)
  end

  def error_503
    respond_to_error(503)
  end
end
