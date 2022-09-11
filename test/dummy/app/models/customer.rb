class Customer < ApplicationRecord
  acts_as_brazilian_document_wrapper brazilian_document_field: :cpf
end
