# frozen_string_literal: true

class BrazilianDocumentType < ActiveModel::Type::Value
  def cast(value)
    BrazilianDocumentWrapper::Wrapper.new(value.to_s)
  end
end
