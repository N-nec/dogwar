

minetest.register_chatcommand("dog", {
	description = "You get a FREE tank",
	func = function (name)
		local player = minetest.get_player_by_name(name)
		local pos = player:get_pos()
	--	minetest.show_formspec(name, "formname", lobbo())
minetest.add_entity(pos, "dogwar:tank", minetest.serialize({
				--fuel = 15,
				turret_name = "cannon",
				owner = sender and sender:is_player() and sender:get_player_name() or "",
			}))

		end
		})

-- ### ### ### ### ### THIS CODE WILL ATTACH TURRET TO HEAD IF BODY IS A TANK/CAR ### ### ###


-- minetest.register_on_joinplayer(function(player)
--     if is_armor_attached == nil then
--         local pos = player:get_pos()
--         local armor_obj = minetest.add_entity(pos, "TURRET")


--minetest.serialize({                     ---
-- 				--fuel = 15,               ---
-- 				turret_name = "cannon",    <------ REMOVED THIS TO SEE IF ITS IMPORTANT
-- 				owner = "",                ---
-- 			})                             ---



--         armor_obj:set_attach(player) <--- attaches 'TURRET' to 'armor_obj' which is YOU
--         armor_obj:set_eye_offset({x=0,y=10,z=0}, {x=0,y=10,z=-3})
--  		--default.player_set_animation("sit")
--     end
-- end)
--  ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###




-- minetest.register_on_respawnplayer(function(player)
--     if is_armor_attached == nil then
--         local pos = player:get_pos()
--         local armor_obj = minetest.add_entity(pos, "dogwar:tank", minetest.serialize({
-- 				--fuel = 15,
-- 				turret_name = "cannon",
-- 				owner = "",
-- 			}))
--         armor_obj:set_attach(player)
--         armor_obj:set_eye_offset({x=0,y=10,z=0}, {x=0,y=10,z=-3})
--         --default.player_set_animation("sit")
--     end
-- end)
-- minetest.register_on_joinplayer(function (player)
-- 	local name = player:get_player_name()
-- 	--if minetest.get_player_privs(name).news_bypass then
-- 		--return
-- 	--else
-- 		minetest.show_formspec(name,)
-- 	--end
-- end)

