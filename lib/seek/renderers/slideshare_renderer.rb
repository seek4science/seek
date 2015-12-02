module Seek
  module Renderers
    class SlideshareRenderer < BlobRenderer
      def can_render?
        content_blob && content_blob.url && is_slideshare_url?(content_blob.url)
      end

      def render
        api_url = "http://www.slideshare.net/api/oembed/2?url=#{content_blob.url}&format=json"
        json = JSON.parse(RestClient.get(api_url))
        json['html']
      rescue Exception => exception
        if Seek::Config.exception_notification_enabled
          data = { message: 'rendering error', renderer: self, item: content_blob.inspect }
          ExceptionNotifier.notify_exception(exception, data: data)
        end
        ''
      end

      # if it is a slideshare url, which starts with www.slideshare.net, and is made up of 2 parts (params ignored)
      # i.e http://www.slideshare.new/<org>/<slidetitle>
      def is_slideshare_url?(url)
        parsed_url = URI.parse(url)
        frag_count = parsed_url.path.split('/').select { |frag| !frag.blank? && frag != '/' }.count
        parsed_url.host == 'www.slideshare.net' && frag_count == 2 && parsed_url.scheme =~ /(http|https)/
      rescue
        false
      end
    end
  end
end
