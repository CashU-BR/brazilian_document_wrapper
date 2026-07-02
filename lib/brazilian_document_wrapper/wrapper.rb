# frozen_string_literal: true

require_relative 'document_math'

module BrazilianDocumentWrapper
  class InvalidDocumentError < StandardError
    attr_reader :document

    def initialize(document)
      @document = document
      super("Invalid document: #{document}")
    end
  end

  class Wrapper < String
    CNPJ_MASK_CHARS = %r{[.\-/]}.freeze

    def standard
      pretty
    end

    def pretty
      raise BrazilianDocumentWrapper::InvalidDocumentError, self if invalid_document?

      return_document_type { cpf? ? format_cpf(cpf_digits) : format_cnpj(cnpj_chars) }
    end

    def stripped
      raise BrazilianDocumentWrapper::InvalidDocumentError, self if invalid_document?

      return_document_type { cpf? ? cpf_digits : cnpj_chars }
    end
    alias to_param stripped

    def doc_type
      return 'CPF' if cpf?

      'CNPJ' if cnpj?
    end

    def stripped_prefix
      pretty.split('/').first.gsub(/[^0-9A-Za-z]/, '')
    end

    def pretty_prefix
      pretty.split('/').first
    end

    def invalid_document?
      !cnpj? && !cpf?
    end

    def invalid_cnpj?
      !cnpj?
    end

    def branch(code)
      raise BrazilianDocumentWrapper::InvalidDocumentError, self if invalid_cnpj?

      root = cnpj_chars[0, 8]
      order = code.to_s.gsub(CNPJ_MASK_CHARS, '').upcase.rjust(4, '0')

      return_document_type { format_cnpj(DocumentMath.cnpj_digits_for("#{root}#{order}")) }
    end

    def headquarter
      branch('0001')
    end

    def headquarter?
      branch_code == '0001'
    end

    def cnpj?
      DocumentMath.cnpj_valid?(cnpj_chars)
    end

    def cpf?
      DocumentMath.cpf_valid?(cpf_digits)
    end

    private

    def return_document_type
      BrazilianDocumentWrapper::Wrapper.new(yield)
    end

    # Left-pads purely numeric input so documents that lost leading zeros
    # (classic effect of an integer-typed database column) still validate.
    # Never applied when letters are present: an alphanumeric CNPJ root could
    # never have passed through an integer column to begin with.
    def value
      raw = to_s
      return raw if raw.match?(/[A-Za-z]/)

      if raw.length > DocumentMath::CPF_LENGTH
        raw.rjust(DocumentMath::CNPJ_LENGTH, '0')
      else
        raw.rjust(DocumentMath::CPF_LENGTH, '0')
      end
    end

    def cpf_digits
      value.gsub(/\D/, '')
    end

    # Only mask separators are stripped, never letters or unexpected symbols -
    # a stray character must fail validation, not be silently discarded.
    def cnpj_chars
      value.gsub(CNPJ_MASK_CHARS, '').upcase
    end

    def format_cpf(digits)
      format('%<a>s.%<b>s.%<c>s-%<d>s',
             a: digits[0, 3], b: digits[3, 3], c: digits[6, 3], d: digits[9, 2])
    end

    def format_cnpj(chars)
      format('%<a>s.%<b>s.%<c>s/%<d>s-%<e>s',
             a: chars[0, 2], b: chars[2, 3], c: chars[5, 3], d: chars[8, 4], e: chars[12, 2])
    end

    def branch_code
      stripped[8, 4]
    end
  end
end

# Deprecated: kept for one version so `rescue InvalidDocumentError` in
# consumers keeps working. Prefer BrazilianDocumentWrapper::InvalidDocumentError.
unless defined?(InvalidDocumentError)
  InvalidDocumentError = BrazilianDocumentWrapper::InvalidDocumentError
end
