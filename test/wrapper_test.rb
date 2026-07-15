# frozen_string_literal: true

require 'test_helper'

class WrapperTest < ActiveSupport::TestCase
  test 'standard to return the document when 0 is missing from the beginning of cnpj' do
    assert_equal '04.985.802/0001-59', '4985802000159'.to_brazilian_document.standard
  end

  test 'stripped to return the document when 0 is missing from the beginning of cnpj' do
    assert_equal '04985802000159', '4985802000159'.to_brazilian_document.stripped
  end

  test 'standard to return the document when 0 is missing from the beginning of cpf' do
    assert_equal '078.810.710-01', '7881071001'.to_brazilian_document.standard
  end

  test 'formatted to return the document in the standard format' do
    assert_equal '77.075.203/0001-71', '77075203000171'.to_brazilian_document.standard
  end

  test 'to return a brazilian document type when standard format is called' do
    assert_equal BrazilianDocumentWrapper::Wrapper,
                 '77075203000171'.to_brazilian_document.standard.class
    assert_equal BrazilianDocumentWrapper::Wrapper,
                 '42521602000'.to_brazilian_document.standard.class
  end

  test 'pretty to return the document in the visible format' do
    assert_equal '77.075.203/0001-71', '77075203000171'.to_brazilian_document.pretty
  end

  test 'pretty_prefix to return the prefix of the document in the visible format' do
    assert_equal '77.075.203', '77075203000171'.to_brazilian_document.pretty_prefix
  end

  test 'stripped to return only numbers' do
    assert_equal '77075203000171', '77.075.203/0001-71'.to_brazilian_document.stripped
  end

  test 'stripped to return only numbers from cpf' do
    assert_equal '38422716038', '384.227.160-38'.to_brazilian_document.stripped
  end

  test 'stripped_prefix to return only numbers from the prefix of the document' do
    assert_equal '77075203', '77075203000171'.to_brazilian_document.stripped_prefix
  end

  test 'stripped accepts mixed separator formats' do
    assert_equal '77075203000171', '77.075.203/0001-71'.to_brazilian_document.stripped
    assert_equal '77075203000171', '77-075-203/0001-71'.to_brazilian_document.stripped
    assert_equal '77075203000171', '77075203/000171'.to_brazilian_document.stripped
    assert_equal '77075203000171', '77075203000171'.to_brazilian_document.stripped
  end

  test 'invalid_cnpj to return true when is a invalid CNPJ' do
    assert_equal true, '7075203000171'.to_brazilian_document.invalid_cnpj?
  end

  test 'doc_type to return CNPJ when document type is a CNPJ' do
    assert_equal 'CNPJ', '77.075.203/0001-71'.to_brazilian_document.doc_type
    assert_equal true, '77.075.203/0001-71'.to_brazilian_document.cnpj?
  end

  test 'doc_type to return CPF when document type is a CPF' do
    assert_equal 'CPF', '384.227.160-38'.to_brazilian_document.doc_type
    assert_equal true, '384.227.160-38'.to_brazilian_document.cpf?
  end

  test 'doc_type to return nil for an invalid document' do
    assert_nil '384.227.160-8'.to_brazilian_document.doc_type
  end

  test 'to_param to return a document for in the parameter form' do
    assert_equal '38422716038', '384.227.160-38'.to_brazilian_document.to_param
  end

  test 'to_param raises InvalidDocumentError for an invalid document' do
    assert_raise(BrazilianDocumentWrapper::InvalidDocumentError) do
      '384.227.160-8'.to_brazilian_document.to_param
    end
  end

  test 'to raise InvalidDocumentError when string is a invalid document' do
    error = assert_raise(BrazilianDocumentWrapper::InvalidDocumentError) do
      '384.227.160-8'.to_brazilian_document.stripped
    end
    assert_equal 'Invalid document: 384.227.160-8', error.message
  end

  test 'the deprecated top-level InvalidDocumentError alias still catches the error' do
    error = assert_raise(InvalidDocumentError) do
      '384.227.160-8'.to_brazilian_document.stripped
    end
    assert_kind_of BrazilianDocumentWrapper::InvalidDocumentError, error
  end

  test 'to return a Wrapper class when is a document string' do
    document = '77.075.203/0001-71'.to_brazilian_document

    assert_equal BrazilianDocumentWrapper::Wrapper, document.stripped.class
    assert_equal BrazilianDocumentWrapper::Wrapper, document.pretty.class
    assert_equal BrazilianDocumentWrapper::Wrapper, document.standard.class
    assert_equal BrazilianDocumentWrapper::Wrapper, document.to_param.class
  end

  test 'a sample of real numeric documents remain valid after internalizing the checksum' do
    real_cnpjs = %w[04985802000159 77075203000171 18933677000148 52256591000166]
    real_cpfs = %w[07881071001 38422716038 61854357050]

    real_cnpjs.each { |cnpj| assert cnpj.to_brazilian_document.cnpj?, "expected #{cnpj} valid" }
    real_cpfs.each { |cpf| assert cpf.to_brazilian_document.cpf?, "expected #{cpf} valid" }
  end
end
