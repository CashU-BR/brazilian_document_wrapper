# frozen_string_literal: true

require 'test_helper'

class DocumentMathTest < ActiveSupport::TestCase
  DocMath = BrazilianDocumentWrapper::DocumentMath

  test 'char_value converts digits and uppercase letters per the SERPRO manual' do
    assert_equal 0, DocMath.char_value('0')
    assert_equal 9, DocMath.char_value('9')
    assert_equal 17, DocMath.char_value('A')
    assert_equal 42, DocMath.char_value('Z')
  end

  test 'verify_digit applies the mod 11 rule shared by CPF and CNPJ' do
    assert_equal 0, DocMath.verify_digit(11) # remainder 0
    assert_equal 0, DocMath.verify_digit(12) # remainder 1
    assert_equal 9, DocMath.verify_digit(2)  # remainder 2 -> 11 - 2
    assert_equal 1, DocMath.verify_digit(21) # remainder 10 -> 11 - 10
  end

  test 'cnpj_valid? is retrocompatible with the legacy numeric-only weights' do
    assert DocMath.cnpj_valid?('11222333000181')
    refute DocMath.cnpj_valid?('11222333000180')
  end

  test 'cnpj_valid? supports the official SERPRO alphanumeric example' do
    assert DocMath.cnpj_valid?('12ABC34501DE35')
    refute DocMath.cnpj_valid?('12ABC34501DE36')
  end

  test 'cnpj_valid? rejects non-string input without raising' do
    refute DocMath.cnpj_valid?(nil)
    refute DocMath.cpf_valid?(nil)
  end

  test 'generate_cpf always returns a valid, non-repeated CPF' do
    50.times do
      digits = DocMath.generate_cpf
      assert DocMath.cpf_valid?(digits)
      refute DocMath.repeated_chars?(digits)
    end
  end

  test 'generate_cnpj defaults to a numeric-only root' do
    10.times do
      digits = DocMath.generate_cnpj
      assert_match(/\A\d{14}\z/, digits)
      assert DocMath.cnpj_valid?(digits)
    end
  end

  test 'generate_cnpj with alphanumeric: true may include letters in the root' do
    digits = Array.new(30) { DocMath.generate_cnpj(alphanumeric: true) }

    assert(digits.any? { |d| d.match?(/[A-Z]/) })
    digits.each { |d| assert DocMath.cnpj_valid?(d) }
  end
end
