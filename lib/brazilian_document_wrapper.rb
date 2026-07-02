# frozen_string_literal: true

require 'brazilian_document_wrapper/version'
require 'brazilian_document_wrapper/railtie'
require 'brazilian_document_wrapper/document_math'
require 'brazilian_document_wrapper/core_ext'
require 'brazilian_document_wrapper/wrapper'
require 'brazilian_document_wrapper/acts_as_brazilian_document_wrapper'

module BrazilianDocumentWrapper
  # `alphanumeric: true` generates a CNPJ root with letters (IN RFB
  # 2.229/2024). Defaults to numeric-only to keep existing factories/specs
  # in consumer apps unchanged.
  def self.generate_cnpj(formatted = true, alphanumeric: false)
    document = Wrapper.new(DocumentMath.generate_cnpj(alphanumeric: alphanumeric))
    formatted ? document.pretty : document.stripped
  end

  def self.generate_cpf(formatted = true)
    document = Wrapper.new(DocumentMath.generate_cpf)
    formatted ? document.pretty : document.stripped
  end
end
