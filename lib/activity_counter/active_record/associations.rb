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
        def self.status_field_for(reflection)
          (reflection.options[:status_field] or 'status')
        end
        def self.add_multiple_counter_cache(reflection)
          status_field_name = status_field_for(reflection)
          statuses = reflection.options[:counter_cache]

          statuses.each_pair do |type,value|
            exception = [:defaults].include?(type)
            methods = %W(#{type} #{type}? to_#{type}? from_#{type}?).map{|method| self.method_defined?(method) ? 'yes' : nil }.compact
            if methods.empty? && !exception
              class_eval <<-MAGIC, __FILE__, __LINE__ + 1
                def #{type}
                  @#{type}_accessor ||= RelationCounter.new(self, reflection.name, #{type}, #{value})
                end
              MAGIC
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
        
        class RelationCounter
          attr_reader :record, :reflection, :name, :value
      
          def initialize(record, reflection_name ,status_name, status_value)
            @record, @reflection, @name, @value = record, reflection_for(record, reflection_name), status_name, status_value
          end
          def to?
            changes and changes.last == value
          end
          def from?
            changes and changes.first == value
          end
          def changes
            record.changes[status_field_name] or nil
          end
          #def count
          #  Counter.where(:source_class => inverse_class_name, :source_id => source[:id], :cached_class => record.class.to_s, :name => counter_name).count
          #end
          private
          def reflection_for(record, name)
            record.class.reflections[name]
          end
          def inverse_class_name
            (reflection.options[:class_name] or reflection.name.classify)
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