# encoding: utf-8
require 'singleton'

class Bdf
  include Singleton

  BDF_FONT_DIR = File.join(*%W[#{File.dirname(__FILE__)} .. font shinonome-0.9.11 bdf])
  def initialize
    # p "Bdf initializing.."
    @fonts = {}

    [
      ['shnmk16.bdf',  2],
      ['shnm8x16a.bdf', 1]
    ].each do |filename, byte|
      File.open(File.join(BDF_FONT_DIR, filename)) do |f|
        start_bitmap = false
        code = nil
        f.each_line do |line|
          case
          when line =~ /^STARTCHAR\s+(\w+)/
            str = $1
            code = if byte == 2
                     ("\x1B\x24\x42" + str.unpack("a2"*(str.length/2)).map(&:hex).map(&:chr).join)
                       .force_encoding(Encoding::ISO2022_JP).encode(Encoding::UTF_8)
                   else
                     str.hex.chr
                   end
            @fonts[code] = []
          when line =~ /^BITMAP/
            start_bitmap = true
          when line =~ /^ENDCHAR/
            start_bitmap = false
          when start_bitmap
            @fonts[code] <<  line.hex
          end
        end
      end
    end

    # p "Bdf initializied"
  end

  def [](chr)
    return nil unless @fonts.has_key?(chr)
    @fonts[chr]
  end

  def string_to_bdf(str)
    strcodes = str.split(//).map do |chr|
      @fonts[chr].map do |bytes|
        sprintf(chr.ascii_only? ? '%08b' : '%016b', bytes)
      end
    end
    (0..15).to_a.map do |i|
      strcodes.map{|strcode| strcode[i]; strcode[i].split(//).map(&:to_i)}.flatten#.join.to_i(2)
    end
  end
end

class String
  def to_bdf
    Bdf.instance.string_to_bdf(self)
  end
end
