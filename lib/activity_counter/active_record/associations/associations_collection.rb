require 'active_record/associations/association_collection'
module ActiveRecord
  module Associations
    class AssociationCollection < AssociationProxy
      attr_reader :counter_cache_statuses_list, :default_counters
      def owner
        @owner
      end
      
      
      alias_method :activity_count_initialize, :initialize
      def initialize(owner, reflection)
        activity_count_initialize(owner, reflection)
        @counter_cache_options = reflection.reverseme.options[:counter_cache]
        @is_multiple_counter_cache = @counter_cache_options.is_a?(Hash)
        if @is_multiple_counter_cache
          @defaults = {}
          
          @counter_cache_statuses_list = @counter_cache_options.reject{ |key,value| key == :default }
          @has_status_counter = !@counter_cache_statuses_list.blank?
          @defaults = @counter_cache_options[:default]
          @internal_counter = InternalCounter.new(@owner, @reflection, self)
          @default_counters = []
        end
      end
      def call_counter(name)
        @internal_counter.send(:call, name, scoped)
      end
      def method_missing(method, *args)
        is_status_counter = Proc.new{ |method|
          @has_status_counter and @counter_cache_options.reject{ |key,value| key == :default }.keys.include?(method.to_sym)
        }
        is_default_counter = Proc.new{ |method|
          [:new, :total, :simple].include?(method)
        }
        if @is_multiple_counter_cache && (is_status_counter.call(method) || is_default_counter.call(method))
          counter_name = method
          eval <<-MAGIC
            def #{counter_name.to_s}
              call_counter #{counter_name.inspect}
            end
          MAGIC
          send(counter_name)
        else
          super
        end
      end
      private

      class InternalCounter < ActiveSupport::BasicObject
        def initialize(owner, reflection, collection)
          @counter     ||= {}
          @owner         = owner
          @reflection    = reflection
          @collection    = collection.scoped
          
          @status_column = @reflection.status_column_name
          # statuses hash list
          @counter_caches = collection.counter_cache_statuses_list
        end
        def inspect
          case @current_counter
          when :total then
            @collection
          when :new then
            @collection.where("created_at = updated_at")
          else
            @collection.where( @status_column => @counter_caches[@current_counter] )
          end
        end
        def count(options={})
          options = {:force => false}.merge(options)
          (options[:force] && options[:force] == :db ? inspect.count : (counter.reload and counter.count))
        end
        private
        def call(counter_name, collection)
          @current_counter = counter_name
          @collection    = collection
          self
        end
        def counter
          params = {:source => @owner, :auto => @reflection, :name => @current_counter}
          #puts "New counter params: #{params.inspect}"
          @counter[@current_counter] ||= Counter.create_or_retrieve(params)
          
        end
        def method_missing(method, *args, &block)
          inspect.send(method, *args, &block)
        end
      end
    end
  end
end