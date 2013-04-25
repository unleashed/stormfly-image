module StormFly
  module Image
    module Util
      module Spinner
        
        class Output < Array
          alias_method :puts, :<<
          alias_method :print, :<<
        end

        def spinner(title, options = {})
          fps = options.fetch(:fps, 20)
          output = options.fetch(:output, STDOUT)
          quote_freq = options.fetch(:quote_freq, 10)
          quotes = options.fetch(:quotes) { ['working hard', 'wasting time', 'shuffling bits around', 'flushing to /dev/null', 'thinking', 'applying magic', 'watching paint dry', 'accelerating', 'waiting for python', 'running java', 'getting older', 'growing beard'] }
          short_title = options.fetch(:short) { title.split.first }

          lines = Output.new
          chars = %w[| / - \\]
          delay = 1.0/fps
          iter = 0

          output.print "#{title}... "
          output.flush

          return yield(lines).tap { spinner_flush(output, lines, short_title) } unless output.isatty

          spinner = Thread.new do
            totalwait = 0.0
            q = quotes.shuffle.cycle
            quote = q.next
            change_quote = false

            while iter do
              c = chars[(iter += 1) % chars.length]
              if totalwait > quote_freq
                rem = totalwait % quote_freq
                if rem < 1.5
                  c = "*#{quote}*"
                  change_quote = true
                else
                  quote = q.next if change_quote
                  change_quote = false
                end
              end

              output.print c

              sleep delay
              totalwait += delay

              output.print "\b" * c.size
              output.print " " * c.size
              output.print "\b" * c.size
            end
          end

          yield(lines).tap do
            iter = false
            spinner.join
            output.print "\b"
            spinner_flush(output, lines, short_title)
          end
        end

        private

        def spinner_flush(output, lines, short_title)
          output.print " done.\n"
          lines.each do |l|
            output.puts "#{short_title} >>> #{l}"
          end
          output.flush
        end

      end # module Spinner
    end # module Util
  end # module Image
end # module StormFly
