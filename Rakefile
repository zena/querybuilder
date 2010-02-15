require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  'lib').expand_path)

require 'querybuilder'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs     << 'lib' << 'test'
  test.pattern  = 'test/**/**_test.rb'
  test.verbose  = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test' << 'lib'
    test.pattern = 'test/**/**_test.rb'
    test.verbose = true
    test.rcov_opts = ['-T', '--exclude-only', '"test\/,^\/"']
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

task :default => :test

# GEM management
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.version = QueryBuilder::VERSION
    gemspec.name = "querybuilder"
    gemspec.summary = %Q{QueryBuilder is an interpreter for the "pseudo sql" language}
    gemspec.description = %Q{QueryBuilder is an interpreter for the "pseudo sql" language. This language
    can be used for two purposes:

     1. protect your database from illegal SQL by securing queries
     2. ease writing complex relational queries by abstracting table internals}
    gemspec.email = "gaspard@teti.ch"
    gemspec.homepage = "http://zenadmin.org/524"
    gemspec.authors = ["Gaspard Bucher"]

    gemspec.add_development_dependency('yamltest', '>= 0.5.0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

