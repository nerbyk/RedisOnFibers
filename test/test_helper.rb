# frozen_string_literal: true

# load whole app
$LOAD_PATH.unshift File.expand_path('../app', __FILE__)

require 'minitest'
require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/hooks/default'
