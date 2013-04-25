# A block range describes the absolute offsets of a block in a certain file
# As a convention, Block::Range does always exclude its end.

module StormFly
  module Image
    module Block

      def self.Range(*args, &blk)
        Range.new(*args, &blk)
      end

      class Range
        include Enumerable
        include Comparable
        include StormFly::Image::Util::Composable

        composed_of :r

        def each(&blk)
          r.each(&blk)
        end

        def <=>(o)
          r.begin <=> o.begin
        end

        def initialize(*args)
          b = args.shift
          if args.empty?
            raise ArgumentError, "wrong argument: must be either a Range or <begin, excluded_end>, #{b.class} given" unless b.is_a? ::Range
            range_initialize(b)
          else
            nonrange_initialize(b, *args)
          end
        end

        def adjacent?(o)
          # note that other objects having variable exclude_end parameters will produce incorrect results
          # (our own object always has exclude_end == true)
          oend = o.end
          oend = oend.succ unless o.exclude_end?
          r.end == o.begin or r.begin == oend
        end

        def mergeable?(o)
          # adjacent ranges are mergeable if the boundaries are discrete (and they are if we can call succ and pred)
          r.cover? o.begin or r.cover? o.end or adjacent? o
        end

        def merge(o)
          raise "Unmergeable ranges #{self.inspect} - #{o.inspect}" unless mergeable? o
          oend = o.end
          oend = oend.succ unless o.exclude_end?
          self.class.new([r.begin, o.begin].min, [r.end, oend].max)
        end

        def merge!(o)
          self.r = merge o
        end

        private

        def range_initialize(nr)
          if not nr.exclude_end?
            nonrange_initialize(nr.begin, nr.end.succ)
          else
            raise "Cannot create a range beginning after ending" if nr.end < nr.begin
            self.r = nr
          end
        end

        # in these kind of ranges you usually don't want to include the specified end
        # this is done so that I can use r = Range.new(offset, offset+size) and
        # have r.size return the same size I used to create the range.
        def nonrange_initialize(rbegin, rexclend)
          raise "Cannot create a range beginning after ending" if rexclend < rbegin
          self.r = ::Range.new(rbegin, rexclend, true)
        end

      end # class Range

    end # module Block
  end # module Image
end # module StormFly
