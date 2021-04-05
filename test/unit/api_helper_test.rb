# frozen_string_literal: true

require_relative '../test_helper'

describe ApiHelper do
  describe 'parse full text search' do
    it 'handles phrase enclosed by double quotes' do
      source = '"lung cancer"'
      result = ApiHelper.parse_full_text_search(source)
      assert_equal('lung<->cancer', result)
    end

    it 'converts AND token to &' do
      source = 'A AND B'
      result = ApiHelper.parse_full_text_search(source)
      assert_equal('A & B', result)
    end

    it 'converts OR token to |' do
      source = 'A OR B'
      result = ApiHelper.parse_full_text_search(source)
      assert_equal('A | B', result)
    end

    it 'converts NOT token to !' do
      source = 'NOT A'
      result = ApiHelper.parse_full_text_search(source)
      assert_equal('! A', result)
    end

    it 'handles complex full test search expression' do
      source = '"lung cancer" AND (screening OR NOT procedure)'
      result = ApiHelper.parse_full_text_search(source)
      assert_equal('lung<->cancer & (screening | ! procedure)', result)
    end

    it 'handles complex full test search expression with multiple double quotes' do
      source = '"lung cancer" AND ("skin cancer" OR "bladder cancer")'
      result = ApiHelper.parse_full_text_search(source)
      assert_equal('lung<->cancer & (skin<->cancer | bladder<->cancer)', result)
    end
  end
end
