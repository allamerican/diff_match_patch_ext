# diff_match_patch_ext

> **Unsupported.** This gem is published as-is for our own use. Issues and pull requests are not monitored, and there is no guarantee of updates or compatibility. Fork it if you need changes.

A Ruby binding for the C++ (STL) port of Google's diff-match-patch. It is a drop-in replacement for `diff_match_patch_native`, whose binding depends on `rice` 1.x, which does not build on Ruby 3. This gem uses Ruby's C API directly and has no runtime dependencies. It supports Ruby 2.6 and later.

```ruby
gem 'diff_match_patch_ext', git: 'https://github.com/allamerican/diff_match_patch_ext.git', tag: 'v1.0.0'
```

```ruby
dmp = DiffMatchPatch.new
diffs = dmp.diff_main(old_text, new_text, false) # [[-1 | 0 | 1, text], ...]
dmp.diff_cleanup_semantic!(diffs)               # cleans up diffs in place and returns it
dmp.diff_pretty_html(diffs)                     # HTML with <del>/<ins>
```

Only these methods are exposed, with the same interface and output as `diff_match_patch_native` 1.0.2:

- Diffs are arrays of `[operation, text]` pairs, where operation is `-1` (delete), `0` (equal) or `1` (insert).
- Returned strings are binary (ASCII-8BIT).
- The library compares bytes, not characters, so a changed multibyte UTF-8 character is split across diffs.
- `diff_main` gives up after 1 second and returns a coarser diff, as upstream does.

## Development

```sh
bundle install
bundle exec rake   # compiles the extension and runs the tests
```

The tests compare against results recorded from `diff_match_patch_native` 1.0.2 on Ruby 2.6 (`test/fixtures`, recorded by `test/record_fixture.rb`), so any change in output shows up as a failure.

## Licence

`ext/diff_match_patch_ext/diff_match_patch.h` is copied unchanged from `diff_match_patch_native` 1.0.2. It and the rest of this gem are licensed under Apache 2.0 (see `LICENSE`).
