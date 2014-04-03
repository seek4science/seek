module ActionView
  class Renderer
    def render(context, options)
      options = check_for_override(context,options)
      if options.key?(:partial)
        render_partial(context, options)
      else
        render_template(context, options)
      end
    end

    def check_for_override context,options
      #FIXME: hardcoded hack - this will be moved to a configuration if decided to be the approach to take
      if Seek::Config.is_biovel?
        unless options[:seek_template].nil?
          if context.controller_name=="homes"
            if options[:seek_template].to_s=="index"
              options[:template]="index_biovel"
            end
          end
        end
      end
      options
    end
  end
end