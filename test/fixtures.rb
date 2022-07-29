# frozen_string_literal: true

# Some uses of Sequel such as joins can result in erasure of like-named fields such as id
# Use distinct id ranges to ensure code is working as expected and not because of accidental
# id matches
timestamp = Date.today
old_artifact_timestamp = Date.new(2010, 6, 1)
DB[:repositories].insert(id: 101,
                         name: 'USPSTF',
                         alias: 'USPSTF',
                         fhir_id: 'uspstf',
                         home_page: 'https://www.uspreventiveservicestaskforce.org/uspstf/',
                         created_at: timestamp,
                         updated_at: timestamp)
DB[:repositories].insert(id: 102,
                         name: 'CDS Connect',
                         alias: 'CDS Connect',
                         fhir_id: 'cds-connect',
                         home_page: 'https://cds.ahrq.gov/cdsconnect',
                         created_at: timestamp,
                         updated_at: timestamp)
DB[:artifacts].insert(
  id: 201,
  cedar_identifier: 'abc-1',
  url: 'http://example.org/abc-1',
  remote_identifier: '201',
  artifact_status: 'active',
  title: 'Bladder cancer',
  description: 'Bladder cancer is similar to many other types of cancer in that it is a heterogeneous condition',
  keywords: '["cancer", "adult"]',
  keyword_text: 'cancer, adult',
  repository_id: 101,
  published_on: '2020-07-16',
  created_at: old_artifact_timestamp,
  updated_at: old_artifact_timestamp,
  published_on_precision: 3,
  published_on_start: '2020-07-16 00:00:00',
  published_on_end: '2020-07-16 23:59:59'
)
DB[:artifacts].insert(
  id: 202,
  cedar_identifier: 'abc-2',
  remote_identifier: '202',
  artifact_status: 'active',
  artifact_type: 'Abstract',
  title: 'Diabetes',
  description: 'Lower vitamin D levels have been reported to increase risk for some types of cancer, diabetes.',
  keywords: '["diabetes", "adult"]',
  keyword_text: 'diabetes, adult',
  repository_id: 102,
  published_on: '2021-07-16',
  created_at: timestamp,
  updated_at: timestamp,
  published_on_precision: 3,
  published_on_start: '2021-07-16 00:00:00',
  published_on_end: '2021-07-16 23:59:59'
)
DB[:artifacts].insert(
  id: 203,
  cedar_identifier: 'abc-3',
  remote_identifier: '203',
  artifact_status: 'retired',
  title: 'Type 2 Diabetes',
  keywords: '["diabetes"]',
  keyword_text: 'diabetes',
  repository_id: 101,
  created_at: timestamp,
  updated_at: timestamp,
  published_on_precision: 0
)
DB[:artifacts].insert(
  id: 204,
  cedar_identifier: 'abc-4',
  remote_identifier: '204',
  artifact_status: 'retracted',
  title: 'Type 2 Diabetes (retracted)',
  keywords: '["diabetes"]',
  keyword_text: 'diabetes',
  repository_id: 101,
  strength_of_recommendation_score: 'moderate',
  strength_of_recommendation_sort: 1,
  quality_of_evidence_score: 'high',
  quality_of_evidence_sort: 2,
  created_at: timestamp,
  updated_at: timestamp,
  published_on: '2021-01-02',
  published_on_precision: 3,
  published_on_start: '2021-01-02 00:00:00',
  published_on_end: '2021-01-02 23:59:59'
)
DB[:artifacts].insert(
  id: 205,
  cedar_identifier: 'abc-5',
  remote_identifier: '205',
  artifact_status: 'active',
  title: 'High Cholesterol',
  keywords: '["cholesterol"]',
  keyword_text: 'cholesterol',
  repository_id: 101,
  published_on: '2021-01-01',
  created_at: timestamp,
  updated_at: timestamp,
  published_on_precision: 1,
  published_on_start: '2021-01-01 00:00:00',
  published_on_end: '2021-12-31 23:59:59'
)
DB[:artifacts].insert(
  id: 206,
  cedar_identifier: 'abc-6',
  remote_identifier: '206',
  artifact_status: 'unknown',
  title: 'High Cholesterol',
  keywords: '["cholesterol"]',
  keyword_text: 'cholesterol',
  repository_id: 101,
  published_on: '2021-01-01',
  created_at: timestamp,
  updated_at: timestamp,
  published_on_precision: 2,
  published_on_start: '2021-01-01 00:00:00',
  published_on_end: '2021-01-31 23:59:59'
)
DB[:artifacts].update(content_search: Sequel.lit(
  "setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(keyword_text, '')), 'B') ||
  setweight(to_tsvector('english', coalesce(description, '')), 'D')"
))
DB[:concepts].insert(
  id: 301,
  umls_cui: 'CUI1',
  umls_description: 'CUI1 desc',
  synonyms_text: '["foo", "bar", "baz"]',
  synonyms_psql: '["foo", "bar", "baz"]',
  codes: '[{"system": "MSH", "code": "D0001"}, {"system": "SNOMEDCT_US", "code": "10001"}]',
  created_at: timestamp,
  updated_at: timestamp
)
DB[:concepts].insert(
  id: 302,
  umls_cui: 'CUI2',
  umls_description: 'CUI2 desc',
  synonyms_text: '["abc", "foo, bar, baz"]',
  synonyms_psql: '["abc", "foo<->bar<->baz"]',
  codes: '[{"system": "MSH", "code": "D0002"}]',
  created_at: timestamp,
  updated_at: timestamp
)
DB[:concepts].insert(
  id: 303,
  umls_cui: 'CUI3',
  umls_description: 'CUI3 desc',
  synonyms_text: '["foo bar", "baz"]',
  synonyms_psql: '["foo<->bar", "baz"]',
  created_at: timestamp,
  updated_at: timestamp
)
DB[:concepts].insert(
  id: 304,
  umls_cui: 'CUI4',
  umls_description: 'CUI4 desc',
  synonyms_text: '["foo-bar", "baz"]',
  synonyms_psql: '["foo-bar", "baz"]',
  created_at: timestamp,
  updated_at: timestamp
)
DB[:artifacts_concepts].insert(
  artifact_id: 201,
  concept_id: 301
)
DB[:artifacts_concepts].insert(
  artifact_id: 202,
  concept_id: 302
)
DB[:artifacts_concepts].insert(
  artifact_id: 201,
  concept_id: 302
)
DB[:mesh_tree_nodes].insert(
  id: 401,
  code: 'D00',
  tree_number: 'A00',
  indirect_artifact_count: 2,
  direct_artifact_count: 0,
  name: 'Parent',
  created_at: timestamp,
  updated_at: timestamp
)
DB[:mesh_tree_nodes].insert(
  id: 411,
  code: 'D00',
  tree_number: 'A00.1',
  indirect_artifact_count: 0,
  direct_artifact_count: 1,
  name: 'Child.1',
  parent_id: 401,
  created_at: timestamp,
  updated_at: timestamp
)
DB[:mesh_tree_nodes].insert(
  id: 412,
  code: 'D00',
  tree_number: 'A00.2',
  indirect_artifact_count: 0,
  direct_artifact_count: 1,
  name: 'Child.2',
  parent_id: 401,
  created_at: timestamp,
  updated_at: timestamp
)
DB[:import_runs].insert(
  id: 501,
  repository_id: 101,
  total_count: 1,
  created_at: timestamp,
  updated_at: timestamp
)

DB[:versions].insert(
  id: 601,
  item_type: 'Artifact',
  item_id: 201,
  event: 'create',
  import_run_id: 501
)
DB[:versions].insert(
  id: 602,
  item_id: 201,
  item_type: 'Artifact',
  event: 'update',
  import_run_id: 501,
  object: '{"id": 201, "cedar_identifier": "abc-1", "title": "title v1", "keywords": ["cancer", "adult"], '\
          '"repository_id": 101}'
)
