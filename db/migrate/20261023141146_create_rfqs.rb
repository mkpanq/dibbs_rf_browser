class CreateRfqs < ActiveRecord::Migration[8.1]
  def change
    create_table :rfqs do |t|
      t.string :solicitation, null: false
      t.string :purchase_request, null: false
      t.string :nsn, null: false
      t.string :fsc
      t.string :item_name
      t.integer :quantity
      t.string :unit
      t.date :return_by
      t.string :buyer
      t.string :amsc
      t.string :item_type
      t.string :set_aside
      t.integer :set_aside_pct
      t.date :posted_on, null: false
      t.date :last_seen_on, null: false
      t.timestamps
    end
    add_index :rfqs, [ :solicitation, :purchase_request ], unique: true
  end
end
