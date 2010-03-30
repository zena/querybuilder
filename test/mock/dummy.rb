require 'mock/dummy_processor'

class Dummy
  include QueryBuilder
  self.query_compiler = DummyProcessor
end