# frozen_string_literal: true

require 'test_helper'

class ActsAsBrazilianDocumentWrapperTest < ActiveSupport::TestCase
  def test_a_business_protests_brazilian_document_field_should_be_document
    assert_equal 'document', BusinessProtest.brazilian_document_field
  end

  def test_a_customers_brazilian_document_field_should_be_document
    assert_equal 'cpf', Customer.brazilian_document_field
  end

  def test_a_customers_brazilian_document_field_behave_like_brazilian_document
    protest = BusinessProtest.new(document: '52.256.591/0001-66')

    BrazilianDocumentWrapper::Wrapper.instance_methods(false).each do |method|
      assert_equal(protest.document.respond_to?(method), true)
    end
  end
end
