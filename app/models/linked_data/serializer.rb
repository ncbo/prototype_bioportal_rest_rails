
module LinkedData
  module Serializer

    def self.included(base)
      base.extend(ClassMethods)
    end

    def serializable_fields
      fields = self.class.serializable_fields_default.nil? ? [] : self.class.serializable_fields_default
      fields_additional = self.class.serializable_fields_additional.nil? ? [] : self.class.serializable_fields_additional
      fields.concat fields_additional
    end

    def serializable_fields_default
      return [] if self.class.serializable_fields_default.nil?
      self.class.serializable_fields_default
    end

    def serializable_methods
      return [] if self.class.serializable_methods.nil?
      self.class.serializable_methods
    end

    module ClassMethods
      attr_accessor :serializable_fields_default, :serializable_fields_additional, :serializable_methods

      def serializable_fields
        @serializable_fields_default.concat @serializable_fields_additional
      end

      def serialize_default(*fields)
        @serializable_fields_default = fields
      end

      def serialize_additional(*fields)
        @serializable_fields_additional = fields
      end

      def serialize_methods(*methods)
        @serializable_methods = methods
      end
    end
  end
end