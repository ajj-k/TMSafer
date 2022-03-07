class CreateMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :members do |t|
      t.references :school, foreign_key: true
      t.string :name
      t.string :icon
      t.string :url
      t.string :cource
    end
  end
end
