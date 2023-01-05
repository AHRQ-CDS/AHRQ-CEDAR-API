# frozen_string_literal: true

require_relative '../test_helper'

describe ConceptHelper do
  describe 'concept search' do
    it 'finds concepts' do
      concepts = ConceptHelper.concepts_matching('foo')
      assert_equal 2, concepts.size
    end

    it 'finds concepts with mesh codes' do
      concepts = ConceptHelper.concepts_with_mesh_code_matching('foo')
      assert_equal 1, concepts.size
    end
  end

  describe 'mesh node search' do
    it 'finds mesh nodes' do
      nodes = ConceptHelper.mesh_nodes_matching('foo')
      assert_equal 1, nodes.size
      assert_equal 'D0001', nodes[0].code
    end

    it 'handles when no mesh nodes match' do
      nodes = ConceptHelper.mesh_nodes_matching('yyz')
      assert_equal 0, nodes.size
    end

    it 'finds mesh node parents' do
      nodes = ConceptHelper.parents_of_mesh_nodes_matching('foo')
      assert_equal 1, nodes.size
      assert_equal 'D0000', nodes[0].code
    end

    it 'deduplicates mesh node parents' do
      nodes = ConceptHelper.parents_of_mesh_nodes_matching('foo', 'abc')
      assert_equal 1, nodes.size
      assert_equal 'D0000', nodes[0].code
    end

    it 'finds mesh node children' do
      nodes = ConceptHelper.children_of_mesh_nodes_matching('xyzzy')
      assert_equal 2, nodes.size
    end
  end
end
