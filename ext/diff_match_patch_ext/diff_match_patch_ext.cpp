// Ruby binding for the header-only diff_match_patch STL port, written against
// Ruby's C API. It replaces diff_match_patch_native, whose rice 1.x binding
// does not build on Ruby 3.
//
// These methods are exposed: diff_main, diff_cleanup_semantic! and
// diff_pretty_html. They have the same Ruby interface as
// diff_match_patch_native: diffs are arrays of [operation, text] pairs, where
// operation is -1 (delete), 0 (equal) or 1 (insert), and returned strings are
// binary (ASCII-8BIT), as rice returned them.
//
// Ruby errors are raised with longjmp, which would skip C++ destructors, so
// every Ruby argument is type-checked before any C++ object is created, and
// C++ exceptions are converted to Ruby errors only after the C++ work is done.

#include <ruby.h>

#include <string>

#include "diff_match_patch.h"

typedef diff_match_patch<std::string> dmp_t;

static VALUE cDiffMatchPatch;

static VALUE str_to_ruby(const std::string &str) {
  return rb_str_new(str.data(), static_cast<long>(str.size()));
}

static std::string str_from_ruby(VALUE str) {
  return std::string(RSTRING_PTR(str), static_cast<size_t>(RSTRING_LEN(str)));
}

static int op_to_ruby(dmp_t::Operation op) {
  switch (op) {
    case dmp_t::DELETE: return -1;
    case dmp_t::INSERT: return 1;
    default: return 0;
  }
}

static VALUE diffs_to_ruby(const dmp_t::Diffs &diffs, VALUE out) {
  for (dmp_t::Diffs::const_iterator diff = diffs.begin(); diff != diffs.end(); ++diff) {
    rb_ary_push(out, rb_assoc_new(INT2FIX(op_to_ruby(diff->operation)), str_to_ruby(diff->text)));
  }
  return out;
}

// Raises unless diffs is an array of [-1|0|1, String] pairs. Called before any
// C++ object exists.
static void check_diffs(VALUE diffs) {
  Check_Type(diffs, T_ARRAY);
  for (long i = 0; i < RARRAY_LEN(diffs); ++i) {
    VALUE diff = rb_ary_entry(diffs, i);
    Check_Type(diff, T_ARRAY);
    if (RARRAY_LEN(diff) != 2) {
      rb_raise(rb_eArgError, "diff %ld must be an [operation, text] pair", i);
    }
    VALUE op = rb_ary_entry(diff, 0);
    if (!FIXNUM_P(op) || FIX2LONG(op) < -1 || FIX2LONG(op) > 1) {
      rb_raise(rb_eArgError, "diff %ld has an invalid operation (expected -1, 0 or 1)", i);
    }
    Check_Type(rb_ary_entry(diff, 1), T_STRING);
  }
}

// Expects diffs to have passed check_diffs.
static dmp_t::Diffs diffs_from_ruby(VALUE diffs) {
  dmp_t::Diffs out;
  for (long i = 0; i < RARRAY_LEN(diffs); ++i) {
    VALUE diff = rb_ary_entry(diffs, i);
    long op = FIX2LONG(rb_ary_entry(diff, 0));
    dmp_t::Operation operation = op < 0 ? dmp_t::DELETE : (op > 0 ? dmp_t::INSERT : dmp_t::EQUAL);
    out.push_back(dmp_t::Diff(operation, str_from_ruby(rb_ary_entry(diff, 1))));
  }
  return out;
}

// Copies a C++ exception's message so the error can be raised after the
// exception object and every other C++ object are gone.
static void copy_error(std::string &message, const char *fallback) {
  try {
    throw;
  } catch (const std::string &error) {
    message = error;
  } catch (const std::exception &error) {
    message = error.what();
  } catch (...) {
    message = fallback;
  }
}

// diff_main(text1, text2, checklines = false) -> [[op, text], ...]
static VALUE rb_diff_main(int argc, VALUE *argv, VALUE self) {
  VALUE text1, text2, checklines;
  rb_scan_args(argc, argv, "21", &text1, &text2, &checklines);
  StringValue(text1);
  StringValue(text2);

  VALUE result = rb_ary_new();
  std::string error;
  bool failed = false;
  try {
    dmp_t dmp;
    dmp_t::Diffs diffs = dmp.diff_main(str_from_ruby(text1), str_from_ruby(text2), RTEST(checklines));
    diffs_to_ruby(diffs, result);
  } catch (...) {
    copy_error(error, "diff_main failed");
    failed = true;
  }
  if (failed) rb_raise(rb_eRuntimeError, "%s", error.c_str());
  return result;
}

// diff_cleanup_semantic!(diffs) -> diffs, replacing the array's contents
static VALUE rb_diff_cleanup_semantic_bang(VALUE self, VALUE diffs) {
  check_diffs(diffs);
  rb_check_frozen(diffs);

  VALUE cleaned = rb_ary_new();
  std::string error;
  bool failed = false;
  try {
    dmp_t::Diffs cpp_diffs = diffs_from_ruby(diffs);
    dmp_t::diff_cleanupSemantic(cpp_diffs);
    diffs_to_ruby(cpp_diffs, cleaned);
  } catch (...) {
    copy_error(error, "diff_cleanup_semantic! failed");
    failed = true;
  }
  if (failed) rb_raise(rb_eRuntimeError, "%s", error.c_str());
  return rb_ary_replace(diffs, cleaned);
}

// diff_pretty_html(diffs) -> String
static VALUE rb_diff_pretty_html(VALUE self, VALUE diffs) {
  check_diffs(diffs);

  VALUE html = Qnil;
  std::string error;
  bool failed = false;
  try {
    html = str_to_ruby(dmp_t::diff_prettyHtml(diffs_from_ruby(diffs)));
  } catch (...) {
    copy_error(error, "diff_pretty_html failed");
    failed = true;
  }
  if (failed) rb_raise(rb_eRuntimeError, "%s", error.c_str());
  return html;
}

extern "C" void Init_diff_match_patch_ext(void) {
  cDiffMatchPatch = rb_define_class("DiffMatchPatch", rb_cObject);
  rb_define_method(cDiffMatchPatch, "diff_main", RUBY_METHOD_FUNC(rb_diff_main), -1);
  rb_define_method(cDiffMatchPatch, "diff_cleanup_semantic!", RUBY_METHOD_FUNC(rb_diff_cleanup_semantic_bang), 1);
  rb_define_method(cDiffMatchPatch, "diff_pretty_html", RUBY_METHOD_FUNC(rb_diff_pretty_html), 1);
}
