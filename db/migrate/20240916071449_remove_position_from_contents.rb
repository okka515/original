class RemovePositionFromContents < ActiveRecord::Migration[6.1]
  def change
    remove_column :contents, :position
  end
end
