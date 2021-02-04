# frozen_string_literal: true

# Very simple fixture to start with: one table with single entry
DB.create_table :artifacts do
  primary_key :id
  foreign_key :repository_id, :repositories
  string :cedar_identifier
  string :remote_identifier
  string :artifact_status
  string :keywords
  string :mesh_keywords
  string :title
  string :description
  date :published_on
  string :url
end

DB.create_table :repositories do
  primary_key :id
  string :name
  string :home_page
end

DB[:repositories].insert(id: 1, name: 'USPSTF')
DB[:artifacts].insert(
  id: 1,
  cedar_identifier: 'abc-1',
  remote_identifier: '100',
  artifact_status: 'active',
  title: 'cancer',
  keywords: '[]',
  mesh_keywords: '[]',
  repository_id: 1
)
DB[:artifacts].insert(
  id: 2,
  cedar_identifier: 'abc-2',
  remote_identifier: '102',
  artifact_status: 'active',
  title: 'Diabetes',
  keywords: '[]',
  mesh_keywords: '[]',
  repository_id: 1
)
DB[:artifacts].insert(
  id: 3,
  cedar_identifier: 'abc-3',
  remote_identifier: '103',
  artifact_status: 'active',
  title: 'Type 2 Diabetes',
  keywords: '[]',
  mesh_keywords: '[]',
  repository_id: 1
)
