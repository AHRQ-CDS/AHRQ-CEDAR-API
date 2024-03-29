# frozen_string_literal: true

require_relative '../test_helper'

describe SearchParser do
  describe 'parse full text search' do
    it 'handles simple text search, adding implicit &s' do
      source = 'aa bb cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa&bb&cc', result)
      source = "aa bb's cc"
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa&bb's&cc", result)
      source = 'aa bb+ cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa&bb+&cc', result)
    end

    it 'handles simple text search, ignoring punctuation' do
      source = 'aa, bb; cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa&bb&cc', result)
    end

    it 'handles hyphenated words' do
      source = 'aa-cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal('(aa-cc|aacc|aa<->cc)', result)
    end

    it 'handles synonyms in simple text searches' do
      source = 'aa foo cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa&('foo'|'bar'|'baz')&cc", result)
    end

    it 'ignores case for synonym lookup' do
      source = 'aa FOO cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa&('foo'|'bar'|'baz')&cc", result)
    end

    it 'handles synonyms when the search word is hyphenated' do
      source = 'aa f-oo cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal("(aa&('foo'|'bar'|'baz')&cc)|(aa<->f-oo<->cc|aa<->foo<->cc|aa<->f<->oo<->cc)", result)
    end

    it 'handles hyphenated synonyms' do
      source = 'aa foo-bar cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal(
        "(aa&('foo-bar' <-> 'foo' <-> 'bar'|'baz'|'foo' <-> 'bar')&cc)" \
        '|(aa<->foo-bar<->cc|aa<->foobar<->cc|aa<->foo<->bar<->cc)',
        result
      )
    end

    it 'handles multi-word synonyms in simple text searches' do
      source = 'aa abc cc'
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa&('abc'|'foo' <-> 'bar' <-> 'baz')&cc", result)
    end

    it 'ignores stop words when looking for synonyms' do
      source = 'aa of foo'
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa&of&('foo'|'bar'|'baz')", result)
    end

    it 'handles phrase synonyms in simple text searches' do
      source = 'def ghi klm'
      result = SearchParser.to_postgres_query(source)

      assert_equal("(def&ghi&klm)|('def' <-> 'ghi' <-> 'klm'|nop)", result)
    end

    it 'handles simple parenthetical, adding implicit &s' do
      source = '(aa bb cc)'
      result = SearchParser.to_postgres_query(source)

      assert_equal('(aa&bb&cc)', result)
    end

    it 'handles more complex implicit &s mixed with parentheticals' do
      source = 'aa (bb cc)'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa&(bb&cc)', result)
    end

    it 'handles synonyms within more complex implicit &s mixed with parentheticals' do
      source = 'aa (foo cc)'
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa&(('foo'|'bar'|'baz')&cc)", result)
    end

    it 'handles more complex implicit &s mixed with negation' do
      source = 'aa NOT bb'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa&!bb', result)
    end

    it 'handles synonyms with more complex implicit &s mixed with negation' do
      source = 'aa NOT foo'
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa&!('foo'|'bar'|'baz')", result)
    end

    it 'handles complex full text search expression' do
      source = '"aa bb" AND (cc OR NOT dd)'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa<->bb&(cc|!dd)', result)
    end

    it 'ignores synonyms that do not match a multi-word full text search expression' do
      source = '"aa foo" AND (cc OR NOT foo)'
      result = SearchParser.to_postgres_query(source)

      assert_equal("aa<->foo&(cc|!('foo'|'bar'|'baz'))", result)
    end

    it 'handles multi-word synonyms within multi-word full text search expression' do
      source = '"foo bar" AND (cc OR NOT foo)'
      result = SearchParser.to_postgres_query(source)

      assert_equal("('foo' <-> 'bar'|'baz')&(cc|!('foo'|'bar'|'baz'))", result)
    end

    it 'handles complex full text search expression with multiple double quotes' do
      source = '"aa bb" AND ("cc dd" OR "ee ff")'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa<->bb&(cc<->dd|ee<->ff)', result)
    end

    it 'handles complex full text search expression with multiple parentheses' do
      source = 'aa AND ((bb OR cc) AND ((dd OR ee) AND (NOT ff)))'
      result = SearchParser.to_postgres_query(source)

      assert_equal('aa&((bb|cc)&((dd|ee)&(!ff)))', result)
    end

    it 'converts AND, OR, NOT to &, |, !' do
      text = 'aa AND bb OR NOT cc'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa&bb|!cc', result)
    end

    it 'skips leading and trailing blank space in phrase' do
      text = '" aa bb "'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->bb', result)
    end

    it 'ignores punctuation in phrases' do
      text = '"aa, bb"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->bb', result)

      text = '"aa; bb"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->bb', result)

      text = '"aa: bb"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->bb', result)

      text = '"aa. bb"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->bb', result)
    end

    it 'skips extra blank space in phrase' do
      text = '"aa   bb"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->bb', result)
    end

    it 'handles braces in phrases' do
      text = '"aa (bb)"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->(bb)', result)
    end

    it 'handles missing spaces combined with parentheticals' do
      text = 'aa AND(bb OR cc)'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa&(bb|cc)', result)
    end

    it 'handles missing spaces combined with phrases' do
      text = 'aa AND"bb cc"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa&bb<->cc', result)
    end

    it 'handles search terms that start with a keyword' do
      text = 'aa OR ORGAN'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa|organ', result)
    end

    it 'handles two phrases next to each other' do
      text = '"aa bb""bb aa"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa<->bb&bb<->aa', result)
    end

    it 'skips empty phrases' do
      text = '""'
      result = SearchParser.to_postgres_query(text)

      assert_equal(0, result.length)
      text = '"" aa'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa', result)
      text = '""aa'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa', result)
      text = 'aa ""'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa', result)
      text = 'aa""'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa', result)
      text = '""aa"'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa', result)
      text = '"aa""'
      result = SearchParser.to_postgres_query(text)

      assert_equal('aa', result)
    end
  end
end
