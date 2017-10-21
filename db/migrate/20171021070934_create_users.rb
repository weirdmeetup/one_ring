class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :provider, limit: 20, null: false
      t.string :uid, limit: 20, null: false
      t.string :name, limit: 20, null: false

      t.timestamps
    end
    add_index 'users', %w[provider uid], name: 'user_uniq_provider_uid', unique: true, using: :btree
  end
end
