module StormFly
  module Image
    class BurnManager

      class Burner
        attr_reader :range_queue
        attr_accessor :output

        def initialize(filename, output = STDOUT)
          @filename, @output = filename, output

          @file = File.open filename, 'wb'
          @file.advise :noreuse

          @range_queue = Queue.new
        end

        def burn!
          loop do
            # block on Queue#pop
            range, data, vrfy = @range_queue.pop
            break true unless range
            break false unless burn(range, data, vrfy)
          end
        end

        private

        def burn(range, data, verify = false)
          @file.seek(range.begin)
          @file.write data

          # :noreuse is usually a no-op (which it _is_ for Linux 3.5). so make sure we also specify dontneed for each range.
          @file.advise(:dontneed, range.begin, range.size)

          if verify
            # sync the data at this point, else we might read garbage because of page cache being discarded
            # and the verify method reading directly without the data being necessarily on-disk
            @file.fdatasync rescue nil

            verify(range, data)
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

      attr_accessor :targets, :uuids, :check, :output

      def initialize(imagefile, targets, check, options = {})
        @targets = options.fetch(:targets) { [] }
        @uuids = options.fetch(:uuids) { [] }
        @check = options.fetch(:check, false)
        @output = options.fetch :output, STDOUT
        @segmentsize = options.fetch :segmentsize, 1536*1024
        @r = StormFly::Image::Block::Map::Reader @imagefile, @segmentsize
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

          # this waits until all threads are waiting (waiting on Queue#pop or dead)
          sleep 1 until threads.all? &:stop?
          # get out if no thread is alive
          break if threads.none? &:alive?

          # verify if an UUID was patched or if it is the first range
          verify = check and patched or range.begin == 0
          range_desc = [range, data, verify]

          burners.each do |burner|
            next unless b2t[burner].alive?
            burner.range_queue << range_desc
          end
        end # each

        {}.tap do |results|
          b2t.map do |burner, t|
            results[burner.filename] = t.value
          end
        end

      end # class Burner

    end # class BurnManager
  end # module Image
end # module StormFly
