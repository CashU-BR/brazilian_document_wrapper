# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in brazilian_document_wrapper.gemspec.
gemspec

gem 'brazilian_documents', '~> 0.1.4'

group :development do
  gem 'sqlite3'
end

gem 'simplecov', require: false, group: :test

# To use a debugger
gem 'pry', group: %i[development test]
gem 'rubocop', '~> 1.0', '>= 1.0.0', require: false, group: %i[development test]
