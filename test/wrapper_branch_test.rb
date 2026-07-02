# frozen_string_literal: true

require 'test_helper'

class WrapperBranchTest < ActiveSupport::TestCase
  test 'to return the headquarter document from CNPJ' do
    document = '77.075.203/0001-71'.to_brazilian_document

    assert_equal '77.075.203/0001-71', document.headquarter
  end

  test 'returns true for headquarter CNPJ' do
    document = '18.933.677/0001-48'.to_brazilian_document

    assert document.headquarter?
  end

  test 'returns false for branch CNPJ' do
    document = '18.933.677/0002-29'.to_brazilian_document

    refute document.headquarter?
  end

  test 'to raise InvalidDocumentError when headquarter is called from a invalid CNPJ' do
    error = assert_raise(BrazilianDocumentWrapper::InvalidDocumentError) do
      '384.227.160-38'.to_brazilian_document.headquarter
    end
    assert_equal 'Invalid document: 384.227.160-38', error.message
  end

  test 'branch recalculates verify digits for an arbitrary branch code' do
    document = '18.933.677/0001-48'.to_brazilian_document

    assert_equal '18.933.677/0002-29', document.branch('0002')
  end

  test 'branch with 0001 matches headquarter' do
    document = '77.075.203/0001-71'.to_brazilian_document

    assert_equal document.headquarter, document.branch('0001')
  end

  test 'branch to raise InvalidDocumentError for an invalid CNPJ' do
    assert_raise(BrazilianDocumentWrapper::InvalidDocumentError) do
      '384.227.160-38'.to_brazilian_document.branch('0002')
    end
  end
end
