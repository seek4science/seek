class ErrorsController < ApplicationController
  layout 'errors'
  respond_to :html

  def error_404
    respond_with do |format|
      format.html
    end
  end

  def error_500
    respond_with do |format|
      format.html
    end
  end

  def error_422
    respond_with do |format|
      format.html
    end
  end

  def error_503
    respond_with do |format|
      format.html { render template: "errors/error_503", layout: 'layouts/errors', locals: {exception: Exception} }
    end
  end
end
