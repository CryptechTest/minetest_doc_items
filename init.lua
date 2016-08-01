local groupdefs = {
	["book"] = "Books",
	["vessel"] = "Vessels",
	["dye"] = "Dyes",
	["wheat"] = "Wheat",
	["stick"] = "Sticks",
	["wool"] = "Wool",
	["sand"] = "Sand",
	["wood"] = "Wood",
	["stone"] = "Stone",
	["metal"] = "Metal",
	["tree"] = "Tree Trunks",
	["leaves"] = "Leaves and Needles",
	["flower"] = "Flowers",
	["sapling"] = "Saplings",
	["fleshy"] = "Flesh",
}

local minegroups = {
	["cracky"] = "Cracky",
	["crumbly"] = "Crumbly",
	["choppy"] = "Choppy",
	["snappy"] = "Snappy",
	["bendy"] = "Bendy",
	["oddly_breakable_by_hand"] = "Oddly breakable by hand",
}

local damagegroups= {
	["fleshy"] = "Flesh",
}

local forced_nodes = {
	"default:cloud",
	"bones:bones",
	"farming:soil",
	"farming:soil_wet",
	"farming:desert_sand_soil",
	"farming:desert_sand_soil_wet",
	"fire:basic_flame",
	"farming:wheat_8",
	"farming:cotton_8",
}

local item_name_overrides = {
	["screwdriver:screwdriver"] = "Screwdriver",
	["fire:basic_flame"] = "Basic Flame",
	["farming:wheat_8"] = "Wheat Plant",
	["farming:cotton_8"] = "Cotton Plant",
	["default:lava_source"] = "Lava",
	["default:water_source"] = "Water",
	["default:river_water_source"] = "River Water",
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
			formstring = formstring .. "Mining capabilities:\n"
			for k,v in pairs(groupcaps) do
				formstring = formstring .. "- " .. group_to_string(k, "mining") .. ": Level " .. v.maxlevel .. "\n"
			end
		end
		formstring = formstring .. "\n"

		local damage_groups = tool_capabilities.damage_groups
		if damage_groups ~= nil then
			formstring = formstring .. "Damage:\n"
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
			formstring = formstring .. "Transparent to sunlight: "..yesno(data.def.sunlight_propagates).. "\n"

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

			-- minetest_game factoids
			if data.def.groups.flammable == 1 then
				formstring = formstring .. "This block is flammable and burns slowly.\n"
			elseif data.def.groups.flammable == 2 then
				formstring = formstring .. "This block is flammable and burns at medium speed.\n"
			elseif data.def.groups.flammable == 3 then
				formstring = formstring .. "This block is highly flammable and burns very quickly.\n"
			elseif data.def.groups.flammable == 4 then
				formstring = formstring .. "This block is very easily set on fire and burns extremely quickly.\n"
			elseif data.def.groups.flammable ~= nil then
				formstring = formstring .. "This block is flammable.\n"
			end

			if data.def.groups.puts_out_fire ~= nil then
				formstring = formstring .. "This block will extinguish nearby fire.\n"
			end

			formstring = formstring .. "\n"
			if data.def.groups.oddly_breakable_by_hand ~= nil then
				formstring = formstring .. "This block can be dug by hand. How odd.\n"
			end

			if data.def.groups.cracky == 1 then
				formstring = formstring .. "This block is slightly cracky and can be dug by a strong pickaxe.\n"
			elseif data.def.groups.cracky == 2 then
				formstring = formstring .. "This block is cracky and can be dug by a pickaxe.\n"
			elseif data.def.groups.cracky == 3 then
				formstring = formstring .. "This block is very cracky and can be dug easily by a pickaxe.\n"
			elseif data.def.groups.cracky ~= nil then
				formstring = formstring .. "This block is cracky in some way.\n"
			end


			if data.def.groups.crumbly == 1 then
				formstring = formstring .. "This block is slightly crumbly and can be dug by a good shovel.\n"
			elseif data.def.groups.crumbly == 2 then
				formstring = formstring .. "This block is crumbly and can be dug by a shovel.\n"
			elseif data.def.groups.crumbly == 3 then
				formstring = formstring .. "This block is very crumbly and can be dug easily by a shovel.\n"
			elseif data.def.groups.crumbly ~= nil then
				formstring = formstring .. "This block is crumbly in some way.\n"
			end

			if data.def.groups.explody == 1 then
				formstring = formstring .. "This block is a bit prone to explosions.\n"
			elseif data.def.groups.explody == 2 then
				formstring = formstring .. "This block is prone to explosions.\n"
			elseif data.def.groups.explody == 3 then
				formstring = formstring .. "This block is very prone to explosions and easily affected by them.\n"
			elseif data.def.groups.explody ~= nil then
				formstring = formstring .. "This block is prone to explosions to some extent.\n"
			end

			if data.def.groups.snappy == 1 then
				formstring = formstring .. "This block is slightly snappy and can be dug by fine tools.\n"
			elseif data.def.groups.snappy == 2 then
				formstring = formstring .. "This block is snappy and can be dug by fine tools.\n"
			elseif data.def.groups.snappy == 3 then
				formstring = formstring .. "This block is highly snappy and can be dug easily by fine tools.\n"
			elseif data.def.groups.snappy ~= nil then
				formstring = formstring .. "This block is to some extent snappy.\n"
			end

			if data.def.groups.choppy == 1 then
				formstring = formstring .. "This block is a bit choppy and can be dug by axes and other tools which involve brute force.\n"
			elseif data.def.groups.choppy == 2 then
				formstring = formstring .. "This block is choppy and can be dug by axes and other tools which involve brute force.\n"
			elseif data.def.groups.choppy == 3 then
				formstring = formstring .. "This block is highly choppy and can easily be dug by axes and other tools which involve brute force.\n"
			elseif data.def.groups.choppy ~= nil then
				formstring = formstring .. "This block is choppy to some extent and can be dug by axes and similar tools.\n"
			end

			if data.def.groups.flora == 1 then
				formstring = formstring .. "This block belongs to the Flora group. It a living organism which likes to grow and spread on dirt with grass or dirt with dry grass when it is in light. On desert sand, it will wither and die and turn into a dry shrub.\n"
			end

			if data.def.groups.soil == 1 then
				formstring = formstring .. "This block is natural soil. It supports the spreading of blocks belonging to the Flora group and the growth of blocks belonging to the Saplings group.\n"
			elseif data.def.groups.soil == 2 or data.def.groups.soil == 3 then
				formstring = formstring .. "This block serves as a soil for wild plants (Flora, Saplings) as well as plants grown from seeds. It supports their growth and spreading.\n"
			end

			if data.def.groups.fleshy ~= nil then
				formstring = formstring .. "This block is made out of flesh.\n"
			end

			-- Show other “exposable” groups
			local gstring, gcount = groups_to_string(data.def.groups)
			if gstring ~= nil then
				if gcount == 1 then
					formstring = formstring .. "This block belongs to the "..minetest.formspec_escape(gstring).." group.\n"
				else
					formstring = formstring .. "This block belongs to these groups: "..minetest.formspec_escape(gstring)..".\n"
				end
			end

			formstring = formstring .. "\n"

			-- Non-default drops
			if data.def.drop ~= nil and data.def.drop ~= data.def.itemstring then
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
					if dropstack:get_name() ~= data.def.itemstring and dropstack:get_name() ~= 1 then
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

-- Add node aliases
for i=2,5 do
	doc.add_entry_alias("nodes", "default:grass_1", "default:grass_"..i)
	doc.add_entry_alias("nodes", "default:dry_grass_1", "default:dry_grass_"..i)
end
for i=1,7 do
	doc.add_entry_alias("nodes", "farming:wheat_8", "farming:wheat_"..i)
	doc.add_entry_alias("nodes", "farming:cotton_8", "farming:cotton_"..i)
end
doc.add_entry_alias("nodes", "default:lava_source", "default:lava_flowing")
doc.add_entry_alias("nodes", "default:water_source", "default:water_flowing")
doc.add_entry_alias("nodes", "default:river_water_source", "default:river_water_flowing")

doc.new_category("tools", {
	name = "Tools and weapons",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc or "N/A"
			local usagehelp = data.usagehelp or "N/A"
			local formstring = ""
			-- Hand
			if data.itemstring == "" then
				formstring = formstring .. "image[11,0;1,1;"..minetest.formspec_escape(minetest.registered_items[""].wield_image).."]"
			-- Other tools
			else
				formstring = formstring .. "item_image[11,0;1,1;"..data.itemstring.."]"
			end
			formstring = formstring .. "textarea[0.25,1;10,8;;Description: "..minetest.formspec_escape(longdesc).."\n\n"
			formstring = formstring .. "Usage: "..minetest.formspec_escape(usagehelp).. "\n\n"
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
			local longdesc = data.longdesc or "N/A"
			local usagehelp = data.usagehelp or "N/A"
			local formstring = "item_image[11,0;1,1;"..data.itemstring.."]"
			formstring = formstring .. "textarea[0.25,1;10,8;;Description: "..minetest.formspec_escape(longdesc).."\n\n"
			formstring = formstring .. "Usage: "..minetest.formspec_escape(usagehelp).. "\n\n"
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

dofile(minetest.get_modpath("doc_minetest_game") .. "/helptexts.lua")

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
			longdesc = "You use your bare hand whenever you are not wielding any item. With your hand you can dig the weakest blocks and deal minor damage by punching. Using the hand is often a last resort, as proper mining tools and weapons are usually better than the hand. When you are wielding an item which is not a mining tool or a weapon it will behave is it were the hand when you start mining or punching.",
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
