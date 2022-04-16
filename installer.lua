local args = dofile("/gtmos/argser.lua")(...)
  :named("remove", true, "boolean"):alias("r"):default(false)
  :named("setup", true, "boolean"):alias("s"):default(false)
  :parse().args

if args["remove"] then
  fs.delete("/gtmos")
end
if args["setup"] then
  fs.makeDir("/Users")
  print("No setup, for now...")
end