
module LinkedData
  module Serializer
    attr_accessor :default_fields, :additional_fields, :methods

    def serialize_default(*fields)
      @default_fields = fields
    end

    def serialize_additional(*fields)
      @additional_fields = fields
    end

    def serialize_methods(*methods)
      @methods = methods
    end

    def as_json(options = {})
      options[:only] = options[:only].nil? || options[:only].empty? ? serialize_default : options[:only]
      options.extract!(:only) if options[:only].include?("all")
      @table.as_json(options)
    end

  end

end