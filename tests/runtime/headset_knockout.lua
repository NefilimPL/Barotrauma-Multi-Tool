-- Disposable NT CS server. Assert real physiology, not just loaded XML/DLL.
local G=BMTHeadsets
LuaUserData.RegisterType('Neurotrauma.NTHuman')
local NT=LuaUserData.CreateStatic('Neurotrauma.NTHuman')
local room
for h in Hull.HullList do if h.Submarine==Submarine.MainSub and (not room or h.Rect.Width>room.Rect.Width) then room=h end end
assert(room);room.WaterVolume=0;room.Oxygen=100000000
local patients,rows={},{}
local function make(label,model)
    local pos=Vector2(room.WorldPosition.X+(#patients-3)*25,room.WorldPosition.Y)
    local c=Character.Create('human',pos,label,nil,0,false,true,true,nil,true,false)
    c.TeamID=CharacterTeamType.Team1;c.AIController.Enabled=false
    local item=Item(ItemPrefab.Prefabs[model or 'aegisheadsetmk2'],pos,nil)
    local cell=Item(ItemPrefab.Prefabs['batterycell'],pos,nil)
    assert(c.Inventory.TryPutItem(item,c,{InvSlotType.Headset}))
    assert(item.OwnInventory.TryPutItem(cell,0,false,false,c))
    local p={label=label,c=c,item=item,cell=cell,offset=(#patients-3)*25,ticks=0,incap=0,maxIncap=0}
    patients[#patients+1]=p;return p
end
local symptom=make('NT unconsciousness')
local coma=make('NT coma')
local critical=make('critical burn')
local empty=make('empty cell')
local basic=make('mudraptor basic','aegisheadset')
local mk2=make('mudraptor MkII')
local idle=make('healthy idle')
-- Installed NT's integer delay postpones its final two character entries120s.
local raptor=Character.Create('mudraptor',Vector2(room.WorldPosition.X+100000,room.WorldPosition.Y),'knockout-attacker',nil,0,false,true,true,nil,true,false)
local sentinel=Character.Create('crawler',Vector2(room.WorldPosition.X+100000,room.WorldPosition.Y),'knockout-sentinel',nil,0,false,true,true,nil,true,false)
Hook.Patch('bmt.test.knockout-enable','Barotrauma.Character','Update',function(c)
    for _,p in ipairs(patients) do
        if c==p.c then
            c.Enabled=true
            -- Follow the moving submarine; a fixed world point leaves its hull.
            c.TeleportTo(Vector2(room.WorldPosition.X+p.offset,room.WorldPosition.Y))
            p.incap=c.IsIncapacitated and p.incap+1/60 or 0
            p.maxIncap=math.max(p.maxIncap,p.incap)
        end
    end
end,Hook.HookMethodType.Before)
Hook.Patch('bmt.test.nt-post-count','Neurotrauma.NTHuman','PostHook',function(nt)
    for _,p in ipairs(patients) do if nt.Human==p.c then p.ticks=p.ticks+1 end end
end,Hook.HookMethodType.After)
local function check(name,fn)
    local ok,err=pcall(fn)
    rows[#rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
    print('[HEADSET KNOCKOUT] '..rows[#rows])
end
local function apply(p,id,value)
    p.c.CharacterHealth.ApplyAffliction(p.c.AnimController.MainLimb,AfflictionPrefab.Prefabs[id].Instantiate(value),false,true)
end
local function strength(p,id)
    local a=p.c.CharacterHealth.GetAffliction(id)
    return a and a.Strength or 0
end
local function recovered(p)
    assert(p.ticks>=3,'NT physiology did not run')
    assert(not p.c.IsDead and not p.c.IsIncapacitated and not p.c.IsKnockedDown and p.c.Stun==0,
        'dead='..tostring(p.c.IsDead)..' stun='..p.c.Stun..' vitality='..p.c.Vitality)
    assert(strength(p,'unconsciousness')==0 and strength(p,'givein')==0,'NT knockout remains')
    assert(G.energy(p.item)>0 and G.energy(p.item)<100,'recovery must consume real power')
end
Timer.Wait(function()
    for _,p in ipairs(patients) do
        assert(NT.getNTHumanFromCharacter(p.c),'NT patient missing')
        p.c.CharacterHealth.SetAllDamage(0,0,0);p.cell.Condition=100
    end
    for _,p in ipairs({symptom,coma,empty}) do apply(p,'unconsciousness',100);p.c.SetStun(5,true) end
    apply(coma,'coma',60)
    apply(critical,'burn',125)
    check('critical fixture alive below zero vitality',function() assert(not critical.c.IsDead and critical.c.IsUnconscious) end)
    empty.cell.Condition=0
    local attack
    for limb in raptor.AnimController.Limbs do if limb.attack then attack=limb.attack;break end end
    assert(attack,'no mudraptor bite attack')
    for _,p in ipairs({basic,mk2}) do
        local head=p.c.AnimController.GetLimb(LimbType.Head)
        p.c.ApplyAttack(raptor,head.WorldPosition,attack,1/60,Vector2.Zero,false,head,0)
    end
    check('MkII absorbs actual mudraptor bite',function() assert(mk2.c.Vitality==100 and mk2.c.Stun==0 and G.energy(mk2.item)<100) end)
    check('basic model receives actual mudraptor bite',function() assert(basic.c.Vitality<100 or basic.c.Stun>0) end)
    Timer.Wait(function()
        check('NT unconsciousness recovers within8s',function() recovered(symptom);assert(symptom.maxIncap<5,'continuous incapacitation exceeded5s') end)
    end,8000)
    Timer.Wait(function()
        check('NT coma and its knockout recover within15s',function() recovered(coma);assert(strength(coma,'coma')==0) end)
        check('critical patient recovers without stun starving the wound',function() recovered(critical);assert(critical.c.Vitality>0) end)
        check('empty cell cannot cure NT knockout',function()
            assert(empty.ticks>=3 and G.energy(empty.item)==0 and strength(empty,'unconsciousness')>0 and empty.c.IsIncapacitated)
        end)
    end,15000)
    Timer.Wait(function()
        check('healthy NT patient has zero idle drain over20s',function() assert(idle.ticks>=8 and G.energy(idle.item)==100 and idle.c.Vitality==100) end)
        for _,p in ipairs(patients) do
            rows[#rows+1]=string.format('STATE %s ticks=%d energy=%.4f vitality=%.4f down=%s maxIncap=%.3f hull=%s',p.label,p.ticks,G.energy(p.item),p.c.Vitality,tostring(p.c.IsKnockedDown),p.maxIncap,tostring(p.c.AnimController.CurrentHull))
            if p==idle then
                for _,d in ipairs(G.state(p.item).debits or {}) do rows[#rows+1]='IDLE DEBIT '..d.reason..' '..d.amount end
            end
        end
        File.Write('LocalMods/MULTI-TOOL-V2/headset-knockout-results.txt',table.concat(rows,'\n'))
        Hook.RemovePatch('bmt.test.knockout-enable','Barotrauma.Character','Update',Hook.HookMethodType.Before)
        Hook.RemovePatch('bmt.test.nt-post-count','Neurotrauma.NTHuman','PostHook',Hook.HookMethodType.After)
        for _,p in ipairs(patients) do p.c.Remove() end
        raptor.Remove();sentinel.Remove()
    end,20000)
end,3000)
