require File.dirname(__FILE__) + '/test_helper.rb'
require 'benchmark'

class DummyQueryBuilder < Test::Unit::TestCase
  yamltest
  
  def id;         123;  end
  def parent_id;  333;  end
  def project_id; 9999; end
  def connection; self; end
  
  
  def yt_parse(key, source, opts)
    opts = Hash[*(opts.map{|k,v| [k.to_sym, v]}.flatten)]
    
    case key
    when 'res'
      
      begin
        query = DummyProcessor.new(source, opts).query
        (query.main_class != DummyClass ? "#{query.main_class}: " : '') + query.to_s
      rescue QueryBuilder::QueryException => err
        err.message
      end
    when 'sxp'
      # s-expression
      QueryBuilder::Parser.parse(source).inspect
    when 'sql'
      DummyProcessor.new(source, opts).query.sql(binding)
    when 'count'
      DummyProcessor.new(source, opts).query.to_s(:count)
    when 'count_sql'
      DummyProcessor.new(source, opts).query.sql(binding, :count)
    else
      "parse not implemented for '#{key}' in querybuilder_test.rb"
    end
  end
=begin
  def test_benchmark
    Benchmark.bmbm do |x|
      ['basic', 'errors', 'filters'].each do |file_name|
        x.report("#{file_name}:") do
          @@test_strings[file_name].each do |name, keys|
            src = keys['src'] || name.gsub('_', ' ')
            100.times do
              begin
                QueryBuilder::Parser.parse(src)
              rescue QueryBuilder::QueryException => err
                #
              end
            end
          end
        end
      end
    end
  end
=end
  yt_make
end