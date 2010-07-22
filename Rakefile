require 'rubygems'
require 'rake'
require(File.join(File.dirname(__FILE__), 'lib/query_builder/info'))

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = QueryBuilder::VERSION
    gem.name = 'querybuilder'
    gem.summary = %Q{QueryBuilder is an interpreter for the "pseudo sql" language.}
    gem.description = %Q{QueryBuilder is an interpreter for the "pseudo sql" language. This language
    can be used for two purposes:

     1. protect your database from illegal SQL by securing queries
     2. ease writing complex relational queries by abstracting table internals}
    gem.email = "gaspard@teti.ch"
    gem.homepage = "http://zenadmin.org/524"
    gem.authors = ["Gaspard Bucher"]
    gem.add_dependency "rubyless", ">= 0.5.0"
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_development_dependency "yamltest", ">= 0.5.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

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

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
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

