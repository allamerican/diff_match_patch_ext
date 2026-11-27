# Records the reference results in test/fixtures from diff_match_patch_native,
# the rice-based gem this one replaces. Run it with that gem installed, on a
# Ruby it builds on (it was recorded with 1.0.2 on Ruby 2.6):
#
#   gem install diff_match_patch_native -v 1.0.2
#   ruby test/record_fixture.rb
gem 'diff_match_patch_native', '1.0.2'
require 'diff_match_patch_native'
require_relative 'corpus'
require_relative 'fixture'

cases = dmp_corpus.map do |text1, text2|
  dmp = DiffMatchPatch.new
  raw = dmp.diff_main(text1, text2, false)
  cleaned = dmp.diff_cleanup_semantic!(raw.map { |op, text| [op, text.dup] })
  { raw: raw, cleaned: cleaned, html: dmp.diff_pretty_html(cleaned) }
end

File.write(Fixture::PATH, Fixture.dump(cases))
puts "Recorded #{cases.size} cases in #{Fixture::PATH}"
