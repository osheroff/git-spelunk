require 'grit'

if RUBY_VERSION >= "2.0.0"
  class String
    def getord(offset); self[offset].ord; end
  end

  PACK_IDX_SIGNATURE = "\377tOc".force_encoding(Encoding::ASCII_8BIT)
end
