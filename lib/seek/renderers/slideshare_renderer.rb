module Seek
  module Renderers
    class SlideshareRenderer < BlobRenderer
      def can_render?
        blob.url && is_slideshare_url?(blob.url)
      end

      def external_embed?
        true
      end

      def render_content
        api_url = "http://www.slideshare.net/api/oembed/2?url=#{blob.url}&format=json"
        json = JSON.parse(RestClient.get(api_url))
        json['html']
      end

      # if it is a slideshare url, which starts with www.slideshare.net, and is made up of 2 parts (params ignored)
      # i.e http://www.slideshare.new/<org>/<slidetitle>
      def is_slideshare_url?(url)
        parsed_url = URI.parse(url)
        frag_count = parsed_url.path.split('/').count { |frag| !frag.blank? && frag != '/' }
        parsed_url.host == 'www.slideshare.net' && frag_count == 2 && parsed_url.scheme =~ /(http|https)/
      rescue
        false
      end
    end
  end
end
