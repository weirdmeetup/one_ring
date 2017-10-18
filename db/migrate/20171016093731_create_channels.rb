class CreateChannels < ActiveRecord::Migration[5.1]
  def change
    create_table :channels do |t|
      t.string :cid, null: false
      t.string :name, null: false
      t.string :master, null: false

      t.timestamps
    end
  end
end
