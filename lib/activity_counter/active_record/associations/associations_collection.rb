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
        puts "Class variable Owner: #{@owner}"
        puts "Given Owner: #{owner.inspect}"
        puts "Containing class: #{self.object_id}"
        @counter_cache_options = reflection.reverseme.last.options[:counter_cache]
        @counter_cache_options_without_default = @counter_cache_options.reject{ |key,value| key == :default }
        define_counters_accessor
      end
      #alias_method :rails_method_missing, :method_missing
      #def method_missing(method, *args)
      #  puts "missing method #{method}"
      #  if @counter_cache_options.reject{ |key,value| key == :default }.keys.include?(method.to_sym)
      #    
      #    send(method)
      #  else
      #    rails_method_missing(method, args.first)
      #  end
      #end
      private
      def define_counters_accessor
        @counter_cache_options_without_default.keys.each do |accessor_name|
          eval <<-MAGIC
            module MagicMethods
              def #{accessor_name}
                puts "Containing class: \#{self.object_id}"
                puts "Owner: \#{@owner.inspect}"
                Counter.create_or_retrieve(:source => @owner, :auto => @reflection, :name => #{accessor_name.inspect})
              end
            end
          MAGIC
        end
        self.class.send :include, MagicMethods
        @counter_cache_options_without_default.keys.each do |accessor_name|
          puts "Is #{accessor_name} defined? #{(respond_to? accessor_name).inspect}"
        end
      end
    end
  end
end