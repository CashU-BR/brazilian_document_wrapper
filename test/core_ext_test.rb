# frozen_string_literal: true

require 'test_helper'

class CoreExtTest < ActiveSupport::TestCase
  def test_to_check_if_is_brazilian_document_type
    assert_equal BrazilianDocumentWrapper::Wrapper, '77.075.203/0001-71'.to_brazilian_document.class
  end
end
