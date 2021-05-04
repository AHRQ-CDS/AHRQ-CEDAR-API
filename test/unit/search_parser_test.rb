# frozen_string_literal: true

require_relative '../test_helper'

describe SearchParser do
  describe 'parse full text search' do
    it 'handles simple text search, adding implicit &s' do
      source = 'aa bb cc'
      result = SearchParser.parse(source)
      assert_equal('aa&bb&cc', result)
    end

    it 'handles simple parenthetical, adding implicit &s' do
      source = '(aa bb cc)'
      result = SearchParser.parse(source)
      assert_equal('(aa&bb&cc)', result)
    end

    it 'handles more complex implicit &s mixed with parentheticals' do
      source = 'aa (bb cc)'
      result = SearchParser.parse(source)
      assert_equal('aa&(bb&cc)', result)
    end

    it 'handles more complex implicit &s mixed with negation' do
      source = 'aa NOT bb'
      result = SearchParser.parse(source)
      assert_equal('aa&!bb', result)
    end

    it 'handles complex full text search expression' do
      source = '"aa bb" AND (cc OR NOT dd)'
      result = SearchParser.parse(source)
      assert_equal('aa<->bb&(cc|!dd)', result)
    end

    it 'handles complex full text search expression with multiple double quotes' do
      source = '"aa bb" AND ("cc dd" OR "ee ff")'
      result = SearchParser.parse(source)
      assert_equal('aa<->bb&(cc<->dd|ee<->ff)', result)
    end

    it 'handles complex full text search expression with multiple parentheses' do
      source = 'aa AND ((bb OR cc) AND ((dd OR ee) AND (NOT ff)))'
      result = SearchParser.parse(source)
      assert_equal('aa&((bb|cc)&((dd|ee)&(!ff)))', result)
    end

    it 'converts AND, OR, NOT to &, |, !' do
      text = 'aa AND bb OR NOT cc'
      result = SearchParser.parse(text)
      assert_equal('aa&bb|!cc', result)
    end

    it 'skips leading and trailing blank space in phrase' do
      text = '" aa bb "'
      result = SearchParser.parse(text)
      assert_equal('aa<->bb', result)
    end

    it 'skips extra blank space in phrase' do
      text = '"aa   bb"'
      result = SearchParser.parse(text)
      assert_equal('aa<->bb', result)
    end

    it 'handles missing spaces combined with parentheticals' do
      text = 'aa AND(bb OR cc)'
      result = SearchParser.parse(text)
      assert_equal('aa&(bb|cc)', result)
    end

    it 'handles missing spaces combined with phrases' do
      text = 'aa AND"bb cc"'
      result = SearchParser.parse(text)
      assert_equal('aa&bb<->cc', result)
    end

    it 'handles search terms that start with a keyword' do
      text = 'aa OR ORGAN'
      result = SearchParser.parse(text)
      assert_equal('aa|ORGAN', result)
    end

    it 'handles two phrases next to each other' do
      text = '"aa bb""bb aa"'
      result = SearchParser.parse(text)
      assert_equal('aa<->bb&bb<->aa', result)
    end

    it 'skips empty phrase' do
      text = '""'
      result = SearchParser.parse(text)
      assert_equal(0, result.length)
    end
  end
end