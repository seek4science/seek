require 'curb'

module ModelsHelper
  def get_jws_applet path
    url='http://jjj.biochem.sun.ac.za/webMathematica/upload/upload_stuart.jsp'

    c = Curl::Easy.new(url)
    c.multipart_form_post = true
    file=File.new(path)
    puts "SENDING:"+file.path

    c.http_post(Curl::PostField.file('upfile',file.path))
    puts "Response:"+c.response_code.to_s
    puts c.body_str
    return c.body_str
  end
end
