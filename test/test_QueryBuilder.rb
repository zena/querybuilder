require File.dirname(__FILE__) + '/test_helper.rb'


class DummyQueryBuilder < Test::Unit::TestCase
  yamltest :files => [:basic, :errors, :filters]
  
  def id;         123;  end
  def parent_id;  333;  end
  def project_id; 9999; end
  def connection; self; end
  
  
  def yt_parse(key, source, opts)
    opts = Hash[*(opts.map{|k,v| [k.to_sym, v]}.flatten)]
    query = DummyQuery.new(source, opts) unless key == 'sxp'
    
    case key
    when 'res'
      begin
        query = DummyProcessor.new(source).query
        (query.main_class != DummyClass ? "#{query.main_class}: " : '') + query.to_s
      rescue NewQueryBuilder::QueryException => err
        err.message
      end
    when 'sxp'
      # s-expression
      NewQueryBuilder::Parser.parse(source).inspect
    when 'sql'
      query.sql(binding)
    when 'count'
      query.to_s(:count)
    when 'count_sql'
      query.sql(binding, :count)
    else
      "parse not implemented for '#{key}' in query_builder_test.rb"
    end
  end
  
  yt_make
end