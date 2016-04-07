require 'rubygems'
require 'rake'
require(File.join(File.dirname(__FILE__), 'lib/query_builder/info'))

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "QueryBuilder #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Rebuild sources files from ragel parser definitions"
task :ragel do
  [
    "cd lib && ragel querybuilder_ext.rl   -o querybuilder_ext.c",
    "cd lib && ragel querybuilder_rb.rl -R -o querybuilder_rb.rb",
  ].each do |cmd|
    puts cmd
    system cmd
  end
end

desc "Build native extensions"
task :build => :ragel do
  [
    'ruby lib/extconf.rb',
    'mv Makefile lib/',
    'cd lib && make',
  ].each do |cmd|
    puts cmd
    system cmd
  end
end

