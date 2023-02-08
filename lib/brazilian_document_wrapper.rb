# frozen_string_literal: true

require 'brazilian_document_wrapper/version'
require 'brazilian_document_wrapper/railtie'
require 'brazilian_document_wrapper/core_ext'
require 'brazilian_document_wrapper/wrapper'
require 'brazilian_document_wrapper/acts_as_brazilian_document_wrapper'

module BrazilianDocumentWrapper
  def self.generate_cnpj(formatted = true)
    BRDocuments::CNPJ.generate(formatted)
  end

  def self.generate_cpf(formatted = true)
    BRDocuments::CPF.generate(formatted)
  end
end
