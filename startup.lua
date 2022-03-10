local program = require "programs"
local real_term = term.current()

-- program.new(function(env)
--   if not env.shell.run("shell") then
--     while true do
--       coroutine.yield()
--     end
--   end
-- end, 1, 3, 26, 10, "Shell")

program.new(function(env)
  if not env.shell.run(env.shell.resolve("/disk/tasks.lua")) then
    while true do
      coroutine.yield()
    end
  end
end, 30, 3, 15, 5, "Tasks")

program.new(function(env)
  local path = ""
  local w, h = env.term.getSize()
  while true do
    local file = env.gtmos.lddfm(true, 1, 1, w, h, path)

    local old_term = term.redirect(real_term)
    program.new(function(env2)
      if not env2.shell.run(file) then
        while true do
          coroutine.yield()
        end
      end
    end, 1, 3, 26, 10, fs.getName(file))
    term.redirect(old_term)

    path = env.fs.getDir(file)
    coroutine.yield()
  end
end, 27, 9, 25, 10, "Explorer")

term.setBackgroundColor(colors.cyan)
term.clear()
program.update("", "", "", "", "", "")

while true do
  local event, var1, var2, var3, var4, var5 = os.pullEventRaw()

  term.setBackgroundColor(colors.cyan)
  term.clear()
  program.update(event, var1, var2, var3, var4, var5)
end

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)