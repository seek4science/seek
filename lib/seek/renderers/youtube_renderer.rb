module Seek
  module Renderers
    class YoutubeRenderer < BlobRenderer
      def can_render?
        blob.url && is_youtube_url?(blob.url) && extract_video_code(blob.url)
      end

      def external_embed?
        true
      end

      def render_content
        code = extract_video_code(blob.url)
          
        "<iframe width=\"560\" height=\"315\" src=\"https://www.youtube-nocookie.com/embed/#{code}\" frameborder=\"0\" allowfullscreen></iframe>"
      end

      def is_youtube_url?(url)
        parsed_url = URI.parse(url)
        ['youtube.com', 'youtu.be', 'm.youtube.com', 'www.youtube.com'].include?(parsed_url.host) &&
          ['http', 'https'].include?(parsed_url.scheme)
      rescue
        false
      end

      def extract_video_code(url)
        match = url.match(/[\?\&]v[i]?\=([-_a-zA-Z0-9]+)/) ||
                url.match(/youtu\.be\/([-_a-zA-Z0-9]+)/) ||
                url.match(/\/v\/([-_a-zA-Z0-9]+)/) ||
                url.match(/\/embed\/([-_a-zA-Z0-9]+)/)
        match[1] if match
      end
    end
  end
end
