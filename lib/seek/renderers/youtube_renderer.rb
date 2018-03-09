module Seek
  module Renderers
    class YoutubeRenderer < BlobRenderer
      def can_render?
        content_blob && content_blob.url && is_youtube_url?(content_blob.url) && extract_video_code(content_blob.url)
      end

      def render_content
        code = extract_video_code(content_blob.url)
        "<iframe width=\"560\" height=\"315\" src=\"https://www.youtube.com/embed/#{code}\" frameborder=\"0\" allowfullscreen></iframe>"
      end

      def is_youtube_url?(url)
        parsed_url = URI.parse(url)
        parsed_url.host.end_with?('youtube.com', 'youtu.be') && parsed_url.scheme =~ /(http|https)/
      rescue
        false
      end

      def extract_video_code(url)
        match = url.match(/\?v\=([-a-zA-Z0-9]+)/) ||
                url.match(/youtu\.be\/([-a-zA-Z0-9]+)/) ||
                url.match(/\/v\/([-a-zA-Z0-9]+)/) ||
                url.match(/\/embed\/([-a-zA-Z0-9]+)/)
        match[1] if match
      end
    end
  end
end
