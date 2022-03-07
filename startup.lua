local program = require "programs"

program.new(function(env)
  env.shell.run("shell")
end, 2, 3, 25, 10, "Shell")

program.new(function(env)
  while true do
    env.term.setBackgroundColor(env.colors.white)
    env.term.setTextColor(env.colors.black)
    env.term.clear()
    env.term.setCursorPos(1, 1)

    local progs = env.gtmos.getProcesses()
    for programNum = 1, #progs do
     local loop_prog = progs[programNum]
     print(loop_prog.getProcessId(), loop_prog.getProcessName())
    end
    coroutine.yield()
  end
end, 30, 5, 15, 5, "Tasks")

while true do
  term.setBackgroundColor(colors.cyan)
  term.clear()
  program.update("", "", "", "", "", "")

  local event, var1, var2, var3, var4, var5 = os.pullEventRaw()

  term.setBackgroundColor(colors.cyan)
  term.clear()
  program.update(event, var1, var2, var3, var4, var5)
end

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)