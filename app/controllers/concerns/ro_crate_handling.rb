module RoCrateHandling
  extend ActiveSupport::Concern

  private

  def send_ro_crate(path, filename)
    response.headers['Content-Length'] = File.size(path).to_s
    send_file(path, filename: filename, type: 'application/zip', disposition: 'inline')
  end
end