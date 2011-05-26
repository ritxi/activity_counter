require 'active_record/associations/association_collection'
module ActiveRecord
  module Associations
    class AssociationCollection < AssociationProxy
      #
      # count_on :new 
      # count_on :all (default if no params are given)
      # count_on :accepted
      # count_on :all, :force => true (count all and force calculated using sql)
      def count_on(*options)
        counter_name    = options.first
        counter_options = options.last
        if options.blank?
          options.keys.include?(:force)
          count
        else
          source = @owner
          cached = inverse_class_name
        end
      end
      
      alias_method :activity_count_initialize, :initialize
      def initialize(owner, reflection)
        activity_count_initialize(owner, reflection)
        reflection.reverseme(reflection)
        if reflection.reverseme.last.options[:counter_cache].is_a?(Hash)
          options = reflection.reverseme.last.options[:counter_cache].reject{ |key,value| key == :default }
        end
      end
      private
      def define_counter_accessor(reflection, accessor_name)
        class_eval <<-MAGIC
          def #{accessor_name}
            Counter.create_or_retrieve(:source => @owner, :reflection => @reflection, :name => #{accessor_name.inspect})
          end
        MAGIC
      end
    end
  end
end