local gos = {}

for k, v in pairs(os) do
  gos[k] = v
end

function gos.version()
  return "GTMOS 0.0.1 on "..os.version()
end

function gos.run(environment, programPath, ...)
  local new_env = environment
  local g_env = require"gtmos_env"
  for k, v in pairs(g_env) do
    if not(k == "arg") then 
      new_env[k] = v
    end
  end
  return os.run(new_env, programPath, ...)
end

return gos