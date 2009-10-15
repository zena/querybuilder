module QueryBuilder
  class QueryException < Exception
  end
end

require File.dirname(__FILE__) + '/query_builder/version'
require File.dirname(__FILE__) + '/query_builder/query'
begin
  require File.dirname(__FILE__) + '/querybuilder_ext'
  puts "using C parser"
rescue LoadError
  require File.dirname(__FILE__) + '/querybuilder_rb'
  puts "using ruby parser"
end
require File.dirname(__FILE__) + '/query_builder/parser'
require File.dirname(__FILE__) + '/query_builder/processor'
