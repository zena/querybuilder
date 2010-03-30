require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  '..' + 'lib').expand_path)
require 'stringio'
require 'test/unit'
require 'querybuilder'
require 'rubygems'
require 'shoulda'
require 'yamltest'

require 'mock/dummy_processor'
require 'mock/user_processor'
require 'mock/dummy'