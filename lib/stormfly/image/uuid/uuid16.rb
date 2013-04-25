require 'uuid'

module StormFly
  module Image
    class UUID
      class UUID16 < UUID
        pack 'H*'
        unpack 'nnnnnnnn'
        dashes 8, 12, 16, 20
        binsize 16
        strsize 36

        def self.probe(uuid)
          uuid.count('-') == 4 or uuid.bytesize == 16
        end

        def self.probe_stream(bytestream, offset)
          true
        end

        def self.generate
          # uuid library generates 16-byte UUIDs
          build(::UUID.new.generate)
        end

        def dashify(uuid_ary)
          uuid_s = super
          [4, -10, -5].each { |i| uuid_s.slice! i }
          uuid_s
        end

      end # class UUID16

    end # class UUID
  end # module Image
end # module StormFly
