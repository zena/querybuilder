module QueryBuilder
  class QueryException < Exception
  end
end

require File.dirname(__FILE__) + '/version'
require File.dirname(__FILE__) + '/query'
begin
  require File.dirname(__FILE__) + '/querybuilder_ext'
  puts "using C parser"
rescue LoadError
  require File.dirname(__FILE__) + '/querybuilder_rb'
  puts "using ruby parser"
end
require File.dirname(__FILE__) + '/parser'
require File.dirname(__FILE__) + '/processor'
