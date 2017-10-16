class CreateChannels < ActiveRecord::Migration[5.1]
  def change
    create_table :channels do |t|
      t.string :cid, null: false
      t.string :name, null: false
      t.string :master
      t.datetime :last_updated_at, null: false

      t.timestamps
    end
  end
end
