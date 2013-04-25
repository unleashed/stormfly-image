# Block::Map::{Read,Writ}er classes allow us to read and write from files
# describing the offsets and data of an image.

module StormFly
  module Image
    module Block
      module Map

        def self.Reader(*args)
          Reader.new(*args)
        end

        def self.Writer(*args)
          Writer.new(*args)
        end

        # StreamedData provides data from a seekable stream in easily digerible chunks of "chunksize" bytes
        class StreamedData
          include Enumerable

          def initialize(source, offset, datasize, chunksize)
            @source, @offset, @datasize, @chunksize = source, offset, datasize, chunksize
            @srcoffset = source.tell
          end

          def each(&block)
            Enumerator.new do |y|
              consumed = 0

              while consumed < @datasize
                off = @srcoffset + consumed
                sz = [@datasize - consumed, @chunksize].min

                @source.seek off
                d = @source.read(sz)

                break if d.nil? or d.empty?

                @source.advise :dontneed, off, sz
                # experimentation says the line below actually produces a slow down
                #@source.advise :willneed, off + sz, 0

                y.yield(@offset + consumed, d)

                consumed += d.bytesize
              end

            end.each(&block)
          end

        end

        class Reader
          @@re = Regexp.new('O: (?<offset>\d+) \* S: (?<size>\d+)', nil, 'n')

          include Enumerable

          attr_reader :file

          # chunksize can present problems for UUIDs because right now we cannot search UUIDs across contiguous chunks
          # XXX so we'll set it to a huge value for the time being.
          def initialize(file, chunksize = 1536*1024)
            @file, @chunksize = file, 1536*1024*30000
            @file.advise :sequential
            @file.advise :noreuse
          end

          def read_header
            begin
              # this discards the NEW BLOCK thing and goes straight to the info line
              2.times { file.readline }
              infoline = file.readline
            rescue EOFError
              return nil
            end

            md = @@re.match infoline
            raise "Could not read offset/size info at map file offset #{file.tell}" unless md

            [Integer(md[:offset]), Integer(md[:size])]
          end

          # this reads a block info, not the actual data, which is provided gradually by the StreamedData object
          def read_block
            off, size = read_header
            return nil unless off

            StreamedData.new(file, off, size, @chunksize)
          end

          def each(&block)
            Enumerator.new do |y|
              loop do
                d = read_block
                break unless d

                d.each do |off, data|
                  y.yield(Block::Range.new(off, off + data.size), data)
                end
              end
            end.each(&block)
          end

        end

        class Writer
          attr_reader :file

          def initialize(file, list)
            @file, @list = file, list
            @file.advise :sequential
            @file.advise :noreuse
            @file.advise :dontneed
          end

          def write!(&blk)
            @list.each do |r, data|
              written = retries = 0

              d = blk ? blk.call(data) : data
              sz = data.size

              file.write "\n=== NEW BLOCK ===\nO: #{r.begin} * S: #{d.size}\n"

              while written < sz
                raise "Too many retries trying to write to file" if retries > 10
                retries += 1
                written += file.write d[written..-1]
              end
              # advising a :dontneed after writing for this range has proven to actually slow down
              # execution (although maybe performs better memory-wise)
            end
          end

        end

      end
    end
  end
end
