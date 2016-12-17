-- Boilerplate to support localized strings if intllib mod is installed.
local S
if minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s,a,...)a={a,...}return s:gsub("@(%d+)",function(n)return a[tonumber(n)]end)end
end

doc.sub.items = {}

-- Template texts
doc.sub.items.temp = {}
doc.sub.items.temp.deco = S("This is a decorational block.")
doc.sub.items.temp.build = S("This block is a building block for creating various buildings.")
doc.sub.items.temp.craftitem = S("This item is primarily used for crafting other items.")

doc.sub.items.temp.eat = S("Hold it in your hand, then leftclick to eat it.")
doc.sub.items.temp.eat_bad = S("Hold it in your hand, then leftclick to eat it. But why would you want to do this?")

doc.sub.items.settings = {}
doc.sub.items.settings.friendly_group_names = false
local setting = minetest.setting_getbool("doc_items_friendly_group_names")
if setting ~= nil then
	doc.sub.items.settings.friendly_group_names = setting
end
doc.sub.items.settings.itemstring = false
setting = minetest.setting_getbool("doc_items_show_itemstrings")
if setting ~= nil then
	doc.sub.items.settings.itemstring = setting
end

-- Local stuff
local groupdefs = {}
local mininggroups = {}
local miscgroups = {}
local item_name_overrides = {
	[""] = S("Hand"),
	["air"] = S("Air")
}
local suppressed = {
	["ignore"] = true,
}

-- Helper functions
local yesno = function(bool)
	if bool==true then return S("Yes")
	elseif bool==false then return S("No")
	else return "N/A" end
end

local groups_to_string = function(grouptable, filter)
	local gstring = ""
	local groups_count = 0
	for id, value in pairs(grouptable) do
		if (filter == nil or filter[id] == true) then
			-- Readable group name
			if groups_count > 0 then
				-- List seperator
				gstring = gstring .. S(", ")
			end
			if groupdefs[id] ~= nil and doc.sub.items.settings.friendly_group_names == true then
				gstring = gstring .. groupdefs[id]
			else
				gstring = gstring .. id
			end
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
	if string.sub(text, #text, #text) == "\n" or text == "" then
		return text
	else
		return text .. "\n"
	end
end

--[[ Make sure the text ends with two newlines by appending any missing newlines at the end, if neccessary. ]]
local newline2 = function(text)
	if string.sub(text, #text-1, #text) == "\n\n" or text == "" then
		return text
	elseif string.sub(text, #text, #text) == "\n" then
		return text .. "\n"
	else
		return text .. "\n\n"
	end
end


-- Extract suitable item description for formspec
local description_for_formspec = function(itemstring)
	if minetest.registered_items[itemstring] == nil then
		-- Huh? The item doesn't exist for some reason. Better give a dummy string
		minetest.log("warning", "[doc] Unknown item detected: "..tostring(itemstring))
		return S("Unknown item (@1)", tostring(itemstring))
	end
	local description = minetest.registered_items[itemstring].description
	if description == nil or description == "" then
		return minetest.formspec_escape(itemstring)
	else
		return minetest.formspec_escape(scrub_newlines(description))
	end
end

local get_entry_name = function(itemstring)
	local def = minetest.registered_items[itemstring]
	if def._doc_items_entry_name ~= nil then
		return def._doc_items_entry_name
	elseif item_name_overrides[itemstring] ~= nil then
		return item_name_overrides[itemstring]
	else
		return def.description
	end
end

doc.sub.items.get_group_name = function(groupname)
	if groupdefs[groupname] ~= nil and doc.sub.items.settings.friendly_group_names == true then
		return groupdefs[groupname]
	else
		return groupname
	end
end

local burntime_to_text = function(burntime)
	if burntime == nil then
		return S("unknown")
	elseif burntime == 1 then
		return S("1 second")
	else
		return S("@1 seconds", burntime)
	end
end

--[[ Convert tool capabilities to readable text. Extracted information:
* Mining capabilities
* Durability (when mining
* Full punch interval
* Damage groups
]]
local factoid_toolcaps = function(tool_capabilities, check_uses)
	local formstring = ""
	if check_uses == nil then check_uses = false end
	if tool_capabilities ~= nil and tool_capabilities ~= {} then
		local groupcaps = tool_capabilities.groupcaps
		if groupcaps ~= nil then
			local miningcapstr = ""
			local miningtimesstr = ""
			local miningusesstr = ""
			local caplines = 0
			local timelines = 0
			local useslines = 0
			for k,v in pairs(groupcaps) do
				-- Mining capabilities
				local minrating, maxrating
				for rating, time in pairs(v.times) do
					if minrating == nil then minrating = rating else
						if minrating > rating then minrating = rating end
					end
					if maxrating == nil then maxrating = rating else
						if maxrating < rating then maxrating = rating end
					end
				end
				local maxlevel = v.maxlevel
				if not maxlevel then
					-- Default from tool.h
					maxlevel = 1
				end
				miningcapstr = miningcapstr .. S("• @1: @2", doc.sub.items.get_group_name(k), maxlevel)
				miningcapstr = miningcapstr .. "\n"
				caplines = caplines + 1

				for rating=3, 1, -1 do
					if v.times ~= nil and v.times[rating] ~= nil then
						local maxtime = v.times[rating]
						local mintime
						local mintimestr, maxtimestr
						mintime = maxtime / maxlevel
						mintimestr = string.format("%.1f", mintime)
						maxtimestr = string.format("%.1f", maxtime)
						if mintimestr ~= maxtimestr then
							miningtimesstr = miningtimesstr ..
								S("• @1, rating @2: @3 s - @4 s",
								doc.sub.items.get_group_name(k), rating,
								mintimestr, maxtimestr)
						else
							miningtimesstr = miningtimesstr ..
								S("• @1, rating @2: @3 s",
								doc.sub.items.get_group_name(k), rating,
								mintimestr)
						end
						miningtimesstr = miningtimesstr.. "\n"
						timelines = timelines + 1
					end
				end

				-- Number of mining uses
				local base_uses = v.uses
				if not base_uses then
					-- Default from tool.h
					base_uses = 20
				end
				if check_uses and base_uses > 0 then
					for level=0, maxlevel do
						local real_uses = base_uses * math.pow(3, maxlevel - level)
						miningusesstr = miningusesstr .. S("• @1, level @2: @3 uses", doc.sub.items.get_group_name(k), level, real_uses)
						miningusesstr = miningusesstr .. "\n"
						useslines = useslines + 1
					end
				end
			end
			if caplines > 0 then
				formstring = formstring .. S("This tool is capable of mining.") .. "\n"
				formstring = formstring .. S("Maximum toughness levels:") .. "\n"
				formstring = formstring .. miningcapstr
				formstring = newline(formstring)
			end
			if timelines > 0 then
				formstring = formstring .. S("Mining times:") .. "\n"
				formstring = formstring .. miningtimesstr
			end
			if useslines > 0 then
				formstring = formstring .. S("Mining durability:") .. "\n"
				formstring = formstring .. miningusesstr
			end
			if caplines > 0 or useslines > 0 or timelines > 0 then
				formstring = newline2(formstring)
			end
		end

		-- Weapon data
		local damage_groups = tool_capabilities.damage_groups
		if damage_groups ~= nil then
			formstring = formstring .. S("This is a melee weapon which deals damage by punching.") .. "\n"
			-- Damage groups
			formstring = formstring .. S("Maximum damage per hit:") .. "\n"
			for k,v in pairs(damage_groups) do
				formstring = formstring .. S("• @1: @2 HP", doc.sub.items.get_group_name(k), v)
				formstring = formstring .. "\n"
			end

			-- Full punch interval
			local punch = 1.0
			if tool_capabilities.full_punch_interval ~= nil then
				punch = tool_capabilities.full_punch_interval
			end
			formstring = formstring .. S("Full punch interval: @1 s", string.format("%.1f", punch))
			formstring = formstring .. "\n"
		end

	end
	return formstring
end

-- Pointing range of itmes
local range_factoid = function(itemstring, def)
	local handrange = minetest.registered_items[""].range
	local itemrange = def.range
	if itemstring == "" then
		if handrange ~= nil then
			return S("Range: @1", itemrange)
		else
			return S("Range: 4")
		end
	else
		if handrange == nil then handrange = 4 end
		if itemrange ~= nil then
			return S("Range: @1", itemrange)
		else
			return S("Range: @1 (@2)", get_entry_name(""), handrange)
		end
	end
end

-- Smelting fuel factoid
local factoid_fuel = function(itemstring, ctype)
	local formstring = ""
	local result, decremented =  minetest.get_craft_result({method = "fuel", items = {itemstring}})
	if result ~= nil and result.time > 0 then
		local base
		local burntext = burntime_to_text(result.time)
		if ctype == "tools" then
			base = S("This tool can serve as a smelting fuel with a burning time of @1.", burntext)
		elseif ctype == "nodes" then
			base = S("This block can serve as a smelting fuel with a burning time of @1.", burntext)
		else
			base = S("This item can serve as a smelting fuel with a burning time of @1.", burntext)
		end
		formstring = formstring .. base
		local replaced = decremented.items[1]:get_name()
		if not decremented.items[1]:is_empty() and replaced ~= itemstring then
			formstring = formstring .. S(" Using it as fuel turns it into: @1.", description_for_formspec(replaced))
		end
		formstring = newline(formstring)
	end
	return formstring
end

-- Shows the itemstring of an item
local factoid_itemstring = function(itemstring, playername)
	local privs = minetest.get_player_privs(playername)
	if doc.sub.items.settings.itemstring or (privs.give or privs.debug) then
		return S("Itemstring: \"@1\"", itemstring)
	else
		return ""
	end
end

local entry_image = function(data)
	local formstring = ""
	-- No image for air
	if data.itemstring ~= "air" then
		-- Hand
		if data.itemstring == "" then
			formstring = formstring .. "image["..(doc.FORMSPEC.ENTRY_END_X-1)..","..doc.FORMSPEC.ENTRY_START_Y..";1,1;"..
				minetest.registered_items[""].wield_image.."]"
		-- Other items
		elseif data.image ~= nil then
			formstring = formstring .. "image["..(doc.FORMSPEC.ENTRY_END_X-1)..","..doc.FORMSPEC.ENTRY_START_Y..";1,1;"..data.image.."]"
		else
			formstring = formstring .. "item_image["..(doc.FORMSPEC.ENTRY_END_X-1)..","..doc.FORMSPEC.ENTRY_START_Y..";1,1;"..data.itemstring.."]"
		end
	end
	return formstring
end

-- Stuff for factoids
local factoid_generators = {}
factoid_generators.nodes = {}
factoid_generators.tools = {}
factoid_generators.craftitems = {}

--[[ Returns a list of all registered factoids for the specified category and type
* category_id: Identifier of the Documentation System category in which the factoid appears
* factoid_type: If set, oly returns factoid with a matching factoid_type.
                If nil, all factoids for this category will be generated
* data: Entry data to parse ]]
local factoid_custom = function(category_id, factoid_type, data)
	local ftable = factoid_generators[category_id]
	local datastring = ""
	-- Custom factoids are inserted here
	for i=1,#ftable do
		if factoid_type == nil or ftable[i].ftype == factoid_type then
			datastring = datastring .. ftable[i].fgen(data.itemstring, data.def)
			if datastring ~= "" then
				datastring = newline(datastring)
			end
		end
	end
	return datastring
end

-- Shows core information shared by all items, to be inserted at the top
local factoids_header = function(data, ctype)
	local longdesc = data.longdesc
	local usagehelp = data.usagehelp
	local datastring = ""
	if longdesc ~= nil then
		datastring = datastring .. S("Description: @1", longdesc)
		datastring = newline2(datastring)
	end
	if usagehelp ~= nil then
		datastring = datastring .. S("Usage help: @1", usagehelp)
		datastring = newline2(datastring)
	end
	datastring = datastring .. factoid_custom(ctype, "use", data)
	datastring = newline2(datastring)

	if data.itemstring ~= "" then
		datastring = datastring .. S("Maximum stack size: @1", data.def.stack_max)
		datastring = newline(datastring)
	end
	datastring = datastring .. range_factoid(data.itemstring, data.def)

	datastring = newline2(datastring)

	if data.def.liquids_pointable == true then
		if ctype == "nodes" then
			datastring = datastring .. S("This block points to liquids.").."\n"
		elseif ctype == "tools" then
			datastring = datastring .. S("This tool points to liquids.").."\n"
		elseif ctype == "craftitems" then
			datastring = datastring .. S("This item points to liquids.").."\n"
		end
	end
	if data.def.on_use ~= nil then
		if ctype == "nodes" then
			datastring = datastring .. S("Punches with this block don't work as usual; melee combat and mining are either not possible or work differently.").."\n"
		elseif ctype == "tools" then
			datastring = datastring .. S("Punches with this tool don't work as usual; melee combat and mining are either not possible or work differently.").."\n"
		elseif ctype == "craftitems" then
			datastring = datastring .. S("Punches with this item don't work as usual; melee combat and mining are either not possible or work differently.").."\n"
		end
	end

	datastring = newline(datastring)

	-- Show tool capability stuff, including durability if not overwritten by custom field
	local check_uses = false
	if ctype == "tools" then
		check_uses = data.def._doc_items_durability == nil
	end
	datastring = datastring .. factoid_toolcaps(data.def.tool_capabilities, check_uses)
	datastring = newline2(datastring)

	return datastring
end

-- Shows less important information shared by all items, to be inserted at the bottom
local factoids_footer = function(data, playername, ctype)
	local datastring = ""
	datastring = datastring .. factoid_custom(ctype, "groups", data)
	datastring = newline2(datastring)

	-- Show other “exposable” groups
	local gstring, gcount = groups_to_string(data.def.groups, miscgroups)
	if gstring ~= nil then
		if gcount == 1 then
			if ctype == "nodes" then
				datastring = datastring .. S("This block belongs to the @1 group.", gstring) .. "\n"
			elseif ctype == "tools" then
				datastring = datastring .. S("This tool belongs to the @1 group.", gstring) .. "\n"
			elseif ctype == "craftitems" then
				datastring = datastring .. S("This item belongs to the @1 group.", gstring) .. "\n"
			end
		else
			if ctype == "nodes" then
				datastring = datastring .. S("This block belongs to these groups: @1.", gstring) .. "\n"
			elseif ctype == "tools" then
				datastring = datastring .. S("This tool belongs to these groups: @1.", gstring) .. "\n"
			elseif ctype == "craftitems" then
				datastring = datastring .. S("This item belongs to these groups: @1.", gstring) .. "\n"
			end
		end
	end
	datastring = newline2(datastring)

	-- Show fuel recipe
	datastring = datastring .. factoid_fuel(data.itemstring, ctype)
	datastring = newline2(datastring)

	-- Other custom factoids
	datastring = datastring .. factoid_custom(ctype, "misc", data)
	datastring = newline2(datastring)

	-- Itemstring
	datastring = datastring .. factoid_itemstring(data.itemstring, playername)

	return datastring
end

function doc.sub.items.register_factoid(category_id, factoid_type, factoid_generator)
	local ftable = { fgen = factoid_generator, ftype = factoid_type }
	if category_id == "nodes" or category_id == "tools" or category_id == "craftitems" then
		table.insert(factoid_generators[category_id], ftable)
		return true
	elseif category_id == nil then
		table.insert(factoid_generators.nodes, ftable)
		table.insert(factoid_generators.tools, ftable)
		table.insert(factoid_generators.craftitems, ftable)
		return false
	end
end

doc.new_category("nodes", {
	hide_entries_by_default = true,
	name = S("Blocks"),
	description = S("Item reference of blocks and other things which are capable of occupying space"),
	build_formspec = function(data, playername)
		if data then
			local formstring = ""
			local datastring = ""

			formstring = entry_image(data)
			datastring = factoids_header(data, "nodes")

			datastring = datastring .. S("Collidable: @1", yesno(data.def.walkable)) .. "\n"
			local liquid
			if data.def.liquidtype ~= "none" then liquid = true else liquid = false end
			if data.def.pointable == true then
				datastring = datastring .. S("Pointable: Yes") .. "\n"
			elseif liquid then
				datastring = datastring .. S("Pointable: Only by special items") .. "\n"
			else
				datastring = datastring .. S("Pointable: No") .. "\n"
			end
			datastring = newline2(datastring)
			if liquid then
				datastring = newline(datastring, false)
				datastring = datastring .. S("This block is a liquid with these properties:") .. "\n"
				local range, renew, viscos
				if data.def.liquid_range then range = data.def.liquid_range else range = 8 end
				if data.def.liquid_renewable ~= nil then renew = data.def.liquid_renewable else renew = true end
				if data.def.liquid_viscosity then viscos = data.def.liquid_viscosity else viscos = 0 end
				if renew then
					datastring = datastring .. S("• Renewable") .. "\n"
				else
					datastring = datastring .. S("• Not renewable") .. "\n"
				end
				if range == 0 then
					datastring = datastring .. S("• No flowing") .. "\n"
				else
					datastring = datastring .. S("• Flowing range: @1", range) .. "\n"
				end
				datastring = datastring .. S("• Viscosity: @1", viscos) .. "\n"
			end
			datastring = newline2(datastring)

			-- Global factoids
			--- Direct interaction with the player
			---- Damage (very important)
			if data.def.damage_per_second ~= nil and data.def.damage_per_second > 1 then
				datastring = datastring .. S("This block causes a damage of @1 hit points per second.", data.def.damage_per_second) .. "\n"
			elseif data.def.damage_per_second == 1 then
				datastring = datastring .. S("This block causes a damage of @1 hit point per second.", data.def.damage_per_second) .. "\n"
			end
			if data.def.drowning > 1 then
				datastring = datastring .. S("This block decreases your breath and causes a drowning damage of @1 hit points every 2 seconds.", data.def.drowning) .. "\n"
			elseif data.def.drowning == 1 then
				datastring = datastring .. S("This block decreases your breath and causes a drowning damage of @1 hit point every 2 seconds.", data.def.drowning) .. "\n"
			end
			local fdap = data.def.groups.fall_damage_add_percent
			if fdap ~= nil then
				if fdap > 0 then
					datastring = datastring .. S("The fall damage on this block is increased by @1%.", fdap) .. "\n"
				elseif fdap <= -100 then
					datastring = datastring .. S("This block negates all fall damage.") .. "\n"
				else
					datastring = datastring .. S("The fall damage on this block is reduced by @1%.", math.abs(fdap)) .. "\n"
				end
			end
			datastring = datastring .. factoid_custom("nodes", "damage", data)
			datastring = newline2(datastring)

			---- Movement
			if data.def.groups.disable_jump == 1 then
				datastring = datastring .. S("You can not jump while standing on this block.").."\n"
			end
			if data.def.climbable == true then
				datastring = datastring .. S("This block can be climbed.").."\n"
			end
			local bouncy = data.def.groups.bouncy
			if bouncy ~= nil then
				datastring = datastring .. S("This block will make you bounce off with an elasticity of @1%.", bouncy).."\n"
			end
			datastring = datastring .. factoid_custom("nodes", "movement", data)
			datastring = newline2(datastring)

			---- Sounds
			local function is_silent(def, soundtype)
				return type(def.sounds) ~= "table" or def.sounds[soundtype] == nil or def.sounds[soundtype] == "" or (type(data.def.sounds[soundtype]) == "table" and (data.def.sounds[soundtype].name == nil or data.def.sounds[soundtype].name == ""))
			end
			local silentstep, silentdig, silentplace = false, false, false
			if data.def.walkable and is_silent(data.def, "footstep") then
				silentstep = true
			end
			if data.def.diggable and is_silent(data.def, "dig") and is_silent(data.def, "dug")  then
				silentdig = true
			end
			if is_silent(data.def, "place") and is_silent(data.def, "place_failed") and data.itemstring ~= "air" then
				silentplace = true
			end
			if silentstep and silentdig and silentplace then
				datastring = datastring .. S("This block is completely silent when walked on, mined or built.").."\n"
			elseif silentdig and silentplace then
				datastring = datastring .. S("This block is completely silent when mined or built.").."\n"
			else
				if silentstep then
					datastring = datastring .. S("Walking on this block is completely silent.").."\n"
				end
				if silentdig then
					datastring = datastring .. S("Mining this block is completely silent.").."\n"
				end
				if silentplace then
					datastring = datastring .. S("Building this block is completely silent.").."\n"
				end
			end
			datastring = datastring .. factoid_custom("nodes", "sound", data)
			datastring = newline2(datastring)

			-- Block activity
			--- Gravity
			if data.def.groups.falling_node == 1 then
				datastring = datastring .. S("This block is affected by gravity and can fall.").."\n"
			end
			datastring = datastring .. factoid_custom("nodes", "gravity", data)
			datastring = newline2(datastring)

			--- Dropping and destruction
			if data.def.buildable_to == true then
				datastring = datastring .. S("Building another block at this block will place it inside and replace it.").."\n"
				if data.def.walkable then
					datastring = datastring .. S("Falling blocks can go through this block; they destroy it when doing so.").."\n"
				end
			end
			if data.def.walkable == false then
				if data.def.buildable_to == false and data.def.drop ~= "" then
					datastring = datastring .. S("This block will drop as an item when a falling block ends up inside it.").."\n"
				else
					datastring = datastring .. S("This block is destroyed when a falling block ends up inside it.").."\n"
				end
			end
			if data.def.groups.attached_node == 1 then
				if data.def.paramtype2 == "wallmounted" then
					datastring = datastring .. S("This block will drop as an item when it is not attached to a surrounding block.").."\n"
				else
					datastring = datastring .. S("This block will drop as an item when no collidable block is below it.").."\n"
				end
			end
			if data.def.floodable == true then
				datastring = datastring .. S("Liquids can flow into this block and destroy it.").."\n"
			end
			datastring = datastring .. factoid_custom("nodes", "drop_destroy", data)
			datastring = newline2(datastring)

			-- Block appearance
			--- Light
			if data.def.light_source > 3 then
				datastring = datastring .. S("This block is a light source with a light level of @1.", data.def.light_source).."\n"
			elseif data.def.light_source > 0 then
				datastring = datastring .. S("This block glows faintly with a light level of @1.", data.def.light_source).."\n"
			end
			if data.def.paramtype == "light" and data.def.sunlight_propagates then
				datastring = datastring .. S("This block allows light to propagate with a small loss of brightness, and sunlight can even go through losslessly.").."\n"
			elseif data.def.paramtype == "light" then
				datastring = datastring .. S("This block allows light to propagate with a small loss of brightness.").."\n"
			elseif data.def.sunlight_propagates then
				datastring = datastring .. S("This block allows sunlight to propagate without loss in brightness.").."\n"
			end
			datastring = datastring .. factoid_custom("nodes", "light", data)
			datastring = newline2(datastring)

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
						nstring = nstring .. S(", ")
					end
					if name ~= nil then
						nstring = nstring .. name
					else
						nstring = nstring .. S("Unknown Node")
					end
				end
				if #nodes == 1 then
					datastring = datastring .. S("This block connects to this block: @1.", nstring) .. "\n"
				elseif #nodes > 1 then
					datastring = datastring .. S("This block connects to these blocks: @1.", nstring) .. "\n"
				end

				local gstring, gcount = groups_to_string(groups)
				if gcount == 1 then
					datastring = datastring .. S("This block connects to blocks of the @1 group.", gstring) .. "\n"
				elseif gcount > 1 then
					datastring = datastring .. S("This block connects to blocks of the following groups: @1.", gstring) .. "\n"
				end
			end

			datastring = newline2(datastring)

			-- Mining groups
			datastring = datastring .. factoid_custom("nodes", "mining", data)
			datastring = newline(datastring)
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
						datastring = datastring .. S("This block can be mined by any mining tool in half a second.").."\n"
					elseif data.def.groups.dig_immediate == 3 then
						datastring = datastring .. S("This block can be mined by any mining tool immediately.").."\n"
					-- Note: “unbreakable” is an unofficial group for undiggable blocks
					elseif data.def.diggable == false or nogroups or data.def.groups.immortal == 1 or data.def.groups.unbreakable == 1 then
						datastring = datastring .. S("This block can not be mined by ordinary mining tools.").."\n"
					end
				else
					if data.def.groups.dig_immediate == 2 then
						datastring = datastring .. S("This block can be destroyed by any mining tool in half a second.").."\n"
					elseif data.def.groups.dig_immediate == 3 then
						datastring = datastring .. S("This block can be destroyed by any mining tool immediately.").."\n"
					elseif data.def.diggable == false or nogroups or data.def.groups.immortal == 1 or data.def.groups.unbreakable == 1 then
						datastring = datastring .. S("This block can not be destroyed by ordinary mining tools.").."\n"
					end
				end
				-- Expose “ordinary” mining groups (crumbly, cracky, etc.) and level group
				-- Skip this for immediate digging to avoid redundancy
				if data.def.groups.dig_immediate ~= 3 then
					local mstring = S("This block can be mined by mining tools which match any of the following mining ratings and its toughness level.").."\n"
					mstring = mstring .. S("Mining ratings:").."\n"
					local minegroupcount = 0
					for group,_ in pairs(mininggroups) do
						local rating = data.def.groups[group]
						if rating ~= nil then
							mstring = mstring .. S("• @1: @2", doc.sub.items.get_group_name(group), rating).."\n"
							minegroupcount = minegroupcount + 1
						end
					end
					local level = data.def.groups.level
					if not level then
						level = 0
					end
					mstring = mstring .. S("Toughness level: @1", level).."\n"

					if minegroupcount > 0 then
						datastring = datastring .. mstring
					end
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
					datastring = datastring .. S("This block won't drop anything when mined.").."\n"
				elseif type(data.def.drop) == "string" then
					local dropstack = ItemStack(data.def.drop)
					if dropstack:get_name() ~= data.itemstring and dropstack:get_name() ~= 1 then
						local desc = get_desc(dropstack)
						local count = dropstack:get_count()
						if count > 1 then
							datastring = datastring .. S("This block will drop the following when mined: @1×@2.", count, desc).."\n"
						else
							datastring = datastring .. S("This block will drop the following when mined: @1.", desc).."\n"
						end
					end
				elseif type(data.def.drop) == "table" and data.def.drop.items ~= nil then
					local max = data.def.drop.max_items
					local dropstring = ""
					local dropstring_base = ""
					if max == nil then
						dropstring_base = S("This block will drop the following items when mined: %s.")
					elseif max == 1 then
						if #data.def.drop.items == 1 then
							dropstring_base = S("This block will drop the following when mined: %s.")
						else
							dropstring_base = S("This block will randomly drop one of the following when mined: %s.")
						end
					else
						dropstring_base = S("This block will randomly drop up to %d drops of the following possible drops when mined: %s.")
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
							-- List seperator
							dropstring = dropstring .. S(", ")
						end
						local probtable = probtables[i]
						local icount = 0
						local dropstring_this = ""
						for _, itemtable in pairs(probtable.items) do
							if icount > 0 then
								-- Final list seperator
								dropstring_this = dropstring_this .. S(" and ")
							end
							local desc = S(itemtable.desc)
							local count = itemtable.count
							if count ~= 1 then
								desc = S("@1×@2", count, desc)
							end
							dropstring_this = dropstring_this .. desc
							icount = icount + 1
						end

						local rarity = probtable.rarity
						local raritystring = ""
						-- No percentage if there's only one possible guaranteed drop
						if not(rarity == 1 and #data.def.drop.items == 1) then
							local chance = (1/rarity)*100
							if rarity > 200 then -- <0.5%
							-- For very low percentages
								dropstring_this = S("@1 (<0.5%)", dropstring_this)
							else
								-- Add circa indicator for percentages with decimal point
								-- FIXME: Is this check actually reliable?
								local fchance = string.format("%.0f", chance)
								if math.fmod(chance, 1) > 0 then
									dropstring_this = S("@1 (ca. @2%)", dropstring_this, fchance)
								else
									dropstring_this = S("@1 (@2%)", dropstring_this, fchance)
								end
							end
						end
						dropstring = dropstring .. dropstring_this
						pcount = pcount + 1
					end
					if max ~= nil and max > 1 then
						datastring = datastring .. string.format(dropstring_base, max, dropstring)
					else
						datastring = datastring .. string.format(dropstring_base, dropstring)
					end
					datastring = newline(datastring)
				end
			end
			datastring = newline2(datastring)
	
			datastring = datastring .. factoids_footer(data, playername, "nodes")

			formstring = formstring .. doc.widgets.text(datastring, nil, nil, doc.FORMSPEC.ENTRY_WIDTH - 1.2)

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!]"
		end
	end
})

doc.new_category("tools", {
	hide_entries_by_default = true,
	name = S("Tools and weapons"),
	description = S("Item reference of all wieldable tools and weapons"),
	sorting = "function",
	-- Roughly sort tools based on their capabilities. Tools which dig the same stuff end up in the same group
	sorting_data = function(entry1, entry2)
		-- Hand beats all
		if entry1.eid == "" then return true end
		if entry2.eid == "" then return false end
		-- No tool capabilities = instant loser
		if entry1.data.def.tool_capabilities == nil then return false end
		if entry2.data.def.tool_capabilities == nil then return true end
		local comp = {}
		comp[1] = {}
		comp[2] = {}
		comp[1].gc = entry1.data.def.tool_capabilities.groupcaps
		comp[2].gc = entry2.data.def.tool_capabilities.groupcaps
		-- No group capabilities = instant loser
		if comp[1].gc == nil then return false end
		if comp[2].gc == nil then return true end
		for e=1, 2 do
			local groups = {}
			local gc = comp[e].gc
			local group, mintime
			local groupcount = 0
			local uses
			for k,v in pairs(gc) do
				if groupcount == 0 then
					group = k
				end
				for rating, time in pairs(v.times) do
					if mintime == nil or time < mintime then
						mintime = time
					end
				end
				if groups[k] ~= true then
					groupcount = groupcount + 1
					groups[k] = true
				end
			end
			comp[e].count = groupcount
			comp[e].group = group
			comp[e].mintime = mintime
		end

		-- We want to sort out digging tools with multiple capabilities
		if comp[1].count > 1 and comp[1].count > comp[2].count then
			return false
		-- Tiebreaker 1: Minimum digging time
		elseif comp[1].group == comp[2].group then
			return comp[1].mintime < comp[2].mintime
		-- Final tiebreaker: Sort by group name
		else
			return comp[1].group < comp[2].group
		end
	end,
	build_formspec = function(data, playername)
		if data then
			local formstring = ""
			local datastring = ""

			formstring = entry_image(data)
			datastring = factoids_header(data, "tools")

			-- Overwritten durability info
			if type(data.def._doc_items_durability) == "number" then
				-- Fixed number of uses
				datastring = datastring .. S("Durability: @1 uses", data.def._doc_items_durability)
				datastring = newline2(datastring)
			elseif type(data.def._doc_items_durability) == "string" then
				-- Manually described durability
				datastring = datastring .. S("Durability: @1", data.def._doc_items_durability)
				datastring = newline2(datastring)
			end

			datastring = datastring .. factoids_footer(data, playername, "tools")

			formstring = formstring .. doc.widgets.text(datastring, nil, nil, doc.FORMSPEC.ENTRY_WIDTH - 1.2)

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!]"
		end
	end
})

doc.new_category("craftitems", {
	hide_entries_by_default = true,
	name = S("Miscellaneous items"),
	description = S("Item reference of items which are neither blocks, tools or weapons (esp. crafting items)"),
	build_formspec = function(data, playername)
		if data then
			local formstring = ""
			local datastring = ""

			formstring = entry_image(data)
			datastring = factoids_header(data, "craftitems")
			datastring = datastring .. factoids_footer(data, playername, "craftitems")

			formstring = formstring .. doc.widgets.text(datastring, nil, nil, doc.FORMSPEC.ENTRY_WIDTH - 1.2)

			return formstring
		else
			return "label[0,1;NO DATA AVALIABLE!]"
		end
	end
})

-- Register group definition stuff
-- More (user-)friendly group names to replace the rather technical names
-- for better understanding
function doc.sub.items.add_friendly_group_names(groupnames)
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

-- Collect information about all items
local function gather_descs()
	-- Internal help texts for default items
	local help = {
		longdesc = {},
		usagehelp = {},
	}

	-- 1st pass: Gather groups of interest
	for id, def in pairs(minetest.registered_items) do
		-- Gather all groups used for mining
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

		-- ... and gather all groups which appear in crafting recipes
		local crafts = minetest.get_all_craft_recipes(id)
		if crafts ~= nil then
			for c=1,#crafts do
				for k,v in pairs(crafts[c].items) do
					if string.sub(v,1,6) == "group:" then
						local groupstring = string.sub(v,7,-1)
						local groups = string.split(groupstring, ",")
						for g=1, #groups do
							miscgroups[groups[g]] = true
						end
					end
				end
			end
		end

		-- ... and gather all groups used in connects_to
		if def.connects_to ~= nil then
			for c=1, #def.connects_to do
				if string.sub(def.connects_to[c],1,6) == "group:" then
					local group = string.sub(def.connects_to[c],7,-1)
					miscgroups[group] = true
				end
			end
		end
	end

	-- 2nd pass: Add entries

	-- Set default air text
	-- Custom longdesc and usagehelp may be set by mods through the add_helptexts function
	if minetest.registered_items["air"]._doc_items_longdesc then
		help.longdesc["air"] = minetest.registered_items["air"]._doc.items_longdesc
	else
		help.longdesc["air"] = S("A transparent block, basically empty space. It is usually left behind after digging something.")
	end
	if minetest.registered_items["ignore"]._doc_items_create_entry ~= nil then
		suppressed["ignore"] = minetest.registered_items["ignore"]._doc_items_create_entry == true
	end

	-- Add entry for the default tool (“hand”)
	-- Custom longdesc and usagehelp may be set by mods through the add_helptexts function
	local handdef = minetest.registered_items[""]
	if handdef._doc_items_create_entry ~= false then
		if handdef._doc_items_longdesc then
			help.longdesc[""] = handdef._doc_items_longdesc
		else
			-- Default text
			help.longdesc[""] = S("Whenever you are not wielding any item, you use the hand which acts as a tool with its own capabilities. When you are wielding an item which is not a mining tool or a weapon it will behave as if it would be the hand.")
		end
		if handdef._doc_items_entry_name then
			item_name_overrides[""] = handdef._doc_items_entry_name
		end
		doc.new_entry("tools", "", {
			name = item_name_overrides[""],
			hidden = handdef._doc_items_hidden == true,
			data = {
				longdesc = help.longdesc[""],
				usagehelp = help.usagehelp[""],
				itemstring = "",
				def = handdef,
			}
		})
	end

	local add_entries = function(deftable, category_id)
		for id, def in pairs(deftable) do
			local name, ld, uh, im
			local forced = false
			if def._doc_items_create_entry == true and def ~= nil then forced = true end
			name = get_entry_name(id)
			if not (((def.description == nil or def.description == "") and def._doc_items_entry_name == nil) or (def._doc_items_create_entry == false) or (suppressed[id] == true)) or forced then
				if def._doc_items_longdesc then
					ld = def._doc_items_longdesc
				end
				if help.longdesc[id] ~= nil then
					ld = help.longdesc[id]
				end
				if def._doc_items_usagehelp then
					uh = def._doc_items_usagehelp
				end
				if help.usagehelp[id] ~= nil then
					uh = help.usagehelp[id]
				end
				if def._doc_items_image then
					im = def._doc_items_image
				end
				local hidden
				if id == "air" or id == ""  then hidden = false end
				if type(def._doc_items_hidden) == "boolean" then
					hidden = def._doc_items_hidden
				end
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
	if itemstring == nil or itemstring == "" or playername == nil or playername == "" then
		return false
	end
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
	if digger == nil then return end
	local playername = digger:get_player_name()
	if playername ~= nil and playername ~= "" and oldnode ~= nil then
		reveal_item(playername, oldnode.name)
		reveal_items_in_inventory(digger)
	end
end)

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	if puncher == nil then return end
	local playername = puncher:get_player_name()
	if playername ~= nil and playername ~= "" and node ~= nil then
		reveal_item(playername, node.name)
	end
end)

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if placer == nil then return end
	local playername = placer:get_player_name()
	if playername ~= nil and playername ~= "" and itemstack ~= nil and not itemstack:is_empty() then
		reveal_item(playername, itemstack:get_name())
	end
end)

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	if player == nil then return end
	local playername = player:get_player_name()
	if playername ~= nil and playername ~= "" and itemstack ~= nil and not itemstack:is_empty() then
		reveal_item(playername, itemstack:get_name())
	end
end)

minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
	if user == nil then return end
	local playername = user:get_player_name()
	if playername ~= nil and playername ~= "" and itemstack ~= nil and not itemstack:is_empty() then
		reveal_item(playername, itemstack:get_name())
		if replace_with_item ~= nil then
			reveal_item(playername, replace_with_item)
		end
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
