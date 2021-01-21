# frozen_string_literal: true

# Very simple fixture to start with: one table with single entry
DB.create_table :artifacts do
  primary_key :id
  foreign_key :repository_id, :repositories
  string :remote_identifier
end

DB.create_table :repositories do
  primary_key :id
  string :name
end

DB[:repositories].insert(id: 1, name: 'USPSTF')
DB[:artifacts].insert(id: 1, remote_identifier: '1', repository_id: 1)
