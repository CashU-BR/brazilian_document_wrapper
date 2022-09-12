class ApplicationRecord < ActiveRecord::Base
  include BrazilianDocumentWrapper::ActsAsBrazilianDocumentWrapper

  self.abstract_class = true
end
