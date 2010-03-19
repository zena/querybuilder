module QueryBuilder
  class QueryException < Exception
  end
end

require 'query_builder/info'
require 'query_builder/query'
begin
  require 'querybuilder_ext'
  puts "using C parser"
rescue LoadError
  require 'querybuilder_rb'
  puts "using ruby parser"
end
require 'query_builder/parser'
require 'query_builder/processor'
