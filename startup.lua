local program = require "programs"
local gtmos_env = require "gtmos_env"

program.new(function(_)
  gtmos_env.shell.run("shell")
end, 15, 10, 25, 10, "Shell")

program.new(function(prog)
  while true do
    gtmos_env.term.setBackgroundColor(gtmos_env.colors.white)
    gtmos_env.term.setTextColor(gtmos_env.colors.black)
    gtmos_env.term.clear()
    gtmos_env.term.setCursorPos(1, 1)

    local progs = prog.getProcesses()
    for programNum = 1, #progs do
      local loop_prog = progs[programNum]
      print(loop_prog.getProcessId(), loop_prog.getProcessName())
    end
    coroutine.yield()
  end
end, 35, 10, 15, 5, "Tasks")

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