# frozen_string_literal: true

class InvalidDocumentError < StandardError
  attr_reader :document

  def initialize(document)
    @document = document
    super("Invalid document: #{document}")
  end
end

module BrazilianDocumentWrapper
  class Wrapper < String
    def standard
      pretty
    end

    def stripped
      raise InvalidDocumentError.new(self) if invalid_document?

      return_document_type do
        if cpf?
          BRDocuments::CPF.strip(value)
        else
          BRDocuments::CNPJ.strip(value)
        end
      end
    end

    def pretty
      raise InvalidDocumentError.new(self) if invalid_document?

      return_document_type do
        if cpf?
          BRDocuments::CPF.pretty(value)
        else
          BRDocuments::CNPJ.pretty(value)
        end
      end
    end

    def doc_type
      return 'CPF' if cpf?

      'CNPJ' if cnpj?
    end

    def stripped_prefix
      pretty.split('/').first.gsub(/[^\d]/, '')
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

    def headquarter
      raise InvalidDocumentError.new(self) if invalid_cnpj?

      headquarter = "#{pretty_prefix}/0001"
      verify_digits = BRDocuments::CNPJ.calculate_verify_digits(headquarter).join('')

      return_document_type do
        "#{headquarter}-#{verify_digits}"
      end
    end

    def headquarter?
      branch_code == '0001'
    end

    def to_param
      return_document_type do
        if cpf?
          BRDocuments::CPF.strip(value)
        else
          BRDocuments::CNPJ.strip(value)
        end
      end
    end

    def cnpj?
      BRDocuments::CNPJ.valid?(value)
    end

    def cpf?
      BRDocuments::CPF.valid?(value)
    end

    private

    def return_document_type
      BrazilianDocumentWrapper::Wrapper.new(yield)
    end

    def value
      if length > 11
        to_s.rjust(14, '0')
      else
        to_s.rjust(11, '0')
      end
    end

    def branch_code
      stripped[8..-3]
    end
  end
end
