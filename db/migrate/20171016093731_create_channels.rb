class CreateChannels < ActiveRecord::Migration[5.1]
  def change
    create_table :channels, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" do |t|
      t.string :cid, null: false
      t.string :name, null: false
      t.string :master, null: false
      t.boolean :active, null: false, default: true
      t.datetime :warned_at

      t.timestamps
    end
  end
end
