local args = dofile("/gtmos/argser.lua")(...)
  :named("remove", false, "boolean"):alias("r"):default(false)
  :named("setup", false, "boolean"):alias("s"):default(false)
  :parse().args

for key, value in pairs(args) do
  print(key, value)
end

print(args)

if args["remove"] then
  fs.delete("/gtmos")
end
if args["setup"] then
  fs.makeDir("/Users")
  print("No setup, for now...")
end