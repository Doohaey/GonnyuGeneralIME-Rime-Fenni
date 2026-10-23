local options = require("gannyu_input_options")
local M = {}

function M.init(env)
  require("gannyu_data_lifecycle").init(env)
  env.connection = env.engine.context.option_update_notifier:connect(function(context, name)
    if name:match("^gannyu_") and not context:get_option("gannyu_batch") then
      context:refresh_non_confirmed_composition()
    end
  end)
end

function M.func(input, segment, env)
  local data = require("gannyu_data_lifecycle").current(env)
  local _, suffix = options.names(env)
  if suffix ~= env.suffix then
    env.translator = nil
    collectgarbage("collect")
    local schema = suffix == "" and env.engine.schema or Schema(env.engine.schema.schema_id .. suffix)
    env.translator = Component.Translator(env.engine, schema, "translator", "script_translator")
    assert(env.translator, "input options translator is unavailable")
    env.suffix = suffix
  end
  local translation = env.translator:query(input, segment)
  if translation then
    for candidate in translation:iter() do
      if not data.forbidden_words or not data.forbidden_words[candidate.text] then
        yield(candidate)
      end
    end
  end
end

function M.fini(env)
  env.connection:disconnect()
  env.translator = nil
  require("gannyu_data_lifecycle").fini(env)
end

return M
