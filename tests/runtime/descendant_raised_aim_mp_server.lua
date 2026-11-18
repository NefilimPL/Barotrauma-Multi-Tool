-- Isolated loopback acceptance: real authoritative arm, native floor and client.
assert(SERVER and Game.RoundStarted)
local G=BMTDescendantSuit;local P='bmt.raised.aim.mp'
local R={rows={},passed=0,failed=0,shots=0,unsafe=0};ServoRaisedAimMP=R
local function log(s) R.rows[#R.rows+1]=s;print('[RAISED MP] '..s);File.Write('LocalMods/MULTI-TOOL-V2/raised-aim-mp-server.txt',table.concat(R.rows,'\n')) end
local function state() return G.state(R.suit) end
local function phase(n)
    G.setMode(R.suit,'off',R.wearer);R.phase=n;R.before=R.shots;R.unsafe=0
    local m=Networking.Start(P..'.phase');m.WriteByte(n)
    for _,k in ipairs({'suit','ally','enemy'}) do m.WriteUInt16(R[k].ID) end
    Networking.Send(m,R.client.Connection)
end
Hook.Patch(P..'.shots','Barotrauma.Items.Components.Projectile','Shoot',function(projectile)
    if projectile.Item.Prefab.Identifier.Value~='descendantpulsebolt' or not R.suit then return end
    R.shots=R.shots+1
    if R.phase==2 or R.phase==4 then
        local p=G.toolPose(R.wearer,state());local head=R.ally.AnimController.GetLimb(LimbType.Head)
        if not state().combatAim or not state().combatAim.raised or p.muzzle.y<=head.WorldPosition.Y then R.unsafe=R.unsafe+1 end
    end
end,Hook.HookMethodType.Before)
Networking.Receive(P..'.hello',function(_,client)
    if R.client then return end
    R.client=client;R.wearer=assert(client.Character);local c=R.wearer;c.GodMode=true;c.SetAllDamage(0,0,0)
    for h in Hull.HullList do
        if h.Submarine==Submarine.MainSub and h.Rect.Width>850 and (not R.room or h.Rect.Height>R.room.Rect.Height) then R.room=h end
    end
    assert(R.room,'no broad dry chamber')
    local q=R.room.WorldRect;R.home=Vector2(q.X+150,q.Y-q.Height+90)
    for other in Character.CharacterList do if other~=c then Entity.Spawner.AddEntityToRemoveQueue(other) end end
    for item in Item.ItemList do
        local p=item.WorldPosition
        if not item.ParentInventory and item.Submarine==R.room.Submarine and p.X>q.X+50 and p.X<q.X+800 and p.Y<q.Y and p.Y>q.Y-q.Height then Entity.Spawner.AddEntityToRemoveQueue(item) end
    end
    local old={};for item in c.Inventory.AllItems do old[#old+1]=item end
    for _,item in ipairs(old) do item.Drop(c,true);Entity.Spawner.AddEntityToRemoveQueue(item) end
    c.TeleportTo(R.home)
    Hook.Add('think',P..'.air',function()
        for h in Hull.HullList do h.WaterVolume=0;h.Oxygen=10000000 end
        c.Oxygen=100;if R.ally then R.ally.Oxygen=100 end;if R.enemy then R.enemy.Oxygen=100 end
    end)
    Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['descendantservosuit'],c.Inventory,nil,nil,function(suit)
        R.suit=suit;assert(c.Inventory.TryPutItem(suit,c,{InvSlotType.OuterClothes}))
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['batterycell'],G.container(suit,1),nil,nil,function(cell) R.cell=cell end,false)
        Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs['pulselaserammobox'],c.Inventory,nil,nil,function(box) assert(G.container(suit,1).TryPutItem(box,1,false,false,c));R.box=box end,false)
    end,false)
    Entity.Spawner.AddCharacterToSpawnQueue('human',R.home+Vector2(550,0),function(h) h.TeamID=CharacterTeamType.Team2;h.AIController.Enabled=false;h.GodMode=true;R.enemy=h end)
    Entity.Spawner.AddCharacterToSpawnQueue('human',R.home-Vector2(100,0),function(h) h.TeamID=c.TeamID;h.AIController.Enabled=false;R.ally=h;R.health=h.CharacterHealth.Vitality end)
    local function ready()
        if not R.suit or not R.cell or not R.box or not R.ally or not R.enemy then Timer.Wait(ready,100);return end
        log('READY room='..R.room.Rect.Width..'x'..R.room.Rect.Height..' server_authority='..tostring(G.authoritative));Timer.Wait(function() phase(1) end,1200)
    end
    ready()
end)
Networking.Receive(P..'.report',function(m,client)
    local n,clientOK,detail=m.ReadByte(),m.ReadBoolean(),m.ReadString()
    if client~=R.client or n~=R.phase then return end
    local ok,result=pcall(function()
        assert(not R.wearer.AnimController.InWater,'wearer in water')
        assert(R.shots>R.before,'no native pulse shot')
        assert(R.ally.CharacterHealth.Vitality>=R.health-.01,'ally injured')
        local high=n==2 or n==4
        assert(state().combatAim and state().combatAim.raised==high,'unexpected arm plan')
        assert(R.unsafe==0,'low shot during raised stage')
        return 'shots='..(R.shots-R.before)..' raised='..tostring(high)..' allyVitality='..R.ally.CharacterHealth.Vitality
    end)
    ok=ok and clientOK
    if ok then R.passed=R.passed+1 else R.failed=R.failed+1 end
    log((ok and 'PASS ' or 'FAIL ')..n..' server='..tostring(result)..' client='..detail)
    if n==4 then
        G.setMode(R.suit,'off',R.wearer);Hook.Remove('think',P..'.air');Hook.RemovePatch(P..'.shots','Barotrauma.Items.Components.Projectile','Shoot',Hook.HookMethodType.Before)
        log('RESULT passed='..R.passed..' failed='..R.failed..' real_joined_client=true')
        local done=Networking.Start(P..'.done');Networking.Send(done,R.client.Connection)
    else
        local side=n==1 or n==3
        R.ally.TeleportTo(R.wearer.WorldPosition+Vector2(side and 90 or -150,0))
        Timer.Wait(function() phase(n+1) end,300)
    end
end)
log('WAITING real joined client')
