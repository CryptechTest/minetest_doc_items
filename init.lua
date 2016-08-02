local groupdefs = {
}

local minegroups = {
}

local damagegroups= {
}

local forced_nodes = {
}

local item_name_overrides = {
}

local groups_to_string = function(grouptable)
	local gstring = ""
	local groups_count = 0
	for id, value in pairs(grouptable) do
		if groupdefs[id] ~= nil then
			if groups_count > 0 then
				gstring = gstring .. "\\, "
			end
			gstring = gstring .. minetest.formspec_escape(groupdefs[id])
			groups_count = groups_count + 1
		end
	end
	if groups_count == 0 then
		return nil
	else
		return gstring, groups_count
	end
end

local group_to_string = function(groupname, grouptype)
	local grouptable
	if grouptype == "mining" then
		grouptable = minegroups
	elseif grouptype == "damage" then
		grouptable = damagegroups
	elseif grouptype == "generic" then
		grouptable = groupdefs
	else
		return minetest.formspec_escape(groupname)
	end

	if grouptable[groupname] ~= nil then
		return minetest.formspec_escape(grouptable[groupname])
	else
		return minetest.formspec_escape(groupname)
	end
end

local burntime_to_text = function(burntime)
	if burntime == nil then
		return "unknown"
	elseif burntime == 1 then
		return "1 second"
	else
		return string.format("%d seconds", burntime)
	end
end

local toolcaps_to_text = function(tool_capabilities)
	local formstring = ""
	if tool_capabilities ~= nil and tool_capabilities ~= {} then
		local punch = 1.0
		if tool_capabilities.full_punch_interval ~= nil then
			punch = tool_capabilities.full_punch_interval
		end
		formstring = formstring .. "Full punch interval: "..punch.." s\n\n"

		local groupcaps = tool_capabilities.groupcaps
		if groupcaps ~= nil then
			formstring = formstring .. "This tool is capable of mining.\nMining capabilities:\n"
			for k,v in pairs(groupcaps) do
				local minrating, maxrating
				for rating, time in pairs(v.times) do
					if minrating == nil then minrating = rating else
						if minrating > rating then minrating = rating end
					end
					if maxrating == nil then maxrating = rating else
						if maxrating < rating then maxrating = rating end
					end
				end
				local ratingstring = "Unknown rating"
				if minrating ~= nil and maxrating ~= nil then
					if minrating == maxrating then
						ratingstring = "Rating "..minrating
					else
						ratingstring = "Rating "..minrating.."-"..maxrating
					end
				end
				local levelstring
				if v.maxlevel == 0 then
					levelstring = "level 0"
				elseif v.maxlevel ~= nil then
					levelstring = "level 0-"..v.maxlevel
				else
					levelstring = "any level"
				end
				formstring = formstring .. "- " .. group_to_string(k, "mining") .. ": "..ratingstring..", ".. levelstring .. "\n"
			end
		end
		formstring = formstring .. "\n"

		local damage_groups = tool_capabilities.damage_groups
		if damage_groups ~= nil then
			formstring = formstring .. "This is a melee weapon which deals damage by punching.\nMaximum damage per hit:\n"
			for k,v in pairs(damage_groups) do
				formstring = formstring .. "- " .. group_to_string(k, "damage") .. ": " .. v .. " HP\n"
			end
		end
	end
	return formstring
end


doc.new_category("nodes", {
	name = "Blocks",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp

			local formstring = ""
			if data.itemstring ~= "air" then
				formstring = formstring .. "item_image[11,0;1,1;"..data.itemstring.."]"
			end
			formstring = formstring .. "textarea[0.25,1;10,8;;"
			if longdesc ~= nil then
				formstring = formstring .. "Description: "..minetest.formspec_escape(longdesc).."\n\n"
			end
			if usagehelp ~= nil then
				formstring = formstring .. "Usage help: "..minetest.formspec_escape(usagehelp).. "\n\n"
			end
			formstring = formstring .. "Maximum stack size: "..data.def.stack_max.. "\n"

			local yesno = function(bool)
				if bool==true then return "Yes"
				elseif bool==false then return "No"
				else return "N/A" end
			end

			formstring = formstring .. "Collidable: "..yesno(data.def.walkable).. "\n"
			local liquid
			if data.def.liquidtype ~= "none" then liquid = true else liquid = false end
			formstring = formstring .. "Liquid: "..yesno(liquid).. "\n"
			if liquid then
				local range, renew, viscos
				if data.def.liquid_range then range = data.def.liquid_range else range = 8 end
				if data.def.liquid_renewable ~= nil then renew = data.def.liquid_renewable else renew = true end
				if data.def.liquid_viscosity then viscos = data.def.liquid_viscosity else viscosity = 0 end
				formstring = formstring .. "Liquid range: "..range.. "\n"
				formstring = formstring .. "Liquid viscosity: "..viscos.. "\n"
				formstring = formstring .. "Renewable liquid: "..yesno(renew).. "\n"
			end
			formstring = formstring .. "Pointable: "..yesno(data.def.pointable).. "\n"

			formstring = formstring .. "\n"

			-- Global factoids
			if data.def.buildable_to == true then
				formstring = formstring .. "This block will be replaced when building on it.\n"
			end
			if data.def.light_source == 15 then
				formstring = formstring .. "This block is an extremely bright light source. It glows as bright the sun.\n"
			elseif data.def.light_source == 14 then
				formstring = formstring .. "This block is a very bright light source.\n"
			elseif data.def.light_source > 12 then
				formstring = formstring .. "This block is a bright light source.\n"
			elseif data.def.light_source > 5 then
				formstring = formstring .. "This block is a light source of medium luminance.\n"
			elseif data.def.light_source > 1 then
				formstring = formstring .. "This block is a weak light source and glows faintly.\n"
			elseif data.def.light_source == 1 then
				formstring = formstring .. "This block glows faintly. It is barely noticable.\n"
			end
			if data.def.paramtype == "light" and data.def.sunlight_propagates then
				formstring = formstring .. "This block allows light to propagate with a small loss of brightness, but sunlight can go through without loss.\n"
			elseif data.def.paramtype == "light" then
				formstring = formstring .. "This block allows light to propagate with a small loss of brightness.\n"
			elseif data.def.sunlight_propagates then
				formstring = formstring .. "This block allows sunlight to propagate without loss in brightness.\n"
			end
			if data.def.climbable == true then
				formstring = formstring .. "This block can be climbed.\n"
			end
			if data.def.damage_per_second > 1 then
				formstring = formstring .. "This block causes a damage of "..data.def.damage_per_second.." hit points per second.\n"
			elseif data.def.damage_per_second == 1 then
				formstring = formstring .. "This block causes a damage of "..data.def.damage_per_second.." hit point per second.\n"
			elseif data.def.damage_per_second < -1 then
				formstring = formstring .. "This block heals "..data.def.damage_per_second.." hit points per second.\n"
			elseif data.def.damage_per_second == -1 then
				formstring = formstring .. "This block heals "..data.def.damage_per_second.." hit point per second.\n"
			end
			if data.def.drowning > 1 then
				formstring = formstring .. "This block decreases your breath and causes a drowning damage of "..data.def.drowning.." hit points every 2 seconds.\n"
			elseif data.def.drowning == 1 then
				formstring = formstring .. "This block decreases your breath and causes a drowning damage of "..data.def.drowning.." hit point every 2 seconds.\n"
			end

			if data.def.drops ~= "" then
				if data.def.groups.immortal == 1 then
					formstring = formstring .. "This block can not be dug by ordinary digging tools.\n"
				end
				if data.def.groups.dig_immediate == 2 then
					formstring = formstring .. "This block can be dug by any tool in half a second.\n"
				elseif data.def.groups.dig_immediate == 3 then
					formstring = formstring .. "This block can be dug by any tool immediately.\n"
				end
			else
				if data.def.groups.immortal == 1 then
					formstring = formstring .. "This block can not be destroyed by ordinary digging tools.\n"
				end
				if data.def.groups.dig_immediate == 2 then
					formstring = formstring .. "This block can be destroyed by any tool in half a second.\n"
				elseif data.def.groups.dig_immediate == 3 then
					formstring = formstring .. "This block can be destroyed by any tool immediately.\n"
				end
			end

			if data.def.groups.falling_node == 1 then
				formstring = formstring .. "This block is affected by gravity and can fall.\n"
			end
			if data.def.groups.attached_node == 1 then
				formstring = formstring .. "This block must be attached to another block\\, otherwise it will drop as an item.\n"
			end
			if data.def.groups.disable_jump == 1 then
				formstring = formstring .. "You can not jump while standing on this block.\n"
			end
			local fdap = data.def.groups.fall_damage_add_percent 
			if fdap ~= nil then
				if fdap > 0 then
					formstring = formstring .. "The fall damage on this block is increased by "..fdap.."%.\n"
				elseif fdap == -100 then
					formstring = formstring .. "This block negates all fall damage.\n"
				else
					formstring = formstring .. "The fall damage on this block is reduced by "..math.abs(fdap).."%.\n"
				end
			end
			local bouncy = data.def.groups.bouncy
			if bouncy ~= nil then
				formstring = formstring .. "This block will make you bounce off with an elasticity of "..bouncy.."%.\n"
			end

			formstring = formstring .. "\n"

			-- Expose mining groups (crumbly, cracky, etc.) and level group
			local mstring = "This block can be mined by mining tools which match any of the following mining ratings and its mining level.\n"
			mstring = mstring .. "Mining ratings:\n"
			local minegroupcount = 0
			for g,name in pairs(minegroups) do
				local rating = data.def.groups[g]
				if rating ~= nil then
					mstring = mstring .. "- "..name..": "..rating.."\n"
					minegroupcount = minegroupcount + 1
				end
			end
			if data.def.groups.level ~= nil then
				mstring = mstring .. "Mining level: "..data.def.groups.level.."\n"
			else
				mstring = mstring .. "Mining level: 0\n"
			end

			if minegroupcount > 0 then
				formstring = formstring .. mstring
			end
			formstring = formstring .. "\n"

			-- TODO: Insert custom group-based factoids here

			-- Show other “exposable” groups in quick list
			local gstring, gcount = groups_to_string(data.def.groups)
			if gstring ~= nil then
				if gcount == 1 then
					formstring = formstring .. "This block belongs to the "..minetest.formspec_escape(gstring).." group.\n"
				else
					formstring = formstring .. "This block belongs to these groups: "..minetest.formspec_escape(gstring)..".\n"
				end
			end

			-- Non-default drops
			if data.def.drop ~= nil and data.def.drop ~= data.itemstring and data.itemstring ~= "air" then
				local get_desc = function(stack)
					local desc = minetest.registered_items[stack:get_name()].description
					if desc == nil then
						return stack:get_name()
					else
						return desc
					end
				end
				if data.def.drop == "" then
					formstring = formstring .. "This block won't drop anything when mined.\n"
				elseif type(data.def.drop) == "string" then
					local dropstack = ItemStack(data.def.drop)
					if dropstack:get_name() ~= data.itemstring and dropstack:get_name() ~= 1 then
						local desc = get_desc(dropstack)
						local count = dropstack:get_count()
						local finalstring
						if count > 1 then
							finalstring = count .. " × "..desc
						else
							finalstring = desc
						end
						formstring = formstring .. "This block will drop the following when mined: "..finalstring
					end
				elseif type(data.def.drop) == "table" then
					local max = data.def.drop.max_items
					if max == nil then
						formstring = formstring .. "This block will drop the following items when mined: "
					elseif max == 1 then
						formstring = formstring .. "This block will randomly drop one of the following when mined: "
					else
						formstring = formstring .. "This block will randomly drop up to "..max.." items of the following items when mined: "
					end
					local icount = 0
					local remaining_rarity = 1
					for i=1,#data.def.drop.items do
						for j=1,#data.def.drop.items[i].items do
							if icount > 0 then
								formstring = formstring .. ", "
							end
							local dropstack = ItemStack(data.def.drop.items[i].items[j])
							local desc = get_desc(dropstack)
							local count = dropstack:get_count()
							if count ~= 1 then
								desc = desc .. "(×"..count
							end
							formstring = formstring .. desc
							icount = icount + 1
						end
						local rarity = data.def.drop.items[i].rarity
						if rarity == nil then
							if max ~= nil then
								rarity = remaining_rarity
							else
								rarity = 1
							end
						end
						local chance = (1/rarity)*100
						-- Add circa indicator for percentages with decimal point
						local ca = ""
						-- FIXME: Does this actually reliable?
						if math.fmod(chance, 1) > 0 then
							ca = "ca. "
						end
						formstring = formstring .. string.format(" (%s%.0f%%)", ca, chance)
						if max ~= nil then
							remaining_rarity = 1/(1/remaining_rarity - 1/rarity)
						end
					end
					formstring = formstring .. ".\n"
				end
			end
	
			-- Show fuel recipe
			local result =  minetest.get_craft_result({method = "fuel", items = {data.itemstring}})
			if result ~= nil and result.time > 0 then
				formstring = formstring .. "This block can serve as a smelting fuel with a burning time of "..burntime_to_text(result.time)..".\n"
			end

			formstring = formstring .. ";]"

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})

doc.new_category("tools", {
	name = "Tools and weapons",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp
			local formstring = ""
			-- Hand
			if data.itemstring == "" then
				formstring = formstring .. "image[11,0;1,1;"..minetest.formspec_escape(minetest.registered_items[""].wield_image).."]"
			-- Other tools
			else
				formstring = formstring .. "item_image[11,0;1,1;"..data.itemstring.."]"
			end
			formstring = formstring .. "textarea[0.25,1;10,8;;"
			if longdesc ~= nil then
				formstring = formstring .. "Description: "..minetest.formspec_escape(longdesc).."\n\n"
			end
			if usagehelp ~= nil then
				formstring = formstring .. "Usage help: "..minetest.formspec_escape(usagehelp).. "\n\n"
			end
			if data.itemstring ~= "" then
				formstring = formstring .. "Maximum stack size: "..data.def.stack_max.. "\n"
			end

			local yesno = function(bool)
				if bool==true then return "Yes"
				elseif bool==false then return "No"
				else return "N/A" end
			end

			local range = 4.0
			if data.def.range ~= nil then range = data.def.range end
			formstring = formstring .. "Range: "..range.."\n"

			formstring = formstring .. "\n"

			formstring = formstring .. toolcaps_to_text(data.def.tool_capabilities)

			formstring = formstring .. "\n"

			-- Global factoids
			if data.def.liquids_pointable == true then
				formstring = formstring .. "This item will point to liquids rather than ignore them.\n"
			end

			-- Show other “exposable” groups
			local gstring, gcount = groups_to_string(data.def.groups)
			if gstring ~= nil then
				if gcount == 1 then
					formstring = formstring .. "This tool belongs to the "..minetest.formspec_escape(gstring).." group.\n"
				else
					formstring = formstring .. "This tool belongs to these groups: "..minetest.formspec_escape(gstring)..".\n"
				end
			end

			-- Show fuel recipe
			local result = minetest.get_craft_result({method = "fuel", items = {data.itemstring}})
			if result ~= nil and result.time > 0 then
				formstring = formstring .. "This tool can serve as a smelting fuel with a burning time of "..burntime_to_text(result.time)..".\n"
			end

			formstring = formstring .. ";]"

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})


doc.new_category("craftitems", {
	name = "Miscellaneous items",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp
			local formstring = "item_image[11,0;1,1;"..data.itemstring.."]"
			formstring = formstring .. "textarea[0.25,1;10,8;;"
			if longdesc ~= nil then
				formstring = formstring .. "Description: "..minetest.formspec_escape(longdesc).."\n\n"
			end
			if usagehelp ~= nil then
				formstring = formstring .. "Usage help: "..minetest.formspec_escape(usagehelp).. "\n\n"
			end
			formstring = formstring .. "Maximum stack size: "..data.def.stack_max.. "\n"

			local yesno = function(bool)
				if bool==true then return "Yes"
				elseif bool==false then return "No"
				else return "N/A" end
			end

			local range = 4.0
			if data.def.range ~= nil then range = data.def.range end
			formstring = formstring .. "Range: "..range.."\n"

			formstring = formstring .. "\n"

			formstring = formstring .. toolcaps_to_text(data.def.tool_capabilities)

			formstring = formstring .. "\n"

			-- Global factoids
			if data.def.liquids_pointable == true then
				formstring = formstring .. "This item will point to liquids rather than ignore them.\n"
			end

			-- Show other “exposable” groups
			local gstring, gcount = groups_to_string(data.def.groups)
			if gstring ~= nil then
				if gcount == 1 then
					formstring = formstring .. "This item belongs to the "..minetest.formspec_escape(gstring).." group.\n"
				else
					formstring = formstring .. "This item belongs to these groups: "..minetest.formspec_escape(gstring)..".\n"
				end
			end

			-- Show fuel recipe
			local result = minetest.get_craft_result({method = "fuel", items = {data.itemstring}})
			if result ~= nil and result.time > 0 then
				formstring = formstring .. "This item can serve as a smelting fuel with a burning time of "..burntime_to_text(result.time)..".\n"
			end

			formstring = formstring .. ";]"

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})

doc.sub.minetest_game = {}
doc.sub.minetest_game.help = {}
doc.sub.minetest_game.help.longdesc = {}
doc.sub.minetest_game.help.usagehelp = {}
-- Gather help texts
function doc.sub.minetest_game.add_helptexts(longdesc, usagehelp)
	for k,v in pairs(longdesc) do
		doc.sub.minetest_game.help.longdesc[k] = v
	end
	for k,v in pairs(usagehelp) do
		doc.sub.minetest_game.help.usagehelp[k] = v
	end
end

local function gather_descs()
	local help = doc.sub.minetest_game.help
	doc.new_entry("nodes", "air", {
		name = "Air",
		data = {
			itemstring = "air",
			longdesc = "A transparent block, basically empty space. It is usually left behind after digging something.",
			def = minetest.registered_nodes["air"],
		}
	})
	for id, def in pairs(minetest.registered_nodes) do
		local name, ld, uh
		name = def.description
		local forced = false
		for i=1, #forced_nodes do
			if id == forced_nodes[i] then forced = true end
		end
		if item_name_overrides[id] ~= nil then
			name = item_name_overrides[id]
		else
			name = def.description
		end
		if not (name == nil or name == "" or def.groups.not_in_creative_inventory) or forced then
			if help.longdesc[id] ~= nil then
				ld = help.longdesc[id]
			end
			if help.usagehelp[id] ~= nil then
				uh = help.usagehelp[id]
			end
			local infotable = {
				name = name,
				data = {
					longdesc = ld,
					usagehelp = uh,
					itemstring = id,
					def = def,
				}
			}
			doc.new_entry("nodes", id, infotable)
		end
	end

	-- Add the hand
	doc.new_entry("tools", "", {
		name = "Hand",
		data = {
			longdesc = "You use your bare hand whenever you are not wielding any item. With your hand you can dig the weakest blocks and deal minor damage by punching. Using the hand is often a last resort, as proper mining tools and weapons are usually better than the hand. When you are wielding an item which is not a mining tool or a weapon it will behave is it were the hand when you start mining or punching. In Creative Mode, the mining capabilities, range and damage of the hand are greatly enhanced.",
			itemstring = "",
			def = minetest.registered_items[""]
		}
	})
	for id, def in pairs(minetest.registered_tools) do
		local name, ld, uh
		if item_name_overrides[id] ~= nil then
			name = item_name_overrides[id]
		else
			name = def.description
		end
		if not (name == nil or name == "" or def.groups.not_in_creative_inventory) then
			if help.longdesc[id] ~= nil then
				ld = help.longdesc[id]
			end
			if help.usagehelp[id] ~= nil then
				uh = help.usagehelp[id]
			end
			local infotable = {
				name = name,
				data = {
					longdesc = ld,
					usagehelp = uh,
					itemstring = id,
					def = def,
				}
			}
			doc.new_entry("tools", id, infotable)
		end
	end

	for id, def in pairs(minetest.registered_craftitems) do
		local name, ld, uh
		name = def.description
		if not (name == nil or name == "" or def.groups.not_in_creative_inventory) then
			if help.longdesc[id] ~= nil then
				ld = help.longdesc[id]
			end
			if help.usagehelp[id] ~= nil then
				uh = help.usagehelp[id]
			end
			local infotable = {
				name = name,
				data = {
					longdesc = ld,
					usagehelp = uh,
					itemstring = id,
					def = def,
				}
			}
			doc.new_entry("craftitems", id, infotable)
		end
	end
end

minetest.after(0, gather_descs)
