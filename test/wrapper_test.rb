# frozen_string_literal: true

require 'test_helper'

class WrapperTest < ActiveSupport::TestCase
  test 'formatted to return the document in the standard format' do
    assert_equal '77.075.203/0001-71', '77075203000171'.to_brazilian_document.standard
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

  test 'stripped_prefix to return only numbers from the prefix of the document' do
    assert_equal '77075203', '77075203000171'.to_brazilian_document.stripped_prefix
  end

  test 'invalid_cnpj to return true when is a invalid CNPJ' do
    assert_equal true, '7075203000171'.to_brazilian_document.invalid_cnpj?
  end

  test 'doc_type to return CNPJ when document type is a CNPJ' do
    assert_equal 'CNPJ', '77.075.203/0001-71'.to_brazilian_document.doc_type
  end

  test 'doc_type to return CPF when document type is a CPF' do
    assert_equal 'CPF', '384.227.160-38'.to_brazilian_document.doc_type
  end

  test 'to_param to return a document for in the parameter form' do
    assert_equal '38422716038', '384.227.160-38'.to_brazilian_document.to_param
  end

  test 'to raise InvalidDocumentError when string is a invalid document' do
    assert_raise(InvalidDocumentError) do
      '384.227.160-8'.to_brazilian_document.stripped
    end
  end

  test 'to return a Wrapper class when is a document string' do
    document = '77.075.203/0001-71'.to_brazilian_document

    assert_equal BrazilianDocumentWrapper::Wrapper, document.stripped.class
    assert_equal BrazilianDocumentWrapper::Wrapper, document.pretty.class
    assert_equal BrazilianDocumentWrapper::Wrapper, document.standard.class
    assert_equal BrazilianDocumentWrapper::Wrapper, document.to_param.class
  end

  test 'to return the headquarter document from CNPJ' do
    document = '77.075.203/0001-71'.to_brazilian_document

    assert_equal '77.075.203/0001-71', document.headquarter
  end

  test 'to raise InvalidDocumentError when headquarter is called from a invalid CNPJ' do
    assert_raise(InvalidDocumentError) do
      '384.227.160-38'.to_brazilian_document.headquarter
    end
  end
end
