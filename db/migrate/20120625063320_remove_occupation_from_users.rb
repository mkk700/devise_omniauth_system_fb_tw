class RemoveOccupationFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :occupation
      end

  def down
    add_column :users, :occupation, :string
  end
end
