class CreateIiifs < ActiveRecord::Migration
  def change
    create_table :iiifs do |t|

      t.timestamps null: false
    end
  end
end
