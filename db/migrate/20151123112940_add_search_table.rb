class AddSearchTable < ActiveRecord::Migration
  def change
create_table :searches do |t|
      t.string :name
      t.timestamps null: false
    end
  end
end
