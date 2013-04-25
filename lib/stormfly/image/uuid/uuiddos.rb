module StormFly
  module Image
    class UUID

      class UUIDDOS < UUID
        pack 'H*'
        unpack 'vv'
        dashes 1
        binsize 4
        strsize 9
        endian :little
        upcase

        def self.probe(uuid)
          /[0-9a-fA-F]{4}-[0-9a-fA-F]{4}/.match uuid or uuid.bytesize == 4
        end

        def self.probe_stream(bytestream, offset)
          return true if probe(bytestream[offset, 9])
          if bytestream[offset + 15, 3] == 'FAT'
            [true, "found #{bytestream[offset + 15, 5]} volume serial" ]
          end
        end

        def self.generate(now = nil)
          # FAT UUIDs (volume serials) at least until Win2K/XP are dependant on time. So sleep if nothing specified.
          now ||= begin
            sleep(1 + Random.rand * 2)
            Time.now
          end
          # Note that neither Wikipedia nor [1] seem to get this right, but actually reversed. [1] even implies
          # that the binary form is big endian... *sigh*
          # [1] http://www.digital-detective.co.uk/documents/Volume%20Serial%20Numbers.pdf
          valdx = (now.month << 8) + now.day + (now.sec << 8) + (now.nsec / 10_000_000)
          valdx &= 0xFFFF
          valcx = now.year + (now.hour << 8) + now.min
          valcx &= 0xFFFF
          build([valdx & 0xFF, (valdx & 0xFF00) >> 8, valcx & 0xFF, (valcx & 0xFF00) >> 8].pack 'C*')
        end

      end # class UUIDDOS

    end # class UUID
  end # module Image
end # module StormFly
