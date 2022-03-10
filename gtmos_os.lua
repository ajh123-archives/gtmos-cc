local gos = {}

for k, v in pairs(os) do
  gos[k] = v
end

function gos.version()
  return "GTMOS 0.0.1 on "..os.version()
end

function gos.run(environment, programPath, ...)
  local g_env = require"gtmos_env"
  local new_env = {}
  local args = {}

  for k, v in pairs(g_env) do
    new_env[k] = v
  end

  for k, v in pairs(environment) do
    if k == "arg" then
      for ak, av in pairs(environment[k]) do
        args[ak] = av
      end
      new_env[k] = v
    elseif k == "shell" then
      new_env[k] = v
    end
  end

  local file = fs.open(programPath, "r" )
  local data = file.readAll()
  file.close()
  local func, err = loadstring(data)
  if func then
    _ENV = new_env
    setfenv(func, _ENV)
    local ok, err = pcall(func, unpack(args))
    if err then
      -- msg = err
      -- if (type(err) == "table") then
      --   msg = textutils.serialize(err)
      --   -- msg = ""
      --   -- local function getTable(table)
      --   --   local out = ""
      --   --   for _, v in pairs(table) do
      --   --     if (type(v) == "table") then
      --   --       out = getTable(v)
      --   --     else
      --   --       out = out..tostring(v)
      --   --     end
      --   --   end
      --   --   return out
      --   -- end
      --   -- msg = getTable(err)
      -- end
      error(tostring({programPath, tostring(err)}))
    end
    return ok
  else
    error(err)
  end
end

return gos