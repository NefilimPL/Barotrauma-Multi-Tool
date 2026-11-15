-- Diagnostic only: run on the disposable dedicated server after round start.
-- Measures the production headset against native coil attacks and other spam.
local G=assert(BMTHeadsets)
local U=require('CombatTool.util')
local position=Submarine.MainSub.WorldPosition
for hull in Hull.HullList do
    if hull.Submarine==Submarine.MainSub then position=hull.WorldPosition;break end
end
local objects,rows={},{}
local limited=require('AegisHeadset.config').powerRate~=nil
local function track(o) objects[#objects+1]=o;return o end
local function wearer(label)
    local c=track(Character.Create('human',position,label,nil,0,false,true,true,nil,true,false))
    c.AIController.Enabled=false;c.Enabled=true
    local item=track(Item(ItemPrefab.Prefabs['aegisheadsetmk2'],position,nil))
    local cell=track(Item(ItemPrefab.Prefabs['batterycell'],position,nil))
    assert(c.Inventory.TryPutItem(item,c,{InvSlotType.Headset}))
    assert(item.OwnInventory.TryPutItem(cell,0,false,false,c))
    return c,item,cell
end
local function sample(label,item)
    local row=string.format('%s energy=%.4f',label,G.energy(item))
    rows[#rows+1]=row;print('[HEADSET SPAM] '..row)
end
local function probe(label,fn)
    local ok,err=pcall(fn)
    if not ok then rows[#rows+1]='ERROR '..label..': '..tostring(err) end
end
probe('native coil',function()
    local c,item=wearer('coil-spam')
    local coil=track(Item(ItemPrefab.Prefabs['dischargecoil'],position,nil))
    local d=LuaUserData.RegisterType('Barotrauma.Items.Components.ElectricalDischarger')
    LuaUserData.MakeFieldAccessible(d,'attack')
    local attack=assert(U.component(coil,'ElectricalDischarger').attack)
    sample('native coil before',item)
    for i=1,6 do
        c.ApplyAttack(nil,position,attack,1,Vector2.Zero,false)
        sample('native coil hit '..i,item)
    end
    if limited then assert(math.abs(G.energy(item)-95)<.001 and c.Stun==0 and not c.IsDead) end
end)
probe('other repeated effects',function()
    for _,id in ipairs({'burn','stun','internaldamage'}) do
        local c,item=wearer(id..'-spam')
        sample(id..' before',item)
        for i=1,1000 do
            c.AddDamage(position,{AfflictionPrefab.Prefabs[id].Instantiate(1)},0,false,Vector2.Zero,nil,1)
        end
        sample(id..' after 1000 calls in one frame',item)
        if limited then assert(math.abs(G.energy(item)-95)<.001 and c.Stun==0 and not c.IsDead) end
    end
end)
local function finish()
    File.Write('LocalMods/MULTI-TOOL-V2/headset-power-spam-results.txt',table.concat(rows,'\n'))
    -- NT initializes blood type on a timer after character creation.
    Timer.Wait(function()
        for i=#objects,1,-1 do if not objects[i].Removed then objects[i].Remove() end end
    end,3000)
    print('[HEADSET SPAM] COMPLETE')
end
if limited then
    probe('normal healing with small positive remainder',function()
        local c,item,cell=wearer('small-remainder')
        cell.Condition=5.1
        c.AddDamage(position,{AfflictionPrefab.Prefabs['burn'].Instantiate(100)},0,false,Vector2.Zero,nil,1)
        c.CharacterHealth.ApplyAffliction(c.AnimController.MainLimb,AfflictionPrefab.Prefabs['burn'].Instantiate(20))
        G.heal(c,item,1)
        local burn=c.CharacterHealth.GetAfflictionStrengthByIdentifier('burn',true)
        assert(burn<.001,'discounted treatment slowed with positive power: '..burn)
        assert(math.abs(G.energy(item)-.1)<.001)
        sample('normal healing with small positive remainder',item)
    end)
    local c,item=wearer('sustained-spam')
    local started=G.now;local frames=0
    Hook.Add('think','bmt.test.headset.power-spam',function()
        local elapsed=G.now-started
        if elapsed>=5 then
            Hook.Remove('think','bmt.test.headset.power-spam')
            probe('sustained spam',function()
                sample(string.format('mixed spam %.4fs %d frames',elapsed,frames),item)
                assert(G.energy(item)>=100-5-5*elapsed-.001,'sustained drain exceeded limit')
                assert(G.energy(item)<90,'sustained test did not exercise refill')
            end)
            finish();return
        end
        frames=frames+1
        c.AddDamage(position,{AfflictionPrefab.Prefabs['burn'].Instantiate(100)},0,false,Vector2.Zero,nil,1)
        G.heal(c,item,1/60);G.spend(item,1,'probe:combined-pressure')
    end)
else finish() end
