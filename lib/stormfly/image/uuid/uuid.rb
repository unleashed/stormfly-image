module StormFly
  module Image

    # note that some UUIDs (such as those from LVM) are not based on HEX, so wont work here!
    class UUID < String

      # TODO: enhancement - stop inheriting from String and compose it instead
      module ClassMethods

        # for use within classes inheriting from UUID
        def pack(pattern)
          attr_writer :pack_pattern

          class_eval do
            define_method :pack_pattern do
              instance_variable_get('@pack_pattern') || pattern
            end
          end

          protected :pack_pattern, :pack_pattern=
        end

        def unpack(pattern)
          attr_writer :unpack_pattern

          class_eval do
            define_method :unpack_pattern do
              instance_variable_get('@unpack_pattern') || pattern
            end
          end

          protected :unpack_pattern, :unpack_pattern=
        end

        def upcase
          class_eval do
            def upcase?
              true
            end
          end
        end

        def strsize(sz)
          class_eval do
            define_method :expected_strsize do
              sz
            end
          end
        end

        def binsize(sz)
          class_eval do
            define_method :expected_binsize do
              sz
            end

            def verify_bin(binuuid = self.bin)
              binuuid.bytesize == expected_binsize
            end
          end
        end

        def endian(kind)
          # instance method :endian is alread private on target class
          class_eval do
            define_method :endian do
              kind
            end
          end
        end

        # TODO: currently unused. Use it to better perform verification and
        # auto-build string UUIDs.
        def dashes(*dashes)
          class_eval do
            define_method :dashes do
              dashes
            end
          end

          protected :dashes
        end
      end

      # we keep information about all inheriting classes so that we can probe them
      module KlassInfo
        # list of classes inheriting from us
        def klasses
          @@klasses ||= []
        end

        def inherited(klass)
          klasses << klass
        end
      end

      extend ClassMethods
      extend KlassInfo

      def self.build(*args)
        uuid = args.first

        klass = klasses.find do |k|
          k.probe uuid
        end

        raise "Unknown UUID format out of #{klasses.size} UUID types loaded" unless klass

        klass.send(:new, *args)
      end

      # hide :new and others from public visibility
      private_class_method :new, :klasses, :inherited

      attr_reader :uuid, :bin

      def initialize(uuid, base = 16)
        @base = base
        # we should never test for '-' because it is a valid binary byte value!
        if verify_bin uuid
          self.bin = uuid
        else
          self.uuid = uuid
        end
        super(@uuid)
      end

      def uuid=(uuid, pack_s = self.pack_pattern)
        verify_str! uuid

        @uuid = uuid
        @bin = [@uuid.gsub('-', '')].pack(pack_s)
        @bin.reverse! if endian == :little

        if block_given?
          yield
        end

        @uuid.tap { |u| u.upcase! if upcase? }
      end

      def bin=(uuid, unpack_s = self.unpack_pattern)
        verify_bin! uuid

        @bin = uuid
        uuid_ary = @bin.unpack(unpack_s).map { |c| c.to_s(@base).rjust(4, '0') }
        uuid_ary.reverse! if endian == :little

        @uuid = dashify(uuid_ary)
        @uuid.upcase! if upcase?

        @bin
      end

      alias_method :to_s, :uuid

      private

        def self.probe(uuid)
          raise "Unimplemented"
        end

        def self.probe_stream(bytestream, offset)
          raise "Uninmplemented"
        end

        def self.generate
          raise "Unimplemented"
        end

        def expected_strsize
          raise "Unimplemented"
        end

        def expected_binsize
          raise "Unimplemented"
        end

        def verify_bin(binuuid = self.bin)
          binuuid.bytesize == expected_binsize
        end

        def verify_bin!(binuuid = self.bin)
          raise "Unsupported binary UUID format" unless verify_bin(binuuid)
        end

        def verify_str(uuid = self.uuid)
          uuid.bytesize == expected_strsize
        end

        def verify_str!(uuid = self.uuid)
          raise "Unsupported UUID format => #{uuid} b/c #{uuid.bytesize} != expected #{expected_strsize}" unless verify_str(uuid)
        end

        def endian
          :big
        end

        def upcase?
         false
        end

        # this method must be overriden if not all array elements should be joined
        def dashify(uuid_ary)
          uuid_ary.join '-'
        end

    end # class UUID
  end # module Image
end # module StormFly
