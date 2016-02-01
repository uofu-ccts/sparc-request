class RemoveMinimumColumnsFromArmModel < ActiveRecord::Migration
  def change
    remove_column :arms, :minimum_subject_count
    remove_column :arms, :minimum_visit_count
  end
end
