
module ActionView
  class Renderer
    @@alternative_map = {}

    def self.clear_alternative(key)
      key = stringify_values(key)
      @@alternative_map.delete(key)
    end

    def self.clear_alternatives
      @@alternative_map.clear
    end

    def self.define_alternative(key, value)
      key = stringify_values(key)
      @@alternative_map[key] = value
    end

    # converts all the values to strings (from symbols) to simplify lookup
    def self.stringify_values(hash)
      Hash[hash.map { |k, v| [k, v.to_s] }]
    end

    def render(context, options)
      options = check_for_override(context, options)
      if options.key?(:partial)
        render_partial(context, options)
      else
        render_template(context, options)
      end
    end

    def check_for_override(context, options)
      unless options[:seek_template].nil?
        value = @@alternative_map[{ controller: context.controller_name, seek_template: options[:seek_template].to_s }]
        options[:template] = value unless value.nil?
      end

      unless options[:seek_partial].nil?
        value = @@alternative_map[{ controller: context.controller_name.to_s, seek_partial: options[:seek_partial].to_s }]
        if value.nil?
          value = @@alternative_map[{ seek_partial: options[:seek_partial].to_s }]
        end
        if value.nil?
          options[:partial] = options[:seek_partial]
        else
          if value.blank?
            options[:text] = ''
          else
            options[:partial] = value.to_s
          end
        end
      end
      options
    end
  end
end
