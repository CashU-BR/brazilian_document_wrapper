# frozen_string_literal: true

require 'types/brazilian_document_type'

module BrazilianDocumentWrapper
  module ActsAsBrazilianDocumentWrapper
    extend ActiveSupport::Concern

    class_methods do
      def acts_as_brazilian_document(options = {})
        value = (options[:brazilian_document_field] || :document)
        cattr_accessor :brazilian_document_field, default: value.to_s

        attribute value, BrazilianDocumentType.new
      end
    end
  end
end
