require 'rubygems'
require 'spreadsheet'
require 'open-uri'
require 'net/http'

module Jerm
  class SysmolabResource < Resource
  
    def initialize(user,pass)
      @username = user
      @password = pass
    end
  
  end
end