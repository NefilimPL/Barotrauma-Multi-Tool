-- TEST ONLY. Item-specific fixtures and proof counters for the shared scene.
local M={}
function M.install(R,A)
    local D,V,C,H,U=A.D,A.V,A.C,A.H,A.U
    local function sampled() return R.started and A.now()-R.started>=5 end
    local function credit(value,amount)
        if not sampled() then return end
        for _,a in ipairs(R.actors) do
            if a.item==value or a.pack==value then a.work=a.work+amount;return end
        end
    end
    if C then local fire=C.fire;C.fire=function(s,ctx)
        local count=#C.rings;fire(s,ctx)
        if #C.rings>count then credit(s.item,1) end
    end end
    if D then local hold=D.hold;D.hold=function(owner,value,target,dt)
        local ok=hold(owner,value,target,dt);if ok then credit(value,dt) end;return ok
    end end
    if H then local debit=H.recordDebit;H.recordDebit=function(value,amount,reason)
        debit(value,amount,reason)
        for _,a in ipairs(R.actors) do if a.item==value then
            if a.testMode=='heal' and type(reason)=='string' and reason:sub(1,5)=='heal:' then
                credit(value,amount/(a.testKind=='aegisheadsetmk2' and .05 or .125))
            elseif a.testMode=='pressure' and reason=='pressure' then credit(value,amount) end
            break
        end end
    end end
    if V then local insert=V.insert;V.insert=function(pack,value,...)
        local ok=insert(pack,value,...)
        if ok then for _,a in ipairs(R.actors) do
            if a.pack==pack and a.testMode=='vacuum' then credit(pack,1);break end
        end end
        return ok
    end
    local snapshot=V.snapshot;V.snapshot=function(ctx,view)
        local result=snapshot(ctx,view)
        if R.phase and R.phase.mode=='panel' then credit(ctx.pack,1) end
        return result
    end end
    local fixing={}
    Hook.Patch('bmt.performance.repair.before','Barotrauma.Items.Components.Repairable','Update',function(r)
        if not sampled() or not R.phase or R.phase.mode~='repair' or R.phase.item=='descendantservosuit' then return end
        for _,a in ipairs(R.actors) do if a.device==r.Item then fixing[r]={actor=a,before=r.Item.Condition};break end end
    end,Hook.HookMethodType.Before)
    Hook.Patch('bmt.performance.repair.after','Barotrauma.Items.Components.Repairable','Update',function(r)
        local entry=fixing[r];if not entry then return end;fixing[r]=nil
        entry.actor.work=entry.actor.work+math.max(0,r.Item.Condition-entry.before)
    end,Hook.HookMethodType.After)
    local wallUses, wallChanges = {}, {}
    Hook.Patch('bmt.performance.wall.before','Barotrauma.Items.Components.RepairTool','Use',function(tool)
        if not sampled() then return end
        for _,a in ipairs(R.actors) do
            if a.item==tool.Item and a.wall and (a.testMode=='weld' or a.testMode=='cut') and
                (not C or not C.isWeapon or not C.isWeapon(a.item) or C.toolComponent(a.item,a.testMode)==tool) then
                wallUses[#wallUses+1]={tool=tool,actor=a};return
            end
        end
    end,Hook.HookMethodType.Before)
    Hook.Patch('bmt.performance.wall.after','Barotrauma.Items.Components.RepairTool','Use',function(tool)
        local entry=wallUses[#wallUses]
        if entry and entry.tool==tool then wallUses[#wallUses]=nil end
    end,Hook.HookMethodType.After)
    -- Follow the native ray's actual section during the synchronous tool use.
    -- Fixture damage outside Use and walls on other submarines do not count.
    local damageOverload={'System.Int32','System.Single','Barotrauma.Character','System.Boolean','System.Boolean'}
    Hook.Patch('bmt.performance.wall.damage.before','Barotrauma.Structure','AddDamage',damageOverload,function(wall,p)
        local use=wallUses[#wallUses]
        if not use then return end
        local section=p['sectionIndex']
        wallChanges[#wallChanges+1]={wall=wall,section=section,before=wall.SectionDamage(section),actor=use.actor}
    end,Hook.HookMethodType.Before)
    Hook.Patch('bmt.performance.wall.damage.after','Barotrauma.Structure','AddDamage',damageOverload,function(wall)
        local hit=wallChanges[#wallChanges]
        if not hit or hit.wall~=wall then return end
        wallChanges[#wallChanges]=nil
        if wall.Submarine~=hit.actor.wall.Submarine then return end
        local delta=wall.SectionDamage(hit.section)-hit.before
        credit(hit.actor.item,math.max(0,hit.actor.testMode=='cut' and delta or -delta))
    end,Hook.HookMethodType.After)
    local function nativeShot(projectile)
        if not sampled() then return end
        for _,a in ipairs(R.actors) do
            if a.testKind=='smg' and projectile.Launcher==a.item then credit(a.item,1);return end
        end
    end
    for _,method in ipairs({'DoLaunch','DoHitscan'}) do
        Hook.Patch('bmt.performance.native.shot.'..method,'Barotrauma.Items.Components.Projectile',method,nativeShot,Hook.HookMethodType.After)
    end
    function R.fill(a,count,kind)
        local pages=math.ceil(count/100)
        a.expected=count;a.pending=a.pending+pages
        for pageIndex=1,pages do local n=math.min(100,count-(pageIndex-1)*100)
            A.item('aegisvacuumpage',a.pack.OwnInventory,function(page)
                a.pending=a.pending+n
                for i=1,n do A.item(kind or 'iron',page.OwnInventory,function(value)
                    a.pending=a.pending-1
                end) end
                a.pending=a.pending-1
            end)
        end
    end
    function R.prepareItem(a,p)
        a.lastShots=nil;a.lastCount=0;a.work=0
        if p.item=='aegisheadset' or p.item=='aegisheadsetmk2' then
            a.pending=a.pending+1
            A.item('divingmask',a.c.Inventory,function(mask)
                assert(a.c.Inventory.TryPutItem(mask,a.c,{InvSlotType.Head}))
                a.pending=a.pending+1
                A.item('oxygentank',mask.OwnInventory,function(tank) a.oxygen=tank;a.pending=a.pending-1 end)
                a.pending=a.pending-1
            end)
        elseif p.item=='aegisvacuum' then
            a.home=R.base+Vector2(((a.index-1)%4-1.5)*800,a.index<=4 and -450 or 450)
            a.c.TeleportTo(a.home)
        elseif p.item=='aegisvacuumpack' then
            local count=p.mode=='storage10000' and 10000 or p.mode=='storage1000' and 1000 or p.mode=='panel' and 1000 or p.mode=='salvage' and 200 or 0
            if count>0 then R.fill(a,count,p.mode=='salvage' and 'wrench' or 'iron') end
            if p.mode=='salvage' then
                a.pending=a.pending+1
                A.item('aegisvacuum',a.c.Inventory,function(vacuum)
                    a.vacuum=vacuum
                    assert(a.c.Inventory.TryPutItem(vacuum,a.c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
                    a.pending=a.pending+1
                    A.item('batterycell',vacuum.OwnInventory,function(cell) a.cell=cell;a.pending=a.pending-1 end)
                    a.pending=a.pending-1
                end)
            end
        elseif p.item=='multi-toolset' then
            U.component(a.item,'Pump').IsOn=p.mode=='cut'
            U.component(a.item,'Controller').State=p.mode=='extinguish'
        elseif p.item=='combatmultitool' then
            U.component(a.item,'Pump').IsOn=p.mode=='cut'
            U.component(a.item,'Controller').State=p.mode=='extinguish'
        end
        if p.mode=='weld' or p.mode=='cut' then
            local chosen,best
            for wall in Structure.WallList do
                if wall.Submarine==Submarine.MainSub and wall.HasBody and not wall.Indestructible and not wall.Prefab.Platform then
                    for section=0,wall.SectionCount-1 do
                        local point=wall.SectionPosition(section,true)
                        local d=(point-(Submarine.MainSub.WorldPosition+Vector2((a.index-4)*100,0))).LengthSquared()
                        if not best or d<best then chosen={wall=wall,section=section,point=point};best=d end
                    end
                end
            end
            assert(chosen,'No native wall fixture');a.wall=chosen.wall;a.section=chosen.section
            a.home=chosen.point-Vector2(85,0);a.aim=chosen.point;a.wallReference=chosen.point
            a.c.TeleportTo(a.home)
        else a.aim=a.home+Vector2(500,0) end
    end
    function R.maintainItem(a,p)
        local mode=p.mode
        if mode=='heal' or mode=='hit' then
            a.c.GodMode=false
            local health=a.c.CharacterHealth
            local burn=health.GetAfflictionStrengthByIdentifier('burn',true)
            if burn>20 then a.c.SetAllDamage(0,0,0) end
            if mode=='heal' then
                for _,id in ipairs({'burn','lacerations','blunttrauma'}) do
                    health.ApplyAffliction(a.c.AnimController.MainLimb,AfflictionPrefab.Prefabs[id].Instantiate(4))
                end
            else
                local before=a.cell.Condition
                a.c.AddDamage(a.c.WorldPosition,{AfflictionPrefab.Prefabs['burn'].Instantiate(5)},0,false,Vector2.Zero,nil,1)
                if a.cell.Condition<before then credit(a.item,1) end
            end
        elseif mode=='pressure' then
            a.c.GodMode=false
        elseif mode=='storage1000' or mode=='storage10000' then
            if sampled() and #V.contents(a.pack)==a.expected then a.work=a.work+.1 end
        elseif mode=='salvage' then
            if not V.jobs[a.pack] and not V.pending[a.pack] then V.startSalvage(V.context(a.vacuum,a.c)) end
            local progress=V.salvageProgress(a.pack)
            if progress and sampled() then a.work=math.max(a.work,progress.done) end
        elseif mode=='vacuum' then
            -- A soak exercises collection continuously without filling capacity.
            if R.phase.item=='mixed' then
                local contents=V.contents(a.pack)
                if #contents>200 then for _,value in ipairs(contents) do A.remove(value) end end
            end
            a.lootAt=a.lootAt or 0
            if A.now()>=a.lootAt then
                a.lootAt=A.now()+.5
                local origin=V.muzzle(a.item);local direction=V.direction(a.item)
                for n=1,4 do A.worldItem('iron',Vector2(origin.x+direction.x*120,origin.y+direction.y*120+n*3),function() end) end
            end
        elseif mode=='shield' then
            if sampled() and C.state(a.item).shield then a.work=a.work+.1 end
        elseif mode=='sonar' then
            local s=D.state(a.item)
            if not s.sonar then D.toggleSonar(a.c,a.item) end
            if s.sonar and sampled() then a.work=a.work+.1 end
        elseif mode=='passive' then
            if sampled() then
                local gained=0
                for skill,before in pairs(a.skillBaseline or {}) do gained=gained+math.max(0,a.c.Info.Job.GetSkillLevel(skill)-before) end
                a.work=math.max(a.work,gained)
            end
        elseif mode=='light' then
            local light=U.component(a.item,'LightComponent',a.testKind=='combatmultitool' and 2 or 1)
            if sampled() and light and light.IsOn and a.cell and a.cell.Condition>0 then a.work=a.work+.1 end
        end
        if mode=='repair' and p.item=='wrenchscrewdrivertwoinoneset' then
            -- The normal double-click switches this dual tool to its screwdriver state.
            a.item.AddTag('electricalrepairtool');a.item.AddTag('screwdriver')
        end
        if mode=='repair' and p.item~='descendantservosuit' then
            local r=a.device.GetComponentString('Repairable')
            a.c.SelectedItem=a.device
            if not r.CurrentFixer then r.StartRepairing(a.c,LuaUserData.CreateEnumTable('Barotrauma.Items.Components.Repairable+FixActions').Repair) end
            if a.device.Condition>65 then a.device.Condition=10 end
        end
        if a.wall then
            local damage=a.wall.SectionDamage(a.section)
            if mode=='weld' and damage<20 then a.wall.AddDamage(a.section,50-damage,a.c,false,false)
            elseif mode=='cut' and damage>70 then a.wall.AddDamage(a.section,30-damage,a.c,false,false) end
        end
    end
    function R.inputItem(a,p,dt)
        if a.index<=2 and not R.serverOnly then return end -- Actual remote clients supply their own inputs.
        local active=p.mode=='fire' or p.mode=='shield' or p.mode=='vacuum' or p.mode=='weld' or p.mode=='cut' or p.mode=='extinguish' or p.mode=='light'
        a.c.SetInput(InputType.Aim,false,active)
        a.c.CursorPosition=a.c.Position+(a.aim or a.home+Vector2(500,0))-a.c.WorldPosition
        if active and p.mode~='shield' and p.mode~='light' then
            a.item.Use(dt,a.c)
        end
        if p.mode=='grab' then
            local s=D.state(a.item)
            -- Disabled-navigation fixture humans are manual wearers, never AI grabbers.
            if not s.target then
                local q=a.enemy.WorldPosition
                s.acquireGrab=true;s.nextScan=0
                a.c.CursorPosition=a.c.Position+q-a.c.WorldPosition
                a.c.SetInput(InputType.Aim,false,true)
            end
        end
    end
end
return M
