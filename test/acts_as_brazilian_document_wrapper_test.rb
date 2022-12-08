# frozen_string_literal: true

require 'test_helper'

class ActsAsBrazilianDocumentWrapperTest < ActiveSupport::TestCase
  def test_a_business_protests_brazilian_document_field_should_be_document
    assert_equal 'document', BusinessProtest.brazilian_document_field
  end

  def test_a_customers_brazilian_document_field_should_be_document
    assert_equal 'cpf', Customer.brazilian_document_field
  end

  def test_a_business_protest_brazilian_document_field_behave_like_brazilian_document
    protest = BusinessProtest.new(document: '52.256.591/0001-66')

    BrazilianDocumentWrapper::Wrapper.instance_methods(false).each do |method|
      assert_equal(protest.document.respond_to?(method), true)
    end
  end

  def test_a_customers_should_behave_like_natural_person
    customer = Customer.new(cpf: '618.543.570-50')

    assert_equal true, customer.natural_person?
    assert_equal false, customer.legal_person?
  end

  def test_a_business_protest_should_behave_like_legal_person
    protest = BusinessProtest.new(document: '52.256.591/0001-66')

    assert_equal false, protest.natural_person?
    assert_equal true, protest.legal_person?
  end

  def test_a_business_protest_should_save_document_in_format_standard
    protest = BusinessProtest.new(document: '52256591000166')

    protest.save!

    assert_equal protest.document, '52.256.591/0001-66'
  end
end
