require File.expand_path('../linked_data/rdf_util', __FILE__)

# Base object for ontology classes.
# This object is read-only. Setting values for attributes will not propagate these values to the triplestore.
class Klass
  include ActiveModel::Serialization

  # Include custom serialization DSL
  include LinkedData::Serializer

  # Include queries from query module
  include LinkedData::Queries::Klass

  # Default attributes. These were standardized by NCBO and each ontology has its own mapping to these values.
  attr_accessor :id, :ontology, :label, :synonym, :definition, :obsolete

  # Serialization options
  serialize_default :id, :label, :synonym, :definition, :obsolete
  serialize_methods :properties, :child_count, :parents, :children

  # Define Restful relationships for outputting links
  include RestfulLinks
  resource_path "/ontologies/:ontology/classes/:klass"
  related_resources :ontology => Ontology, :resources => "/resource_index/by_concept?conceptid=:klass",
                    :children => "/ontologies/:ontology/classes/:klass/children"

  LABEL = "http://www.w3.org/2004/02/skos/core#prefLabel"
  SYNONYM = "http://www.w3.org/2004/02/skos/core#altLabel"
  DEFINITION = "http://www.w3.org/2004/02/skos/core#definition"
  OBSOLETE = "http://www.w3.org/2002/07/owl#deprecated"

  ####
  ## Class methods
  ####

  # Find an existing class.
  # @param [String] URI id for the class
  # @param [String] id/acronym of the ontology where the class is located
  # @option options options for finding classes
  # @return [Klass]
  def self.find(id, ontology, options = {})
    klass = self.new
    klass.id = id
    klass.ontology = ontology.upcase
    klass.init
    klass.populate_default_attr
    klass
  end

  # Check whether or not the class exists
  # @return [Boolean]
  def self.exists?(id, ontology)
    RDFUtil.query("ASK FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%> WHERE { <%%ID%%> ?p ?o } ".gsub("%%ONT%%", ontology).gsub("%%ID%%", id))["boolean"]
  end

  ####
  ## Instance methods
  ####

  # Provide values for default attributes
  def init
    @synonym = []; @definition = [];
  end

  # Overrides default serialization method. This enables the "include" query string parameter to work and hides
  # values by default so users only get a subsection of the available data.
  # @option options [Symbol] :only list of attributes that should be shown. Can contain "all" to show all.
  # @return [String] json representation of the object given the paramters provided
  def as_json(options = {})
    # If we need all attributes, then don't restrict using :only and include methods. Otherwise, just serialize the default or what's requested.
    if options[:only] && options[:only].include?("all")
      # This calls the super method (the one we override) to get a plain hash of our object
      obj_hash = super
      serialize_methods(obj_hash)
      # Take out the only option since we want to serialize everything in the object
      options.extract!(:only)
    else
      # If we get fields to serialize from the controller, use those. Otherwise, use defaults.
      options[:only] = options[:only].nil? || options[:only].empty? ? serializable_fields_default : options[:only]
      # If the options contain methods, then include those in a separate parameter by using an intersection
      methods = options[:only].map {|e| e.to_sym} & serializable_methods
      # Convert field names to strings
      options[:only].map! {|e| e.to_s} if options[:only]
      obj_hash = super.as_json(options)
      serialize_methods(obj_hash, methods)
    end
    obj_hash
  end

  # Set the default attributes that every class should have.
  def populate_default_attr
    query = BASE_ATTR_QUERY.gsub("%%ONT%%", @ontology).gsub("%%ID%%", @id)
    results = RDFUtil.query(query)
    raise ActionController::RoutingError.new("Class not found") if results.empty?
    values = {}
    results.each do |result|
      value = RDFUtil.convert_xsd(result["value"]["type"], result["value"]["datatype"], result["value"]["value"])
      attribute = result["bpProp"]["value"]
      values[attribute] = values[attribute].nil? ? [] : values[attribute]
      values[attribute] << value unless value.nil? || (value.respond_to?(:empty) && value.empty?)
    end
    @label = (values[LABEL] || [""]).shift
    @synonym.concat values[SYNONYM] || []
    @definition.concat values[DEFINITION] || []
    obsolete = values[OBSOLETE] || []
    @obsolete = obsolete.shift == true
  end

  # All of the properties for the term that exist in the triplestore.
  # @return [Hash] properties
  def properties
    results = RDFUtil.query("DESCRIBE <#{@id}>")
    convert_describe_results(results)
  end

  # Number of children the term has
  # @return [Integer] count of children
  def child_count
    RDFUtil.query(CHILD_COUNT_QUERY.gsub("%%ID%%", @id).gsub("%%ONT%%", @ontology))[0]["childcount"]["value"].to_i
  end

  # URIs for child classes
  # @return [Array] URIs for all child classes
  def children
    children = RDFUtil.query(CHILDREN_QUERY.gsub("%%ID%%", @id).gsub("%%ONT%%", @ontology))
    RDFUtil.sparql_select_values(children)
  end

  # URIs for all parent classes
  # @return [Array] URIs for all parent classes
  def parents
    parents = RDFUtil.query(PARENTS_QUERY.gsub("%%ID%%", @id).gsub("%%ONT%%", @ontology))
    RDFUtil.sparql_select_values(parents)
  end

  private

  def convert_describe_results(results)
    results_converted = {}
    results[@id].each do |predicate, values|
      values_objs = []
      values.each {|value| values_objs << RDFUtil.convert_xsd(value["type"], value["datatype"], value["value"])}
      values_objs = values_objs.length == 1 ? values_objs.shift : values_objs
      results_converted[predicate] = values_objs
    end
    results_converted
  end

  # Add the results of calling a list of instance methods to a hash with the method name as the key and return as the value
  # @param [Hash] hash where the method results are to be added
  # @param [Array, nil] list of methods that should get called
  def serialize_methods(hash, methods = nil)
    methods ||= serializable_methods
    methods.each do |method|
      hash[method.to_s] = self.send(method.to_s)
    end
  end

end
