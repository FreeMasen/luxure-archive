local Error = require 'luxure.error'

describe('Error', function()
  it('raise raises error', function()
    local succ, err = pcall(function()
      Error.raise('Things')
    end)
    assert.is.falsy(succ)
    assert(string.find(err, '|Things'), string.format('Failed to find Things at the end of err: %q', err))
  end)
  it('pcall from non-internal Error', function()
    local err_text = 'Things|Stuff|People|Places|Animals|Minerals'
    local succ, err = Error.pcall(function()
      error(err_text)
    end)
    assert.is.falsy(succ)
    local stripped = err:gsub('.+%.lua:[0-9]+: ', '')
    assert.are.equal(err_text, stripped)
  end)
  it('formatting short', function()
    assert.are.equal(Error.__tostring({
      msg = 'This is an error',
    }), 'This is an error')
  end)
  it('formatting long', function()
    assert.are.equal(Error.__tostring({
      msg_with_line = 'This is an error with a line',
    }), 'This is an error with a line')
  end)
  it('formatting long with traceback', function()
    assert.are.equal(Error.__tostring({
      msg_with_line = 'This is an error with a line',
      traceback = 'This is a traceback'
    }), 'This is an error with a line\nThis is a traceback')
  end)
end)