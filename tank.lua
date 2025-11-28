-- dogwar/tank.lua


local registered_turrets = {}
function dogwar.register_tank_turret(name, def)
	def.bones = def.bones or {}
	def.on_activate = def.on_activate or function(tank)
		tank.turret = minetest.add_entity(tank.object:get_pos(), def.entity, "stay")
		tank.turret:set_attach(tank.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
	end

	registered_turrets[name] = def
end

local gravity = tonumber(minetest.settings:get("movement_gravity")) or 5

local function create_id(self)
	for i, obj in pairs(minetest.object_refs) do
		if obj == self.object then
			self.id = i
			break
		end
	end
end

local function create_inv(self, inv_content)
	self.inv = minetest.create_detached_inventory("dogwar:tank"..self.id, {
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			if to_list == "fuel" then
				local stack = inv:get_stack(from_list, from_index)
				stack:set_count(count)
				local output, _decremented_input = minetest.get_craft_result({method = "fuel", width = 1, items = {stack}})
				if output.time == 0 then
					return 0
				end
				return math.floor((100-self.fuel)/output.time)
			end
			return count
		end,

		allow_put = function(inv, listname, index, stack, player)
			if listname == "fuel" then
				local output, _decremented_input = minetest.get_craft_result({method = "fuel", width = 1, items = {stack}})
				if output.time == 0 then
					return 0
				end
				return math.floor((100-self.fuel)/output.time)
			end
			return stack:get_count()
		end,

		--~ allow_take = func(inv, listname, index, stack, player),
	--~ --  ^ Called when a player wants to take something out of the inventory
	--~ --  ^ Return value: number of items allowed to take
	--~ --  ^ Return value: -1: Allow and don't modify item count in inventory

		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			if to_list == "fuel" then
				local stack = inv:get_stack(to_list, to_index)
				stack:set_count(count)
				local player_inv = player:get_inventory()
				local pos = player:get_pos()
				local input = {method = "fuel", width = 1, items = {stack}}
				repeat
					local output
					output, input = minetest.get_craft_result(input)
					if output.time == 0 then
						break
					end
					self.fuel = self.fuel + output.time
					if output.item then
						local lo = player_inv:add_item("main", output.item)
						if not lo:is_empty() then
							minetest.item_drop(lo, player, pos)
						end
					end
					for i = 1, #output.replacements do
						local lo = player_inv:add_item("main", output.replacements[i])
						if not lo:is_empty() then
							minetest.item_drop(lo, player, pos)
						end
					end
				until input.items[1]:is_empty()
				inv:set_stack("fuel", to_index, ItemStack(nil))
				local lo = player_inv:add_item("main", input.items[1])
				if not lo:is_empty() then
					minetest.item_drop(lo, player, pos)
				end
				return
			end
		end,

		on_put = function(inv, listname, index, stack, player)
			if listname == "fuel" then
				local player_inv = player:get_inventory()
				local pos = player:get_pos()
				local input = {method = "fuel", width = 1, items = {stack}}
				repeat
					local output
					output, input = minetest.get_craft_result(input)
					if output.time == 0 then
						break
					end
					self.fuel = self.fuel + output.time
					if output.item then
						local lo = player_inv:add_item("main", output.item)
						if not lo:is_empty() then
							minetest.item_drop(lo, player, pos)
						end
					end
					for i = 1, #output.replacements do
						local lo = player_inv:add_item("main", output.replacements[i])
						if not lo:is_empty() then
							minetest.item_drop(lo, player, pos)
						end
					end
				until input.items[1]:is_empty()
				inv:set_stack("fuel", index, ItemStack(nil))
				local lo = player_inv:add_item("main", input.items[1])
				if not lo:is_empty() then
					minetest.item_drop(lo, player, pos)
				end
				return
			end
		end,

		--~ on_take = func(inv, listname, index, stack, player),
	--~ --  ^ Called after the actual action has happened, according to what was allowed.
	--~ --  ^ No return value
	})
	self.inv:set_size("fuel", 1)
	self.inv:set_size("ammo", 2*4)
	for listname, list in pairs(inv_content) do
		for i = 1, #list do
			list[i] = ItemStack(list[i])
		end
		self.inv:set_list(listname, list)
	end
end

minetest.register_entity("dogwar:tank", {
	hp_max = 3000,
	armor = {immortal = 1},
	physical = true,
	collide_with_objects = true,
	damage = 100,
	--weight = 5,
	collisionbox = {-1.9,-0.99,-1.9, 1.9,0.3,1.9},
	visual = "mesh",
	visual_size = {x=10, y=10},
	mesh = "dogwar_tank_bottom.b3d",
	textures = {"dogwar_tank.png"},
	makes_footstep_sound = false,
	automatic_rotate = 0,
	stepheight = 1.5,


	on_activate = function(self, staticdata)
		local inv_content
		if staticdata == "" then -- initial activate
			self.fuel = 15
			self.turret_name = "cannon"
			self.owner = ""
			self.object:set_armor_groups({immortal = 1})
		else
			local s = minetest.deserialize(staticdata) or {}
			self.fuel = tonumber(s.fuel) or 15
			self.turret_name = s.turret_name
			--self.owner = s.owner or ""
			self.id = s.id
			inv_content = s.inv_content
		end
		if not self.id then
			create_id(self)
		end
		self.inv = minetest.get_inventory({type="detached", name="dogwar:tank"..self.id})
		if not self.inv then
			create_inv(self, inv_content or {})
		end
		local turret_def = registered_turrets[self.turret_name]
		if not turret_def then
			self.turret_name = "cannon"
			turret_def = registered_turrets[self.turret_name]
		end
		turret_def.on_activate(self)
		self.object:set_acceleration(vector.new(0, -gravity, 0))
		self.cannon_direction_horizontal = self.object:get_yaw()
		self.cannon_direction_vertical = -90
		self.shooting_range = 100
		self.timer = 0
	end,

 	 on_death = function(self, killer)
            local pos = self.object:get_pos()

            -- stop particle/sound effects immediately
            if self.exhaust then
                minetest.delete_particlespawner(self.exhaust)
                self.exhaust = nil
            end
            if self.engine_sound then
                minetest.sound_stop(self.engine_sound)
                self.engine_sound = nil
            end

            -- forcefully detach and restore player, then trigger respawn
            if self.driver then
                local ply = self.driver
                -- attempt safe detach
                pcall(function()
                    if ply.get_attach and ply:get_attach() then
                        ply:set_detach()
                    end
                end)
                -- restore visuals/state
                pcall(function()
                    ply:set_properties({visual_size = {x=1, y=1}})
                    ply:set_eye_offset({x=0,y=0,z=0}, {x=0,y=0,z=0})
                    default.player_set_animation(ply, "stand")
                    player_api.player_attached[ply:get_player_name()] = false
                end)
                -- move player slightly away to avoid immediate re-attachment/overlap
                pcall(function()
                    local safe_pos = pos and vector.add(pos, {x=0, y=1.5, z=0}) or ply:get_pos()
                    ply:setpos(safe_pos)
                end)
                -- force death/respawn if still alive (ensures proper respawn flow)
                pcall(function()
                    if ply:is_player() and ply:get_hp() > 0 then
                        ply:set_hp(0)
                    end
                end)
                self.driver = nil
            end

            -- remove turret after a short delay so it doesn't get removed before the tank
            if self.turret then
                local turret = self.turret
                self.turret = nil
                minetest.after(0.1, function()
                    pcall(function() if turret and turret.remove then turret:remove() end end)
                end)
            end
      end,

	get_staticdata = function(self)
		local inv_content = {}
		for listname, list in pairs(self.inv:get_lists()) do
			inv_content[listname] = {}
			for i = 1, #list do
				inv_content[listname][i] = list[i]:to_string()
			end
		end
		return minetest.serialize({
			fuel = self.fuel,
			turret_name = self.turret_name,
			owner = self.owner,
			id = self.id,
			inv_content = inv_content,
		})
	end,



	on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end

        -- If no driver, let the clicker enter the tank
        if not self.driver then
            -- avoid attaching players already attached elsewhere
            if clicker:get_attach() then return end

            -- attach player to tank (adjust offset if needed)
            clicker:set_attach(self.object, "", {x=0, y=1.2, z=0}, {x=0, y=0, z=0})
            -- hide player model and adjust view
            clicker:set_properties({visual_size = {x=0, y=0}})
            clicker:set_eye_offset({x=0, y=5, z=5}, {x=0, y=20, z=20})
            if player_api and player_api.player_attached then
                player_api.player_attached[clicker:get_player_name()] = true
            end
            self.driver = clicker
            -- initialize cannon direction from player view
            self.cannon_direction_horizontal = clicker:get_look_horizontal() or self.object:get_yaw()
            return
        end

        -- If clicker is the current driver -> exit (safe detach)
        if clicker == self.driver then
            -- safe detach attempt
            pcall(function()
                if clicker.get_attach and clicker:get_attach() then
                    clicker:set_detach()
                end
            end)

            -- restore visuals/state
            pcall(function()
                clicker:set_properties({visual_size = {x=1, y=1}})
                clicker:set_eye_offset({x=0,y=0,z=0}, {x=0,y=0,z=0})
                if default and default.player_set_animation then
                    default.player_set_animation(clicker, "stand")
                end
                if player_api and player_api.player_attached then
                    player_api.player_attached[clicker:get_player_name()] = false
                end
            end)

            -- compute safe exit positions (in front, above, behind) relative to tank yaw
            local pos = self.object and self.object:get_pos() or clicker:get_pos()
            local yaw = (self.object and self.object:get_yaw()) or 0
            local forward = { x = math.cos(yaw), y = 0, z = math.sin(yaw) }
            local candidates = {
                vector.add(pos, { x = forward.x * 1.5, y = 0.5, z = forward.z * 1.5 }), -- in front
                vector.add(pos, { x = 0, y = 1.5, z = 0 }),                             -- above
                vector.add(pos, { x = -forward.x * 1.5, y = 0.5, z = -forward.z * 1.5 })-- behind
            }

            -- pick first non-solid spot
            local exit_pos = nil
            for _, p in ipairs(candidates) do
                local node = minetest.get_node_or_nil(vector.round(p))
                if node then
                    local nodedef = minetest.registered_nodes[node.name]
                    if not nodedef or nodedef.walkable == false then
                        exit_pos = p
                        break
                    end
                else
                    exit_pos = p
                    break
                end
            end
            if not exit_pos then
                exit_pos = vector.add(pos, {x=0, y=2, z=0})
            end

            -- place player at safe position
            pcall(function() clicker:setpos(exit_pos) end)

            -- clear driver reference
            self.driver = nil
            return
        end

        -- otherwise someone else clicked while occupied -> ignore or show message
    end,

	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		local vel = self.object:get_velocity()
		if vel.y == 0 and (vel.x ~= 0 or vel.z ~= 0) then
			vel = vector.new()
			self.object:set_velocity(vel)
		end
		if not self.driver or self.fuel <= 0
		then

			return
		end

		local yaw = self.object:get_yaw()
		local ctrl = self.driver:get_player_control()
		local turned
		local moved -- luacheck: ignore
		if vel.y == 0 then
			local anim
			if ctrl.left then
				yaw = yaw + dtime
				self.cannon_direction_horizontal = self.cannon_direction_horizontal + dtime
				anim = {{x=80, y=99}, 30, 0}
				turned = true
			elseif ctrl.right then
				self.cannon_direction_horizontal = self.cannon_direction_horizontal - dtime
				yaw = yaw - dtime
				anim = {{x=60, y=79}, 30, 0}
				turned = true
			else
				anim = {{x=0, y=0}, 0, 0}
				turned = false
			end
			if turned then
				self.object:set_yaw((yaw+2*math.pi)%(2*math.pi))
			end
			if ctrl.up then
				self.object:set_velocity({x=math.cos(yaw+math.pi/2)*3, y=vel.y, z=math.sin(yaw+math.pi/2)*3})
				anim = {{x=0, y=19}, 30, 0}
				moved = true
			end
			if ctrl.up and ctrl.left then
				self.cannon_direction_horizontal = self.cannon_direction_horizontal - dtime
				yaw = yaw - dtime
				--turned = true
				self.object:set_velocity({x=math.cos(yaw+math.pi/2)*3, y=vel.y, z=math.sin(yaw+math.pi/2)*3})
				anim = {{x=20, y=39}, 15, 0}
			elseif ctrl.up and ctrl.right then
				self.cannon_direction_horizontal = self.cannon_direction_horizontal - dtime
				yaw = yaw - dtime
				--turned = true
				self.object:set_velocity({x=math.cos(yaw+math.pi/2)*3, y=vel.y, z=math.sin(yaw+math.pi/2)*3})
				anim = {{x=20, y=39}, 15, 0}
			end


			if ctrl.down then
				self.object:set_velocity({x=math.cos(yaw+math.pi/2)*-2, y=vel.y, z=math.sin(yaw+math.pi/2)*-2})
				anim = {{x=20, y=39}, 15, 0}
				moved = true
			end
			if ctrl.down and ctrl.left then
				self.cannon_direction_horizontal = self.cannon_direction_horizontal - dtime
				yaw = yaw - dtime
				self.object:set_velocity({x=math.cos(yaw+math.pi/2)*-2, y=vel.y, z=math.sin(yaw+math.pi/2)*-2})
				turned = true
				anim = {{x=20, y=39}, 15, 0}
			elseif ctrl.down and ctrl.right then
				self.cannon_direction_horizontal = self.cannon_direction_horizontal - dtime
				yaw = yaw - dtime
				self.object:set_velocity({x=math.cos(yaw+math.pi/2)*-2, y=vel.y, z=math.sin(yaw+math.pi/2)*-2})
				turned = true
				anim = {{x=20, y=39}, 15, 0}
			end
			self.object:set_animation(unpack(anim))
		end

		local turret_def = registered_turrets[self.turret_name]
		if self.turret and not (self.static_turret) then
			local dlh = self.driver:get_look_horizontal()
			local dlv = self.driver:get_look_vertical()
			self.cannon_direction_horizontal = dlh
			self.cannon_direction_vertical =  math.max(-100,math.min(-60,(-math.deg(dlv)-90)))
			if turret_def.bones[1] then
                local angle = math.deg(yaw - dlh) + 180
                if angle > 180 then angle = angle - 360 end
                self.turret:set_bone_position(turret_def.bones[1], {x=0, y=0, z=0},
                        {x=0, y=angle, z=0})
            end
			if turret_def.bones[2] then
				self.turret:set_bone_position(turret_def.bones[2], {x=0,y=1.2,z=0},
						{x=self.cannon_direction_vertical,y=0,z=0})
			end
		end

		local shooted = false
		if ctrl.LMB and (not self.last_shoot_time or
				self.timer >= self.last_shoot_time + turret_def.shoot_cooldown) then
			shooted = true
			turret_def.shoot(self, dtime)
			self.last_shoot_time = self.timer
		end

		if turret_def.on_step then
			turret_def.on_step(self, dtime, shooted)
		end

		if self.shooting_range then
			self.shooting_range_hud_1 = self.shooting_range
			self.shooting_range_hud_2 = 0
			while self.shooting_range_hud_1 > 30 do
				self.shooting_range_hud_1 = self.shooting_range_hud_1 - 1
				self.shooting_range_hud_2 = self.shooting_range_hud_2 + 1
			end
		else
			self.shooting_range_hud_1 = 0
			self.shooting_range_hud_2 = 0
		end
	end,
})



-- minetest.register_on_joinplayer(function(player)
-- player.set_model(player, "dogwar:tank", {x=1, y=1}, 60)
-- end)


minetest.register_entity("dogwar:tank_shoot", {
	physical = true,
	collide_with_objects = true,
	weight = 10,
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	visual = "mesh",
	damage = 100,
	visual_size = {x=5, y=5},
	mesh = "dogwar_tank_shoot.b3d",
	textures = {"dogwar_tank_shoot.png"},
	automatic_rotate = 0,
	automatic_face_movement_dir = 90.0,
--  ^ automatically set yaw to movement direction; offset in degrees; false to disable
	automatic_face_movement_max_rotation_per_sec = -1,
--  ^ limit automatic rotation to this value in degrees per second. values < 0 no limit

	on_activate = function(self, staticdata)
		if staticdata ~= "stay" then
			self.object:remove()
			return
		end
		self.object:set_acceleration(vector.new(0, -gravity, 0))
	end,

	on_step = function(self, dtime)
		local vel = self.object:get_velocity() or nil
        
		if self.oldvel and
				((self.oldvel.x ~= 0 and vel.x == 0) or
				(self.oldvel.y ~= 0 and vel.y == 0) or
				(self.oldvel.z ~= 0 and vel.z == 0)) then
			tnt.boom(vector.round(self.object:get_pos()), {damage_radius=3,radius=2})
		return
			self.object:remove()

			
		end

		local rot = -math.deg(math.atan(vel.y/(vel.x^2+vel.z^2)^0.5))
		--self.object:set_animation({x=rot+90, y=rot+90}, 0, 0)

		self.oldvel = vel
	end
})

minetest.register_entity("dogwar:tank_top", {
	physical = false,
	weight = 5,
	damage = 100,
	collisionbox = {-0.0,-0.0,-0.0, 0.0,0.0,0.0},
	visual = "mesh",
	visual_size = {x=1, y=1},
	mesh = "dogwar_tank_top.b3d",
	textures = {"dogwar_tank_top.png"},
	on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= "stay" then
			self.object:remove()
		end
	end,
})

dogwar.register_tank_turret("cannon", {
	entity = "dogwar:tank_top",
	shoot_cooldown = 1,
	damage = 100,
	bones = {"top_master", "cannon_barrel"},
	shoot = function(tank)
		local vel = tank.object:get_velocity()
		local shoot = minetest.add_entity(tank.object:get_pos():offset(0, 1.2, 0), "dogwar:tank_shoot", "stay")
		--local shoot2 = minetest.add_entity(tank.object:get_pos():offset(0, 1.2, 0), "dogwar:tank_shoot", "stay")
		shoot:set_velocity(vector.add(vel, vector.new(
			math.cos(tank.cannon_direction_horizontal + math.rad(90))
					* math.sin(math.rad(-tank.cannon_direction_vertical))*tank.shooting_range,
			math.cos(math.rad(-tank.cannon_direction_vertical))*tank.shooting_range,
			math.sin(tank.cannon_direction_horizontal + math.rad(90))
					* math.sin(math.rad(-tank.cannon_direction_vertical))*tank.shooting_range
		)))

		minetest.sound_play("dogwar_tank_shoot", {
			pos = tank.object:get_pos(),
			gain = 0.5,
			max_hear_distance = 32,
		}, true)
	end,
})

--[[
dogwar.register_tank_turret("cannonship", {
	entity = "dogwar:tank_top",
	shoot_cooldown = 1,
	bones = {"top_master001", "cannon_barrel001"},
	shoot = function(tank)
		local vel = tank.object:get_velocity()
		local shoot = minetest.add_entity(tank.object:get_pos():offset(0, 1.2, 0), "dogwar:tank_shoot", "stay")
		shoot:set_velocity(vector.add(vel, vector.new(
			math.cos(tank.cannon_direction_horizontal + math.rad(90))
					* math.sin(math.rad(-tank.cannon_direction_vertical))*tank.shooting_range,
			math.cos(math.rad(-tank.cannon_direction_vertical))*tank.shooting_range,
			math.sin(tank.cannon_direction_horizontal + math.rad(90))
					* math.sin(math.rad(-tank.cannon_direction_vertical))*tank.shooting_range
		)))
		minetest.sound_play("dogwar_tank_shoot", {
			pos = tank.object:get_pos(),
			gain = 0.5,
			max_hear_distance = 32,
		}, true)
	end,
})


minetest.register_entity("dogwar:cannonship", {
	physical = false,
	weight = 5,
	collisionbox = {-0.9,-0.9,-0.9, 0.9,0.9,0.},
	visual = "mesh",
	visual_size = {x=1, y=1},
	mesh = "dogwar_tank_top.b3d",
	textures = {"dogwar_tank.png"},
	on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= "stay" then
			self.object:remove()
		end
	end,
})]]


minetest.register_entity("dogwar:cannon", {
	physical = false,
	weight = 5,
    damage = 100, 
	collisionbox = {-0.9,-0.9,-0.9, 0.9,0.9,0.},
	visual = "mesh",
	visual_size = {x=1, y=1},
	mesh = "dogwar_tank_top.b3d",
	textures = {"dogwar_tank_top.png"},
	on_activate = function(self, staticdata, dtime_s)
		if staticdata ~= "stay" then
			self.object:remove()
		end
	end,
})


