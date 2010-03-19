module QueryBuilder
  class QueryException < Exception
  end

  def self.resolve_const(klass)
    if klass.kind_of?(String)
      constant = nil
      klass.split('::').each do |m|
        constant = constant ? constant.const_get(m) : Module.const_get(m)
      end
      constant
    else
      klass
    end
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
