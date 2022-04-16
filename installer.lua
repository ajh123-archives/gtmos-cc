local args = dofile("/gtmos/argser.lua")(...)
  :named("remove", false, "boolean"):alias("r"):default(false)
  :named("setup", false, "boolean"):alias("s"):default(false)
  :parse().args

for i, arg in ipairs(args) do
  print(i .. ". " .. arg)
end

print(args)

if args.remove then
  fs.delete("/gtmos")
end
if args.setup then
  print("No setup, for now...")
end