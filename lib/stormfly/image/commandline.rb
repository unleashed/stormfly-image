require 'optparse'
require 'pathname'
require 'stormfly/image/version'
require 'stormfly/image/util/rubyversion'

module StormFly
  module Image
    module CommandLine

      WritablePathname = Class.new Pathname
      BlockPathname = Class.new Pathname

      def option_parser(*args)
        OptionParser.new(*args) do |opts|
          opts.version = StormFly::Image::VERSION

          opts.accept Pathname do |pathname|
            Pathname.new(pathname).tap do |pn|
              raise ArgumentError, "cannot read #{pathname}" unless pn.readable?
            end
          end

          opts.accept WritablePathname do |wpathname|
            WritablePathname.new(wpathname).tap do |pn|
              raise ArgumentError, "cannot write to #{wpathname}" unless pn.writable? or
                  (not pn.exist? and pn.dirname.writable?)
            end
          end

          opts.accept BlockPathname do |bpathname|
            BlockPathname.new(bpathname).tap do |bn|
              raise ArgumentError, "#{bpathname} is not a block device" unless bn.blockdev?
            end
          end

          opts.on_tail '-v', '--version', 'Show this program\'s version' do
            puts opts.ver
            exit
          end

          opts.on_tail '-h', '--help', 'Display this screen' do
            puts opts
            exit
          end

          yield opts if block_given?
        end
      end

      module Application
        def self.run(options = {})
          ruby = options.fetch(:ruby) { '2.0.0' }
          stderr = options.fetch(:stderr, STDERR)
          debug = options.fetch(:debug, false)

          unless StormFly::Image::Util::RubyVersion.is.at_least ruby
            stderr.puts "Please upgrade your Ruby interpreter to at least version #{ruby}"
            exit 1
          end

          return yield if debug

          begin
            yield
          rescue RuntimeError => e
            stderr.puts "runtime error: #{e}"
            exit 3
          rescue StandardError => e
            stderr.puts "error: #{e}"
            exit 4
          rescue SystemExit => e
            exit e.status
          rescue Interrupt
            stderr.puts "interrupted"
            exit 130 # SIGINT status
          rescue Exception => e
            stderr.puts "exception: #{e}"
            exit 5
          end
        end

      end # module Application

    end # module CommandLine
  end # module Image
end # module StormFly
