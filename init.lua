doc.sub.items = {}

-- Template texts
doc.sub.items.temp = {}
doc.sub.items.temp.deco = "This is a decorational block."
doc.sub.items.temp.build = "This block is a building block for creating various buildings."
doc.sub.items.temp.craftitem = "This item is primarily used for crafting other items."

doc.sub.items.temp.eat = "Hold it in your hand, then leftclick to eat it."
doc.sub.items.temp.eat_bad = "Hold it in your hand, then leftclick to eat it. But why would you want to do this?"

-- Local stuff
local groupdefs = {}
local mininggroups = {}
local miscgroups = {}
local forced_items = {
	["air"] = true,
}
local item_name_overrides = {
	[""] = "Hand",
	["air"] = "Air"
}

-- Helper functions
local yesno = function(bool)
	if bool==true then return "Yes"
	elseif bool==false then return "No"
	else return "N/A" end
end


local groups_to_string = function(grouptable, filter)
	local gstring = ""
	local groups_count = 0
	for id, value in pairs(grouptable) do
		if groupdefs[id] ~= nil and (filter == nil or filter[id] == true) then
			-- Readable group name
			if groups_count > 0 then
				gstring = gstring .. ", "
			end
			gstring = gstring .. groupdefs[id]
			groups_count = groups_count + 1
		end
	end
	if groups_count == 0 then
		return nil, 0
	else
		return gstring, groups_count
	end
end

local group_to_string = function(groupname)
	if groupdefs[groupname] ~= nil then
		return groupdefs[groupname]
	else
		return groupname
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
				formstring = formstring .. "• " .. group_to_string(k) .. ": "..ratingstring..", ".. levelstring .. "\n"
			end
		end
		formstring = formstring .. "\n"

		local damage_groups = tool_capabilities.damage_groups
		if damage_groups ~= nil then
			formstring = formstring .. "This is a melee weapon which deals damage by punching.\nMaximum damage per hit:\n"
			for k,v in pairs(damage_groups) do
				formstring = formstring .. "• " .. group_to_string(k) .. ": " .. v .. " HP\n"
			end
		end
	end
	return formstring
end

local range_factoid = function(itemstring, def)
	local handrange = minetest.registered_items[""].range
	local itemrange = def.range
	if itemstring == "" then
		if handrange ~= nil then
			return "Range: "..itemrange
		else
			return "Range: 4"
		end
	else
		if handrange == nil then handrange = 4 end
		if itemrange ~= nil then
			return "Range: "..itemrange
		else
			return "Range: "..minetest.formspec_escape(item_name_overrides[""]).." ("..handrange..")"
		end
	end
end

-- Smelting fuel factoid
local fuel_factoid = function(itemstring, ctype)
	local formstring = ""
	local result, decremented =  minetest.get_craft_result({method = "fuel", items = {itemstring}})
	if result ~= nil and result.time > 0 then
		local base
		if ctype == "tools" then
			base = "This tool can serve as a smelting fuel with a burning time of %s."
		elseif ctype == "nodes" then
			base = "This block can serve as a smelting fuel with a burning time of %s."
		else
			base = "This item can serve as a smelting fuel with a burning time of %s."
		end
		formstring = formstring .. string.format(base, burntime_to_text(result.time))
		local replaced = decremented.items[1]:get_name()
		if not decremented.items[1]:is_empty() and replaced ~= itemstring then
			formstring = formstring .. " Using it as fuel turns it into: "..minetest.formspec_escape(minetest.registered_items[replaced].description).."."
		end
		formstring = formstring .. "\n"
	end
	return formstring
end


-- For factoids
local factoid_generators = {}
factoid_generators.nodes = {}
factoid_generators.tools = {}
factoid_generators.craftitems = {}

function doc.sub.items.register_factoid(category_id, factoid_type, factoid_generator)
	local ftable = { fgen = factoid_generator, ftype = factoid_type }
	if category_id == "nodes" then
		table.insert(factoid_generators.nodes, ftable)
		return true
	elseif category_id == "tools" then
		table.insert(factoid_generators.tools, ftable)
		return true
	elseif category_id == "craftitems" then
		table.insert(factoid_generators.craftitems, ftable)
		return true
	else
		return false
	end
end

doc.new_category("nodes", {
	name = "Blocks",
	description = "Item reference of blocks and other things which are capable of occupying space",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp

			local formstring = ""
			if data.itemstring ~= "air" then
				formstring = formstring .. "item_image[11,0;1,1;"..data.itemstring.."]"
			end
			formstring = formstring .. "textarea[0.25,0.5;11,8;;"
			if longdesc ~= nil then
				formstring = formstring .. "Description: "..minetest.formspec_escape(longdesc).."\n\n"
			end
			if usagehelp ~= nil then
				formstring = formstring .. "Usage help: "..minetest.formspec_escape(usagehelp).. "\n\n"
			end
			formstring = formstring .. "Maximum stack size: "..data.def.stack_max.. "\n"

			formstring = formstring .. range_factoid(data.itemstring, data.def) .. "\n"

			if data.def.liquids_pointable == true then
				formstring = formstring .. "This block points to liquids.\n"
			end
			if data.def.on_use ~= nil then
				formstring = formstring .. "Punches with this block don't work as usual\\; melee combat and mining are either not possible or work differently.\n"
			end

			formstring = formstring .. "\n"

			formstring = formstring .. toolcaps_to_text(data.def.tool_capabilities) .. "\n"

			formstring = formstring .. "Collidable: "..yesno(data.def.walkable).. "\n"
			local liquid
			if data.def.liquidtype ~= "none" then liquid = true else liquid = false end
			if data.def.pointable == true then
				formstring = formstring .. "Pointable: Yes\n"
			elseif liquid then
				formstring = formstring .. "Pointable: Only by special items\n"
			else
				formstring = formstring .. "Pointable: No\n"
			end
			formstring = formstring .. "\n"
			if liquid then
				formstring = formstring .. "This block is a liquid with these properties:\n"
				local range, renew, viscos
				if data.def.liquid_range then range = data.def.liquid_range else range = 8 end
				if data.def.liquid_renewable ~= nil then renew = data.def.liquid_renewable else renew = true end
				if data.def.liquid_viscosity then viscos = data.def.liquid_viscosity else viscos = 0 end
				if range == 0 then
					formstring = formstring .. "• Flowing range: 0 (no flowing)\n"
				else
					formstring = formstring .. "• Flowing range: "..range.. "\n"
				end
				formstring = formstring .. "• Viscosity: "..viscos.. "\n"
				formstring = formstring .. "• Renewable: "..yesno(renew).. "\n"
			end

			formstring = formstring .. "\n"

			-- Global factoids
			if data.def.floodable == true then
				formstring = formstring .. "Liquids can flow into this block and destroy it.\n"
			end
			if data.def.buildable_to == true then
				formstring = formstring .. "This block will be replaced when building on it.\n"
			end
			-- List nodes/groups to which this node connects to
			if data.def.connects_to ~= nil then
				local nodes = {}
				local groups = {}
				for c=1,#data.def.connects_to do
					local itemstring = data.def.connects_to[c]
					if string.sub(itemstring,1,6) == "group:" then
						groups[string.sub(itemstring,7,#itemstring)] = 1
					else
						table.insert(nodes, itemstring)
					end
				end

				local nstring = ""
				for n=1,#nodes do
					local name
					if item_name_overrides[nodes[n]] ~= nil then
						name = item_name_overrides[nodes[n]]
					else
						name = minetest.registered_nodes[nodes[n]].description
					end
					if n > 1 then
						nstring = nstring .. ", "
					end
					if name ~= nil then
						nstring = nstring .. name
					else
						nstring = nstring .. "Unknown Node"
					end
				end
				nstring = minetest.formspec_escape(nstring)
				if #nodes == 1 then
					formstring = formstring .. "This block connects to this block: "..nstring..".\n"
				elseif #nodes > 1 then
					formstring = formstring .. "This block connects to these blocks: "..nstring..".\n"
				end

				local gstring, gcount = groups_to_string(groups)
				if gcount == 1 then
					formstring = formstring .. "This block connects to blocks of the "..minetest.formspec_escape(gstring).." group.\n"
				elseif gcount > 1 then
					formstring = formstring .. "This block connects to blocks of the following groups: "..minetest.formspec_escape(gstring)..".\n"
				end
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

			if data.def.groups.falling_node == 1 then
				formstring = formstring .. "This block is affected by gravity and can fall.\n"
			end

			if data.def.groups.attached_node == 1 then
				if data.def.paramtype2 == "wallmounted" then
					formstring = formstring .. "This block will drop as an item when it is not attached to a surrounding block.\n"
				else
					formstring = formstring .. "This block will drop as an item if no collidable block is below it.\n"
				end
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

			--[[ Check if there are no groups at all, helps for finding undiggable nodes,
			-- but this approach might miss some of these; still better than nothing. ]]
			local nogroups = true
			for k,v in pairs(data.def.groups) do
				-- If this is reached once, we know the groups table is not empty
				nogroups = false
				break
			end
			-- dig_immediate
			if data.def.drop ~= "" then
				if data.def.groups.dig_immediate == 2 then
					formstring = formstring .. "This block can be mined by any mining tool in half a second.\n"
				elseif data.def.groups.dig_immediate == 3 then
					formstring = formstring .. "This block can be mined by any mining tool immediately.\n"
				-- Note: “unbreakable” is an unofficial group for undiggable blocks
				elseif nogroups or data.def.groups.immortal == 1 or data.def.groups.unbreakable == 1 then
					formstring = formstring .. "This block can not be mined by ordinary mining tools.\n"
				end
			else
				if data.def.groups.dig_immediate == 2 then
					formstring = formstring .. "This block can be destroyed by any mining tool in half a second.\n"
				elseif data.def.groups.dig_immediate == 3 then
					formstring = formstring .. "This block can be destroyed by any mining tool immediately.\n"
				elseif nogroups or data.def.groups.immortal == 1 or data.def.groups.unbreakable == 1 then
					formstring = formstring .. "This block can not be destroyed by ordinary mining tools.\n"
				end
			end
			-- Expose “ordinary” mining groups (crumbly, cracky, etc.) and level group
			-- Skip this for immediate digging to avoid redundancy
			if data.def.groups.dig_immediate ~= 3 then
				local mstring = "This block can be mined by mining tools which match any of the following mining ratings and its mining level.\n"
				mstring = mstring .. "Mining ratings:\n"
				local minegroupcount = 0
				for group,_ in pairs(mininggroups) do
					local rating = data.def.groups[group]
					if rating ~= nil then
						mstring = mstring .. "• "..groupdefs[group]..": "..rating.."\n"
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
			end
			formstring = formstring .. "\n"

			-- Custom factoids are inserted here
			for i=1,#factoid_generators.nodes do
				formstring = formstring .. factoid_generators.nodes[i].fgen(data.itemstring, data.def)
				formstring = formstring .. "\n"
			end

			-- Show other “exposable” groups in quick list
			local gstring, gcount = groups_to_string(data.def.groups, miscgroups)
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
				elseif type(data.def.drop) == "table" and data.def.drop.items ~= nil then
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
						if rarity > 200 then -- <0.5%
							-- For very low percentages
							formstring = formstring .. " (<0.5%)"
						else
							-- Add circa indicator for percentages with decimal point
							local ca = ""
							-- FIXME: Does this actually reliable?
							if math.fmod(chance, 1) > 0 then
								ca = "ca. "
							end
							formstring = formstring .. string.format(" (%s%.0f%%)", ca, chance)
						end
						if max ~= nil then
							remaining_rarity = 1/(1/remaining_rarity - 1/rarity)
						end
					end
					formstring = formstring .. ".\n"
				end
			end
	
			-- Show fuel recipe
			formstring = formstring .. fuel_factoid(data.itemstring, "nodes")

			formstring = formstring .. ";]"

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})

doc.new_category("tools", {
	name = "Tools and weapons",
	description = "Item reference of all wieldable tools and weapons",
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
			formstring = formstring .. "textarea[0.25,0.5;11,8;;"
			if longdesc ~= nil then
				formstring = formstring .. "Description: "..minetest.formspec_escape(longdesc).."\n\n"
			end
			if usagehelp ~= nil then
				formstring = formstring .. "Usage help: "..minetest.formspec_escape(usagehelp).. "\n\n"
			end
			if data.itemstring ~= "" then
				formstring = formstring .. "Maximum stack size: "..data.def.stack_max.. "\n"
			end

			formstring = formstring .. range_factoid(data.itemstring, data.def) .. "\n"

			if data.def.liquids_pointable == true then
				formstring = formstring .. "This tool points to liquids.\n"
			end
			if data.def.on_use ~= nil then
				formstring = formstring .. "Punches with this tool don't work as usual\\; melee combat and mining are either not possible or work differently.\n"
			end

			formstring = formstring .. "\n"

			formstring = formstring .. toolcaps_to_text(data.def.tool_capabilities) .. "\n"

			-- Show other “exposable” groups
			local gstring, gcount = groups_to_string(data.def.groups, miscgroups)
			if gstring ~= nil then
				if gcount == 1 then
					formstring = formstring .. "This tool belongs to the "..minetest.formspec_escape(gstring).." group.\n"
				else
					formstring = formstring .. "This tool belongs to these groups: "..minetest.formspec_escape(gstring)..".\n"
				end
			end

			-- Show fuel recipe
			formstring = formstring .. fuel_factoid(data.itemstring, "tools")

			formstring = formstring .. ";]"

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})


doc.new_category("craftitems", {
	name = "Miscellaneous items",
	description = "Item reference of items which are neither blocks, tools or weapons (esp. crafting items)",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp
			local formstring = "item_image[11,0;1,1;"..data.itemstring.."]"
			formstring = formstring .. "textarea[0.25,0.5;11,8;;"
			if longdesc ~= nil then
				formstring = formstring .. "Description: "..minetest.formspec_escape(longdesc).."\n\n"
			end
			if usagehelp ~= nil then
				formstring = formstring .. "Usage help: "..minetest.formspec_escape(usagehelp).. "\n\n"
			end
			formstring = formstring .. "Maximum stack size: "..data.def.stack_max.. "\n"

			formstring = formstring .. range_factoid(data.itemstring, data.def) .. "\n"

			if data.def.liquids_pointable == true then
				formstring = formstring .. "This item points to liquids.\n"
			end
			if data.def.on_use ~= nil then
				formstring = formstring .. "Punches with this item don't work as usual\\; melee combat and mining are either not possible or work differently.\n"
			end
			formstring = formstring .. "\n"

			formstring = formstring .. toolcaps_to_text(data.def.tool_capabilities) .. "\n"

			-- Show other “exposable” groups
			local gstring, gcount = groups_to_string(data.def.groups, miscgroups)
			if gstring ~= nil then
				if gcount == 1 then
					formstring = formstring .. "This item belongs to the "..minetest.formspec_escape(gstring).." group.\n"
				else
					formstring = formstring .. "This item belongs to these groups: "..minetest.formspec_escape(gstring)..".\n"
				end
			end

			-- Show fuel recipe
			formstring = formstring .. fuel_factoid(data.itemstring, "craftitems")

			formstring = formstring .. ";]"

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})

doc.sub.items.help = {}
doc.sub.items.help.longdesc = {}
doc.sub.items.help.usagehelp = {}
-- Sets the long description for a table of items
function doc.sub.items.set_items_longdesc(longdesc_table)
	for k,v in pairs(longdesc_table) do
		doc.sub.items.help.longdesc[k] = v
	end
end
-- Sets the usage help texts for a table of items
function doc.sub.items.set_items_usagehelp(usagehelp_table)
	for k,v in pairs(usagehelp_table) do
		doc.sub.items.help.usagehelp[k] = v
	end
end

-- Register group definition stuff
-- “Real” group names to replace the rather technical names
function doc.sub.items.add_real_group_names(groupnames)
	for internal, real in pairs(groupnames) do
		groupdefs[internal] = real
	end
end

-- Declare groups as mining groups
function doc.sub.items.add_mining_groups(groupnames)
	for g=1,#groupnames do
		mininggroups[groupnames[g]] = true
	end
end

-- Adds groups to be displayed in the generic “misc.” groups
-- factoid. Those groups should be neither be used as mining
-- groups nor as damage groups and should be relevant to the
-- player in someway.
function doc.sub.items.add_notable_groups(groupnames)
	for g=1,#groupnames do
		miscgroups[groupnames[g]] = true
	end
end

-- Add item which will be forced to be added to the item list,
-- even if the item is not in creative inventory
function doc.sub.items.add_forced_item_entries(itemstrings)
	for i=1,#itemstrings do
		forced_items[itemstrings[i]] = true
	end
end

-- Register a list of entry names where the entry name should differ
-- from the original item description
function doc.sub.items.add_item_name_overrides(itemstrings)
	for internal, real in pairs(itemstrings) do
		item_name_overrides[internal] = real
	end
end

local function gather_descs()
	local help = doc.sub.items.help

	-- Set default air text
	-- Custom longdesc and usagehelp may be set by mods through the add_helptexts function
	if help.longdesc["air"] == nil then
		help.longdesc["air"] = "A transparent block, basically empty space. It is usually left behind after digging something."
	end

	-- NOTE: Mod introduces group “not_in_doc”: Items with this group will not have entries
	-- NOTE: New group “in_doc”: forces an entry on this item when the item would otherwise not have one

	-- Add node entries
	for id, def in pairs(minetest.registered_nodes) do
		local name, ld, uh
		local forced = false
		if (forced_items[id] == true or def.groups.in_doc) and minetest.registered_nodes[id] ~= nil then forced = true end
		if item_name_overrides[id] ~= nil then
			name = item_name_overrides[id]
		else
			name = def.description
		end
		if not (name == nil or name == "" or def.groups.not_in_creative_inventory or def.groups.not_in_doc) or forced then
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

	-- Add entry for the default tool (“hand”)
	-- Custom longdesc and usagehelp may be set by mods through the add_helptexts function
	if help.longdesc[""] == nil then
		-- Default text
		help.longdesc[""] = "Whenever you are not wielding any item, you use the hand which acts as a tool with its own capabilities. When you are wielding an item which is not a mining tool or a weapon it will behave as if it would be the hand."
	end
	doc.new_entry("tools", "", {
		name = item_name_overrides[""],
		data = {
			longdesc = help.longdesc[""],
			usagehelp = help.usagehelp[""],
			itemstring = "",
			def = minetest.registered_items[""]
		}
	})
	-- Add tool entries
	for id, def in pairs(minetest.registered_tools) do
		local name, ld, uh
		local forced = false
		if (forced_items[id] == true or def.groups.in_doc) and minetest.registered_nodes[id] ~= nil then forced = true end
		if item_name_overrides[id] ~= nil then
			name = item_name_overrides[id]
		else
			name = def.description
		end
		if not (name == nil or name == "" or def.groups.not_in_creative_inventory or def.groups.not_in_doc) or forced then
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

	-- Add craftitem entries
	for id, def in pairs(minetest.registered_craftitems) do
		local name, ld, uh
		name = def.description
		local forced = false
		if (forced_items[id] == true or def.groups.in_doc) and minetest.registered_nodes[id] ~= nil then forced = true end
		if item_name_overrides[id] ~= nil then
			name = item_name_overrides[id]
		else
			name = def.description
		end
		if not (name == nil or name == "" or def.groups.not_in_creative_inventory or def.groups.not_in_doc) or forced then
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
