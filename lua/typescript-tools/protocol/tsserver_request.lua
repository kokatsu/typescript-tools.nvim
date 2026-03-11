-- Handler for typescript.tsserverRequest from vue_ls hybrid mode.
-- Forwards arbitrary tsserver commands and returns the response body.

local M = {}

---@type TsserverProtocolHandler
function M.handler(request, response, params)
  if not params.command then
    response(nil)
    return
  end

  request {
    command = params.command,
    arguments = params.arguments,
  }

  local body = coroutine.yield()

  -- handle_response passes response.body (the payload) on success, but on error
  -- tsserver omits body so we receive the full response object with success=false.
  if not body or body.success == false then
    response(nil)
    return
  end

  response { body = body }
end

return M
