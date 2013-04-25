module StormFly
  module Image
    class UUID

      class Gatherer
        attr_accessor :file

        include Enumerable

        def initialize(file, uuid_builder = UUID)
          @file, @uuid_builder = file, uuid_builder
        end

        def each(&block)
          Enumerator.new do |y|
            loop do
              begin
                u = @file.readline.split('=').last.chomp!
              rescue EOFError
                # this allows for a rewind if needed
                @file.seek 0 if @file.respond_to? :seek
                break
              end
              y << (@uuid_builder ? @uuid_builder.build(u) : u)
            end
          end.each(&block)
        end

        def uuids
          each do end
        end

      end # class Gatherer

    end # class UUID
  end # module Image
end # module StormFly
