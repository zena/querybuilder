require 'test_helper'

class DummyTest < Test::Unit::TestCase
  Query = QueryBuilder::Query

  context 'A class with QueryBuilder included' do

    subject do
      Dummy
    end

    should 'return compiler class on query_compiler' do
      assert_equal DummyProcessor, subject.query_compiler
    end

    should 'return a Query object on build_query' do
      assert_kind_of Query, subject.build_query(:all, 'objects')
    end

  end
end