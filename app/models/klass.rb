require File.expand_path('../linked_data/rdf_util', __FILE__)

class Klass

  attr_accessor :id, :ontology, :label, :synonym, :definition, :obsolete

  def self.init
    @synonym = []; @definition = [];
  end

  def initialize(id, ontology, label, synonym, definition, obsolete = false, options = {})
    @id = id; @ontology = ontology; @label = label; @synonym = synonym; @definition = definition; @obsolete = obsolete
  end

  def default_serialize
    [:id, :label, :synonym, :definition, :obsolete]
  end

  def methods_serialize
    [:properties, :child_count, :parents, :children]
  end

  # Custom json representation.
  def as_json(options = {})
    # Output all the attributes for a class
    if options[:only] && options[:only].include?("all")
      # This calls the super method (the one we override) to get a plain hash of our object
      obj_hash = super
      # Add in the methods that should get serialized
      methods_serialize.each do |method|
        obj_hash[method.to_s] = self.send(method.to_s)
      end
      # Take out the only option since we want to serialize everything in the object
      options.extract!(:only)
    else
      # If we get fields to serialize from the controller, use those. Otherwise, use defaults.
      options[:only] = options[:only].nil? || options[:only].empty? ? default_serialize : options[:only]
      # Convert field names to strings
      options[:only].map! {|e| e.to_s} if options[:only]
      obj_hash = super.as_json(options)
    end
    obj_hash
  end

  def self.find(id, ontology, options = {})
    ont_id = ontology.upcase
    self.init
    @id = id
    @ontology = ont_id
    raise ActionController::RoutingError.new("Class not found") unless self.exists?
    self.default_attr
    self.new(@id, ont_id, @label, @synonym, @definition, @obsolete)
  end

  def self.exists?
    RDFUtil.query("ASK FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%> WHERE { <%%ID%%> ?p ?o } ".gsub("%%ONT%%", @ontology).gsub("%%ID%%", @id))["boolean"]
  end

  OBSOLETE_QUERY = <<-EOS
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    ASK FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%> WHERE { <%%ID%%> a owl:DeprecatedClass }
  EOS
  def self.default_attr
    @label = predicate_values("skos:prefLabel", @ontology).shift
    @synonym.concat predicate_values("skos:altLabel", @ontology)
    @definition.concat predicate_values("skos:definition", @ontology)
    @obsolete = predicate_values("owl:deprecated", @ontology).shift == true
    # Try another way to get obsolete information
    @obsolete = RDFUtil.query(OBSOLETE_QUERY.gsub("%%ONT%%", @ontology).gsub("%%ID%%", @id))["boolean"] unless @obsolete
  end

  PREDICATE_QUERY = <<-EOS
    PREFIX owl:  <http://www.w3.org/2002/07/owl#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

    SELECT DISTINCT *
    FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
    FROM <http://bioportal.bioontology.org/ontologies/globals>
    WHERE
    {
      <%%ID%%> %%PRED%% ?o
    }
  EOS
  def self.predicate_values(predicate, ont_id)
    query = PREDICATE_QUERY.gsub("%%ONT%%", ont_id).gsub("%%ID%%", @id).gsub("%%PRED%%", predicate)
    results = RDFUtil.query(query)
    values = []
    results.each do |result|
      result = result["o"]
      value = RDFUtil.convert_xsd(result["type"], result["datatype"], result["value"])
      values << value unless value.nil? || value.empty?
    end
    values
  end

  def properties
    results = RDFUtil.query("DESCRIBE <#{@id}>")
    convert_describe_results(results)
  end

  CHILD_COUNT_QUERY = <<-EOS
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT (COUNT(?s) as ?childcount)
    FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
    WHERE
    {
      ?s rdfs:subClassOf <%%ID%%>
    }
  EOS
  def child_count
    RDFUtil.query(CHILD_COUNT_QUERY.gsub("%%ID%%", @id).gsub("%%ONT%%", @ontology))[0]["childcount"]["value"].to_i
  end

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

  CHILDREN_QUERY = <<-EOS
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT ?child
    FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
    WHERE
    {
      ?child rdfs:subClassOf <%%ID%%>
    }
  EOS
  def children
    children = RDFUtil.query(CHILDREN_QUERY.gsub("%%ID%%", @id).gsub("%%ONT%%", @ontology))
    RDFUtil.sparql_select_values(children)
  end

  PARENTS_QUERY = <<-EOS
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT ?parent
    FROM <http://bioportal.bioontology.org/ontologies/%%ONT%%>
    WHERE
    {
      <%%ID%%> rdfs:subClassOf ?parent
    }
  EOS
  def parents
    parents = RDFUtil.query(PARENTS_QUERY.gsub("%%ID%%", @id).gsub("%%ONT%%", @ontology))
    RDFUtil.sparql_select_values(parents)
  end

end


# Test code
# require 'pp'

# test = Klass.find("http://ontology.neuinfo.org/NIF/Dysfunction/NIF-Dysfunction.owl#birnlex_12561", "NIF")
# pp test.properties
