# frozen_string_literal: true

module BrazilianDocumentWrapper
  # Pure Ruby checksum/validation/generation for CPF and CNPJ (numeric and
  # alphanumeric, per IN RFB 2.229/2024). No runtime dependency beyond Ruby
  # itself. Operates on already-normalized strings (mask stripped, uppercase);
  # callers own parsing/formatting.
  module DocumentMath
    module_function

    CPF_LENGTH = 11
    CNPJ_LENGTH = 14
    CNPJ_ROOT_LENGTH = 12

    CPF_FIRST_WEIGHTS = (10).downto(2).to_a.freeze
    CPF_SECOND_WEIGHTS = (11).downto(2).to_a.freeze

    NUMERIC_ALPHABET = ('0'..'9').to_a.freeze
    CNPJ_ALPHABET = (NUMERIC_ALPHABET + ('A'..'Z').to_a).freeze

    # Mod 11: remainder < 2 becomes 0, otherwise the digit is (11 - remainder).
    # Same rule for CPF and CNPJ (numeric and alphanumeric) verify digits.
    def verify_digit(sum)
      remainder = sum % 11
      remainder < 2 ? 0 : 11 - remainder
    end

    # '0'..'9' => 0..9, 'A'..'Z' => 17..42 (ASCII codepoint - 48).
    def char_value(char)
      char.ord - 48
    end

    def repeated_chars?(chars)
      chars.chars.uniq.size == 1
    end

    def cpf_verify_digit(digits, weights)
      sum = digits.chars.each_with_index.sum { |digit, index| digit.to_i * weights[index] }
      verify_digit(sum)
    end

    # Weights cycle 2..9 from the rightmost character outward, so the same
    # formula covers numeric and alphanumeric CNPJ roots (backward compatible
    # with the legacy numeric-only weight tables).
    def cnpj_verify_digit(chars)
      sum = chars.reverse.chars.each_with_index.sum do |char, index|
        char_value(char) * (2 + index % 8)
      end
      verify_digit(sum)
    end

    def cpf_valid?(digits)
      return false unless digits.is_a?(String) && digits.match?(/\A\d{#{CPF_LENGTH}}\z/)
      return false if repeated_chars?(digits)

      dv1 = cpf_verify_digit(digits[0, 9], CPF_FIRST_WEIGHTS)
      dv2 = cpf_verify_digit(digits[0, 9] + dv1.to_s, CPF_SECOND_WEIGHTS)
      digits[9, 2] == "#{dv1}#{dv2}"
    end

    def cnpj_valid?(chars)
      return false unless chars.is_a?(String) && chars.match?(/\A[0-9A-Z]{12}\d{2}\z/)
      return false if repeated_chars?(chars)

      root = chars[0, CNPJ_ROOT_LENGTH]
      dv1 = cnpj_verify_digit(root)
      dv2 = cnpj_verify_digit(root + dv1.to_s)
      chars[CNPJ_ROOT_LENGTH, 2] == "#{dv1}#{dv2}"
    end

    def cnpj_digits_for(root)
      dv1 = cnpj_verify_digit(root)
      dv2 = cnpj_verify_digit(root + dv1.to_s)
      "#{root}#{dv1}#{dv2}"
    end

    # Only for tests/factories - the RFB is the sole issuer of real numbers.
    def generate_cpf
      loop do
        digits = Array.new(9) { rand(10) }.join
        dv1 = cpf_verify_digit(digits, CPF_FIRST_WEIGHTS)
        dv2 = cpf_verify_digit(digits + dv1.to_s, CPF_SECOND_WEIGHTS)
        candidate = "#{digits}#{dv1}#{dv2}"
        return candidate if cpf_valid?(candidate)
      end
    end

    def generate_cnpj(alphanumeric: false)
      alphabet = alphanumeric ? CNPJ_ALPHABET : NUMERIC_ALPHABET
      loop do
        root = Array.new(CNPJ_ROOT_LENGTH) { alphabet.sample }.join
        candidate = cnpj_digits_for(root)
        return candidate if cnpj_valid?(candidate)
      end
    end
  end
end
