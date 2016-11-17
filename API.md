# API documentation for `doc_items` (Version 0.7.0)
## Introduction
This document explains the API of `doc_items`. It contains a reference of
all functions.

***Warning***: This mod is still in alpha stage, expect bugs and missing
features!

## Quick start
The most common use case for using this API requires only to set some
hand-written help texts for your items.

The preferred way is to add the following optional fields to the
item definition when using `minetest.register_node`, etc.:

* `_doc_items_longdesc`: Long description of this item.
  Describe here what this item is, what it is for, its purpose, etc.
* `_doc_items_usagehelp`: Description of *how* this item can be used.
  Only set this if needed, e.g. standard mining tools don't need this.

Example:

    minetest.register_node("example:dice", {
        description = "Dice",
        _doc_items_longdesc = "A decorative dice which shows the numbers 1-6 on its sides.",
        _doc_items_usagehelp = "Rightclick the dice to roll it.",
        tiles = { "example_dice.png" },
        is_ground_content = false,
        --[[ and so on … ]]
    })

When using this method, your mod does not need additional dependencies.

See below for some recommendations on writing good help texts.

If you need to set the help texts of nodes you don't register, or you
want to overwrite existing help texts, use `doc.sub.items.set_items_longdesc`
and `doc.sub.items.set_items_longdesc` (see below).
If you need more customization, read ahead. ;-)

## Concepts
### Factoids
Basically, a factoid is usually a single sentence telling the player a specific
fact about the item. The task of each factoid is to basically convert parts
of the item definition to useful, readable, understandable text.

Example: It's a fact that `default:sand` has the group `falling_node=1`.
A factoid for this is basically just a simple conditional which puts the
the sentence “This block is affectet to gravity and can fall.” into the
text if the node is member of said group.

Factoids can be more complex than that. The factoid for node drops needs to
account for different drop types and probabilities, etc.

`doc_items` has many predefined factoids already. This includes all “special”
groups (like `falling_node`), drops, mining capabilities, punch interval,
and much more.

Custom factoids can be added with `doc.sub.items.register_factoid`.

The idea behind factoids is to generate as much information as possible
automatically to reduce reduncancy, inconsistencs and the workload of hand-
written descriptions.

### Long description and usage help
Factoids are not always sufficient to describe an item. This is the case
for facts where the item definition can not be used to automatically
generate texts. Examples: Custom formspecs, ABMs, special tool action
on rightclick.

That's where the long description and usage help comes into play.
Those are two texts which are written manually for a specific item.

Roughly, the long description is for describing **what** the item is, how it
acts, what it is for. The usage help is for explaining **how** the
item can be used. It is less important for standard mining tools and weapons.

There is no hard length limit for the long description and the usage help.

#### Recommendations for long description
The long description should roughly contain the following info:

* What the item does
* What it is good for
* How it may be generated in the world
* Maybe some background info if you're in a funny mood
* Notable information which does't fit elsewhere

The desciption should normally **not** contain:

* Information which is already covered by factoids, like digging groups,
  damage, group memberships, etc.
* How the item can be used
* Direct information about other items
* Any other redundant information
* Crafting recipes

One exception from the rule may be for highlighting the most important
purpose of a simple item, like that coal lumps are primarily used as fuel.

Sometimes, a long description is not neccessary because the item is already
exhaustively explained by factoids.

For very simple items, consider using one of the template texts (see below).

Minimal style guide: Use complete sentences.

#### Recommendations for usage help
The usage help should only be set for items which are in some way special
in their usage. Standard tools and weapons should never have an usage help.

The rule of thumb is this: If a new player who already knows the Minetest
basics, but not this item, will not direcly know how to use this item,
then the usage help should be added. If basic Minetest knowledge or
existing factoids are completely sufficient, usage help should not be added.

The recommendations for what not to put into the usage help is the same
as for long descriptions.

#### Template texts
For your convenience, a few template texts are provided for common texts
to avoid redundancy and to increase consistency for simple things. Read
`init.lua` to see the actual texts.

##### Long description
* `doc.sub.items.temp.build`: For building blocks like the brick block in Minetest Game
* `doc.sub.items.temp.deco`: For other decorational blocks.
* `doc.sub.items.temp.craftitem`: For items solely or almost solely used for crafting

##### Usage help
* `doc.sub.items.temp.eat`: For eatable items using the `on_use=minetest.item_eat(1)` idiom
* `doc.sub.items.temp.eat_bad`: Same as above, but eating them is considered a bad idea

### Forced and suppressed items
By default, an entry for each item is added, except for items without a
description (`description == nil`). This default behaviour can be changed.

Entries can be forced, which means they will be forcefully added, against the
default behaviour. Entries can be suppressed which means they will not
be added at all.

The default behaviour can be overridden by two ways: Groups and a function call.

Use groups when you can directly define an item (in other words, in **your**
mods).

To force the entry of an item, add the item to the group `in_doc = 1`.
To suppress the entry of an item, add the item to the group `not_in_doc = 1`.

There are also the functions `doc.sub.items.add_forced_item_entries` and
`doc.sub.items.add_suppressed_item_entries` which forces or suppress certain
item entries. You should **only** use these functions when you can not use groups.

When there are contradictions, forcing a group takes precedence over suppressing
a group.

### Hidden entries
Hidden entries are entries which are not visible in the list of entries. This
concept directly comes from the Documentation System. The entry will still be
created, it is just not selectable by normal means. Players might be able to
“unlock” an entry later. Refer to the API documentation of the Documentation
System to learn more.

To hide an entry, add the item in question to the group `hidden_from_doc = 1`.
If this is not possible, use `doc.sub.items.add_hidden_item_entries`.

## New item fields
This mod adds support for new fields of the item definition:

* `_doc_items_longdesc`: Long description
* `_doc_items_usagehelp`: Usage help
* `_doc_items_image`: Entry image (default: inventory image)
* `_doc_items_hidden`: Whether entry is hidden (default: `false` for Air, `true` for everything else)
* `_doc_items_create_entry`: Whether to create an entry for this item (default: `true`)
* `_doc_items_entry_name`: The title of the entry. By default, this is the same as the `description` field
  of the item, or “Nameless entry” if it is `nil`.

## Functions
This is the reference of all available functions in this API.

### `doc.sub.items.set_items_longdesc(longdesc_table)`
Sets the long description of items. `longdesc_table` is
a table where the keys are the itemstrings and the values
are the the description strings for each item.

Note the preferred method to set the long description is by using
the item definition field `_doc_items_longdesc`.

This function is intended to be used to set the long description
for items which your mods do not register by themselves.

#### Default long descriptions
`doc_items` registers two long descriptions by default: For air
and the hand (default tool).
By using this function, you can overwrite these default descriptions.

The default hand description is kept very generic, but it might miss
some information on more complex subgames. In this case, the hand's
long description might need overwriting.

#### Example
    doc.sub.items.set_items_longdesc({
         ["example:painter"] = "Paints blocks.",
         ["example:flower"] = "Likes to grow on grass when it is near water.",
    })

### `doc.sub.items.set_items_usagehelp(usagehelp_table)`
Sets the usage help texts of items. The function is completely analog
to `doc.sub.items.set_items_longdesc` and has the same syntax, it
only differs in semantics.

#### Example
    doc.sub.items.set_items_usagehelp({
         ["example:painter"] = "Punch any block to paint it red.",
    })

### `doc.sub.items.register_factoid(category_id, factoid_type, factoid_generator)`
***Note***: This function not fully implemented. It currently supports only
factoids for nodes.

Add a custom factoid (see above) for the specified category.

* `category_id`: The documentation category fow which the factoid applies:
    * `"nodes"`: Blocks
    * `"tools"`: Tools and weapons (***Not yet supported***)
    * `"craftitems"`: Misc. items (***Not yet supported***)
* `factoid_type`: Rough categorization of the factoid's content. Controls
  where in the text the factoid appears. Possible values:
    * `"groups"`: Factoid appears near groups
    * **(more to come)**
* `factoid_generator`: A function which turns item definition into a string
  (see blow)

#### `factoid_generator(itemstring, def)`
`itemstring` is the itemstring of the item to be documented, and `def` is the
complete item definition table (from Minetest).

This function must return a helpful string which turns a part of the item's
definition into an useful sentence or text. The text can contain newlines,
but it must not end with a newline.

This function must **always** return a string. If you don't want to add any text,
return the empty string.

Style guide: Try to use complete sentences and avoid too many newlines.

#### Example
This factoid will add the sentence “This block will extinguish nearby fire.”
to all blocks which are member of the group `puts_out_fire`.

    doc.sub.items.register_factoid("nodes", "groups", function(itemstring, def)
        if def.groups.puts_out_fire ~= nil then
            return "This block will extinguish nearby fire."
        else
            return ""
        end
    end)

### `doc.sub.items.add_friendly_group_names(groupnames)`
Use this function so set some more readable group names to show them
in the formspec, since the internal group names are somewhat cryptic
to players.

`groupnames` is a table where the keys are the “internal” group names and
the values are the group names which will be actually shown in the
Documentation System.

***Note***: This function is mostly there to work around a problem in
Minetest as it does not support “friendly” group names, which means exposing
groups to an interface is not pretty. Therefore, this function may be
deprecated when Minetest supports such a thing.

### `doc.sub.items.get_group_name(internal_group_name)`
Returns the group name of the specified group as displayed by this mod.
If the setting `doc_items_friendly_group_names` is `true`, this might
return a “friendly” group name (see above). If no friendly group name
exists, `internal_group_name` is returned.
If `doc_items_friendly_group_names` is `false`, the argument is always
returned.

### `doc.sub.items.add_notable_groups(groupnames)`
Add a list of groups you think are notable enough to be mentioned in the
“This item belongs to the following groups: (…)” factoid.

`groupnames` is a table of group names.

By default, no groups are shown for this factoid which means this factoid
is never displayed.

What is “notable” is subjective, but here's a rule of thumb you may follow:

You should add groups with this function if:

* This group is used for crafting purposes
* This group is somehow important for interaction
* This group appears in `connect_to` definitions of nodes

Do not add groups if:

* The group is only used internally
* The group is unteresting for the player
* A factoid covering this group already exists
* Writing a factoid would be more useful
* The group is a mining or damage group
* Rating is important to gameplay (consider writing a factoid instead)

The intention of this function is to give a short rundown of the groups
which are notable as they are important to gameplay in some way yet don't
deserve a full-blown factoid.

### `doc.sub.items.add_forced_item_entries(itemstrings)`
Adds items which will be forced to be added to the entry list, even if
the item is not in creative inventory.

`itemstrings` is a table of itemstrings of items to force the entries for.

***Note***: The recommended way to force item entries is by adding the item
to the group `in_doc=1` (see above). Only use this function when you can
not use groups.

### `doc.sub.items.add_suppressed_item_entries(itemstrings)`
Adds items which will be forced to **not** be added to the entry list.

`itemstrings` is a table of itemstrings of items to force the entries for.

***Note***: The recommended way to suppress item entries is by adding the
item to the group `not_in_doc=1` (see above). Only use this function when you
can not use groups.

### `doc.sub.items.add_hidden_item_entries(itemstrings)`
Adds items which will be hidden from the entry list initially. Note the
entries still exist and might be unlocked later.

`itemstrings` is a table of itemstrings of items for which their entries should
be hidden.

***Note***: The recommended way to hide item entries is by adding the
item to the group `hide_from_doc=1` (see above). Only use this function when you
can not use groups.

### `doc.sub.items.add_item_name_overrides(itemstrings)`
Overrides the entry names of entries to the provided names. By default,
each entry name equals the item's `description` field.

`itemstrings` is a table in which the keys are itemstrings and the values
are the entry titles you want to use for those items.

#### Preset overrides
The following item name overrides are defined by default:

    { [""] = "Hand", 
      ["air"] = "Air" }

It is possible to override **these** names, just use the function normally.

#### Example
    doc.sub.items.add_item_name_overrides({
        ["air"] = "Air", -- original description: “Air (You hacker you!)”
        ["farming:wheat_8"] = "Wheat Plant", -- Item description was empty
        ["example:node"] = "My Custom Name",
    })


