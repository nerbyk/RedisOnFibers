# frozen_string_literal: true

$SOURCE_PATH = File.expand_path('../app', __dir__)
$LOAD_PATH.unshift $SOURCE_PATH

require 'minitest'
require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/hooks/default'
require 'minitest/reporters'

ENV['DISABLE_LOG'] = 'true'
ENV['DEBUG'] = nil

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
