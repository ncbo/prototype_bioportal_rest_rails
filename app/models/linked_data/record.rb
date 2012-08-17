require File.expand_path('../rdf_util', __FILE__)


module LinkedData
  class Record < OpenStruct
    include ActiveModel::Validations
    include ActiveModel::Serialization
    include LinkedData::Queries::Record
    # Custom serializer
    include LinkedData::Serializer

    ####
    # Methods to adhere to ActiveModel API
    ####
    attr_accessor :attributes
    def initialize(attributes = {})
      table = attributes[:table].nil? ? {} : attributes[:table]
      super(table)
      @predicate_map = attributes[:predicate_map] unless attributes[:predicate_map].nil?
      @attributes = @table
    end

    def read_attribute_for_validation(key)
      @attributes[key]
    end

    ####
    # Custom methods for 4store interaction and object building
    ####

    # Required fields for subclasses
    class << self; attr_reader :prefix, :rdf_type end

    # Internal usage
    class << self; attr_reader :predicate_map end

    def as_json(options = {})
      options[:only] = options[:only].nil? || options[:only].empty? ? serializable_fields_default : options[:only]
      options.extract!(:only) if options[:only] && options[:only].include?("all")
      @table.as_json(options)
    end

    def self.describe(id = nil)
      query = "DESCRIBE <#{@prefix}#{id}>"
      results = RDFUtil.query(query)
      results_converted = convert_describe_results(results, "#{@prefix}#{id}")
      self.shorten(results_converted)
    end

    def self.shorten(results)
      @predicate_map = {}
      @table = {}
      return if results.nil?
      results.each do |predicate, values|
        if predicate.include?("#")
          short_name = predicate.split("#").last
          @predicate_map[short_name] = predicate
        else
          short_name = predicate.split("/").last
          @predicate_map[short_name] = predicate
        end
        values_cardinality = self.predicates[predicate][:cardinality] == 1 ? values.shift : values
        @table[short_name] = values_cardinality
      end
      self.new(:table => @table, :predicate_map => @predicate_map)
    end

    def self.convert_describe_results(results, object_id)
      return nil if results.empty?
      results_converted = {}
      results[object_id].each do |predicate, values|
        values_objs = []
        values.each {|value| values_objs << RDFUtil.convert_xsd(value["type"], value["datatype"], value["value"])}
        results_converted[predicate] = values_objs
      end
      results_converted
    end

    def self.predicates(rdf_type = nil)
      if @predicates.nil?
        rdf_type ||= @rdf_type
        results = RDFUtil.query(PREDICATE_QUERY.gsub("%%RDF_TYPE%%", @rdf_type))
        @predicates = {}
        results.each do |result|
          predicate = RDFUtil.convert_xsd(result["p"]["type"], result["p"]["datatype"], result["p"]["value"])
          cardinality = RDFUtil.convert_xsd(result["c"]["type"], result["c"]["datatype"], result["c"]["value"])
          # puts result["s"]["value"], predicate, cardinality, "\n" if cardinality > 1
          if !@predicates[predicate].nil? && @predicates[predicate][:cardinality] < cardinality
            @predicates[predicate][:cardinality] = cardinality
          elsif @predicates[predicate].nil?
            @predicates[predicate] = {:cardinality => cardinality}
          end
        end
      end
      @predicates
    end

  end
end