module Jerm
  # This can be concidered an Abstract class and should be extended for you own Harvester. In your specialised class you need to implement the
  # methods #changed_since and #construct_resource.
  class Harvester

    # The base URI for the Data Storage system to be Harvested.
    attr_reader :base_uri

    # Initialized the Harvester with the base_uri, username and password.
    def initialize(base_uri,user, pass)
      @username = user
      @password = pass
      
      @base_uri=base_uri
    end

    # Generates an Enumeration of Jerm::Resources that have changed since the value returned by #last_run.
    # This method ties together the methods #changed_since and #construct_resource and is unlikely to be changed in your subclass.
    def update      
      items = changed_since(last_run)
      resources = []
      items.each do |item|
        resource = construct_resource(item)
        resource.populate
        resources << resource
      end
      return resources
    end

    # returns the time that this Harvester was last run, and causes only new resources since this time to be returned by #update.
    # This date is passed to #changed_since.
    def last_run
      DateTime.parse("1 Jan 2007")
    end

    protected

    # This method it responsible for constructing a new Jerm::Resource, based upon the information provided by <em>item</em>.
    # It is entirely up to you what type is used for <em>item</em>, but within SysMO-DB we tend to use a Hash containg property value pairs.
    def construct_resource item
      raise Exception.new("You need to implement this in your subclass of Harvester")
    end

    # Returns an Enumeration of items changed since the <em>since_date</em>. These items are subsequently passed to #construct_resource.
    def changed_since since_date
      raise Exception.new("You need to implement this in your subclass of Harvester")
    end

  end
end