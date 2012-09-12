require 'cgi'

# Provides a mechanism to create relationships between objects or declare related paths, which are used to generate
# hypermedia links for use in the API.
#
# To use, add the following to your target class:
#   class SubResource
#     resource_path "/resource/:parent_resource/sub/:sub_resource"
#   end
# The segments of the path that start with ":" should correspond to either the class name for the class you are
# declaring for or methods on the class that will return appropriate ids.
#
# To declare related classes, do the following:
#   class SubResource
#     related_resources :resource => Resource, :another => "/path/:sub_resource"
#   end
# Any related resources that are declared using the related class and not a string must also have the resource_path declared.
#
# Objects using this API will need to have the following methods:
#  1. 'id', which outputs the id for the instance of the object. This is used to insert the id into the path.
#  2. Any other segments starting with ":" should have a corresponding instance method.
module RestfulLinks

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Returns a list of related resources
  def related_resources
    self.class.resources || []
  end

  # Returns the object's path
  def resource_path
    self.class.path
  end

  # Get the path with segments replaced appropriately
  def canonical_path
    convert_path(resource_path)
  end

  # Generate links for the object.
  def restful_links
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

  # Fill in path segments using either a provided class or an instance method
  # @param [String] path containing segments to replace
  # @return [String] converted path
  def convert_path(path)
    path = path.dup
    resources_in_path = path.scan /:(\w+)/
    resources_in_path.each do |resource|
      resource = resource[0]
      attribute = resource.downcase == self.class.name.downcase ? "id" : resource
      path.gsub!(":#{resource}", CGI.escape(self.send(attribute.to_sym)))
    end
    @base_url = request.fullpath rescue $BASE_REST_URL
    @base_url + path
  end

  module ClassMethods
    attr_accessor :resources, :path

    # Set the related resources for this object
    # @param [Hash] key symbol representing related object name (used in url), value either String (path) or Object with resource_path set
    def related_resources(*resources)
      @resources = resources.extract_options!
    end

    # Set the path for this object
    # @param [String] path in the form of "/resource/:resource_class_name"
    def resource_path(path)
      @path = path
    end

  end
end