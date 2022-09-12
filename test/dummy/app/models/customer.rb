class Customer < ApplicationRecord
  acts_as_brazilian_document brazilian_document_field: :cpf
end
