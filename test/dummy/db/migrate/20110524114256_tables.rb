class Tables < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :name
      t.string :email
      t.timestamps
    end
    create_table :invitations, :force => true do |t|
      t.string  :status
      t.integer :user_id
      t.integer :event_id
      t.timestamps
    end
    create_table :events, :force => true do |t|
      t.string  :name
      t.text    :description
      t.integer :user_id
      t.timestamps
    end
    create_table :counters, :force => true do |t|
      t.string  :source_class
      t.integer :source_id
      t.string  :cached_class
      t.string  :cached_relation
      t.string  :name
      t.integer :count, :default => 0
    end
  end

  def self.down
    drop_table :counters
    drop_table :events
    drop_table :invitations
    drop_table :users
  end
end
