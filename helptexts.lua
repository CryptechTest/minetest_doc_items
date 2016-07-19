local basicflametext
if minetest.setting_getbool("disable_fire") == true then
	basicflametext = "The basic flame is a damaging but short-lived kind of block. This particular world is rather hostile to fire, so basic flames won't spread and destroy other blocks. They disappear after a while. A basic flame will be extinguished by water and other blocks if it is next to it. A single basic flame block can be destroyed safely by punching it, but it is hurtful if you stand directly in it."
else
	basicflametext = "The basic flame is a damaging and destructive but short-lived kind of block. It will destroy and spread towards near flammable blocks, but fire will disappear if there is nothing to burn left. It will be extinguished by water and other blocks if it is next to it. A single basic flame block can be destroyed safely by punching it, but it is hurtful if you stand directly in it."

end

local flowertext = "Will slowly spread on dirt with grass but withers and dies on sand to become a dry shrub."
local ladderdesc =  "A piece of ladder which allows you to move vertically."
local ladderuse = "Hold the jump key to climb up and the sneak or use key (depends on configuration) to climb down."
local fencedesc = "A fence post. When multiple of these are placed to next to each other, they will automatically build a nice fence structure. You can easily jump over a low fence."
local fencegatedesc = "Fence gates connect neatly to other fence pieces and can be opened or closed. They can be easily jumped over."
local fencegateuse = "Rightclick the gate to open or close it."
local walldesc = "A piece of wall. When multiple of these are placed to next to each other, they will automatically build a nice wall structure. You can easily jump over a low wall."
local slabdesc = "Slabs are half as high as their full block counterparts. Slabs can be easily climbed without needing to jump. They are useful to create long staircases and many other structures. When a slab is placed on another slab of the same type, a new full block is created."
local stairdesc = "Stairs are useful to climb up without needing to jump."


local leavesdesc = "Leaves and needles are solid blocks usually found at trees, but they can be placed anywhere just like every other block. These blocks will decay if there is no tree trunk of any kind near them, unless you have placed the block manually."
local signdesc = "A sign is placed at walls. You can write something want on it."
local signuse = "Rightclick the sign to edit the text."

local beddesc = "Beds allow you to sleep at night and waste some time. Survival in this world does not demand sleep, but sleeping might have some other uses. "
local beduse = "Rightclick on the bed to try to sleep in it. This only works at night. Rightclick the bed again to get up. "
if minetest.setting_getbool("enable_bed_respawn") == false then
	beddesc = beddesc .. "In local folklore, legends are told of other worlds where setting the start point for your next would be possible. But this world is not one of them. "
else
	beddesc = beddesc .. "By sleeping in a bed, you set the starting point for your next life. "
end
if minetest.setting_getbool("enable_bed_night_skip") == false then
	beddesc = beddesc .. "In this strange world, the time will not pass faster for you when you sleep."
else
	beddesc = beddesc .. "Going into bed seems to make time pass faster: The night will be skipped when you go sleep and you are the only human being in this world. If you are not alone, the night will be skipped as soon the majority of all humans went to bed."
end

help = {}
help.longdesc = {
	["default:apple"] = "Eat it to restore 2 hit points.",
	["default:furnace"] = "Cooks several items, using a furnace fuel, into something else.",
	["default:chest"] = "Provides 32 slots of inventory space.",
	["default:chest_locked"] = "Provides 32 slots of inventory space, is accessible only to the player who placed it. Locked chests are also immune to explosions.",
	["default:stone"] = "A very common block in the world of Minetest. It sometimes contains ores. Usable for a variety in crafting recipes. Can be dug with a wooden pickaxe or better.",
	["default:desert_stone"] = "A less common block in the world, usually only found in deserts. Can be dug with a wooden pickaxe or better.",
	["default:stone_with_coal"] = "Some natural coal! Can be dug with a wooden pickaxe or better.",
	["default:stone_with_iron"] = "Some natural iron! Can be dug with a stone pickaxe or better.",
	["default:stone_with_copper"] = "Some natural copper! Can be dug with a stone pickaxe or better.",
	["default:stone_with_mese"] = "This stone contains a small amount of Mese! Can be dug with a steel pickaxe or better to obtain a mese crystal.",
	["default:stone_with_gold"] = "Some natural gold! Can be dug with a steel pickaxe or better.",
	["default:stone_with_diamond"] = "Hooray, diamonds! Can be dug with a steel pickaxe or better.",
	["default:stonebrick"] = "A decorational block.",
	["default:desert_stonebrick"] = "A decorational block.",
	["default:dirt_with_grass"] = "Natural soil for a variety of plants. It has been exposed to sunlight and is thus grassy. Can be dug with a shovel.",
	["default:dirt"] = "Natural soil for a variety of plants. Its top will become grassy if it becomes exposed to sunlight. Can be dug with a shovel.",
	["default:sand"] = "An unstable block, it will fall if nothing is below it. Usually found at beaches. It is best dug with a shovel.",
	["default:desert_sand"] = "An unstable block, it will fall if nothing is below it. Usually found in deserts. It is best dug with a shovel.",
	["default:gravel"] = "An unstable block, it will fall if nothing is below it. It is best dug with a shovel.",
	["default:sandstone"] = "A pretty soft kind of stone.",
	["default:sandstonebrick"] = "A decorational block.",
	["default:clay"] = "Clay.",
	["default:brick"] = "A decorational block.",
	["default:tree"] = "A trunk of an ordinary tree.",
	["default:cloud"] = "A solid block which can not be mined. It could be destroyed by explosions.",
	["default:jungletree"] = "A trunk of a jungle tree.",
	["default:pine_tree"] = "A trunk of a pine tree.",
	["default:aspen_tree"] = "A trunk of a aspen tree.",
	["default:acacia_tree"] = "A trunk of a acacia tree.",
	["default:wood"] = "A decorational and flammable block.",
	["default:junglewood"] = "A decorational and flammable block.",
	["default:pinewood"] = "A decorational and flammable block.",
	["default:acaciawood"] = "A decorational and flammable block.",
	["default:sapling"] = "When placed on dirt and exposed to sunlight, this sapling will grow into an ordinary tree or an apple tree after some time.",
	["default:junglesapling"] = "When placed on dirt and exposed to sunlight, this sapling will grow into a large jungle tree after some time.",
	["default:pine_sapling"] = "When placed on dirt and exposed to sunlight, this sapling will grow into a pine tree after some time.",
	["default:acacia_sapling"] = "When placed on dirt and exposed to sunlight, this sapling will grow into an acacia after some time.",
	["default:leaves"] = leavesdesc,
	["default:jungleleaves"] = leavesdesc,
	["default:pine_needles"] = leavesdesc,
	["default:acacia_leaves"] = leavesdesc,
	["default:aspen_leaves"] = leavesdesc,
	["default:cactus"] = "A piece of cactus usually found in deserts. Cactus placed on desert sand will slowly grow up to 4 cactus blocks high.",
	["default:papyrus"] = "A papyrus piece usually found near water. Papyrus will grow up to 4 blocks high when it is near a water source.",
	["default:bookshelf"] = "A bookshelf provides space for 16 books.",
	["default:glass"] = "A decorational, transparent block.",
	["default:fence_wood"] = fencedesc,
	["default:fence_junglewood"] = fencedesc,
	["default:fence_pine_wood"] = fencedesc,
	["default:fence_acacia_wood"] = fencedesc,
	["default:fence_aspen_wood"] = fencedesc,
	["doors:gate_wood_closed"] = fencegatedesc,
	["doors:gate_junglewood_closed"] = fencegatedesc,
	["doors:gate_acacia_wood_closed"] = fencegatedesc,
	["doors:gate_pine_wood_closed"] = fencegatedesc,
	["doors:gate_aspen_wood_closed"] = fencegatedesc,

	["default:rail"] = "Railroad tracks. Place these on the ground to build your railway, the blocks will automatically connect to each other nicely.",
	["default:ladder_wood"] = ladderdesc,
	["default:ladder_steel"] = ladderdesc,
	["default:water_flowing"] = "You can swim easily in water, but you need to catch your breath from time to time.",
	["default:water_source"] = "You can swim easily in water, but you need to catch your breath from time to time.",
	["default:lava_source"] = "Don't touch the lava, it will hurt you very much and once you're in, it is hard to get out.",
	["default:lava_flowing"] = "Don't touch the lava, it will hurt you very much and once you're in, it is hard to get out.",
	["default:torch"] = "Provides plenty of light, but not as much as a sun would do. It can be placed on almost any block facing any direction.",
	["default:sign_wall_wood"] = signdesc,
	["default:sign_wall_steel"] = signdesc,
	["default:stick"] = "Wooden sticks are used as element in countless crafting recipes.",
	["default:steel_ingot"] = "Smolten iron. It is the element of numerous crafting recipes.",
	["default:mese_crystal_fragment"] = "A piece of what was once a whole mese crystal. It has no use in Minetest Game.",

	["default:cobble"] = "A decorational block, created after digging stone. If it is near water, it might turn into mossy cobblestone.",
	["default:desert_cobble"] = "A decorational block.",
	["default:coal_lump"] = "Coal lumps are your standard furnace fuel, but they are used to make torches and a few other crafting recipes.",
	["default:mossycobble"] = "A decorational block. It is found in underground dungeons and the product of cobblestone near water.",
	["default:coalblock"] = "A decorational block and compact storage of coal lumps. As a furnace fuel, it is slightly more efficient than 9 coal lumps.",
	["default:steelblock"] = "A decorational block.",
	["default:copperblock"] = "A decorational block.",
	["default:bronzeblock"] = "A decorational block.",
	["default:goldblock"] = "A decorational block.",
	["default:diamondblock"] = "A very hard decorational block.",
	["default:obsidian_glass"] = "A decorational, transparent block.",
	["default:obsidian"] = "A hard mineral which is generated when a lava source meets a water source.",

	["default:nyancat"] = "A weird creature with a cat face, cat extremities and a strawberry-flavored pop-tart body. It has been trapped in a block and cannot move and can thus be dug easily by simple tools. Nyan cats are usually followed by nyan cat rainbows. Legends say that in ancient times, long before the creation of our world, the were many of the Nyan Cats which were free and flew through space and sang the \"Nya-nya\" song. Nowadays, nyan cats serve as a fancy collector's item and are traded as souveniers. Apart from that, nyan cats have no intrinsic value.",
	["default:nyancat_rainbow"] = "A rainbow made by a real nyan cat, ancient creatures which once flew through space. It has gone inert and can be dug by simple tools. Like nyan cats, nyan cat rainbows have no intrinsic value.",
	["default:book"] = "A book is used to store notes and to make bookshelfs.",
	["default:grass_1"] = "Some grass. On a Dirt with Grass block, it will slowly spread.",
	["default:meselamp"] = "A bright source of light made out of mese. It shines slightly brighter than a torch.",
	["default:mese"] = "A very rare mineral of alien origin. This is mese in its purest form, can be broken into 9 Mese Crystals.",
	["bucket:bucket_empty"] = "A bucket, liquids can be collected with it.",
	["bucket:bucket_water"] = "A bucket which is filled with water.",
	["bucket:bucket_river_water"] = "A bucket which is filled with river water.",
	["bucket:bucket_lava"] = "A bucket which is filled with lava. You can use it in the furnace as a very efficient fuel (you'll keep the bucket).",

	["bones:bones"] = "These are the remains of a deceased player. It contains the player's former inventory which can be looted. Fresh bones are bones of a player who has deceased recently and can only be looted by the same player. Old bones can be looted by everyone. The bones are destroyed after they have been completely looted.",
	["doors:door_wood"] = "A door covers a vertical area of two blocks to block the way. It can be opened and closed by any player.",
	["doors:door_glass"] = "A door covers a vertical area of two blocks to block the way. It can be opened and closed by any player.",
	["doors:door_obsidian_glass"] = "A door covers a vertical area of two blocks to block the way. It can be opened and closed by any player.",
	["doors:door_steel"] = "Steel doors are owned by the player who placed it, only their owner can open, close or mine them. Steel doors are also immune to TNT explosions.",
	["farming:bread"] = "A nutritious food. Eat it to restore 5 hit points.",
	["farming:seed_wheat"] = "Grows into wheat.",
	["farming:seed_cotton"] = "Grows into cotton.",
	["farming:soil"] = "Dry soil, this is where you can grow crops on. Dry soil will become wet soil if a water source is near.",
	["farming:soil_wet"] = "Wet soil, this is where you can grow crops on.",
	["farming:desert_sand_soil"] = "Dry soil, this is where you can grow crops on. Dry soil will become wet soil if a water source is near.",
	["farming:desert_sand_soil_wet"] = "Wet soil, this is where you can grow crops on.",
	["flowers:mushroom_brown"] = "An edible mushroom. Likes to grow on dirt with grass in forests. It will slowly spread if you leave it alone. Eat it to restore 1 hit point.",
	["flowers:mushroom_red"] = "A poisonous mushroom, don't eat it. Likes to grow on dirt with grass in forests. It will slowly spread if you leave it alone. Eat it to lose 5 hit points.",
	["flowers:geranium"] = flowertext,
	["flowers:dandelion_yellow"] = flowertext,
	["flowers:dandelion_white"] = flowertext,
	["flowers:tulip"] = flowertext,
	["flowers:rose"] = flowertext,
	["flowers:viola"] = flowertext,
	["flowers:waterlily"] = "Waterlilies grow and spread on shallow water. They can't survive on anything else but water.",

	["tnt:tnt"] = "An explosive device. When it explodes, it will hurt living beings, destroy blocks around it, and set flammable blocks on fire. With a small chance, blocks may drop as an item rather than being destroyed. TNT can be ignited by explosions and fire.",
	["tnt:gunpowder"] = "Gunpowder is used to craft TNT and to create gunpowder trails which can be ignited.",

	["fire:basic_flame"] = basicflametext,
	["fire:flint_and_steel"] = "Flint and steel is a tool to start fires.",
	["fire:permanent_flame"] = "The permanent flame is a damaging and destructive block. It will create basic flames next to it if flammable blocks are nearby. Other than the basic flame, the permanent flame will not go away by time alone. Permanent flames will be extinguished by water and similar blocks if it is next to it. A single permanent flame block can be destroyed safely by punching it, but it is hurtful if you stand directly in it.",


	["default:ladder_wood"] = ladderuse,
	["default:ladder_steel"] = ladderuse,

	["doors:trapdoor"] = "A trapdoor covers a hole in the floor and can be opened manually to access the area below it. An opened trapdoor can be climbed like a ladder.",
	["doors:trapdoor_steel"] = "A steel trapdoor covers a hole in the floor and can be opened manually only by the placer to access the area below it. An opened steel trapdoor can be climbed like a ladder. Steel trapdoors are immune to explosions.",

	["screwdriver:screwdriver"] = "A screwdriver can be used to rotate blocks. It can be used 200 times.",

	["boats:boat"] = "A simple boat which allows you to float on the surface of large water bodies. Travelling by boat is slightly faster than swimming.",
	["vessels:glass_bottle"] = "A decorational item. Can be placed like a block.",
	["vessels:drinking_glass"] = "A decorational item which can be placed.",
	["vessels:steel_bottle"] = "A decorational item which can be placed.",
	["vessels:shelf"] = "A vessels shelf provides space for 16 vessels (like glass bottles).",
	["xpanes:pane"] = "Glass panes are thin layers of glass which neatly connect to their neighbors as you build them.",
	["xpanes:bar"] = "Iron bars neatly connect to their neighbors as you build them.",
	["beds:bed_bottom"] = beddesc,
	["beds:fancy_bed_bottom"] = beddesc,
	["walls:cobble"] = walldesc,
	["walls:desertcobble"] = walldesc,
	["walls:mossycobble"] = walldesc,
	["stairs:slab_wood"] = slabdesc,
	["stairs:slab_junglewood"] = slabdesc,
	["stairs:slab_pine_wood"] = slabdesc,
	["stairs:slab_acacia_wood"] = slabdesc,
	["stairs:slab_aspen_wood"] = slabdesc,
	["stairs:slab_stone"] = slabdesc,
	["stairs:slab_cobble"] = slabdesc,
	["stairs:slab_stonebrick"] = slabdesc,
	["stairs:slab_sandstone"] = slabdesc,
	["stairs:slab_sandstonebrick"] = slabdesc,
	["stairs:slab_obsidian"] = slabdesc,
	["stairs:slab_obsidianbrick"] = slabdesc,
	["stairs:slab_brick"] = slabdesc,
	["stairs:slab_straw"] = slabdesc,
	["stairs:slab_steelblock"] = slabdesc,
	["stairs:slab_copperblock"] = slabdesc,
	["stairs:slab_bronzeblock"] = slabdesc,
	["stairs:slab_goldblock"] = slabdesc,
	["stairs:stair_wood"] = stairdesc,
	["stairs:stair_junglewood"] = stairdesc,
	["stairs:stair_pine_wood"] = stairdesc,
	["stairs:stair_acacia_wood"] = stairdesc,
	["stairs:stair_aspen_wood"] = stairdesc,
	["stairs:stair_stone"] = stairdesc,
	["stairs:stair_cobble"] = stairdesc,
	["stairs:stair_stonebrick"] = stairdesc,
	["stairs:stair_sandstone"] = stairdesc,
	["stairs:stair_sandstonebrick"] = stairdesc,
	["stairs:stair_obsidian"] = stairdesc,
	["stairs:stair_obsidianbrick"] = stairdesc,
	["stairs:stair_brick"] = stairdesc,
	["stairs:stair_straw"] = stairdesc,
	["stairs:stair_steelblock"] = stairdesc,
	["stairs:stair_copperblock"] = stairdesc,
	["stairs:stair_bronzeblock"] = stairdesc,
	["stairs:stair_goldblock"] = stairdesc,
}

local bonestime = tonumber(minetest.setting_get("share_bones_time"))
local bonestime2 = tonumber(minetest.setting_get("share_bones_time_early"))
local bonesstring, bonesstring2, bonestime_s, bonestime2_s
if bonestime == nil then bonestime = 1200 end
if bonestime2 == nil then bonestime2 = math.floor(bonestime / 4) end

if bonestime == 0 then
	bonesstring = "In this world this can be done without any delay as the bones instantly become old. "
elseif bonestime % 60 == 0 then
	bonestime_s = string.format("%d min", bonestime/60)
else
	bonestime_s = string.format("%d min %d s", bonestime/60, bonestime%60)
end
if bonestime2 == 0 then
	bonesstring2 = ""
elseif bonestime2 % 60 == 0 then
	bonestime2_s = string.format("%d min", bonestime2/60)
else
	bonestime2_s = string.format("%d min %d s", bonestime2/60, bonestime2 % 60)
end

if bonestime ~= 0 then
	bonesstring = "If these are not your bones, you have to wait "..bonestime_s.." before you can do this. "
end
if bonestime2 ~= 0 then
	bonesstring2 = "If the player died in a protected area of someone else, the bones can be dug after "..bonestime2_s..". "
end

help.usagehelp = {
	["default:apple"] = "Hold it in your hand, then leftclick to eat it.",
	["doors:gate_wood_closed"] = fencegateuse,
	["doors:gate_junglewood_closed"] = fencegateuse,
	["doors:gate_acacia_wood_closed"] = fencegateuse,
	["doors:gate_pine_wood_closed"] = fencegateuse,
	["doors:gate_aspen_wood_closed"] = fencegateuse,
	
	["flowers:mushroom_brown"] = "Hold it in your hand, then leftclick to eat it.",
	["flowers:mushroom_red"] = "Hold it in your hand, then leftclick to eat it. But why would you want to do that?",
	["farming:bread"] = "Hold it in your hand, then leftclick to eat it.",
	["default:furnace"] = "Rightclick the furnace to view it. Place a furnace fuel in the lower slot and the source material in the upper slot. The furnace will slowly use its fuel to smelt the item. The result will be placed into the 4 slots at the right side.",
	["default:chest"] = "Rightclick the chest to open it and to exchange items. You can only dig it when the chest is empty.",
	["default:chest_locked"] = "Point it to reveal the name of its owner. Rightclick the chest to open it and to exchange items. This is only possible if you own the chest. You also can only dig the chest when you own it and it is empty.",
	["default:book"] = "Hold the book in hand and leftclick to write some notes. Doing so will turn the book into a “Book With Text” which cannot be stacked.",
	["default:sign_wall_wood"] = signuse,
	["default:sign_wall_steel"] = signuse,
	["default:bookshelf"] = "Rightclick to open the bookshelf. You can store one book per inventory slot. To collect the bookshelf, you must make sure it does not contain any books.",
	["vessels:shelf"] = "Rightclick to open the vessels shelf. You can store one vessel per inventory slot. To collect the vessels shelf, it must be empty.",
	["bucket:bucket_empty"] = "Rightclick on a liquid source while holding the bucket to collect the liquid. Rightclick again somewhere to empty the bucket, this will create a liquid source at the position you've clicked at.",
	["bucket:bucket_water"] = "Rightclick while holding this bucket on any block to empty it.",
	["bucket:bucket_river_water"] = "Rightclick while holding this bucket on any block to empty it.",
	["bucket:bucket_lava"] = "Rightclick while holding this bucket on any block to empty it. Be careful by doing so, lava is dangerous!",

	["bones:bones"] = "Rightclick to access the inventory, dig it to obtain all items immediately. "..bonesstring..bonesstring2.."It is only possible to take from this inventory, nothing can be stored into it.",

	["tnt:gunpowder"] = "Place gunpowder on the ground to create gunpowder trails. Punch it with a torch to light the gunpowder, which will then ignore neighbor gunpowder and TNT.",
	["tnt:tnt"] = "Place the TNT on the ground and punch it with a torch to light it and quickly get in a safe distance before it explodes. A burning gunpowder trail will also ignite the TNT.",

	["doors:trapdoor"] = "Rightclick the trapdoor to open or close it. When the trapdoor is open, use the sneak or use key (depends on your configuration) to climb down, and the jump key to climb up.",
	["doors:trapdoor_steel"] = "Point the steel trapdoor to see who owns it. Rightclick the trapdoor to open or close it (if you own it). When the trapdoor is open, use the sneak or use key (depends on your configuration) to climb down, and the jump key to climb up.",

	["doors:door_wood"] = "Rightclick the door to open or close it.",
	["doors:door_steel"] = "Point the door to see who owns it. Rightclick the door to open or close it (if you own it).",
	["doors:door_glass"] = "Rightclick the door to open or close it.",
	["doors:door_obsidian_glass"] = "Rightclick the door to open or close it.",

	["screwdriver:screwdriver"] = "Leftclick on a block to rotate it around its current axis. Rightclick on a block to rotate its axis.",

	["boats:boat"] = "Place the boat on an even water surface to set it up. Rightclick the boat to enter it. When you are on the boat, use the forward key to speed up, the backward key to slow down and the left and right keys to turn the boat. Rightclick on the boat again to leave it. Leftclick the placed boat to collect it.",
	["beds:bed_bottom"] = beduse,
	["beds:fancy_bed_bottom"] = beduse,
	["farming:seed_wheat"] = "Use a hoe to create soil, wetten the soil, place the seed on wet soil, watch it grow, then harvest it.",
	["farming:seed_cotton"] = "Use a hoe to create soil, wetten the soil, place the seen on wet soil or wet desert sand, watch it grow, then harvest it.",
	["fire:flint_and_steel"] = "Punch with it on a appropriate surface to create a basic flame. A basic flame can only be created inside air. Fires can't be started on fire-extinguishing blocks (such as water). Flint and steel can be used 64 times.",

	["flowers:waterlily"] = "Waterlilies can only be placed water sources and equivalent blocks.",
}

help.generation = {
	["default:nyancat"] = "These blocks are extremely rare. It has been said that it would take an adventurer several years to even find one of these Nyan Cats. Nyan Cats can appear anywhere, it is completely random. However, Nyan Cats are always followed by a trail of Nyan Cat Rainbows.",
	["default:nyancat_rainbow"] = "These blocks are extremely rare. They only appear behind a Nyan Cat, which itself can appear randomly anywhere.",
}
