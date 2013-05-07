require 'test_helper'
require 'benchmark'

class StringHash
end

class DummyQueryBuilder < Test::Unit::TestCase
  yamltest
  include RubyLess::SafeClass
  safe_method :params => {:class => StringHash, :method => 'get_params'}
  safe_method :id => Number, :parent_id => Number, :project_id => Number
  safe_method :num => {:class => Number, :nil => true}

  safe_method_for StringHash, [:[], Symbol] => String
  safe_method_for StringHash, [:[], String] => String

  def id;         123;  end
  def num;          2;  end
  def parent_id;  333;  end
  def project_id; 9999; end

  context 'A query processor' do
    subject do
      DummyProcessor
    end

    should 'raise a QueryBuilder::SyntaxError on syntax errors' do
      assert_raise(QueryBuilder::SyntaxError) do
        subject.new('this is a bad source')
      end
    end

    should 'return a query object on query' do
      assert_kind_of QueryBuilder::Query, subject.new('objects').query
    end

    should 'overwrite defaults' do
      assert_equal '%Q{SELECT objects.* FROM objects}', subject.new('objects', :default => {:scope => 'site'}).query.to_s
      assert_equal '[%Q{SELECT objects.* FROM objects WHERE objects.project_id = ?}, project_id]', subject.new('objects', :default => {:scope => 'project'}).query.to_s
      assert_equal '[%Q{SELECT objects.* FROM objects WHERE objects.parent_id = ?}, id]', subject.new('objects').query.to_s
    end
    
    should 'not overwrite defaults before last' do
      assert_equal '%Q{SELECT objects.* FROM objects JOIN objects AS ob1 WHERE objects.parent_id = ob1.id GROUP BY objects.id}', subject.new('objects from objects', :default => {:scope => 'site'}).query.to_s
    end
  end

  context 'Including QueryBuilder' do
    context 'in a class' do
      subject do
        Class.new do
          include QueryBuilder
        end
      end

      should 'receive class method query_compiler' do
        assert_nothing_raised do
          subject.query_compiler = 'Foo'
          assert_equal 'Foo', subject.query_compiler
        end
      end

      should 'receive class method query_compiler on sub_class' do
        sub_class = Class.new(subject)
        subject.query_compiler = 'Foo'
        assert_equal 'Foo', subject.query_compiler

        sub_class.query_compiler = 'Bar'
        assert_equal 'Bar', sub_class.query_compiler
        assert_equal 'Foo', subject.query_compiler
      end
    end
  end # Including QueryBuilder

  context 'A query with custom select' do
    subject do
      DummyProcessor.new('star where number < 4', :custom_query_group => 'test').query
    end

    should 'respond to select_keys' do
      assert_equal %w{a c number}, subject.select_keys.sort
    end
    
    should 'return type of custom key' do
      assert_equal :integer, subject.types['number']
    end

    should 'not include star keys' do
      assert !subject.select_keys.include?('*')
    end
  end # A query with custom select


  def yt_parse(key, source, opts)
    opts = {:rubyless_helper => self}.merge(Hash[*(opts.map{|k,v| [k.to_sym, v]}.flatten)])

    case key
    when 'res'

      begin
        query = DummyProcessor.new(source, opts).query
        (query.main_class != DummyClass ? "#{query.main_class}: " : '') + query.to_s
      rescue QueryBuilder::Error => err
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
              rescue QueryBuilder::Error => err
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
