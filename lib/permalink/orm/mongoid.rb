module Permalink
  module Orm
    module Mongoid
      attr_accessor :permalink_options

      # permalink :title
      # permalink :title, :to => :custom_permalink_field
      # permalink :title, :to => :permalink, :to_param => [:id, :permalink]
      # permalink :title, :unique => true
      def permalink(from, options={})
        include InstanceMethods

        options = { :to => :permalink,
                    :to_param => :permalink,
                    :unique => false }.merge(options)

        self.permalink_options = { :from_column_name => from,
                                   :to_column_name => options[:to],
                                   :to_param => [options[:to_param]].flatten,
                                   :unique => options[:unique] }

        field options[:to]
        key options[:to]

        before_validation :create_permalink
        before_save :create_permalink
      end

      module InstanceMethods
        def to_param
          to_param_option = self.class.permalink_options[:to_param]

          to_param_option.compact.collect do |name|
            if respond_to?(name)
              send(name).to_s
            else
              name.to_s
            end
          end.reject(&:blank?).join('-')
        end

        private
        def next_available_permalink(_permalink)
          the_permalink = _permalink

          if self.class.permalink_options[:unique]
            suffix = 2

            while self.class.where(to_permalink_name => the_permalink).first
              the_permalink = "#{_permalink}-#{suffix}"
              suffix += 1
            end
          end

          the_permalink
        end

        def from_permalink_name
          self.class.permalink_options[:from_column_name]
        end

        def to_permalink_name
          self.class.permalink_options[:to_column_name]
        end

        def from_permalink_value
          read_attribute(from_permalink_name)
        end

        def to_permalink_value
          read_attribute(to_permalink_name)
        end

        def create_permalink
          unless from_permalink_value.blank? || !to_permalink_value.blank?
            write_attribute(to_permalink_name, next_available_permalink(from_permalink_value.to_s.to_permalink))
          end
        end
      end
    end
  end
end

Mongoid::Document::ClassMethods.class_eval do
  include Permalink::Orm::Mongoid
end
