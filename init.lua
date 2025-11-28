
local modname = minetest.get_current_modname()
assert(modname == "dogwar")
local path = minetest.get_modpath(modname) .. "/"

dogwar = {}

dofile(path.."tank.lua")
--dofile(path.."truck.lua")
dofile(path.."construction.lua")
