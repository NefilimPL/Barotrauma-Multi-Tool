-- Native dedicated-server hook/parameter conversion probe. No real shop/wallet.
assert(SERVER and Game.RoundStarted)
local G=BMTVacuum
local U=require('CombatTool.util')
local rows={}
local function check(name,fn)
    local ok,err=pcall(fn)
    rows[#rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[MERCHANT SERVER] '..rows[#rows])
    File.Write('LocalMods/MULTI-TOOL-V2/merchant-server-results.txt',table.concat(rows,'\n'))
end
LuaUserData.RegisterType('Barotrauma.CargoManager')
local Manager=LuaUserData.CreateStatic('Barotrauma.CargoManager')
local SoldItem=LuaUserData.CreateStatic('Barotrauma.SoldItem')
local Origin=LuaUserData.CreateEnumTable('Barotrauma.SoldItem+SellOrigin')
local manager=Manager(nil)
local function create(kind) return Item(ItemPrefab.Prefabs[kind],Submarine.MainSub.WorldPosition,nil) end
local pack,page,iron,copper=create('aegisvacuumpack'),create('aegisvacuumpage'),create('iron'),create('copper')
assert(pack.OwnInventory.TryPutItem(page,nil));assert(page.OwnInventory.TryPutItem(iron,nil))
local sales={SoldItem(iron.Prefab,iron.ID,false,0,Origin.Submarine),
    SoldItem(copper.Prefab,copper.ID,false,0,Origin.Submarine),SoldItem(page.Prefab,page.ID,false,0,Origin.Submarine)}
local actual
-- Stop before native wallet access, but observe after every production prefix.
G.patch('merchant-probe-stop','Barotrauma.CargoManager','SellItems',function(_,p) p.PreventExecution=true end)
G.patch('merchant-probe-observe','Barotrauma.CargoManager','SellItems',function(_,p)
    actual={};local list=p['itemsToSell']
    if type(list)=='table' then U.each(list,function(sale) actual[#actual+1]=sale.ID end)
    else for i=0,list.Count-1 do actual[#actual+1]=list[i].ID end end
end,true)
local function run()
    actual=nil;manager.SellItems(Identifier('merchant'),sales,nil)
    assert(actual,'native postfix did not run')
    return actual
end
check('native sale list conversion keeps valid stored and ordinary items, excludes internal page',function()
    local got=run();assert(#got==2 and got[1]==iron.ID and got[2]==copper.ID)
end)
check('native sale hook rejects active salvage before removal',function()
    G.jobs[pack]={};local got=run();G.jobs[pack]=nil
    assert(#got==1 and got[1]==copper.ID and not iron.Removed)
end)
check('native sale hook rejects pending products before removal',function()
    G.pending[pack]={};local got=run();G.pending[pack]=nil
    assert(#got==1 and got[1]==copper.ID and not iron.Removed)
end)
check('native sale hook rejects reserved input before removal',function()
    G.reserved[iron]=true;local got=run();G.reserved[iron]=nil
    assert(#got==1 and got[1]==copper.ID and not iron.Removed)
end)
-- Remove only this probe's hooks. Leave production hooks intact.
Hook.RemovePatch('bmt.vacuum.merchant-probe-stop','Barotrauma.CargoManager','SellItems',Hook.HookMethodType.Before)
Hook.RemovePatch('bmt.vacuum.merchant-probe-observe','Barotrauma.CargoManager','SellItems',Hook.HookMethodType.After)
