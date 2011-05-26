module ActivityCounter
  module Model
    module Counter
      module ClassMethods
        def validate_counter
          send :validates_uniqueness_of, :name, :scope => [:source_class, :source_id, :cached_relation], :on => :create
          send :validates_presence_of, :source_class, :source_id, :cached_class, :name
          send :validates_presence_of, :cached_relation, :if => :pluralized_class_is_relation_name
        end
        
        def create_or_retrieve(*options)
          options = cleanup_params(options.first)
          counter = self.where(options).first
          
          (counter.blank? ? generate!(options) : counter)
        end
        
        def generate(*options)
          self.new(cleanup_params(options.first))
        end
        
        def split_source(options)
          @source = options.delete(:source)
          {:source_class => @source.class.to_s, :source_id => @source[:id]}.merge(options)
        end
        
        def find_reflection_name(options)
          case
          when options[:reverse] then
            reverse = options.delete(:reverse)
            options[:source_reflection] = reverse.reverseme.name
          when options[:cached_class] then
            cached_class = options.delete(:cached_class)
            
          when options[:reflection] then
            reflection = options.delete(:reflection)
            options[:source_reflection] = reflection.name
          end
          options
        end
        
        # :source => object that has many items
        #   :reverse => reflection on the belongs to side
        #   :cached_class => class that belongs to other one
        #   :reflection => has_many reflection of the source side
        # :name => counter name
        def cleanup_params(*options)
          options = options.first
          [:source, [:reverse, :reflection], :name].each do |option|
            if option.is_a?(Array)
              option.each{|new_options| validate_option(options, new_options)}
            else
              validate_option(options, option)
            end
          end
          
          options = split_source(options)
          
          options
        end
        def generate!(*options)
          counter = generate(options.first)
          counter.save
          counter
        end
        private
        def validate_option(options, option)
          unless options.keys.include?(option)
            raise "missing parameter #{option} at #{self.class.to_s}.generate method"
          end
        end
          
      end
      module InstanceMethods
        
        # belongs_to relation
        def belongs_to_relation_name
          self[:cached_relation].blank? ? source_class.tableize : self[:cached_relation]
        end
        alias_method :cached_relation, :belongs_to_relation_name
        def source
          eval("#{source_class}.find(#{source_id})")
        end
        def increase
          update_attribute(:count, self[:count]+1)
        end
        def decrease
          self[:count] > 0 and update_attribute(:count, self[:count]-1)
        end
        def cached_items
          # Not working with relations having custom names yet!!!
          cached_class.tableize
          source.send(cached_class.tableize)
        end
        
        def pluralized_class_is_relation_name
          unless source_class.blank?
            #puts "source_class: #{source_class}"
            has_relation = eval(source_class).reflections.keys.include?(cached_relation)
            if self[:cached_relation].blank? && !has_relation
              errors[:cached_relation] << "No relation found named #{cached_relation} for #{self[:cached_class]}"
            end
          end
        end
      end
    end
  end
end