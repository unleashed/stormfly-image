# A simple module to allow a class to be composed of a single object

module StormFly
  module Image
    module Util

      module Composable
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def composed_of(composed)
            class_eval do
              define_method composed do
                instance_variable_get("@#{composed}")
              end

              define_method "#{composed}=" do |newval|
                instance_variable_set("@#{composed}", newval)
              end

              private composed, "#{composed}="

              define_method :is_a? do |klass|
                __send__(composed).is_a?(klass) or super
              end

              define_method :method_missing do |sym, *args, &blk|
                begin
                  r = __send__(composed).public_send(sym, *args, &blk)
                rescue NoMethodError
                  super
                end
                # do not return the composed object but the whole container
                # we must actually get back the composed object using the
                # getter, because the composed variable could very well be
                # stale at that point (ie. the composed object has been replaced)
                # equal? method tests for object id equality.
                r.equal?(__send__ composed) ? self : r
              end

              define_method :respond_to? do |*args|
                send(composed).public_send(:respond_to?, *args) or
                  super
              end
            end # class_eval
          end # def

        end # module ClassMethods

      end # module Composable

    end # module Util
  end # module Image
end # module StormFly
