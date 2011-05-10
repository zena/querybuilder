require 'mock/dummy_processor'

class Dummy < ActiveRecord::Base
  include RubyLess
  safe_method :id => Number

  include QueryBuilder
  self.query_compiler = DummyProcessor
end