require 'rake/extensiontask'
require 'rake/testtask'

Rake::ExtensionTask.new('diff_match_patch_ext') do |ext|
  ext.lib_dir = 'lib/diff_match_patch_ext'
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end
task test: :compile

task default: :test
