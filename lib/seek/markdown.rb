require 'html_pipeline'
require 'html_pipeline/convert_filter/markdown_filter'

module Seek
  class Markdown
    class LinkNofollowFilter < HTMLPipeline::NodeFilter
      SELECTOR = Selma::Selector.new(match_element: 'a')

      def selector
        SELECTOR
      end

      def handle_element(a)
        if a['rel'].blank?
          a['rel'] = 'nofollow'
        elsif !a['rel'].include?('nofollow')
          a['rel'] = a['rel'] + ' nofollow'
        end
      end
    end

    class RelativeLinkFilter < HTMLPipeline::NodeFilter
      SELECTOR = Selma::Selector.new(match_element: 'img')

      def selector
        SELECTOR
      end

      def handle_element(img)
        return if img['src'].nil? || context[:relative_root].nil?

        src = img['src'].strip
        src_uri = URI(src)
        return if src_uri.absolute?

        src = src[1..] if src.start_with?('/')

        img['src'] = Addressable::URI.join(context[:relative_root], src).to_s
      end
    end

    MarkdownPipeline = HTMLPipeline.new(
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new(context: {
        markdown: {
          render: { unsafe: true, github_pre_lang: true, hardbreaks: false },
          extension: { tagfilter: true, table: true, strikethrough: true, autolink: true }
        }
      }),
      node_filters: [LinkNofollowFilter.new, RelativeLinkFilter.new]
    )

    MarkdownPlainTextPipeline = HTMLPipeline.new(
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new(context: {
        markdown: {
          render: { github_pre_lang: true, hardbreaks: false },
          extension: { table: true, strikethrough: true, autolink: true }
        }
      }),
      sanitization_config: { elements: [] }
    )

    # Renders a markdown string to HTML
    def self.render(markdown, relative_root = nil)
      markdown = markdown.encode('UTF-8', invalid: :replace, undef: :replace)
      return '' if markdown.blank?

      context = {
        relative_root: relative_root
      }
      MarkdownPipeline.call(markdown, context: context)[:output]
    end

    # Strips markdown tags from a string and returns plain text
    def self.strip_markdown(markdown)
      markdown = markdown.encode('UTF-8', invalid: :replace, undef: :replace)
      return '' if markdown.blank?
      MarkdownPlainTextPipeline.call(markdown)[:output]
    end
  end
end