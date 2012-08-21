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

  # Necessary values for working with LinkedData::Record
  @prefix = "http://bioportal.bioontology.org/ontologies/"
  @rdf_type = ["http://omv.ontoware.org/2005/05/ontology#Ontology", "http://bioportal.bioontology.org/metadata/OntologyContainer"]

  # Define Restful relationships for outputting links
  include Restful
  resource_path "/ontologies/:id"
  related_resources :metrics => Metrics, :properties => "/ontologies/:id/properties"

  # Get queries from query module
  include LinkedData::Queries::Ontology

  def self.find(id = nil, options = {})
    id ||= options[:id]
    if id.downcase.to_s.eql?("all")
      self.all
    else
      self.describe(id.upcase, options)
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

  def self.describe(id = nil, options = {})
    if options[:version]
      super(["#{@prefix}#{id}", "#{@prefix}#{id}/#{options[:version]}"])
    else
      super(["#{@prefix}#{id}"], ["http://bioportal.bioontology.org/metadata/lastVersion"])
    end
  end

  def id
    self.acronym.upcase rescue ""
  end

  def id=(id)
    @table["acronym"] = id
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