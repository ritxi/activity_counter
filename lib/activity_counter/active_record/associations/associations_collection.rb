require 'active_record/associations/association_collection'
module ActiveRecord
  module Associations
    class AssociationCollection < AssociationProxy
      attr_reader :counter_cache_options_without_default, :default_counters
      def owner
        @owner
      end
      
      
      alias_method :activity_count_initialize, :initialize
      def initialize(owner, reflection)
        activity_count_initialize(owner, reflection)
        @counter_cache_options = reflection.reverseme.options[:counter_cache]
        @defaults = {}
        @has_status_counter = reflection.reverseme.has_status_counter?
        if @has_status_counters
          @counter_cache_options_without_default = @counter_cache_options.reject{ |key,value| key == :default }
          @defaults = @counter_cache_options[:default]
        end
        @internal_counter = InternalCounter.new(@owner, @reflection, self)
        @default_counters = []
      end
      
      def method_missing(method, *args)
        is_status_counter = Proc.new{|method|
          @has_status_counter and @counter_cache_options.reject{ |key,value| key == :default }.keys.include?(method.to_sym)
        }
        is_default_counter = Proc.new{|method|
          [:new, :total].include?(method)
        }
        if is_status_counter.call(method) || is_default_counter.call(method)
          counter_name = method
          eval <<-MAGIC
            def #{counter_name.to_s}
              @internal_counter.send(:call, #{counter_name.inspect})
            end
          MAGIC
          send(counter_name)
        else
          super
        end
      end
      private

      class InternalCounter
        def initialize(owner, reflection, collection)
          @counter     ||= {}
          @owner         = owner
          @reflection    = reflection
          @collection    = collection
          @status_column = @reflection.status_column_name
          # statuses hash list
          @counter_caches = collection.counter_cache_options_without_default
        end
        def to_s
          case @current_counter
          when :total then
            @collection
          when :new then
            @collection.where('created_at = updated_at')
          else
            @collection.where( @status_column => @counter_caches[@current_counter] )
          end
        end
        def count(options={})
          options = {:force => false}.merge(options)
          options[:force] ? self.to_s.count : counter.count
        end
        private
        def call(counter_name)
          @current_counter = counter_name
          self
        end
        def counter
          @counter[@current_counter] ||= Counter.create_or_retrieve(:source => @owner, :auto => @reflection, :name => @current_counter)
        end
      end
    end
  end
end