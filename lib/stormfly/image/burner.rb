module StormFly
  module Image
    class BurnManager
      class Burner
        attr_reader :range_queue
        attr_accessor :output

        def initialize(filename, *args, &blk)
          @filename = filename
          @file = File.open filename, 'wb'
          @file.advise :noreuse

          @range_queue = Queue.new
          @output = STDOUT

          super(*args, &blk)
        end

        def burn!
          loop do
            range, data, vrfy = @range_queue.pop
            break true unless range
            break false unless burn(range, data, vrfy)
          end
        end

        private

        def burn(range, data, verify = false)
          @file.seek(range.begin)
          @file.write data

          # :noreuse is usually a no-op (which it _is_ for Linux 3.5). make sure this gets explicited nonetheless.
          @file.advise(:dontneed, range.begin, range.size)

          # verify if an UUID was patched or if it is the first range
          if verify
            # sync the data at this point, else we might read garbage because of page cache being discarded
            # and the verify method reading directly without the data being necessarily on-disk
            @file.fdatasync rescue nil

            verify(range, data)
            #.tap do |ok|
            #  @output.print (ok ? 'Verify OK' : 'Verify FAILED')
            #end
          else
            true
          end
        end

        def verifyfile
          @verifyfile ||= File.open(@filename, 'rb').tap do |vf|
            vf.advise :random
            vf.advise :noreuse
            vf.advise :dontneed
          end
        end

        def verify(range, data)
          advices = [:noreuse, :dontneed]
          advices.each do |advice|
            # discard this specific data range
            verifyfile.advise(advice, range.begin, range.size)
          end
          verifyfile.seek(range.begin)
          (verifyfile.read(range.size) == data).tap do
            # discard everything on the page cache
            advices.each { |advice| verifyfile.advise advice }
          end
        end
      end # class Burner

      def initialize(imagefile, targets, check, options = {})
        @uuids = options.fetch(:uuids) { [] }
        @output = options.fetch :output, STDOUT
        segmentsize = options.fetch :segmentsize, 1536*1024
        @r = StormFly::Image::Block::Map::Reader imagefile, segmentsize
      end

      def burn!
        output.puts "=> Reading and burning <="

        burners = targets.map do |tgtfile|
          Burner.new(tgtfile)
        end

        b2t = {}
        threads = burners.map do |burner|
          Thread.new do
            Thread.current[:burner] = burner
            burner.burn!
          end.tap do |t|
            b2t[burner] = t
          end
        end

        @r.each do |range, data|
          p = StormFly::Image::UUID::Patcher.new(range.begin, data)
          p.output = output

          patched = uuids.map do |u, new_u|
            matches_s, matches_b = p.replace_uuid(u, new_u)
            (matches_s + matches_b > 0).tap do |matched|
              output.puts "#{matches_s + matches_b} matches of #{u} of which #{matches_s} literal and #{matches_b} binary replaced with #{new_u}." if matched
            end
          end.any?

          verify = check and patched or range.begin == 0
          range_desc = [range, data, verify]

          # this waits until all threads are waiting (done writing prev range or dead)
          sleep 1 until threads.each(&:stop?).all?
          # FAIL if no thread is alive
          return false if threads.none? &:alive?

          burners.each do |burner|
            next unless b2t[burner].alive?
            burner.range_queue << range_desc
          end
        end
      end # spinner
    end # each
    results = threads.map(&:value)
  end # open
  true
end

      end
        

    end # class BurnerManager
  end # module Image
end # module StormFly


def get_queued_range
  r = Thread.current[:data]
  [r[:range], r[:data], r[:verify]]
end

def burn_thread(target, output = STDOUT)
  File.open target, 'wb' do |tgt|
    tgt.advise :noreuse

    File.open target, 'rb' do |tgtdirect|
      tgtdirect.advise :random
      tgtdirect.advise :noreuse
      tgtdirect.advise :dontneed

      loop do
        range, data, verify = queue.pop
        break false unless burn_range(tgt, range, data, verify ? tgtdirect : nil, output)
      end
    end
  end
end
