local width, height = term.getSize()
local programs = {}
local processes = {}
local userEvents = {"mouse_click", "mouse_up", "mouse_drag", "char", "key", "monitor_touch", "key_up", "paste", "terminate"}
local gtmos_env = require "gtmos_env"


programs.new = function(func, x, y, w, h, name)
  local x = x or 1
  local y = y or 1
  local w = w or width
  local h = h or height
  local program = {
    x = x, y = y, w = w, h = h,
    term = window.create(
      term.current(), x, y, w, h
    ),
    selected = false,
    dragging = false,
    name = name,
    reposition = function(self, x, y)
      self.x, self.y = x, y
      self.term.reposition(x, y)
    end,
    resize = function(self, w, h)
      local oldX, oldY = self.term.getPosition()
      self.term.reposition(oldX, oldY, w, h)
      os.queueEvent("term_resize")
    end,
    reset = function(self, x, y, w, h)
      self.x, self.y, self.w, self.h = x, y, w, h
      self.term.reposition(x, y, w, h)
      os.queueEvent("term_resize")
    end
  }
  local pos = #processes
  program.prog = {
    getProcessId = function()
      return pos
    end,
    getProcessName = function()
      return program.name
    end,
    getProcessFromId = function(id)
      for programNum = 1, #processes do
        local loop_prog = processes[programNum].prog
        local prog_id = loop_prog.getProcessId()
        if id == prog_id then return loop_prog end
      end
    end,
    getProcesses = function()
      local porgs = {}
      for programNum = 1, #processes do
        local loop_prog = processes[programNum].prog
        table.insert(porgs, loop_prog)
      end
      return porgs
    end
  }

  local function coroutine_func()
    _ENV = gtmos_env
    _ENV.gtmos = program.prog
    setfenv(func, _ENV)

    local ok, mess = pcall(func, _ENV)
    if not ok then
      while true do
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        print(mess)
        coroutine.yield()
      end
    end
  end
  program.coroutine = coroutine.create(coroutine_func)
  table.insert(processes, pos, program)
end

local updateProgram = function(programNum, event, var1, var2, var3, var4, var5, isUserEvent)
  local program = processes[programNum]
  if program ~= nil then
    local event, var1, var2, var3, var4, var5 = event, var1, var2, var3, var4, var5

    -- redirect to programs terminal
    local oldTerm = term.redirect(program.term)

    -- give the mouse click as seen from the program window
    if string.sub(event, 1, #"mouse") == "mouse" then
      var2 = var2-program.x+1
      var3 = var3-program.y+1
    end

    -- find out if the program window is clicked
    if event == "mouse_click" and var2>=0 and var3>=0 and var2<=program.w and var3<=program.h then
      -- select this program and deselect every other one
      for programNum = 1, #processes do
        processes[programNum].selected = false
      end
      program.selected = true
      if var3 == 0 then
        program.barSelected = true
        program.barSelectedX = var2
        if var2 == 1 then
          program.resizeIconSelected = true
        end
        if var2 == program.w then
          table.remove(processes, programNum)
          term.redirect(oldTerm)
          return
        end
      end

      -- resort program table

      local selectedProgram
      for i = 1, #processes do
        if processes[i].selected then
          selectedProgram = processes[i]
          table.remove(processes, i)
          break
        end
      end
      table.insert(processes, selectedProgram)
    end

    -- move window when mouse is dragged
    if event == "mouse_drag" and program.barSelected then
      program.dragging = true
      if program.resizeIconSelected then
        program:reset(program.x + var2-program.barSelectedX, program.y+var3, program.w-var2+1, program.h-var3)
      else
        program:reposition(program.x + var2-program.barSelectedX, program.y+var3)
      end
    end

    -- deselect bar if mouse is released
    if event == "mouse_up" and program.dragging  then
      program.barSelected = false
      program.resizeIconSelected = false
    end

    -- only give program user events if selected
    if event == "mouse_click" and var3 == 0 then
      event, var1, var2, var3, var4, var5 = "", "", "", "", "", ""
    end
    if not program.selected then
      if isUserEvent then
        event, var1, var2, var3, var4, var5 = "", "", "", "", "", ""
      end
    end

    -- resume program
    coroutine.resume(program.coroutine, event, var1, var2, var3, var4, var5)

    -- delete program if it is finished
    if coroutine.status(program.coroutine) == "dead" then
      table.remove(processes, programNum)
      term.redirect(oldTerm)
      return true
    end

    program.term.redraw()
    term.redirect(oldTerm)

    -- draw line above program
    if program.selected then
      term.setBackgroundColor(colors.lightGray)
      term.setTextColor(colors.gray)
    else
      term.setBackgroundColor(colors.gray)
      term.setTextColor(colors.lightGray)
    end
    paintutils.drawLine(program.x, program.y-1, program.x+program.w-1, program.y-1)

    -- draw resize icon
    term.setCursorPos(program.x, program.y-1)
    term.write("/ "..program.name)

    -- draw close icon
    term.setCursorPos(program.x+program.w-1, program.y-1)
    term.setTextColor(colors.orange)
    term.write("x")

    local pw, ph = program.term.getSize() 
    local px, py = program.term.getCursorPos() 
    local pColor = program.term.getTextColor()
    local pBlink = program.term.getCursorBlink()
    term.setTextColor(pColor)
    if (px>0 and px<pw) and (py>0 and py<ph) then
      term.setCursorPos(px+program.x-1, py+program.y-1)
      term.setCursorBlink(pBlink)
    else
      term.setCursorBlink(false)
    end
  end
end

programs.update = function(event, var1, var2, var3, var4, var5)
  -- check if event is made from the user
  local isUserEvent = false
  for userEventNum = 1, #userEvents do
    local userEvent = userEvents[userEventNum]
    if event == userEvent then
      isUserEvent = true
      break
    end
  end

  -- update every program
  for programNum = 1, #processes do
    if updateProgram(programNum, event, var1, var2, var3, var4, var5, isUserEvent) then break end
  end
end

return programs