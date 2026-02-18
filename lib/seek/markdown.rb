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

    markdown_pipeline_config = {
      convert_filter: HTMLPipeline::ConvertFilter::MarkdownFilter.new(context: {
        markdown: {
          render: { unsafe: true, github_pre_lang: true, hardbreaks: false },
          extension: { tagfilter: true, table: true, strikethrough: true, autolink: true }
        }
      }),
      node_filters: [LinkNofollowFilter.new]
    }

    MarkdownPipeline = HTMLPipeline.new(**markdown_pipeline_config)

    MarkdownPlainTextPipeline = HTMLPipeline.new(**markdown_pipeline_config.merge(sanitization_config: { elements: [] }))

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