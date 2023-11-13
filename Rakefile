# frozen_string_literal: true

require 'html-proofer'

task :test do
  sh 'bundle exec jekyll build'
  options = {
    alt_ignore: [/.*/], # don't worry about images without an alt tag
    ignore_urls: [
      /http(s)?:\/\/localhost.*/, # ignore links to localhost, which are shown when walking through the installation
      /https:\/\/www.nationalarchives.gov.uk.*/, 
      /https:\/\/bitbucket.org\/fairdom\/seek\/downloads\/seek*/,
      /https:\/\/jira-bsse.ethz.ch\/browse*/ # the old Jira has gone
    ], 
    typhoeus: {
      ssl_verifypeer: false,
      ssl_verifyhost: 0
    }
  }
  HTMLProofer.check_directory('./_site', options).run
end
