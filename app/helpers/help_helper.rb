module HelpHelper
  # provides a link to a help page in our documentation, defined by the key and in lib/seek/help/help_links.yml
  # options include:
  # - link_text - the text of the link - default help
  # - url_only - just the url as a string, rather than a full link
  def help_link(key, options = {})
    options = default_help_options.merge(options)
    if options[:include_icon]
      options[:link_text] = content_tag(:span,'',class:'help_icon') + options[:link_text]
    end
    if options[:url_only]
      Seek::Help::HelpDictionary.instance.help_link(key)
    else
      link_to options[:link_text], Seek::Help::HelpDictionary.instance.help_link(key), target: :_blank
    end
  end

  def default_help_options
    {
      link_text: 'Help'
    }
  end

  def help_icon_with_link(key, text, _delay = 200, extra_style = '')
    #image('info', :alt => 'help', 'data-tooltip' => tooltip(text), :style => "vertical-align: middle;#{extra_style}")
    link_to content_tag(:span,'',class:'help_icon') + "What is a "+key, Seek::Help::HelpDictionary.instance.help_link(key), :title =>text ,target: :_blank
  end

end
