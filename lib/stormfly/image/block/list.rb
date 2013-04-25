require "stormfly/image/util/composable"

module StormFly
  module Image
    module Block

      def self.List
        List.new
      end

      class List
        include StormFly::Image::Util::Composable

        composed_of :list
  
        def initialize
          @list = []
        end

        def coalesce!
          replace(inject([uniq!.sort!.shift]) do |acc, nxt|
            last = acc.last
            if last.mergeable? nxt
              last.merge! nxt
              acc
            else
              acc << nxt
            end
          end)
          # return our container instead of the newly replaced list
          self
        end

        private

        def uniq!
          @list.tap &:uniq!
        end

        def sort!
          @list.tap &:sort!
        end

      end # class List

    end # module Block
  end # module Image
end # module StormFly
