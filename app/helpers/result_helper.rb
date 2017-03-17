module ResultHelper
  include TavernaPlayer::RunsHelper

  # Override
  def deep_parse(types, output, zip, index = [])
    content = '<ol>'
    i = 0
    types.each do |type|
      if type.is_a?(Array)
        content += "<li><strong>List #{i + 1}</strong><br />" +
                   deep_parse(type, output, zip, index + [i]) + '</li>'
      else
        # Text outputs are inlined here by us. Other types are linked and
        # inlined by the browser.
        content += "<li style='list-style-type:decimal; list-style-position:outside; display:list-item;'> <span class='mime_type'>(#{type})</span><p>"
        if type.starts_with?('text')
          path = (index + [i]).map { |j| j += 1 }.join('/')
          data = zip.read("#{output.name}/#{path}")
        else
          path = (index + [i]).join('/')
          data = run_path(output.run_id) + "/output/#{output.name}/#{path}"
        end
        content += TavernaPlayer.output_renderer.render(data, type)
        content += '</p></li>'
      end
      i += 1
    end

    raw(content += '</ol>')
  end
end
