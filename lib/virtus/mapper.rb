require 'virtus/mapper/version'
require 'virtus'
require 'active_support/core_ext/hash/indifferent_access'

HWIA = ActiveSupport::HashWithIndifferentAccess

module Virtus
  module Mapper

    attr_reader :mapped_attributes

    def initialize(attrs={})
      @mapped_attributes = HWIA.new(attrs)
      super(prepare_attributes_for_assignment!(@mapped_attributes))
    end

    # A workaround for https://github.com/solnic/virtus/issues/266
    def extend_with(mod)
      attr_set = attribute_set
      self.extend(mod) # Virtus modifies attribute_set
      set_attr_values(attribute_set.collect(&:name))
      update_attribute_set(attr_set)
    end

    private

    def prepare_attributes_for_assignment!(attrs)
      nil_value_keys = attrs.collect { |k, v| k if v.nil? }.compact
      attrs.tap do |h|
        attributes_to_map_by_symbol(attrs).each do |att|
          h[att.name] = h.delete(from(att))
        end
        attributes_to_map_by_call.each do |att|
          h[att.name] = from(att).call(h)
        end
      end.delete_if { |k, v| !nil_value_keys.include?(k) && v.nil? }
    end

    def attributes_to_map_by_symbol(attrs)
      attributes_to_map.select do |att|
        !from(att).respond_to?(:call) &&
        !attrs.has_key?(att.name)
      end
    end

    def attributes_to_map_by_call
      attributes_to_map.select { |att| from(att).respond_to?(:call) }
    end

    def attributes_to_map
      attribute_set.select { |att| !(from(att).nil?) }
    end

    def from(attribute)
      attribute.options[:from]
    end

    def update_attribute_set(attr_set)
      attr_set.merge(attribute_set)
      self.attribute_set = attr_set
    end

    def attribute_set=(attr_set)
      instance_variable_set(:@attribute_set, attr_set)
    end

    def set_attr_values(names)
      attrs = prepare_attributes_for_assignment!(mapped_attributes)
      names.each do |name|
        self.send("#{name}=", attrs[name])
      end
    end
  end
end
