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
    end
  end
end