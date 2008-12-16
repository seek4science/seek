require 'rubygems'
require 'rake'

namespace :seek do
  task(:repop_cv=>:environment) do
    p=Person.find(:all, :conditions=>{:is_dummy=>true}).first
    p=Person.new(:is_dummy=>true, :first_name=>"Dummy User") if (p.nil?)
    expertise=""
    tools=""
    
    File.open('config/expertise.list').each do |item|
      expertise+=item+"," unless item.blank?
    end

    File.open('config/tools.list').each do |item|
      tools+=item+"," unless item.blank?
    end

    p.expertise_list=expertise
    p.tool_list=tools
    p.save

    puts "New user updated with tags:"+p.id.to_s

    

  end
end