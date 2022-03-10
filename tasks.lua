while true do
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)

  local progs = gtmos.getProcesses()
  for programNum = 1, #progs do
   local loop_prog = progs[programNum]
   print(loop_prog.getProcessId(), loop_prog.getProcessName())
  end
  sleep(0.01)
end