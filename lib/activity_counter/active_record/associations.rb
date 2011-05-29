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
          # puts "Rails version"
          activity_counter_add_counter_cache_callbacks(reflection)
        else
          puts reflection.active_record.inspect
          MultipleCounter.add_multiple_counter_cache(reflection)
          # puts "Multiple counter cache!!! #{reflection.name}"
          # puts "#{reflection.options[:counter_cache].inspect}"
        end
      end

      module MultipleCounter
        def self.add_multiple_counter_cache(reflection)
          
          reflection.active_record.send :extend, ActivityCounter::Model::Cached::ClassMethods
          reflection.active_record.configure_cached_class(reflection)
        end
        
        
        module CounterNamespaces
          # Pending, Accepted, Rejected
          class Type
            attr_reader :status, :name
            
            def initialize(status, status_name)
              @status = status
              @name = status_name
            end
            def value
              self.to_s
            end
            def to_s
              status.list[name]
            end
            
            # invitation.status.pending.is?
            def is?
              status == value
            end
            def to?
              changes and changes.last == value
            end
            def from?
              changes and changes.first == value
            end
            def changes
              status.changes
            end
            def counter
              reflection_name = status.record.reflection.name
              source = status.record.send(reflection_name)
              
              cached_class_name = status.cached_class_name
              cached_relation_name = status.cached_relation_name
              Counter.create_or_retrieve({:source => source, :cached_class => cached_class_name, :cached_relation => cached_relation_name, :name => name})
            end
            def call(status)
              @status = status
            end
          end
        end

      end
    end
  end
end