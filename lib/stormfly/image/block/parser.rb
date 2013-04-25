# Block::Parser uses blkparse to get the block data produced by blktrace

require 'pty'

module StormFly
  module Image
    module Block

      def self.Parser(tracefile)
        Parser.new(tracefile)
      end

      class Parser
        attr_reader :list

        def initialize(tracefile)
          @tracefile = tracefile
          @list = Block::List()
        end

        def parse(command = %[blkparse -f "%D %2c %8s %5T.%9t %5p oper %3d action %2a seq %s sector %S numblks %n numbytes %N cmd %C \n" -i #{@tracefile} |
                          grep "sector [[:digit:]]* numblks [[:digit:]]* numbytes [[:digit:]]*"])
          @list = Block::List().tap do |l|
            PTY.spawn command do |reader, writer, pid|
              loop do
                line = read_line(reader) or break
                next if (blkoff, numblks, numbytes = parse_line line).nil? or numbytes == 0
                if numblks == 0		# only happens when ie. numbytes < a block
                  base = blkoff * 512	# XXX this is actually not known, but most likely 512
                else
                  base = blkoff * (numbytes / numblks)
                end
                l << Block::Range(base, base + numbytes)
              end
              Process.wait pid
            end
          end
        end

        def parse!
          parse.coalesce!
        end

        private

        def read_line(reader)
          reader.gets
        rescue Errno::EIO
          nil
        end

        def parse_line(line)
          if md = /sector (?<blkoff>\d+) numblks (?<numblks>\d+) numbytes (?<numbytes>\d+)/.match(line)
            [Integer(md[:blkoff]), Integer(md[:numblks]), Integer(md[:numbytes])]
          end
        end
      end
    end
  end
end
