require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  '..' + 'lib').expand_path)
require 'stringio'
require 'test/unit'
require 'rubygems'
require 'database'
require 'querybuilder'
require 'shoulda'
require 'yamltest'

require 'mock/dummy_processor'
require 'mock/user_processor'
require 'mock/dummy'

require 'active_record'
# in order to use connection for quoting and such
ActiveRecord::Base.establish_connection(:adapter=>'sqlite3', :database=>':memory:')
