# frozen_string_literal: true

timestamp = Date.today
DB[:repositories].insert(id: 1, name: 'USPSTF', created_at: timestamp, updated_at: timestamp)
DB[:artifacts].insert(
  id: 1,
  cedar_identifier: 'abc-1',
  remote_identifier: '100',
  artifact_status: 'active',
  title: 'Bladder cancer',
  description: 'Bladder cancer is similar to many other types of cancer in that it is a heterogeneous condition',
  keywords: '["Cancer", "adult"]',
  mesh_keywords: '[]',
  keyword_text: 'Cancer, adult',
  repository_id: 1,
  created_at: timestamp,
  updated_at: timestamp
)
DB[:artifacts].insert(
  id: 2,
  cedar_identifier: 'abc-2',
  remote_identifier: '102',
  artifact_status: 'active',
  title: 'Diabetes',
  description: 'Lower vitamin D levels have been reported to increase risk for some types of cancer, diabetes.',
  keywords: '["Diabetes", "Adult"]',
  mesh_keywords: '[]',
  keyword_text: 'Diabetes, Adult',
  repository_id: 1,
  created_at: timestamp,
  updated_at: timestamp
)
DB[:artifacts].insert(
  id: 3,
  cedar_identifier: 'abc-3',
  remote_identifier: '103',
  artifact_status: 'active',
  title: 'Type 2 Diabetes',
  keywords: '["diabetes"]',
  mesh_keywords: '[]',
  keyword_text: 'diabetes',
  repository_id: 1,
  created_at: timestamp,
  updated_at: timestamp
)
DB[:artifacts].update(content_search: Sequel.lit(
  "setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(keyword_text, '')), 'B') ||
  setweight(to_tsvector('english', coalesce(mesh_keyword_text, '')), 'B') ||
  setweight(to_tsvector('english', coalesce(description, '')), 'D')"
))
