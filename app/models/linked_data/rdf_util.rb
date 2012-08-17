require 'open-uri'
require 'json'
require 'cgi'

class RDFUtil
  @@endpoint = "http://bmir-dev1:8083/"
  # @@endpoint = "http://sparql.bioontology.org/sparql/?apikey=24e0e77e-54e0-11e0-9d7b-005056aa3316"

  XSD_LITERAL_CONVERT = {
    "http://www.w3.org/2001/XMLSchema#string" => lambda do |value|
      value
    end,
    "http://www.w3.org/2001/XMLSchema#boolean" => lambda do |value|
      value.eql?("true")
    end,
    "http://www.w3.org/2001/XMLSchema#integer" => lambda do |value|
      value.to_i
    end,
    "http://www.w3.org/2001/XMLSchema#double" => lambda do |value|
      value.to_f
    end,
    "http://www.w3.org/2001/XMLSchema#float" => lambda do |value|
      value.to_f
    end,
    "http://www.w3.org/2001/XMLSchema#dateTime" => lambda do |value|
      DateTime.parse(value)
    end,
    "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral" => lambda do |value|
      value
    end,
    "http://www.w3.org/2001/XMLSchema#datetime" => lambda do |value|
      DateTime.parse(value)
    end
  }

  def self.convert_xsd(type, datatype, value)
    case type
      when "uri"
        value
      when "bnode"
        value
      when "literal"
        puts datatype if XSD_LITERAL_CONVERT[datatype].nil?
        debugger if XSD_LITERAL_CONVERT[datatype].nil?
        XSD_LITERAL_CONVERT[datatype].call(value)
    end
  end

  def self.sparql_select_values(results)
    container = []
    results.each do |result|
      triple = result.first[1]
      container << convert_xsd(triple["type"], triple["datatype"], triple["value"])
    end
    container
  end

  def self.query(query, options = {})
    options[:full] ||= false
    data = open("#{@@endpoint}sparql/?query=#{CGI.escape(query)}&output=json").read
    parsed_data = JSON.parse(data)
    options[:full] = true unless parsed_data["results"] && options[:full] == false
    options[:full] == true ? parsed_data : parsed_data["results"]["bindings"]
  end
end