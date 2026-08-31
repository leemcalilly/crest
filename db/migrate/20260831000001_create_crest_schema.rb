class CreateCrestSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :cycles do |t|
      t.string  :slug, null: false
      t.string  :name, null: false
      t.integer :world_cup_year
      t.date    :starts_on, null: false
      t.date    :ends_on, null: false
      t.timestamps
      t.index :slug, unique: true
      t.index :starts_on
    end

    create_table :matches do |t|
      t.references :cycle, null: false, foreign_key: true
      t.date    :played_on, null: false
      t.string  :opponent, null: false
      t.integer :us_score, null: false
      t.integer :opponent_score, null: false
      t.string  :tournament, null: false
      t.string  :city, null: false
      t.string  :country, null: false
      t.boolean :neutral, null: false, default: false
      t.boolean :home, null: false, default: true
      t.timestamps
      t.index :played_on
      t.index :opponent
      t.index :tournament
      t.index [ :city, :country ]
    end

    create_table :players do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
      t.index :slug, unique: true
      t.index :name, unique: true
    end

    create_table :goals do |t|
      t.references :match, null: false, foreign_key: true
      t.references :player, null: true, foreign_key: true
      t.string  :scorer_name, null: false
      t.boolean :for_us, null: false, default: true
      t.integer :minute
      t.boolean :penalty, null: false, default: false
      t.boolean :own_goal, null: false, default: false
      t.timestamps
    end
  end
end
