require File.dirname(__FILE__) + '/test_helper.rb'

class DummyQueryBuilder < Test::Unit::TestCase
  
  def test_rebuild_tables
    query = QueryBuilder::Query.new(QueryBuilder::Processor)
    query.tables = ['foo', 'bar']
    query.rebuild_tables!
    h = {'foo' => ['foo'], 'bar' => ['bar']}
    assert_equal h, query.table_alias
  end
  
  def test_rebuild_attributes_hash
    query = QueryBuilder::Query.new(QueryBuilder::Processor)
    query.select = ['1 as one', 'two', '(20 - (weight / (height * height))) AS bmi_nrm']
    query.rebuild_attributes_hash!
    h = {"bmi_nrm"=>"(20 - (weight / (height * height)))"}
    assert_equal h, query.attributes_alias
  end
end