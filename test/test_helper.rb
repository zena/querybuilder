require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  '..' + 'lib').expand_path)
require 'stringio'
require 'test/unit'
require 'rubygems'
require 'querybuilder'
require 'shoulda'
require 'yamltest'
require 'logger'
require "active_support"
require 'mock/dummy_processor'
require 'mock/user_processor'
require 'mock/dummy'

gem 'activerecord', '>=2.3.18'
require 'active_record'

require 'database'
