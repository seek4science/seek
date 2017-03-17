module HelpHelper
  # provides a link to a help page in our documentation, defined by the key and in lib/seek/help/help_links.yml
  # options include:
  # - link_text - the text of the link - default help
  def help_link(key, options = {})
    options = default_help_options.merge(options)
    if options[:url_only]
      Seek::Help::HelpDictionary.instance.help_link(key)
    else
      link_to options[:link_text], Seek::Help::HelpDictionary.instance.help_link(key), target: :_blank
    end
  end

  def default_help_options
    {
      link_text: 'help'
    }
  end
end
