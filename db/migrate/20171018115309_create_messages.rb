class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.string :user, null: false
      t.text :text, null: false
      t.references :channel, null: false
      t.text :raw, null: false

      t.timestamps
    end
  end
end
