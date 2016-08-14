# `doc_items` (Version 0.4.0)
## Description
Automatically generated documentation of blocks, tools, weapons, crafting
itms and other items.

The goal is to tell the player as much about basically almost all items as
possible, making it very convenient to look up simple things.

The ultimate goal of this mod is that eventually all relevant items have
a complete in-game documentation so no item leaves you confused.

This mod is useful to learn the hard facts about practically all items, like
how much damage weapon XYZ deals or whether you can dig that block.
This modes does NOT give you long explanations about how to use certain
nontrivial things, like the furnace from Minetest Game. This info might be
provided by other mods and insert it into the documentation system.

This mod provides 3 new categories for the Documentation System [doc]:

* Blocks (e.g. dirt, stone, wooden stair)
* Tools and weapons (e.g. wooden pickaxe, steel sword, screwdriver)
* Misc. items (e.g. dye, stick, flour)

Entries are automatically added. The information in the entries is
mostly automatically generated. It countains information about a wide range
of topics:

For blocks, it tells you about physics, digging properties, drops (including
probabilities), liquid information, pointability, whether it glows in the
dark, how light interacts with it, and much more.
For tools and weapons, it mostly tells you about mining capabilities and
damage.
For all items, their range and stack size is shown.

This mod also allows for mods to adding custom written description
and usage help texts in freeform and even custom automatically generated texts
for mod-specific information like flammability in Minetest Game.

If you find a particular item which is lacking an explanation on usage,
request the mod author to add `doc_items` support. (But please wait
for version 1.0.0 first).

## API
This mod has a programming API for adding your own custom help texts,
your custom factoids (single pieces of information extracted from the
item defintion) and more.

For example, if your mods have some complex items which need
explanation, this mod can help you in adding documentation for them.

Read `API.md` to learn more.

## License
Everything in this mod is licensed under WTFPL.
