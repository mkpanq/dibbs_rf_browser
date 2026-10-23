class AddFilterIndexesToRfqs < ActiveRecord::Migration[8.1]
  def change
    add_index :rfqs, :return_by          # open-only default, closing-within, default sort
    add_index :rfqs, [ :fsc, :return_by ]
    add_index :rfqs, [ :set_aside, :return_by ]
    add_index :rfqs, :quantity
    add_index :rfqs, :posted_on
  end
end
