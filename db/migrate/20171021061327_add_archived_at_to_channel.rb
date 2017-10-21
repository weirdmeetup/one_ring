class AddArchivedAtToChannel < ActiveRecord::Migration[5.1]
  def change
    add_column :channels, :archived_at, :datetime
  end
end
