-- Test only: verify the exact native typed-dictionary bridge before enabling hooks.
assert(CLIENT,'run this typed-dictionary probe on the isolated client')
local U=require('CombatTool.util')
local descriptor=LuaUserData.RegisterType('Barotrauma.Items.Components.Fabricator')
LuaUserData.MakeFieldAccessible(descriptor,'availableIngredients')
LuaUserData.MakeFieldAccessible(descriptor,'user')
LuaUserData.RegisterType('System.Collections.Generic.Dictionary`2[[Barotrauma.Identifier, BarotraumaCore],[System.Collections.Generic.List`1[[Barotrauma.Item, Barotrauma]], System.Private.CoreLib]]')
local f
for item in Item.ItemList do f=U.component(item,'Fabricator');if f then break end end
assert(f,'no native fabricator')
local d=f.availableIngredients
assert(type(d)=='userdata','native dictionary was copied to Lua')
local old=d.ContainsKey('iron') and d['iron'] or nil
local sample=Item(ItemPrefab.Prefabs['iron'],f.Item.WorldPosition,nil)
d['iron']={sample}
assert(#d['iron']==1 and d['iron'][1]==sample,'typed indexer did not write native collection')
if old then d['iron']=old else d.Remove('iron') end
VacuumCraftingProbe={fabricator=f,sample=sample}
print('[VACUUM CRAFTING] PASS typed native dictionary accepts dense item references')
