# frozen_string_literal: true

require 'test_helper'

class WrapperAlphanumericCnpjTest < ActiveSupport::TestCase
  # Official SERPRO manual example plus additional vectors covering
  # letter/digit alternation and border cases where remainder < 2 (DV1 = 0).
  ALPHANUMERIC_CNPJ_VECTORS = {
    '12ABC34501DE' => '35',
    '112223330001' => '81',
    '000000000001' => '91',
    '607011900001' => '04',
    'JWC9NAYX0KV1' => '08',
    'CYS8RBHTF4SZ' => '09',
    'CASHU0000001' => '90',
    'A1B2C3D4E5F6' => '68'
  }.freeze

  ALPHANUMERIC_CNPJ_VECTORS.each do |root, dv|
    test "cnpj? accepts alphanumeric root #{root} with verify digits #{dv}" do
      assert_equal true, "#{root}#{dv}".to_brazilian_document.cnpj?
    end
  end

  test 'pretty formats the official SERPRO alphanumeric example' do
    assert_equal '12.ABC.345/01DE-35', '12ABC34501DE35'.to_brazilian_document.pretty
  end

  test 'a fully numeric CNPJ is still a valid CNPJ (particular case of alphanumeric)' do
    assert_equal true, '11222333000181'.to_brazilian_document.cnpj?
  end

  test 'cnpj? rejects an alphanumeric document with a wrong verify digit' do
    assert_equal false, '12.ABC.345/01DE-36'.to_brazilian_document.cnpj?
  end

  test 'cnpj? accepts lowercase letters after normalization to uppercase' do
    assert_equal true, '12.abc.345/01de-35'.to_brazilian_document.cnpj?
    assert_equal '12.ABC.345/01DE-35', '12.abc.345/01de-35'.to_brazilian_document.pretty
  end

  test 'cnpj? rejects wrong length alphanumeric documents' do
    assert_equal false, '12ABC34501D'.to_brazilian_document.cnpj?
    assert_equal false, '12ABC34501DEFG35'.to_brazilian_document.cnpj?
  end

  test 'cnpj? rejects a letter in the verify digit positions' do
    assert_equal false, '12ABC34501DEA5'.to_brazilian_document.cnpj?
  end

  test 'cnpj? rejects characters outside the canonical alphabet without stripping them' do
    assert_equal false, '12ÁBC34501DE35'.to_brazilian_document.cnpj?
    assert_equal false, '12-AB*34501DE35'.to_brazilian_document.cnpj?
  end

  test 'cnpj? and cpf? never raise for nil-like or unexpected string content' do
    assert_equal false, ''.to_brazilian_document.cpf?
    assert_equal false, ''.to_brazilian_document.cnpj?
    assert_equal false, '   '.to_brazilian_document.cpf?
    assert_equal false, '   '.to_brazilian_document.cnpj?
  end

  test 'repeated digit sequences remain invalid even though arithmetically they would pass' do
    assert_equal false, '000.000.000-00'.to_brazilian_document.cpf?
    assert_equal false, '00.000.000/0000-00'.to_brazilian_document.cnpj?
  end

  test 'zero-fill is not extended to alphanumeric CNPJ input' do
    short_alphanumeric = 'ABC34501DE35'
    refute short_alphanumeric.to_brazilian_document.cnpj?
  end

  # Regression: valid alphanumeric CNPJ whose embedded digits ("59992904496")
  # happen to form a valid CPF. cpf_digits used to strip letters with /\D/,
  # so cpf? returned true and pretty/stripped misformatted the document as a
  # CPF - generate_cnpj could emit CPF-shaped strings at random (flaky specs).
  AMBIGUOUS_CNPJ = '5C9992M9H04496'

  test 'an alphanumeric CNPJ whose digits form a valid CPF is never a CPF' do
    wrapper = AMBIGUOUS_CNPJ.to_brazilian_document
    assert_equal false, wrapper.cpf?
    assert_equal true, wrapper.cnpj?
    assert_equal 'CNPJ', wrapper.doc_type
  end

  test 'pretty and stripped format the ambiguous document as CNPJ' do
    wrapper = AMBIGUOUS_CNPJ.to_brazilian_document
    assert_equal '5C.999.2M9/H044-96', wrapper.pretty
    assert_equal AMBIGUOUS_CNPJ, wrapper.stripped
  end

  test 'a CPF-shaped string containing letters is not silently coerced into a CPF' do
    assert_equal false, '9A3.248.661-90'.to_brazilian_document.cpf?
  end
end
