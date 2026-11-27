require 'json'

# test/fixtures/diff_match_patch_native-1.0.2.json holds one JSON object per
# corpus pair, one per line. diff_match_patch splits multibyte characters, so
# its strings can be invalid UTF-8: those are stored as {"base64": "..."}, and
# every other string as plain JSON text. All strings decode to binary
# (ASCII-8BIT), as the library returns them.
module Fixture
  PATH = File.expand_path('fixtures/diff_match_patch_native-1.0.2.json', __dir__)

  def self.encode_string(str)
    utf8 = str.dup.force_encoding(Encoding::UTF_8)
    utf8.valid_encoding? ? utf8 : { 'base64' => [str].pack('m0') }
  end

  def self.decode_string(value)
    value.is_a?(Hash) ? value.fetch('base64').unpack1('m0') : value.b
  end

  def self.encode_diffs(diffs)
    diffs.map { |op, text| [op, encode_string(text)] }
  end

  def self.decode_diffs(diffs)
    diffs.map { |op, text| [op, decode_string(text)] }
  end

  def self.dump(cases)
    lines = cases.map do |c|
      JSON.generate('raw' => encode_diffs(c[:raw]), 'cleaned' => encode_diffs(c[:cleaned]),
                    'html' => encode_string(c[:html]))
    end
    "[\n#{lines.join(",\n")}\n]\n"
  end

  def self.load
    JSON.parse(File.read(PATH, encoding: 'UTF-8')).map do |c|
      { raw: decode_diffs(c['raw']), cleaned: decode_diffs(c['cleaned']), html: decode_string(c['html']) }
    end
  end
end
