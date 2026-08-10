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
        return if img['src'].nil?

        src = img['src'].strip
        return if src.start_with?('http')

        img['src'] = URI.join('http://localhost:3000', '/workflows/3/git/1/raw/', src).to_s
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
    def self.render(markdown)
      markdown = markdown.encode('UTF-8', invalid: :replace, undef: :replace)
      return '' if markdown.blank?
      MarkdownPipeline.call(markdown)[:output]
    end

    # Strips markdown tags from a string and returns plain text
    def self.strip_markdown(markdown)
      markdown = markdown.encode('UTF-8', invalid: :replace, undef: :replace)
      return '' if markdown.blank?
      MarkdownPlainTextPipeline.call(markdown)[:output]
    end
  end
end