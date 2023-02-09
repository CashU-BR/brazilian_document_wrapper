# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in brazilian_document_wrapper.gemspec.
gemspec

group :development do
  gem 'sqlite3'
end

gem 'simplecov', require: false, group: :test

# To use a debugger
gem 'pry', group: %i[development test]
gem 'rubocop', '~> 0.93', require: false, group: %i[development test]
