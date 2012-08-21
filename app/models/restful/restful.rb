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
      links[resource.to_s.downcase] = path.gsub(":id", self.id)
    end
    links
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