# require File.expand_path('../linked_data/record', __FILE__)
require File.expand_path('../linked_data/rdf_util', __FILE__)

class Ontology < LinkedData::Record
  # Validations
  validates_presence_of :administrator, :name
  # validates_presence_of :id, :name, :description, :contact, :format, :released, :viewingRestriction

  # Potnentially aliasing names from triplestore to something more Ruby-like
  # alias :id :acronym

  # Options for serializing (which fields)
  serialize_default :lastVersion, :administrator, :acronym, :name, :description, :contact, :homepage

  # Necessary values for working with Record
  @prefix = "http://bioportal.bioontology.org/ontologies/"
  @rdf_type = "http://omv.ontoware.org/2005/05/ontology#Ontology"

  # Extra values to combine ontology revisions with ontology containers
  class << self; attr_reader :ontology_container end
  @ontology_container = "http://bioportal.bioontology.org/metadata/OntologyContainer"

  # Get queries from query module
  include LinkedData::Queries::Ontology

  def self.find(id = nil, options = {})
    id ||= options[:id]
    if id.downcase.to_s.eql?("all")
      self.all
    else
      self.describe(id.upcase)
    end
  end

  def self.all
    results = RDFUtil.query(ALL_ONTS)
    onts = {}
    results.each do |row|
      onts[row["s"]] = {} if onts[row["s"]].nil?
      predicate = row["p"]["value"]
      # If value is nil, add it as array. If it exists, add to existing array.
      if onts[row["s"]][predicate].nil?
        onts[row["s"]][predicate] = [ RDFUtil.convert_xsd(row["o"]["type"], row["o"]["datatype"], row["o"]["value"]) ]
      else
        onts[row["s"]][predicate] << RDFUtil.convert_xsd(row["o"]["type"], row["o"]["datatype"], row["o"]["value"])
      end
    end
    onts_list = []
    onts.each do |ont_id, ont|
      ont_obj = Ontology.shorten(ont)
      onts_list << ont_obj
    end
    onts_list
  end

  def self.describe(id = nil)
    query = "DESCRIBE <#{@prefix}#{id}>"
    results = RDFUtil.query(query)

    # TODO: This should not happen, but we're going to make quash it for now
    return nil if results.empty?

    results_converted = convert_describe_results(results, "#{@prefix}#{id}")

    # Combine the ontology version information for the latest version if no version id is passed
    unless id.include?("/")
      last_version = results_converted["http://bioportal.bioontology.org/metadata/lastVersion"].first
      results_converted.merge! latest_version(last_version)
    end

    self.shorten(results_converted)
  end

  def self.latest_version(id)
    query = "DESCRIBE <#{id}>"
    results = RDFUtil.query(query)
    # TODO: This should not happen, but we're going to make quash it for now
    return nil if results.empty?
    convert_describe_results(results, id)
  end

  def self.predicates(rdf_type = nil)
    if !$PREDICATES.nil?
      @predicates = $PREDICATES
    else
      if @predicates.nil?
        rdf_type ||= @rdf_type
        results = RDFUtil.query(PREDICATE_QUERY.gsub("%%RDF_TYPE%%", @rdf_type))
        results.concat RDFUtil.query(PREDICATE_QUERY.gsub("%%RDF_TYPE%%", @ontology_container))
        @predicates = {}
        results.each do |result|
          predicate = RDFUtil.convert_xsd(result["p"]["type"], result["p"]["datatype"], result["p"]["value"])
          cardinality = RDFUtil.convert_xsd(result["c"]["type"], result["c"]["datatype"], result["c"]["value"])
          if !@predicates[predicate].nil? && @predicates[predicate][:cardinality] < cardinality
            @predicates[predicate][:cardinality] = cardinality
          elsif @predicates[predicate].nil?
            @predicates[predicate] = {:cardinality => cardinality}
          end
        end
      end
    end
    @predicates
  end

end


# Testing
# require 'pp'

# test = Ontology.find("ABA")
# pp test
# puts "valid: #{test.valid?}"
# puts test.name
# test.name = 11111
# puts test.name
# puts test.this_is_not_a_method