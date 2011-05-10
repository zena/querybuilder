require 'test_helper'

class QueryTest < Test::Unit::TestCase

  context 'An empty query object' do
    subject do
      QueryBuilder::Query.new(QueryBuilder::Processor)
    end

    should 'respond to rebuild_tables' do
      subject.tables = ['foo', 'bar']
      subject.rebuild_tables!
      h = {'foo' => ['foo'], 'bar' => ['bar']}
      assert_equal h, subject.table_alias
    end

    should 'respond to rebuild_attributes_hash' do
      subject.select = ['1 as one', 'two', '(20 - (weight / (height * height))) AS bmi_nrm']
      subject.rebuild_attributes_hash!
      h = {
        'bmi_nrm'=>'(20 - (weight / (height * height)))',
        'two' => 'two',
        'one' => '1',
      }
      assert_equal h, subject.attributes_alias
    end

    should 'respond to add_select' do
      subject.instance_variable_set(:@main_table, 'nodes')
      subject.instance_variable_set(:@default_class, 'Dummy')
      subject.add_select('foo*3', 'bar')
      assert_equal %w{bar}, subject.select_keys
      assert_equal ['nodes.*', 'foo*3 AS "bar"'], subject.select
    end
  end

  context 'A query returned from a processor' do
    subject do
      DummyProcessor.new('objects').query
    end

    should 'return a string representing an array with find SQL and parameters string on to_s' do
      assert_equal "[%Q{SELECT objects.* FROM objects WHERE objects.parent_id = ?}, id]", subject.to_s
    end

    should 'return a string representing an array with count SQL and parameters string on to_s count' do
      assert_equal "[%Q{SELECT COUNT(*) FROM objects WHERE objects.parent_id = ?}, id]", subject.to_s(:count)
    end
  end
end