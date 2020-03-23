class CreateUsers < ActiveRecord::Migration
      def up
        create_table :users do |t|
          t.string :sessionid
          t.string :startTime
          t.string :endTime
          t.text :input
        end
      end
  end