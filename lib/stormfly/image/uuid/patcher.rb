module StormFly
  module Image
    class UUID

      class Patcher
        attr_writer :output

        def initialize(blockoffset, blockdata, bs = Block::Map::ByteScanner)
          @bs = bs.new(blockdata, blockoffset)
          @output = STDOUT
        end

        def data
          @bs.data
        end

        def find_uuid(uuid)
          {
            uuid.to_s => @bs.find(uuid) { |o, d|
              uuid.class.probe_stream(d, o).tap do |probed, extra|
                @output.puts "Failed probe for #{uuid.to_s} at offset #{o}" unless probed
                @output.puts extra if extra
              end
            },
            uuid.bin => @bs.find(uuid.bin) { |o, d|
              uuid.class.probe_stream(d, o).tap do |probed, extra|
                @output.puts "Failed probe for #{uuid.to_s} at offset #{o} (bin)" unless probed
                @output.puts extra if extra
              end
            }
          }
        end

        def replace_uuid(uuid, uuid_new)
          replacements_s = replacements_b = 0
          find_uuid(uuid).each do |u, ofs|
            if u == uuid.bin
              buffertype = :bin
              replacements_b += ofs.size
            else
              buffertype = :to_s
              replacements_s += ofs.size
            end
            ofs.each do |o|
              @bs.patch(o, uuid_new.public_send(buffertype))
            end
          end
          [replacements_s, replacements_b]
        end

      end # class Patcher

    end # class UUID
  end # module Image
end # module StormFly
