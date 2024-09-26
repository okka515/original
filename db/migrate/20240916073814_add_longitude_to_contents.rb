class AddLongitudeToContents < ActiveRecord::Migration[6.1]
  def change
    add_column :contents, :longitude, :float
  end
end
