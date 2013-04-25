module StormFly
  module Image
    module Block
      module Map

        class ByteScanner
          attr_reader :data, :base_offset

          def initialize(data, base_offset = 0)
            @data, @base_offset = data, base_offset
          end

          def find(bytes, &blk)
            [].tap do |off|
              @data.scan(Regexp.new(Regexp.escape(bytes), nil, 'n')) do |_|
                o = Regexp.last_match.offset(0).first
                off << (o + @base_offset) if not blk or blk.call(o, data)
              end
            end
          end

          def patch(off, replace)
            @data[off - @base_offset, replace.size] = replace
          end
        end

      end
    end
  end
end
