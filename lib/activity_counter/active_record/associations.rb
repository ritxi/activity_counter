require 'active_record/associations'
module ActiveRecord
  module Associations
    module ClassMethods
      private
      alias_method :activity_counter_add_counter_cache_callbacks, :add_counter_cache_callbacks
      def add_counter_cache_callbacks(reflection)
        puts "Adding counter cache"
        unless reflection.options[:counter_cache].is_a?(Hash)
          puts "Simple version"
          activity_counter_add_counter_cache_callbacks(reflection)
        else
          MultipleCounter.add_multiple_counter_cache(reflection)
          puts "Multiple counter cache!!! #{reflection.name}"
          puts "#{reflection.options[:counter_cache].inspect}"
        end
      end

      module MultipleCounter
        
        def self.add_multiple_counter_cache(reflection)
          status_field_name = status_field_for(reflection)
          statuses = reflection.options[:counter_cache]
          
          class_eval <<-MAGIC, __FILE__, __LINE__ + 1
            def #{status_field_name.pluralize}
              
              
            end
            def #{status_field_name}(counter_name)
              reflection_name ='#{reflection.name}'
              eval "@#{status_field_name}_#{counter_name}_accessor" ||= RelationCounter.new(self, reflection.name, counter_name, #{value})
            end
          MAGIC
          
          statuses.each_pair do |type,value|
            exception = [:defaults].include?(type)
            methods = %W(#{type} #{type}? to_#{type}? from_#{type}?).map{|method| self.method_defined?(method) ? 'yes' : nil }.compact
            if methods.empty? && !exception

            else
              if type == :defaults
                class_eval <<-MAGIC, __FILE__, __LINE__ + 1
                  def to_new?
                    created_at == updated_at
                  end
                  alias_method :new?, :to_new?
                  def from_new?
                    changes['updated_at'] and changes['updated_at'].first == created_at
                  end
                MAGIC
              elsif !exception
                raise "#{type} method already exists"
              end
            end
          end
        end
        
        
        module CounterNamespaces
          def self.status_field_for(reflection)
            (reflection.options[:status_field] or 'status')
          end
          # Pending, Accepted, Rejected
          class Type
            attr_reader :value, :status, :name
            
            def initialize(status, status_name)
              @status = status
              @name = status_name
            end
            
            def to_s
              status.list[name]
            end
            
            # invitation.status.pending.is?
            def is?
              status == self
            end
            
            def to?
              changes and changes.last == value
            end
            def from?
              changes and changes.first == value
            end
            def changes
              status.record.changes[status_field_name] or nil
            end
            def counter
              reflection_name = status.record.reflection.name
              source = status.record.send(reflection_name)
              
              cached_class_name = status.cached_class_name
              cached_relation_name = status.cached_relation_name
              Counter.create_or_retrieve({:source => source, :cached_class => cached_class_name, :cached_relation => cached_relation_name, :name => name})
            end
          end
          
          # It represents the "status" column
          class Status
            attr_reader :record, :reflection, :name, :status_field
            
            def initialize(record, reflection_name, statuses)
              @record, @reflection, @statuses = record, reflection_for(record, reflection_name), statuses
              @status_field = CounterNamespaces.status_field_for(@reflection)
            end
            def list
              @statuses
            end
            def to_s
              record[status_field]
            end
            
            def cached_class_name
              (reflection.options[:class_name] or reflection.name.classify)
            end
            def cached_relation_name
              reflection.active_record.to_s
            end
            private
            def reflection_for(record, name)
              record.class.reflections[name]
            end
          end
        end
        def listen_changes_on_create(reflection)
          statuses = reflection.options[:counter_cache]
        
        end
      
        def listen_changes_on_update(reflection)
        
        end
      
        def listen_changes_on_destroy(reflection)
        
        end
      end
    end
  end
end