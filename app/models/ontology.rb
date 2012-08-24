require File.expand_path('../linked_data/rdf_util', __FILE__)

# This class represents an ontology in the triplestore. It relies on the LinkedData framework for retreiving and storing information.
# It also adheres to the ActiveModel API where possible and uses a custom serializer mixin for handling the serialization of default attributes
# and custom attributes that are provided as methods. Validations are handled by ActiveModel::Validations. Links are generated using the
# RestfulLinks mixin at serialization (done via controller).
class Ontology < LinkedData::Record
  # Validations
  validates_presence_of :administrator, :name
  # validates_presence_of :id, :name, :description, :contact, :format, :released, :viewingRestriction

  # Options for serializing (which fields)
  serialize_default :lastVersion, :administrator, :acronym, :name, :description, :contact, :homepage

  # Necessary values for working with LinkedData::Record
  @prefix = "http://bioportal.bioontology.org/ontologies/"
  @rdf_type = ["http://omv.ontoware.org/2005/05/ontology#Ontology", "http://bioportal.bioontology.org/metadata/OntologyContainer"]

  # Define Restful relationships for outputting links
  include RestfulLinks
  resource_path "/ontologies/:ontology"
  related_resources :metrics => Metrics, :properties => "/ontologies/:ontology/properties",
                    :reviews => "/ontologies/:ontology/reviews", :download => "/ontologies/:ontology/download",
                    :views => "/ontologies/:ontology/views", :versions => "/ontologies/:ontology/versions",
                    :classes => "/ontologies/:ontology/classes", :mappings => "/ontologies/:ontology/mappings"

  # Get queries from query module
  include LinkedData::Queries::Ontology

  # Find an ontology (or all ontologies)
  # @param [String] id/acronym for ontology to find
  def self.find(id = nil, options = {})
    id ||= options[:id]
    if id.downcase.to_s.eql?("all")
      self.all
    else
      raise ActionController::RoutingError.new("Ontology not found") unless self.exists?(id.upcase)
      self.describe(id.upcase, options)
    end
  end

  # Find all ontologies
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

  # Get the root classes for the ontology
  def root_classes
    roots = RDFUtil.query(ROOT_CLASSES.gsub("%%ID%%", self.id))
    classes = []
    threads = []
    queue = Queue.new
    roots.each {|c| queue << c}
    max_threads = 100
    thread_count = roots.length / 100 == 0 ? roots.length : max_threads
    thread_count.times do
      threads << Thread.new do
        while !queue.empty?
          klass = (queue.pop)["root"]
          next if klass.nil? || klass["type"].eql?("bnode")
          klass = Klass.find(klass["value"], self.id)
          classes << klass
        end
      end
    end
    threads.each {|t| t.join}
    classes
  end

  # Provide an alias for the ontology acronym as id
  # This is used because acronym doesn't exist as an attribute until the ontology is retrieved from 4store
  def id
    self.acronym.upcase rescue ""
  end

  # Set value of id
  def id=(id)
    @table["acronym"] = id
  end

  private

  # Ontology-specific describe that allows for describing a prior version or the most recent
  def self.describe(id = nil, options = {})
    if options[:version]
      super(["#{@prefix}#{id}", "#{@prefix}#{id}/#{options[:version]}"])
    else
      super(["#{@prefix}#{id}"], ["http://bioportal.bioontology.org/metadata/lastVersion"])
    end
  end

end

