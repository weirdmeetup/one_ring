class CreateSecureTokens < ActiveRecord::Migration[5.1]
  def change
    create_table :secure_tokens do |t|
      t.references :user, foreign_key: true, null: false
      t.string :token, limit: 100, null: false

      t.timestamps
    end
  end
end
