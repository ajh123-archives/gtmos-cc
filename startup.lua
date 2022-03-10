local program = require "programs"

program.new(function(env)
  if not env.shell.run("shell") then
    while true do
      coroutine.yield()
    end
  end
end, 2, 3, 27, 10, "Shell")

program.new(function(env)
  if not env.shell.run(env.shell.resolve("/disk/tasks.lua")) then
    while true do
      coroutine.yield()
    end
  end
end, 30, 5, 20, 5, "Tasks")

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