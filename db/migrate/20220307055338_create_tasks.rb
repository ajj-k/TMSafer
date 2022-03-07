class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.references :member, foreign_key: true
      t.string :content
      t.date :date
      t.integer :importance
      t.boolean :done
    end
  end
end
