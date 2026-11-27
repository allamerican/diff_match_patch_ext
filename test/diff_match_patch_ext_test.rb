require 'minitest/autorun'
require 'diff_match_patch_ext'
require_relative 'corpus'
require_relative 'fixture'

class DiffMatchPatchExtTest < Minitest::Test
  DEL = '<del style="background:#ffe6e6;">'.freeze
  INS = '<ins style="background:#e6ffe6;">'.freeze

  def setup
    @dmp = DiffMatchPatch.new
  end

  def test_diff_main
    assert_equal [[0, 'Title'], [1, ' new']], @dmp.diff_main('Title', 'Title new', false)
    assert_equal [[0, 'abc']], @dmp.diff_main('abc', 'abc')
    assert_equal [], @dmp.diff_main('', '', false)
  end

  def test_diff_cleanup_semantic_replaces_the_array_contents
    diffs = @dmp.diff_main('abcd', 'xyz', false)
    result = @dmp.diff_cleanup_semantic!(diffs)

    assert_same diffs, result
    assert_equal [[-1, 'abcd'], [1, 'xyz']], diffs
  end

  def test_diff_pretty_html_escapes_text
    html = @dmp.diff_pretty_html([[0, "a & b\n"], [-1, '<i>'], [1, '<b>']])

    assert_equal "<span>a &amp; b&para;<br></span>#{DEL}&lt;i&gt;</del>#{INS}&lt;b&gt;</ins>", html
  end

  def test_strings_are_binary
    diffs = @dmp.diff_main('café', 'cafe', false)

    assert(diffs.all? { |_, text| text.encoding == Encoding::BINARY })
    assert_equal Encoding::BINARY, @dmp.diff_pretty_html(diffs).encoding
  end

  # The C++ library compares bytes, so a changed multibyte character is split.
  def test_multibyte_characters_are_diffed_by_byte
    diffs = @dmp.diff_cleanup_semantic!(@dmp.diff_main("a – b", "a — b", false))

    assert_equal [[0, "a \xE2\x80".b], [-1, "\x93".b], [1, "\x94".b], [0, ' b']], diffs
  end

  def test_invalid_arguments_raise_ruby_errors
    assert_raises(TypeError) { @dmp.diff_main(nil, 'a', false) }
    assert_raises(ArgumentError) { @dmp.diff_main('a') }
    assert_raises(TypeError) { @dmp.diff_pretty_html('not an array') }
    assert_raises(ArgumentError) { @dmp.diff_pretty_html([[0]]) }
    assert_raises(ArgumentError) { @dmp.diff_pretty_html([[2, 'x']]) }
    assert_raises(TypeError) { @dmp.diff_cleanup_semantic!([[0, 5]]) }
    assert_raises(FrozenError) { @dmp.diff_cleanup_semantic!([[0, 'a'], [1, 'b']].freeze) }
  end

  def test_survives_gc_stress
    GC.stress = true
    html = 20.times.map { |i| @dmp.diff_pretty_html(@dmp.diff_cleanup_semantic!(@dmp.diff_main("abc #{i}", "abd #{i}", false))) }
  ensure
    GC.stress = false
    assert_equal 20, html.uniq.size
  end

  # test/fixtures holds diff_main, diff_cleanup_semantic! and diff_pretty_html
  # results recorded from diff_match_patch_native 1.0.2 (rice) on Ruby 2.6 by
  # test/record_fixture.rb.
  def test_matches_diff_match_patch_native
    fixture = Fixture.load
    pairs = dmp_corpus
    assert_equal fixture.size, pairs.size

    pairs.each_with_index do |(text1, text2), i|
      raw = @dmp.diff_main(text1, text2, false)
      assert_equal fixture[i][:raw], raw, "case #{i}: diff_main"

      cleaned = @dmp.diff_cleanup_semantic!(raw.map { |op, text| [op, text.dup] })
      assert_equal fixture[i][:cleaned], cleaned, "case #{i}: diff_cleanup_semantic!"
      assert_equal fixture[i][:html], @dmp.diff_pretty_html(cleaned), "case #{i}: diff_pretty_html"
    end
  end
end
