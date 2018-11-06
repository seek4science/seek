module DeprecationHelper
  def link_to_function(*args, &block)
    warn 'Deprecated `link_to_function` used!'
    link_to('DEPRECATED LINK TO FUNCTION', '#')
    # if block_given?
    #   return link_to_function(capture(&block), *args)
    # end
    # name         = args.first
    # function     = args.second
    # html_options = args.third || {}
    #
    # onclick = "#{"#{html_options[:onclick]}; " if html_options[:onclick]}#{function}; return false;"
    #
    # href = html_options[:href] || '#'
    #
    # content_tag("a".freeze, name || url, html_options.merge(href: href, onclick: onclick), &block)
  end

  def remote_function(*args)
    warn 'Deprecated `remote_function` used!'
    "console.log('*** DEPRECATED REMOTE FUNCTION ***');"
  end
end