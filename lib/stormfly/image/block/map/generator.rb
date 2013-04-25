# The Generator takes a list of ranges to be read from a file and provides
# an enumerator to obtain them at your own leisure.

module StormFly
  module Image
    module Block
      module Map

        def self.Generator(*args)
          Generator.new(*args)
        end

        class Generator
          include Enumerable

          def initialize(file, list)
            @f = file
            @list = list
            verify!
            @f.advise :sequential
            @f.advise :noreuse
          end

          def each(&block)
            Enumerator.new do |y|
              l = @list.lazy
              loop do
                begin
                  r = l.next
                rescue StopIteration
                  break
                end
                y.yield r, read(r)
              end
            end.each(&block)
          end

          private

          GETBLKSIZE64 = 0x80081272

          # drops blocks that cannot be read on the specified file
          def verify!
            unread = unreadable
            if unread.any?
              @list -= unread
              false
            else
              true
            end
          end

          def read(range)
            off, sz = range.begin, range.size
            @f.seek(off)
            @f.read(sz).tap do
              # free up page cache
              @f.advise(:dontneed, off, sz)
            end
          end

          # produces a list of unaddressable blocks (this can happen if the list was generated for a differently sized device)
          def unreadable
            size = size_of_file @f
            @list.select do |r|
              r.begin >= size or r.end > size
            end.tap do |l|
              STDERR.puts "Found #{l.size} unaddressable ranges with #{l.inject(0) { |acc, r| acc += r.size }} bytes of data" if l.any?
            end
          end

          def size_of_device(dev)
            ioctlparams = [0].pack 'L_'
            dev.ioctl(GETBLKSIZE64, ioctlparams)
            ioctlparams.unpack('L_').first
          end

          def size_of_file(file)
            s = ::File.stat file
            if s.blockdev?
              size_of_device file
            else
              s.size
            end
          end
        end

      end
    end
  end
end
