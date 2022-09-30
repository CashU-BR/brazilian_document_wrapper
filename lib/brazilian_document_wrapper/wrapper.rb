# frozen_string_literal: true

class InvalidDocumentError < StandardError; end

module BrazilianDocumentWrapper
  class Wrapper < String
    def standard
      pretty
    end

    def stripped
      raise InvalidDocumentError if invalid_document?

      return_document_type do
        BRDocuments::CNPJ.strip(self)
      end
    end

    def pretty
      raise InvalidDocumentError if invalid_document?

      return BRDocuments::CPF.pretty(self) if cpf?

      return_document_type do
        BRDocuments::CNPJ.pretty(self)
      end
    end

    def doc_type
      return 'CPF' if cpf?

      return 'CNPJ' if cnpj?
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
      raise InvalidDocumentError if invalid_cnpj?

      headquarter = "#{pretty_prefix}/0001"
      verify_digits = BRDocuments::CNPJ.calculate_verify_digits(headquarter).join('')

      return_document_type do
        "#{headquarter}-#{verify_digits}"
      end
    end

    def to_param
      return_document_type do
        BRDocuments::CNPJ.strip(self)
      end
    end

    def cnpj?
      BRDocuments::CNPJ.valid?(self)
    end

    def cpf?
      BRDocuments::CPF.valid?(self)
    end

    private

    def return_document_type
      BrazilianDocumentWrapper::Wrapper.new(yield)
    end
  end
end
