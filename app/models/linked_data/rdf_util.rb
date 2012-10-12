require 'open-uri'
require 'json'
require 'cgi'
# require 'patron'
# require 'em-synchrony/em-http'
# require 'http_client'

# Utility methods for working with RDF data, mainly returned SPARQL query results from 4store
class RDFUtil

  # Address for the 4store server
  @@endpoint = "http://bmir-dev1:8083"

  # Group of lambdas for handling XSD type conversion
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

  # Takes returned value information and converts to appropriate Ruby object types
  # @param [String] type of value
  # @param [String] XSD datatype
  # @param [String] value in string form
  # @return [Object] converted value
  def self.convert_xsd(type, datatype, value)
    case type
      when "uri"
        value
      when "bnode"
        value
      when "literal"
        puts datatype if XSD_LITERAL_CONVERT[datatype].nil?
        # debugger if XSD_LITERAL_CONVERT[datatype].nil?
        XSD_LITERAL_CONVERT[datatype].call(value) rescue value
    end
  end

  # Convert a URI to it's last segment
  # Examples:
  #    http://example.org/domain/test => test
  #    http://example.org/domain#test => test
  def self.last_fragment(uri)
    if uri.include?("#")
      uri = uri.split("#").last
    else
      uri = uri.split("/").last
    end
    value = nil
    # Try to coerce the string to a typed value
    unless uri.respond_to?("empty?") && uri.empty?
      # Try float
      value = Float(uri) rescue nil
      # If nil (not float) or length != original length (missing decimal), then try integer
      if value.nil? || value.to_s.length != uri.length
        value = Integer(uri) rescue nil
      end
      # Try boolean
      if value.nil?
        if uri.downcase.eql?("true") || uri.downcase.eql?("false")
          value = uri.downcase.eql?("true")
        end
      end
      # Default back to string
      value = uri if value.nil?
    end
    value || uri
  end

  # Convert a list of SPARQL JSON values to proper Ruby objects
  # @param [Array] list of results. Each item should be a hash with type, datatype, and value
  # @return [Array] list of converted values
  def self.sparql_select_values(results)
    container = []
    results.each do |result|
      triple = result.first[1]
      container << convert_xsd(triple["type"], triple["datatype"], triple["value"])
    end
    container
  end

  # Perform a query against the triplestore using HTTP
  # @param [String] properly formed SPARQL query
  # @option options [Symbol] :full default: false. Setting to 'true' will return the whole json, false tries to find bindings and return those.
  def self.query(query, options = {})
    options[:full] ||= false
    start = Time.now
    # puts "#{@@endpoint}sparql/?query=#{CGI.escape(query)}&output=json"
    # File.open("queries.log", 'a+') {|f| f.write("#{@@endpoint}sparql/?query=#{CGI.escape(query)}&output=json\n") }
    open_uri = true
    path = "/sparql/?query=#{CGI.escape(query)}&output=json"
    if open_uri
      data = open(@@endpoint + path).read
    else
      # EventMachine
      # http = EM::HttpRequest.new(@@endpoint + ":" + @@endpoint_port + path).get
      # data = http.response

      # Patron
      # sess = Patron::Session.new
      # sess.timeout = 60
      # sess.base_url = @@endpoint + ":" + @@endpoint_port
      # data = sess.get(path).body

      # jRuby HTTP Client
      # client = HTTP::Client.new(:default_host => @@endpoint)
      # puts path
      # data = @@client.get(path)
      # puts data
    end
    parsed_data = JSON.parse(data)
    # puts "Query from #{caller[0].split(":")[0].split("/").last}:#{caller[0].split(" ")[1].gsub("`", "").gsub("'", "")} #{Time.now - start}s"
    options[:full] = true unless parsed_data["results"] && options[:full] == false
    options[:full] == true ? parsed_data : parsed_data["results"]["bindings"]
  end
end