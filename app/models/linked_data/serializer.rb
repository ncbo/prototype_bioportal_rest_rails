
module LinkedData
  # The Serializer is used to set default fields and serializable methods for objects.
  # Used when serializing methods to provide a flexible, dynamic way to show and hide fields.
  module Serializer

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Full set of serializable fields for the object
    def serializable_fields
      fields = self.class.serializable_fields_default.nil? ? [] : self.class.serializable_fields_default
      fields_additional = self.class.serializable_fields_additional.nil? ? [] : self.class.serializable_fields_additional
      fields.concat fields_additional
    end

    # The default set of serializable fields
    def serializable_fields_default
      return [] if self.class.serializable_fields_default.nil?
      self.class.serializable_fields_default
    end

    # The set of instance methods that can be serialized for the object
    def serializable_methods
      return [] if self.class.serializable_methods.nil?
      self.class.serializable_methods
    end

    module ClassMethods
      attr_accessor :serializable_fields_default, :serializable_fields_additional, :serializable_methods

      # Full set of serializable fields for the object
      def serializable_fields
        @serializable_fields_default.concat @serializable_fields_additional
      end

      # Setter for the default serializable fields. Example:
      #   class TestClass
      #      serialize_default :id, :name
      #   end
      # @param [Symbol] list of symbols corresponding to attribute names
      def serialize_default(*fields)
        @serializable_fields_default = fields
      end

      # Setter for additional fields (non-default) that the object can serialize
      # @param [Symbol] list of symbols corresponding to attribute names
      def serialize_additional(*fields)
        @serializable_fields_additional = fields
      end

      # Setter for methods that can be serialized
      # @param [Symbol] list of symbols corresponding to instance method names
      def serialize_methods(*methods)
        @serializable_methods = methods
      end
    end
  end
end