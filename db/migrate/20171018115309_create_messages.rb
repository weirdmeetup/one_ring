# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" do |t|
      t.string :user, null: false
      t.text :text, null: false
      t.references :channel, null: false
      t.text :raw, null: false

      t.timestamps
    end
  end
end
