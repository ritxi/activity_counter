require 'active_record/associations'
require 'activity_counter/model/cached'
module ActiveRecord
  module Associations
    module ClassMethods
      private
      alias_method :activity_counter_add_counter_cache_callbacks, :add_counter_cache_callbacks
      valid_keys_for_belongs_to_association << :status_field unless valid_keys_for_belongs_to_association.include?(:status_field)
      def add_counter_cache_callbacks(reflection)
        unless reflection.options[:counter_cache].is_a?(Hash)
          # simple counter cache rails version
          activity_counter_add_counter_cache_callbacks(reflection)
        else
          MultipleCounter.add_multiple_counter_cache(reflection)
        end
      end

      module MultipleCounter
        def self.add_multiple_counter_cache(reflection)
          reflection.active_record.send :extend, ActivityCounter::Model::Cached::ClassMethods
          reflection.active_record.configure_cached_class(reflection)
        end
      end
    end
  end
end