# frozen_string_literal: true

timestamp = Date.today
DB[:repositories].insert(id: 1, name: 'USPSTF', created_at: timestamp, updated_at: timestamp)
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
  repository_id: 1,
  created_at: timestamp,
  updated_at: timestamp
)
