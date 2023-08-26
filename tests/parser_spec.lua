local HtParser = require('haskell-tools.parser')

describe('Parser:', function()
  it('Can get function signatures from LSP markdown docs', function()
    -- For some reason, [[ ]] strings do not work here.
    local doc = '```haskell\n'
      .. 'someFunc :: forall a. Num a => a -> a\n'
      .. '```\n'
      .. '```haskell\n'
      .. '_ :: Int -> Int\n'
      .. '```\n'
      .. '```haskell\n'
      .. '_ :: forall a. Num a => a -> a\n'
      .. '```\n'
    local func_sig, all_signatures = HtParser.try_get_signatures_from_markdown('someFunc', doc)
    assert.same('Num a => a -> a', func_sig)
    assert.same({
      'Num a => a -> a',
      'Int -> Int',
    }, all_signatures)
  end)
end)
