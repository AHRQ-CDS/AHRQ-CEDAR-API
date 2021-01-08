# frozen_string_literal: true

# Very simple fixture to start with: one table with single entry
DB.create_table :artifacts do
  primary_key :id
  string :remote_identifier
end
DB[:artifacts].insert(id: 1, remote_identifier: '1')
