# frozen_string_literal: true

require 'test_helper'

class BrazilianDocumentWrapperTest < ActiveSupport::TestCase
  test 'it has a version number' do
    assert BrazilianDocumentWrapper::VERSION
  end

  def test_cnpj_generate_method_formatted
    assert_match(%r{^\d{2}\.\d{3}\.\d{3}/\d{4}\-\d{2}$}, BrazilianDocumentWrapper.generate_cnpj)
  end

  def test_cnpj_generate_method_stripped
    assert_match(/^\d{14}$/, BrazilianDocumentWrapper.generate_cnpj(false))
  end

  def test_cnpj_generate_method_is_always_a_valid_cnpj
    20.times do
      cnpj = BrazilianDocumentWrapper.generate_cnpj(false)
      assert cnpj.to_brazilian_document.cnpj?, "expected #{cnpj} to be a valid CNPJ"
    end
  end

  def test_cnpj_generate_method_alphanumeric_formatted
    assert_match(%r{^[0-9A-Z]{2}\.[0-9A-Z]{3}\.[0-9A-Z]{3}/[0-9A-Z]{4}\-\d{2}$},
                 BrazilianDocumentWrapper.generate_cnpj(true, alphanumeric: true))
  end

  def test_cnpj_generate_method_alphanumeric_is_always_a_valid_cnpj
    20.times do
      cnpj = BrazilianDocumentWrapper.generate_cnpj(false, alphanumeric: true)
      assert cnpj.to_brazilian_document.cnpj?, "expected #{cnpj} to be a valid CNPJ"
    end
  end

  def test_cnpj_generate_method_alphanumeric_defaults_to_numeric_only
    20.times do
      cnpj = BrazilianDocumentWrapper.generate_cnpj(false)
      assert_match(/^\d{14}$/, cnpj)
    end
  end

  def test_cpf_generate_method_formatted
    assert_match(/^\d{3}\.\d{3}\.\d{3}\-\d{2}$/, BrazilianDocumentWrapper.generate_cpf)
  end

  def test_cpf_generate_method_stripped
    assert_match(/^\d{11}$/, BrazilianDocumentWrapper.generate_cpf(false))
  end

  def test_cpf_generate_method_is_always_a_valid_cpf
    20.times do
      cpf = BrazilianDocumentWrapper.generate_cpf(false)
      assert cpf.to_brazilian_document.cpf?, "expected #{cpf} to be a valid CPF"
    end
  end

  def test_generate_round_trips_through_stripped_and_pretty
    cnpj = BrazilianDocumentWrapper.generate_cnpj(false)
    document = cnpj.to_brazilian_document

    assert_equal cnpj, document.stripped
    assert document.pretty.cnpj?
    assert_equal cnpj, document.pretty.stripped
  end
end
