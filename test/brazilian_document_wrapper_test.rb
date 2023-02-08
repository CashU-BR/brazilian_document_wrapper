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

  def test_cpf_generate_method_formatted
    assert_match(/^\d{3}\.\d{3}\.\d{3}\-\d{2}$/, BrazilianDocumentWrapper.generate_cpf)
  end

  def test_cpf_generate_method_stripped
    assert_match(/^\d{11}$/, BrazilianDocumentWrapper.generate_cpf(false))
  end
end
