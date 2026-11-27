# Deterministic corpus of [text1, text2] pairs for comparing diff_match_patch
# implementations. Change it only together with test/fixtures (see
# test/record_fixture.rb).
def dmp_corpus
  rng = Random.new(6582)
  words = %w[the of and a to in is it that was for on with as at by from this have not
             time year day week world house garden river window letter number question
             answer story table paper music water light green blue quiet early small
             résumé naïve café 日本語 emoji😀 & < > "quoted" **Heading** ​]
  long = Array.new(2000) { words[rng.rand(words.size)] }.join(' ')
  long_lines = long.scan(/.{1,80}/).join("\n")

  mutate = lambda do |text, edits|
    t = text.dup
    edits.times do
      pos = rng.rand(t.size)
      case rng.rand(3)
      when 0 then t.insert(pos, words[rng.rand(words.size)] + ' ')
      when 1 then t[pos, rng.rand(1..20)] = ''
      else t[pos, rng.rand(1..10)] = words[rng.rand(words.size)]
      end
    end
    t
  end

  pairs = [
    ['', ''], ['', 'abc'], ['abc', ''], ['same', 'same'],
    ['The quick brown fox', 'The quick red fox jumps'],
    ["line one\nline two\n", "line one\nline 2\nline three\n"],
    ["crlf\r\nline\r\n", "crlf\r\nLINE\r\n"],
    ['a & b < c > d', 'a && b <= c >> d'],
    ['café naïve résumé', 'cafe naive resume'],
    ['日本語のテキスト', '日本語テキストです'],
    ['emoji 😀 here', 'emoji 😃 there'],
    ["**Prices**\nA ticket costs $10.", "**Prices**\nA ticket costs $12.50 plus tax."],
    ["**Heading**​​​​ body", "**Heading**​​​​ new body"],
    ['<b>html</b>', '<i>html</i>'],
    ["tab\tseparated", "tab\tseparated\tmore"],
    ['abcdefghijklmnop' * 50, ('abcdefghijklmnop' * 50).tr('e', 'E')]
  ]
  10.times { |i| pairs << [long[0, 1000 * (i + 1)], mutate.call(long[0, 1000 * (i + 1)], 5 + 2 * i)] }
  3.times { |i| pairs << [long_lines, mutate.call(long_lines, 20 * (i + 1))] }
  pairs << [long, mutate.call(long, 200)]
  pairs
end
