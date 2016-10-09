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
-- List of forcefully added (true) and hidden (false) items
local forced_items = {
	["ignore"] = false
}
local hidden_items = {}
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

-- Replaces all newlines with spaces
local scrub_newlines = function(text)
	local new, x = string.gsub(text, "\n", " ")
	return new
end

--[[ Append a newline to text, unless it already ends with a newline. ]]
local newline = function(text)
	if string.sub(text, #text, #text) == "\n" then
		return text
	else
		return text .. "\n"
	end
end

--[[ Make sure the text ends with two newlines by appending any missing newlines at the end, if neccessary. ]]
local newline2 = function(text)
	if string.sub(text, #text-1, #text) == "\n\n" then
		return text
	elseif string.sub(text, #text, #text) == "\n" then
		return text .. "\n"
	else
		return text .. "\n\n"
	end
end



-- Extract suitable item description for formspec
local description_for_formspec = function(itemstring)
	local description = minetest.registered_items[itemstring].description
	if description == nil or description == "" then
		return minetest.formspec_escape(itemstring)
	else
		return minetest.formspec_escape(scrub_newlines(description))
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
		formstring = newline2(formstring)

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
			return "Range: "..item_name_overrides[""].." ("..handrange..")"
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
			formstring = formstring .. " Using it as fuel turns it into: "..description_for_formspec(replaced).."."
		end
		formstring = newline(formstring)
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
	hide_entries_by_default = true,
	name = "Blocks",
	description = "Item reference of blocks and other things which are capable of occupying space",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp

			local formstring = ""
			if data.itemstring ~= "air" then
				if data.image ~= nil then
					formstring = formstring .. "image[11,0;1,1;"..data.image.."]"
				else
					formstring = formstring .. "item_image[11,0;1,1;"..data.itemstring.."]"
				end
			end
			local datastring = ""
			if longdesc ~= nil then
				datastring = datastring .. "Description: "..longdesc.."\n\n"
			end
			if usagehelp ~= nil then
				datastring = datastring .. "Usage help: "..usagehelp.. "\n\n"
			end
			datastring = datastring .. "Maximum stack size: "..data.def.stack_max.. "\n"

			datastring = datastring .. range_factoid(data.itemstring, data.def) .. "\n"

			datastring = newline2(datastring)

			if data.def.liquids_pointable == true then
				datastring = datastring .. "This block points to liquids.\n"
			end
			if data.def.on_use ~= nil then
				datastring = datastring .. "Punches with this block don't work as usual; melee combat and mining are either not possible or work differently.\n"
			end

			datastring = newline2(datastring)

			datastring = datastring .. toolcaps_to_text(data.def.tool_capabilities)

			datastring = datastring .. "Collidable: "..yesno(data.def.walkable).. "\n"
			local liquid
			if data.def.liquidtype ~= "none" then liquid = true else liquid = false end
			if data.def.pointable == true then
				datastring = datastring .. "Pointable: Yes\n"
			elseif liquid then
				datastring = datastring .. "Pointable: Only by special items\n"
			else
				datastring = datastring .. "Pointable: No\n"
			end
			datastring = newline2(datastring)
			if liquid then
				datastring = newline(datastring, false)
				datastring = datastring .. "This block is a liquid with these properties:\n"
				local range, renew, viscos
				if data.def.liquid_range then range = data.def.liquid_range else range = 8 end
				if data.def.liquid_renewable ~= nil then renew = data.def.liquid_renewable else renew = true end
				if data.def.liquid_viscosity then viscos = data.def.liquid_viscosity else viscos = 0 end
				if renew then
					datastring = datastring .. "• Renewable\n"
				else
					datastring = datastring .. "• Not renewable\n"
				end
				if range == 0 then
					datastring = datastring .. "• No flowing\n"
				else
					datastring = datastring .. "• Flowing range: "..range.. "\n"
				end
				datastring = datastring .. "• Viscosity: "..viscos.. "\n"
			end
			datastring = newline2(datastring)

			-- Global factoids
			--- Direct interaction with the player
			---- Damage (very important)
			if data.def.damage_per_second > 1 then
				datastring = datastring .. "This block causes a damage of "..data.def.damage_per_second.." hit points per second.\n"
			elseif data.def.damage_per_second == 1 then
				datastring = datastring .. "This block causes a damage of "..data.def.damage_per_second.." hit point per second.\n"
			elseif data.def.damage_per_second < -1 then
				datastring = datastring .. "This block heals "..data.def.damage_per_second.." hit points per second.\n"
			elseif data.def.damage_per_second == -1 then
				datastring = datastring .. "This block heals "..data.def.damage_per_second.." hit point per second.\n"
			end
			if data.def.drowning > 1 then
				datastring = datastring .. "This block decreases your breath and causes a drowning damage of "..data.def.drowning.." hit points every 2 seconds.\n"
			elseif data.def.drowning == 1 then
				datastring = datastring .. "This block decreases your breath and causes a drowning damage of "..data.def.drowning.." hit point every 2 seconds.\n"
			end
			local fdap = data.def.groups.fall_damage_add_percent
			if fdap ~= nil then
				if fdap > 0 then
					datastring = datastring .. "The fall damage on this block is increased by "..fdap.."%.\n"
				elseif fdap == -100 then
					datastring = datastring .. "This block negates all fall damage.\n"
				else
					datastring = datastring .. "The fall damage on this block is reduced by "..math.abs(fdap).."%.\n"
				end
			end

			---- Movement
			if data.def.groups.disable_jump == 1 then
				datastring = datastring .. "You can not jump while standing on this block.\n"
			end
			if data.def.climbable == true then
				datastring = datastring .. "This block can be climbed.\n"
			end
			local bouncy = data.def.groups.bouncy
			if bouncy ~= nil then
				datastring = datastring .. "This block will make you bounce off with an elasticity of "..bouncy.."%.\n"
			end


			---- Sounds
			local function is_silent(def, soundtype)
				return def.sounds == nil or def.sounds[soundtype] == nil or def.sounds[soundtype] == "" or (type(data.def.sounds[soundtype]) == "table" and (data.def.sounds[soundtype].name == nil or data.def.sounds[soundtype].name == ""))
			end
			local silentstep, silentdig, silentplace = false, false, false
			if data.def.walkable and is_silent(data.def, "footstep") then
				silentstep = true
			end
			if data.def.diggable and is_silent(data.def, "dig") and is_silent(data.def, "dug")  then
				silentdig = true
			end
			if is_silent(data.def, "place") and data.itemstring ~= "air" then
				silentplace = true
			end
			if silentstep and silentdig and silentplace then
				datastring = datastring .. "This block is completely silent when walked on, mined or built.\n"
			elseif silentdig and silentplace then
				datastring = datastring .. "This block is completely silent when mined or built.\n"
			else
				if silentstep then
					datastring = datastring .. "Walking on this block is completely silent.\n"
				end
				if silentdig then
					datastring = datastring .. "Mining this block is completely silent.\n"
				end
				if silentplace then
					datastring = datastring .. "Building this block is completely silent.\n"
				end
			end

			-- Block activity
			--- Gravity
			if data.def.groups.falling_node == 1 then
				datastring = datastring .. "This block is affected by gravity and can fall.\n"
			end

			--- Dropping and destruction
			if data.def.buildable_to == true then
				datastring = datastring .. "Building another block at this block will place it inside and replace it.\n"
				if data.def.walkable then
					datastring = datastring .. "Falling blocks can go through this block; they destroy it when doing so.\n"
				end
			end
			if data.def.walkable == false then
				if data.def.buildable_to == false and (data.def.paramtype2 == "wallmounted" or data.def.groups.attached_node == 1) then
					datastring = datastring .. "This block will drop as an item when a falling block ends up inside it.\n"
				else
					datastring = datastring .. "This block is destroyed when a falling block ends up inside it.\n"
				end
			end
			if data.def.groups.attached_node == 1 then
				if data.def.paramtype2 == "wallmounted" then
					datastring = datastring .. "This block will drop as an item when it is not attached to a surrounding block.\n"
				else
					datastring = datastring .. "This block will drop as an item when no collidable block is below it.\n"
				end
			end
			if data.def.floodable == true then
				datastring = datastring .. "Liquids can flow into this block and destroy it.\n"
			end

			-- Block appearance
			--- Light
			if data.def.light_source == 15 then
				datastring = datastring .. "This block is an extremely bright light source. It glows as bright the sun.\n"
			elseif data.def.light_source == 14 then
				datastring = datastring .. "This block is a very bright light source.\n"
			elseif data.def.light_source > 12 then
				datastring = datastring .. "This block is a bright light source.\n"
			elseif data.def.light_source > 5 then
				datastring = datastring .. "This block is a light source of medium luminance.\n"
			elseif data.def.light_source > 1 then
				datastring = datastring .. "This block is a weak light source and glows faintly.\n"
			elseif data.def.light_source == 1 then
				datastring = datastring .. "This block glows faintly. It is barely noticable.\n"
			end
			if data.def.paramtype == "light" and data.def.sunlight_propagates then
				datastring = datastring .. "This block allows light to propagate with a small loss of brightness, and sunlight can even go through losslessly.\n"
			elseif data.def.paramtype == "light" then
				datastring = datastring .. "This block allows light to propagate with a small loss of brightness.\n"
			elseif data.def.sunlight_propagates then
				datastring = datastring .. "This block allows sunlight to propagate without loss in brightness.\n"
			end

			--- List nodes/groups to which this node connects to
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
						name = description_for_formspec(minetest.registered_nodes[nodes[n]])
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
				if #nodes == 1 then
					datastring = datastring .. "This block connects to this block: "..nstring..".\n"
				elseif #nodes > 1 then
					datastring = datastring .. "This block connects to these blocks: "..nstring..".\n"
				end

				local gstring, gcount = groups_to_string(groups)
				if gcount == 1 then
					datastring = datastring .. "This block connects to blocks of the "..gstring.." group.\n"
				elseif gcount > 1 then
					datastring = datastring .. "This block connects to blocks of the following groups: "..gstring..".\n"
				end
			end

			datastring = newline2(datastring)

			-- Mining groups
			if data.def.pointable ~= false and (data.def.liquid_type == "none" or data.def.liquid_type == nil) then
				-- Check if there are no mining groups at all
				local nogroups = true
				for groupname,_ in pairs(mininggroups) do
					if data.def.groups[groupname] ~= nil or groupname == "dig_immediate" then
						nogroups = false
						break
					end
				end
				-- dig_immediate
				if data.def.drop ~= "" then
					if data.def.groups.dig_immediate == 2 then
						datastring = datastring .. "This block can be mined by any mining tool in half a second.\n"
					elseif data.def.groups.dig_immediate == 3 then
						datastring = datastring .. "This block can be mined by any mining tool immediately.\n"
					-- Note: “unbreakable” is an unofficial group for undiggable blocks
					elseif data.def.diggable == false or nogroups or data.def.groups.immortal == 1 or data.def.groups.unbreakable == 1 then
						datastring = datastring .. "This block can not be mined by ordinary mining tools.\n"
					end
				else
					if data.def.groups.dig_immediate == 2 then
						datastring = datastring .. "This block can be destroyed by any mining tool in half a second.\n"
					elseif data.def.groups.dig_immediate == 3 then
						datastring = datastring .. "This block can be destroyed by any mining tool immediately.\n"
					elseif data.def.diggable == false or nogroups or data.def.groups.immortal == 1 or data.def.groups.unbreakable == 1 then
						datastring = datastring .. "This block can not be destroyed by ordinary mining tools.\n"
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
							mstring = mstring .. "• "..group_to_string(group)..": "..rating.."\n"
							minegroupcount = minegroupcount + 1
						end
					end
					if data.def.groups.level ~= nil then
						mstring = mstring .. "Mining level: "..data.def.groups.level.."\n"
					else
						mstring = mstring .. "Mining level: 0\n"
					end

					if minegroupcount > 0 then
						datastring = datastring .. mstring
					end
				end
			end
			datastring = newline2(datastring)

			-- Custom factoids are inserted here
			for i=1,#factoid_generators.nodes do
				datastring = datastring .. factoid_generators.nodes[i].fgen(data.itemstring, data.def)
				datastring = newline(datastring)
			end
			datastring = newline2(datastring)

			-- Show other “exposable” groups in quick list
			local gstring, gcount = groups_to_string(data.def.groups, miscgroups)
			if gstring ~= nil then
				if gcount == 1 then
					datastring = datastring .. "This block belongs to the "..gstring.." group.\n"
				else
					datastring = datastring .. "This block belongs to these groups: "..gstring..".\n"
				end
			end
			datastring = newline2(datastring)

			-- Non-default drops
			if data.def.drop ~= nil and data.def.drop ~= data.itemstring and data.itemstring ~= "air" then
				-- TODO: Calculate drop probabilities of max > 1 like for max == 1
				local get_desc = function(stack)
					return description_for_formspec(stack:get_name())
				end
				if data.def.drop == "" then
					datastring = datastring .. "This block won't drop anything when mined.\n"
				elseif type(data.def.drop) == "string" then
					local dropstack = ItemStack(data.def.drop)
					if dropstack:get_name() ~= data.itemstring and dropstack:get_name() ~= 1 then
						local desc = get_desc(dropstack)
						local count = dropstack:get_count()
						local finalstring
						if count > 1 then
							finalstring = count .. "×"..desc
						else
							finalstring = desc
						end
						datastring = datastring .. "This block will drop the following when mined: "..finalstring.."\n"
					end
				elseif type(data.def.drop) == "table" and data.def.drop.items ~= nil then
					local max = data.def.drop.max_items
					if max == nil then
						datastring = datastring .. "This block will drop the following items when mined: "
					elseif max == 1 then
						if #data.def.drop.items == 1 then
							datastring = datastring .. "This block will drop the following when mined: "
						else
							datastring = datastring .. "This block will randomly drop one of the following when mined: "
						end
					else
						datastring = datastring .. "This block will randomly drop up to "..max.." drops of the following possible drops when mined: "
					end
					-- Save calculated probabilities into a table for later output
					local probtables = {}
					local probtable
					local rarity_history = {}
					for i=1,#data.def.drop.items do
						local local_rarity = data.def.drop.items[i].rarity
						local chance = 1
						local rarity = 1
						if local_rarity == nil then
							local_rarity = 1
						end
						if max == 1 then
							-- Chained probability
							table.insert(rarity_history, local_rarity)
							chance = 1
							for r=1, #rarity_history do
								local chance_factor
								if r > 1 and rarity_history[r-1] == 1 then
									chance = 0
									break
								end
								if r == #rarity_history then
									chance_factor = 1/rarity_history[r]
								else
									chance_factor = (rarity_history[r]-1)/rarity_history[r]
								end
								chance = chance * chance_factor
							end
							if chance > 0 then
								rarity = 1/chance
							end
						else
							rarity = local_rarity
							chance = 1/rarity
						end
						-- Exclude impossible drops
						if chance > 0 then
							probtable = {}
							probtable.items = {}
							for j=1,#data.def.drop.items[i].items do
								local dropstack = ItemStack(data.def.drop.items[i].items[j])
								local itemstring = dropstack:get_name()
								local desc = get_desc(dropstack)
								local count = dropstack:get_count()
								if not(itemstring == nil or itemstring == "" or count == 0) then
									if probtable.items[itemstring] == nil then
										probtable.items[itemstring] = {desc = desc, count = count}
									else
										probtable.items[itemstring].count = probtable.items[itemstring].count + count
									end
								end
							end
							probtable.rarity = rarity
							if #data.def.drop.items[i].items > 0 then
								table.insert(probtables, probtable)
							end
						end
					end
					-- Do some cleanup of the probability table
					if max == 1 or max == nil then
						-- Sort by rarity
						local comp = function(p1, p2) 
							return p1.rarity < p2.rarity
						end
						table.sort(probtables, comp)
					end
					-- Output probability table
					local pcount = 0
					for i=1, #probtables do
						if pcount > 0 then
							datastring = datastring .. ", "
						end
						local probtable = probtables[i]
						local icount = 0
						for _, itemtable in pairs(probtable.items) do
							if icount > 0 then
								datastring = datastring .. " and "
							end
							local desc = itemtable.desc
							local count = itemtable.count
							if count ~= 1 then
								desc = count .. "×" .. desc
							end
							datastring = datastring .. desc
							icount = icount + 1
						end

						local rarity = probtable.rarity
						-- No percentage if there's only one possible guaranteed drop
						if not(rarity == 1 and #data.def.drop.items == 1) then
							local chance = (1/rarity)*100
							local ca = ""
							if rarity > 200 then -- <0.5%
							-- For very low percentages
								datastring = datastring .. " (<0.5%)"
							else
								-- Add circa indicator for percentages with decimal point
								-- FIXME: Is this check actually reliable?
								if math.fmod(chance, 1) > 0 then
									ca = "ca. "
								end
								datastring = datastring .. string.format(" (%s%.0f%%)", ca, chance)
							end
						end
						pcount = pcount + 1
					end
					formtring = datastring .. "."
					datastring = newline(datastring)
				end
			end
	
			-- Show fuel recipe
			datastring = newline2(datastring)
			datastring = datastring .. fuel_factoid(data.itemstring, "nodes")

			formstring = formstring .. doc.widgets.text(datastring, 0, 0.5, 10.8, 8)

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})

doc.new_category("tools", {
	hide_entries_by_default = true,
	name = "Tools and weapons",
	description = "Item reference of all wieldable tools and weapons",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp
			local formstring = ""
			-- Hand
			if data.itemstring == "" then
				formstring = formstring .. "image[11,0;1,1;"..minetest.registered_items[""].wield_image.."]"
			-- Other tools
			elseif data.image ~= nil then
				formstring = formstring .. "image[11,0;1,1;"..data.image.."]"
			else
				formstring = formstring .. "item_image[11,0;1,1;"..data.itemstring.."]"
			end
			local datastring = ""
			if longdesc ~= nil then
				datastring = datastring .. "Description: "..longdesc
				datastring = newline2(datastring)
			end
			if usagehelp ~= nil then
				datastring = datastring .. "Usage help: "..usagehelp
				datastring = newline2(datastring)
			end
			if data.itemstring ~= "" then
				datastring = datastring .. "Maximum stack size: "..data.def.stack_max.. "\n"
			end

			datastring = datastring .. range_factoid(data.itemstring, data.def) .. "\n"

			datastring = newline2(datastring)

			if data.def.liquids_pointable == true then
				datastring = datastring .. "This tool points to liquids.\n"
			end
			if data.def.on_use ~= nil then
				datastring = datastring .. "Punches with this tool don't work as usual; melee combat and mining are either not possible or work differently.\n"
			end

			datastring = newline(datastring)

			datastring = datastring .. toolcaps_to_text(data.def.tool_capabilities)

			datastring = newline2(datastring)

			-- Show other “exposable” groups
			local gstring, gcount = groups_to_string(data.def.groups, miscgroups)
			if gstring ~= nil then
				if gcount == 1 then
					datastring = datastring .. "This tool belongs to the "..gstring.." group.\n"
				else
					datastring = datastring .. "This tool belongs to these groups: "..gstring..".\n"
				end
			end

			-- Show fuel recipe
			datastring = newline2(datastring)
			datastring = datastring .. fuel_factoid(data.itemstring, "tools")

			formstring = formstring .. doc.widgets.text(datastring, 0, 0.5, 10.8, 8)

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})


doc.new_category("craftitems", {
	hide_entries_by_default = true,
	name = "Miscellaneous items",
	description = "Item reference of items which are neither blocks, tools or weapons (esp. crafting items)",
	build_formspec = function(data)
		if data then
			local longdesc = data.longdesc
			local usagehelp = data.usagehelp
			local formstring = ""
			if data.image ~= nil then
				formstring = formstring .. "image[11,0;1,1;"..data.image.."]"
			else
				formstring = formstring .. "item_image[11,0;1,1;"..data.itemstring.."]"
			end
			local datastring = ""
			if longdesc ~= nil then
				datastring = datastring .. "Description: "..longdesc.."\n\n"
			end
			if usagehelp ~= nil then
				datastring = datastring .. "Usage help: "..usagehelp.. "\n\n"
			end
			datastring = datastring .. "Maximum stack size: "..data.def.stack_max.. "\n"

			datastring = datastring .. range_factoid(data.itemstring, data.def) .. "\n"

			datastring = newline2(datastring)

			if data.def.liquids_pointable == true then
				datastring = datastring .. "This item points to liquids.\n"
			end
			if data.def.on_use ~= nil then
				datastring = datastring .. "Punches with this item don't work as usual; melee combat and mining are either not possible or work differently.\n"
			end
			datastring = newline(datastring)

			datastring = datastring .. toolcaps_to_text(data.def.tool_capabilities)

			datastring = newline2(datastring)

			-- Show other “exposable” groups
			local gstring, gcount = groups_to_string(data.def.groups, miscgroups)
			if gstring ~= nil then
				if gcount == 1 then
					datastring = datastring .. "This item belongs to the "..gstring.." group.\n"
				else
					datastring = datastring .. "This item belongs to these groups: "..gstring..".\n"
				end
			end

			-- Show fuel recipe
			datastring = newline2(datastring)
			datastring = datastring .. fuel_factoid(data.itemstring, "craftitems")

			formstring = formstring .. doc.widgets.text(datastring, 0, 0.5, 10.8, 8)

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!"
		end
	end
})

doc.sub.items.help = {}
doc.sub.items.help.longdesc = {}
doc.sub.items.help.usagehelp = {}
doc.sub.items.help.image = {}

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

function doc.sub.items.add_item_image_overrides(image_overrides)
	for itemstring, new_image in pairs(image_overrides) do
		doc.sub.items.help.image[itemstring] = new_image
	end
end

-- Register group definition stuff
-- “Real” group names to replace the rather technical names
function doc.sub.items.add_real_group_names(groupnames)
	for internal, real in pairs(groupnames) do
		groupdefs[internal] = real
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

-- Add items which will be forced to be added to the item list,
-- even if the item is not in creative inventory
function doc.sub.items.add_forced_item_entries(itemstrings)
	for i=1,#itemstrings do
		forced_items[itemstrings[i]] = true
	end
end

-- Add items which will be forced *not* to be added to the item list
function doc.sub.items.add_suppressed_item_entries(itemstrings)
	for i=1,#itemstrings do
		forced_items[itemstrings[i]] = false
	end
end

-- Add items which will be hidden from the entry list, but their entries
-- are still created.
function doc.sub.items.add_hidden_item_entries(itemstrings)
	for i=1,#itemstrings do
		hidden_items[itemstrings[i]] = true
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

	-- 1st pass
	-- Gather all groups used for mining
	for id, def in pairs(minetest.registered_items) do
		if def.tool_capabilities ~= nil then
			local groupcaps = def.tool_capabilities.groupcaps
			if groupcaps ~= nil then
				for k,v in pairs(groupcaps) do
					if mininggroups[k] ~= true then
						mininggroups[k] = true
					end
				end
			end
		end
	end

	-- 2nd pass: Add entries

	-- Set default air text
	-- Custom longdesc and usagehelp may be set by mods through the add_helptexts function
	if help.longdesc["air"] == nil then
		help.longdesc["air"] = "A transparent block, basically empty space. It is usually left behind after digging something."
	end

	-- NOTE: New group “not_in_doc”: Items with this group will not have entries
	-- NOTE: New group “hide_from_doc”: Items with this group will not be visible in the entry list initially

	local add_entries = function(deftable, category_id)
		for id, def in pairs(deftable) do
			local name, ld, uh, im
			local forced = false
			if (forced_items[id] == true or def.groups.in_doc) and def ~= nil then forced = true end
			if item_name_overrides[id] ~= nil then
				name = item_name_overrides[id]
			else
				name = def.description
			end
			if not (name == nil or name == "" or def.groups.not_in_doc or forced_items[id] == false) or forced then
				if help.longdesc[id] ~= nil then
					ld = help.longdesc[id]
				end
				if help.usagehelp[id] ~= nil then
					uh = help.usagehelp[id]
				end
				if help.image[id] ~= nil then
					im = help.image[id]
				end
				local hidden
				if id == "air" then hidden = false end
				local custom_image
				name = scrub_newlines(name)
				local infotable = {
					name = name,
					hidden = hidden,
					data = {
						longdesc = ld,
						usagehelp = uh,
						image = im,
						itemstring = id,
						def = def,
					}
				}
				doc.new_entry(category_id, id, infotable)
			end
		end
	end



	-- Add node entries
	add_entries(minetest.registered_nodes, "nodes")

	-- Add entry for the default tool (“hand”)
	-- Custom longdesc and usagehelp may be set by mods through the add_helptexts function
	if help.longdesc[""] == nil then
		-- Default text
		help.longdesc[""] = "Whenever you are not wielding any item, you use the hand which acts as a tool with its own capabilities. When you are wielding an item which is not a mining tool or a weapon it will behave as if it would be the hand."
	end
	doc.new_entry("tools", "", {
		name = item_name_overrides[""],
		hidden = false,
		data = {
			longdesc = help.longdesc[""],
			usagehelp = help.usagehelp[""],
			itemstring = "",
			def = minetest.registered_items[""]
		}
	})
	-- Add tool entries
	add_entries(minetest.registered_tools, "tools")

	-- Add craftitem entries
	add_entries(minetest.registered_craftitems, "craftitems")
end

--[[ Reveal items as the player progresses through the game.
Items are revealed by:
* Digging, punching or placing node,
* Crafting
* Having item in inventory (not instantly revealed) ]]

local function reveal_item(playername, itemstring)
	local category_id
	if minetest.registered_nodes[itemstring] ~= nil then
		category_id = "nodes"
	elseif minetest.registered_tools[itemstring] ~= nil then
		category_id = "tools"
	elseif minetest.registered_craftitems[itemstring] ~= nil then
		category_id = "craftitems"
	elseif minetest.registered_items[itemstring] ~= nil then
		category_id = "craftitems"
	else
		return false
	end
	doc.mark_entry_as_revealed(playername, category_id, itemstring)
	return true
end

local function reveal_items_in_inventory(player)
	local inv = player:get_inventory()
	local list = inv:get_list("main")
	for l=1, #list do
		reveal_item(player:get_player_name(), list[l]:get_name())
	end
end

minetest.register_on_dignode(function(pos, oldnode, digger)
	if digger ~= nil then
		reveal_item(digger:get_player_name(), oldnode.name)
		reveal_items_in_inventory(digger)
	end
end)

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	reveal_item(puncher:get_player_name(), node.name)
end)

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	reveal_item(placer:get_player_name(), itemstack:get_name())
end)

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	reveal_item(player:get_player_name(), itemstack:get_name())
end)

minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
	reveal_item(user:get_player_name(), itemstack:get_name())
	if replace_with_item ~= nil then
		reveal_item(user:get_player_name(), replace_with_item)
	end
end)

minetest.register_on_joinplayer(function(player)
	reveal_items_in_inventory(player)
end)

--[[ Periodically check all items in player inventory and reveal them all.
TODO: Check whether there's a serious performance impact on servers with many players.
TODO: If possible, try to replace this functionality by updating the revealed items as
      soon the player obtained a new item (probably needs new Minetest callbacks). ]]
local checktime = 8
local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer > checktime then
		local players = minetest.get_connected_players()
		for p=1, #players do
			reveal_items_in_inventory(players[p])
		end

		timer = math.fmod(timer, checktime)
	end
end)

minetest.after(0, gather_descs)
