class RemoveWarnedAtFromChannel < ActiveRecord::Migration[5.1]
  def change
    remove_column :channels, :warned_at, :datetime
  end
end
