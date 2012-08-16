require File.expand_path('../rdf_util', __FILE__)

class LinkedDataRecord < OpenStruct
  attr_accessor :predicate_map, :prefix, :rdf_type

  def initialize(table = nil, predicate_map = nil)
    table = table.nil? ? {} : table
    super(table)
    @predicate_map = predicate_map unless predicate_map.nil?
  end

  # def method_missing(id, *args)
  #   field = id.to_s.delete("=")
  #   raise NoMethodError.new("undefined method `#{id}` for #{self.class}", id) unless @table.predicateey?(field)
  #   if id.to_s.include?("=")
  #     @table[field] = args[0]
  #   else
  #     @table[field]
  #   end
  # end

  def self.describe(id = nil)
    query = "DESCRIBE <#{@prefix}#{id}>"
    results = RDFUtil.query(query)
    results_converted = convert_describe_results(results, "#{@prefix}#{id}")
    self.shorten(results_converted)
  end

  def default_serialize
    []
  end

  def as_json(options = {})
    puts "as_json"
    options[:only] = options[:only].nil? || options[:only].empty? ? default_serialize : options[:only]
    options.extract!(:only) if options[:only].include?("all")
    puts options
    @table.as_json(options)
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
    self.new(@table, @predicate_map)
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

  PREDICATE_QUERY = <<-EOS
    SELECT ?s ?p (COUNT(?o) as ?c) WHERE {
        ?s a <%%RDF_TYPE%%> .
        ?s ?p ?o .
    } GROUP BY ?s ?p
  EOS

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