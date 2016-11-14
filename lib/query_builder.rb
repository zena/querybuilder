module QueryBuilder
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

  def self.included(base)
    base.extend ClassMethods
    class << base
      attr_accessor :query_compiler

      # Inheritable accessor
      def query_compiler
        @query_compiler ||= (superclass.respond_to?(:query_compiler,true) ? superclass.query_compiler : nil)
      end
    end
  end

  module ClassMethods
    def build_query(count, pseudo_sql, opts = {})
      raise Exception.new("No query_compiler for #{self}") unless query_compiler
      if count == :first
        opts[:limit] = 1
      end
      opts[:rubyless_helper] ||= self
      query_compiler.new(pseudo_sql, opts.merge(:custom_query_group => query_group)).query
    end

    def query_group
      nil
    end
  end # ClassMethods
end # QueryBuilder

require 'query_builder/info'
require 'query_builder/query'
require 'query_builder/error'
begin
  require 'querybuilder_ext'
rescue LoadError
  require 'querybuilder_rb'
end
require 'query_builder/parser'
require 'query_builder/processor'
