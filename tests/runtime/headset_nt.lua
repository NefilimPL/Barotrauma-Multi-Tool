-- Optional NT CS integration; isolated server with NT enabled only.
local G=BMTHeadsets
local results={}
local function check(name,fn)
    local ok,err=pcall(fn)
    results[#results+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[HEADSET NT] '..results[#results])
end
assert(AfflictionPrefab.Prefabs['heartremoved'],'NT not loaded')
local position
for h in Hull.HullList do if h.Submarine==Submarine.MainSub then position=h.WorldPosition;break end end
local c=Character.Create('human',position,'headset-nt',nil,0,false,true,true,nil,true,false)
c.AIController.Enabled=false
local item=Item(ItemPrefab.Prefabs['aegisheadset'],position,nil)
local cell=Item(ItemPrefab.Prefabs['batterycell'],position,nil)
assert(c.Inventory.TryPutItem(item,c,{InvSlotType.Headset}))
assert(item.OwnInventory.TryPutItem(cell,0,false,false,c))
-- Keep this test synchronous: no game/NT time elapses between damage setup
-- and assertions, isolating the paid regeneration from NT's injury cascade.
local function apply(id,value,limb)
    c.CharacterHealth.ApplyAffliction(limb or c.AnimController.MainLimb,AfflictionPrefab.Prefabs[id].Instantiate(value),false,true)
    return c.CharacterHealth.GetAffliction(id)
end
check('NT CS loads without legacy Lua globals',function()
    assert(tostring(AfflictionPrefab.Prefabs['heartremoved'].ContentPackage.Name)=='Neurotrauma CS')
end)
check('actual NT missing organ regenerates after full paid job',function()
    local a=apply('heartremoved',100)
    for i=1,4 do G.heal(c,item,1);assert(a.Strength>0) end
    G.heal(c,item,1);assert(a.Strength==0 and G.energy(item)<100)
end)
check('actual NT amputation flags regenerate after paid job',function()
    cell.Condition=100
    local a=apply('sla_amputation',1)
    for i=1,9 do G.heal(c,item,1);assert(a.Strength>0) end
    G.heal(c,item,1);assert(a.Strength==0)
end)
check('actual NT protective bookkeeping is preserved',function()
    local a=apply('tshocktimeout',10)
    local before=a.Strength
    G.heal(c,item,1);assert(a.Strength==before)
end)
check('actual NT surgical states close together',function()
    cell.Condition=100
    local limb=c.AnimController.GetLimb(LimbType.LeftArm)
    apply('surgeryincision',50,limb);apply('retractedskin',50,limb)
    for i=1,5 do G.heal(c,item,1) end
    assert(c.CharacterHealth.GetAffliction('surgeryincision',limb).Strength==0)
    assert(c.CharacterHealth.GetAffliction('retractedskin',limb).Strength==0)
end)
check('actual NT blood type and cybernetic marker remain intact',function()
    local blood=apply('o_positive',100)
    local cyber=apply('ra_cyber',1)
    local beforeBlood,beforeCyber=blood.Strength,cyber.Strength
    G.heal(c,item,1)
    assert(blood.Strength==beforeBlood and cyber.Strength==beforeCyber)
end)
check('normal NT immunity and blood pressure do not consume power',function()
    local immunity=apply('immunity',45)
    local pressure=apply('bloodpressure',98.5)
    local before=G.energy(item)
    G.heal(c,item,1)
    assert(math.abs(G.energy(item)-before)<.0001)
    assert(immunity.Strength==45 and pressure.Strength==98.5)
end)
check('actual NT hypotension remains paid regeneration',function()
    local pressure=apply('bloodpressure',60)
    local before=G.energy(item)
    G.heal(c,item,1)
    assert(pressure.Strength>60 and G.energy(item)<before)
end)
File.Write('LocalMods/MULTI-TOOL-V2/headset-nt-results.txt',table.concat(results,'\n'))
-- NT initializes blood type with a delayed callback after Character.Create.
-- Do not remove this fixture before that callback has finished.
Timer.Wait(function() if not c.Removed then c.Remove() end end,3000)
