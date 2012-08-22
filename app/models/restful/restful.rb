require 'cgi'

module Restful

  def self.included(base)
    base.extend(ClassMethods)
  end

  def related_resources
    self.class.resources || []
  end

  def resource_path
    self.class.path
  end

  def links
    links = {}
    self.class.resources.each do |resource, path|
      # If another class was provided as the path, get its path
      unless path.kind_of?(String)
        path = path.path
      end
      # Replace objects in the path with appropriate information
      links[resource.to_s.downcase] = convert_path(path)
    end
    # Represent yourself
    links["self"] = convert_path(self.class.path)
    links
  end

  private

  def convert_path(path)
    path = path.dup
    resources_in_path = path.scan /:(\w+)/
    resources_in_path.each do |resource|
      resource = resource[0]
      attribute = resource.downcase == self.class.name.downcase ? "id" : resource
      path.gsub!(":#{resource}", CGI.escape(self.send(attribute.to_sym)))
    end
    @base_url = request.fullpath rescue "http://localhost:2000"
    @base_url + path
  end

  module ClassMethods
    attr_accessor :resources, :path

    def related_resources(*resources)
      @resources = resources.extract_options!
    end

    def resource_path(path)
      @path = path
    end

  end
end