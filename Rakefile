# frozen_string_literal: true

require 'html-proofer'

task :test do
  sh 'bundle exec jekyll build'
  options = {
    alt_ignore: [/.*/], # don't worry about images without an alt tag
    url_ignore: [/http(s)?:\/\/localhost.*/, /https:\/\/www.nationalarchives.gov.uk.*/, /https:\/\/bitbucket.org\/fairdom\/seek\/downloads\/seek*/], # ignore links to localhost, which are shown when walking through the installation
    typhoeus: {
      ssl_verifypeer: false,
      ssl_verifyhost: 0
    }
  }
  HTMLProofer.check_directory('./_site', options).run
end
