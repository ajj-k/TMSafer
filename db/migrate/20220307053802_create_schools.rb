class CreateSchools < ActiveRecord::Migration[6.1]
  def change
    create_table :schools do |t|
      t.references :user, foreign_key: true
      t.string :name
      t.timestamps null: false
    end
  end
end
