# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :test do
  gem "minitest", "~> 5.8"
  gem "minitest-rg", "~> 5.2"
  gem "minitest-hooks", "~> 1.5"
end

group :test, :development do
  gem "pry", "~> 0.14.1"
  gem "rake", "~> 13.0"
  gem "rubocop", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-performance", require: false
  gem "standard", require: false
end
