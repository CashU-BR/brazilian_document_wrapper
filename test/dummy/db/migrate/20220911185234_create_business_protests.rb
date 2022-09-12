class CreateBusinessProtests < ActiveRecord::Migration[6.1]
  def change
    create_table :business_protests do |t|
      t.string :document

      t.timestamps
    end
  end
end
