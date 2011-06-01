class Tables < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :name
      t.string :email
      t.integer  :status
      t.integer :site_id
      t.integer :photos_count
      t.timestamps
    end
    create_table :invitations, :force => true do |t|
      t.string  :estat
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
      t.string  :source_relation
      t.string  :name
      t.integer :count, :default => 0
    end
    create_table :sites, :force => true do |t|
      t.string  :name
    end
    create_table :messages, :force => true do |t|
      t.integer  :user_id
      t.integer  :status
      t.string :subject
      t.text :body
    end
    create_table :photos, :force => true do |t|
      t.string :description
      t.integer  :user_id
    end
    create_table :videos, :force => true do |t|
      t.string :description
      t.integer  :user_id
    end
  end

  def self.down
    drop_table :counters
    drop_table :events
    drop_table :invitations
    drop_table :users
    drop_table :sites
    drop_table :messages
    drop_table :photos
    drop_table :videos
  end
end
