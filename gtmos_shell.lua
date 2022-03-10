local multishell = multishell
local gshell = {}


local expect = dofile("/rom/modules/main/cc/expect.lua").expect
local make_package = dofile("/rom/modules/main/cc/require.lua").make

local multishell = multishell
local parentShell = shell

if multishell then
  multishell.setTitle(multishell.getCurrent(), "shell")
end

local sDir = parentShell and parentShell.dir() or ""
local sPath = parentShell and parentShell.path() or ".:/rom/programs"
local tAliases = parentShell and parentShell.aliases() or {}
local tCompletionInfo = parentShell and parentShell.getCompletionInfo() or {}
local tProgramStack = {}


local function createShellEnv(dir)
  local env = require "gtmos_env"
  env.require, env.package = make_package(env, dir)
  return env
end


local function tokenise(...)
  local sLine = table.concat({ ... }, " ")
  local tWords = {}
  local bQuoted = false
  for match in string.gmatch(sLine .. "\"", "(.-)\"") do
    if bQuoted then
      table.insert(tWords, match)
    else
      for m in string.gmatch(match, "[^ \t]+") do
        table.insert(tWords, m)
      end
    end
    bQuoted = not bQuoted
  end
  return tWords
end


function gshell.execute(command, ...)
  expect(1, command, "string")
  for i = 1, select('#', ...) do
    expect(i + 1, select(i, ...), "string")
  end

  local sPath = shell.resolveProgram(command)
  if sPath ~= nil then
    tProgramStack[#tProgramStack + 1] = sPath
    if multishell then
      local sTitle = fs.getName(sPath)
      if sTitle:sub(-4) == ".lua" then
          sTitle = sTitle:sub(1, -5)
      end
      multishell.setTitle(multishell.getCurrent(), sTitle)
    end

    local sDir = fs.getDir(sPath)
    local env = createShellEnv(sDir)
    env.arg = { [0] = command, ... }
    local result = require "gtmos_env".os.run(env, sPath, ...)

    tProgramStack[#tProgramStack] = nil
    if multishell then
      if #tProgramStack > 0 then
        local sTitle = fs.getName(tProgramStack[#tProgramStack])
        if sTitle:sub(-4) == ".lua" then
          sTitle = sTitle:sub(1, -5)
        end
        multishell.setTitle(multishell.getCurrent(), sTitle)
      else
        multishell.setTitle(multishell.getCurrent(), "shell")
      end
    end
    return result
  else
    printError("No such program")
    return false
  end
end

function gshell.run(...)
  local tWords = tokenise(...)
  local sCommand = tWords[1]
  if sCommand then
    return gshell.execute(sCommand, table.unpack(tWords, 2))
  end
  return false
end

function gshell.exit()
  shell.exit()
end

function gshell.dir()
  return sDir
end

function gshell.setDir(dir)
  expect(1, dir, "string")
  if not fs.isDir(dir) then
    error("Not a directory", 2)
  end
  sDir = fs.combine(dir, "")
end

function gshell.path()
  return sPath
end

function gshell.setPath(path)
  expect(1, path, "string")
  sPath = path
end

function gshell.resolve(path)
  expect(1, path, "string")
  local sStartChar = string.sub(path, 1, 1)
  if sStartChar == "/" or sStartChar == "\\" then
    return fs.combine("", path)
  else
    return fs.combine(sDir, path)
  end
end

local function pathWithExtension(_sPath, _sExt)
  local nLen = #sPath
  local sEndChar = string.sub(_sPath, nLen, nLen)
  -- Remove any trailing slashes so we can add an extension to the path safely
  if sEndChar == "/" or sEndChar == "\\" then
    _sPath = string.sub(_sPath, 1, nLen - 1)
  end
  return _sPath .. "." .. _sExt
end

function gshell.resolveProgram(command)
  expect(1, command, "string")
  -- Substitute aliases firsts
  if tAliases[command] ~= nil then
      command = tAliases[command]
  end

  -- If the path is a global path, use it directly
  if command:find("/") or command:find("\\") then
      local sPath = gshell.resolve(command)
      if fs.exists(sPath) and not fs.isDir(sPath) then
          return sPath
      else
          local sPathLua = pathWithExtension(sPath, "lua")
          if fs.exists(sPathLua) and not fs.isDir(sPathLua) then
              return sPathLua
          end
      end
      return nil
  end

   -- Otherwise, look on the path variable
  for sPath in string.gmatch(sPath, "[^:]+") do
    sPath = fs.combine(gshell.resolve(sPath), command)
    if fs.exists(sPath) and not fs.isDir(sPath) then
      return sPath
    else
      local sPathLua = pathWithExtension(sPath, "lua")
      if fs.exists(sPathLua) and not fs.isDir(sPathLua) then
        return sPathLua
      end
    end
  end

  -- Not found
  return nil
end

function gshell.programs(include_hidden)
  expect(1, include_hidden, "boolean", "nil")

  local tItems = {}

  -- Add programs from the path
  for sPath in string.gmatch(sPath, "[^:]+") do
    sPath = gshell.resolve(sPath)
    if fs.isDir(sPath) then
      local tList = fs.list(sPath)
      for n = 1, #tList do
        local sFile = tList[n]
        if not fs.isDir(fs.combine(sPath, sFile)) and
          (include_hidden or string.sub(sFile, 1, 1) ~= ".") then
          if #sFile > 4 and sFile:sub(-4) == ".lua" then
            sFile = sFile:sub(1, -5)
          end
          tItems[sFile] = true
        end
      end
    end
  end

  -- Sort and return
  local tItemList = {}
  for sItem in pairs(tItems) do
    table.insert(tItemList, sItem)
  end
  table.sort(tItemList)
  return tItemList
end


local function completeProgram(sLine)
  if #sLine > 0 and (sLine:find("/") or sLine:find("\\")) then
    -- Add programs from the root
    return fs.complete(sLine, sDir, true, false)

  else
    local tResults = {}
    local tSeen = {}

    -- Add aliases
    for sAlias in pairs(tAliases) do
      if #sAlias > #sLine and string.sub(sAlias, 1, #sLine) == sLine then
        local sResult = string.sub(sAlias, #sLine + 1)
        if not tSeen[sResult] then
          table.insert(tResults, sResult)
          tSeen[sResult] = true
        end
      end
    end

    -- Add all subdirectories. We don't include files as they will be added in the block below
    local tDirs = fs.complete(sLine, sDir, false, false)
    for i = 1, #tDirs do
      local sResult = tDirs[i]
      if not tSeen[sResult] then
        table.insert (tResults, sResult)
        tSeen [sResult] = true
      end
    end

    -- Add programs from the path
    local tPrograms = gshell.programs()
    for n = 1, #tPrograms do
      local sProgram = tPrograms[n]
      if #sProgram > #sLine and string.sub(sProgram, 1, #sLine) == sLine then
        local sResult = string.sub(sProgram, #sLine + 1)
        if not tSeen[sResult] then
          table.insert(tResults, sResult)
          tSeen[sResult] = true
        end
      end
    end

    -- Sort and return
    table.sort(tResults)
    return tResults
  end
end

local function completeProgramArgument(sProgram, nArgument, sPart, tPreviousParts)
  local tInfo = tCompletionInfo[sProgram]
  if tInfo then
      return tInfo.fnComplete(gshell, nArgument, sPart, tPreviousParts)
  end
  return nil
end


function gshell.complete(sLine)
  expect(1, sLine, "string")
  if #sLine > 0 then
    local tWords = tokenise(sLine)
    local nIndex = #tWords
    if string.sub(sLine, #sLine, #sLine) == " " then
      nIndex = nIndex + 1
    end
    if nIndex == 1 then
      local sBit = tWords[1] or ""
      local sPath = gshell.resolveProgram(sBit)
      if tCompletionInfo[sPath] then
        return { " " }
      else
        local tResults = completeProgram(sBit)
        for n = 1, #tResults do
          local sResult = tResults[n]
          local sPath = gshell.resolveProgram(sBit .. sResult)
          if tCompletionInfo[sPath] then
            tResults[n] = sResult .. " "
          end
        end
        return tResults
      end

    elseif nIndex > 1 then
      local sPath = gshell.resolveProgram(tWords[1])
      local sPart = tWords[nIndex] or ""
      local tPreviousParts = tWords
      tPreviousParts[nIndex] = nil
      return completeProgramArgument(sPath , nIndex - 1, sPart, tPreviousParts)
    end
  end
  return nil
end

function gshell.completeProgram(program)
  expect(1, program, "string")
  return completeProgram(program)
end

function gshell.setCompletionFunction(program, complete)
  expect(1, program, "string")
  expect(2, complete, "function")
  tCompletionInfo[program] = {
    fnComplete = complete,
  }
end

function gshell.getCompletionInfo()
  return tCompletionInfo
end

function gshell.getRunningProgram()
  if #tProgramStack > 0 then
    return tProgramStack[#tProgramStack]
  end
  return nil
end

function gshell.setAlias(command, program)
  expect(1, command, "string")
  expect(2, program, "string")
  tAliases[command] = program
end

function gshell.clearAlias(command)
  expect(1, command, "string")
  tAliases[command] = nil
end

function gshell.aliases()
  -- Copy aliases
  local tCopy = {}
  for sAlias, sCommand in pairs(tAliases) do
    tCopy[sAlias] = sCommand
  end
  return tCopy
end

if multishell then
  function gshell.openTab(...)
    local tWords = tokenise(...)
    local sCommand = tWords[1]
    if sCommand then
      local sPath = gshell.resolveProgram(sCommand)
      if sPath == "rom/programs/shell.lua" then
        return multishell.launch(createShellEnv("rom/programs"), sPath, table.unpack(tWords, 2))
      elseif sPath ~= nil then
        return multishell.launch(createShellEnv("rom/programs"), "rom/programs/shell.lua", sCommand, table.unpack(tWords, 2))
      else
        printError("No such program")
      end
    end
  end

  function gshell.switchTab(id)
    expect(1, id, "number")
    multishell.setFocus(id)
  end
end



return gshell