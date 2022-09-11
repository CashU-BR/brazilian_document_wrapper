# frozen_string_literal: true

class String
  def to_brazilian_document
    BrazilianDocumentWrapper::Wrapper.new(self)
  end
end
