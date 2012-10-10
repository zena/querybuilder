require 'active_record'
require 'logger'

begin
  class QueryBuilderTestMigration < ActiveRecord::Migration
    def self.up
      create_table 'dummies' do |t|
        t.string  'name'
        t.timestamps
      end
    end
    def self.down

    end
  end

  ActiveRecord::Base.establish_connection(:adapter=>'sqlite3', :database=>':memory:')
  log_path = Pathname(__FILE__).dirname + '../log/test.log'
  Dir.mkdir(log_path.dirname) unless File.exist?(log_path.dirname)
  ActiveRecord::Base.logger = Logger.new(File.open(log_path, 'wb'))
  ActiveRecord::Migration.verbose = false
  #PropertyMigration.migrate(:down)
  QueryBuilderTestMigration.migrate(:up)
  ActiveRecord::Migration.verbose = true
end