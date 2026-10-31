local U=require('CombatTool.util')
local C=require('AegisHeadset.config')
local Medical=require('AegisHeadset.medical')
local M={}
function M.install(G,E)
    local kinds={pressure=1,heal=2,hit=3,restore=4}
    local names={'pressure','heal','hit','restore'}
    local effects,soundTimes={},{}
    local function receive(character,kind,tier,joint)
        if G.disposed or not character or character.Removed then return end
        if kind=='restore' and not G.authoritative and not character.IsDead then Medical.restoreNative(character,joint) end
        effects[#effects+1]={character=character,age=0,tier=tier,kind=kind}
        if #effects>C.maxEffects then table.remove(effects,1) end
        local nextSound=soundTimes[character] or 0
        if G.now>=nextSound or tier==0 then
            soundTimes[character]=G.now+C.soundInterval
            local tags={[0]='empty',[1]='critical',[2]='low',[3]='high'}
            E.SoundPlayer.PlaySound('aegis_headset_'..tags[tier],character.WorldPosition)
        end
    end
    function G.emit(character,item,kind,joint)
        local s=G.state(item)
        local energy=G.energy(item)
        local tier=energy<=0 and 0 or energy<15 and 1 or energy<40 and 2 or 3
        s.effectTimes=s.effectTimes or {}
        if kind~='restore' and G.now<(s.effectTimes[kind] or 0) and not (tier==0 and not s.emptySignaled) then return end
        if kind~='restore' and tier==0 and s.emptySignaled then return end
        s.emptySignaled=tier==0
        s.effectTimes[kind]=G.now+C.effectInterval
        if E.CLIENT then receive(character,kind,tier,joint) end
        if E.SERVER and E.Game.Server then
            local msg=E.Networking.Start(C.protocol)
            msg.WriteUInt16(character.ID);msg.WriteByte(kinds[kind]);msg.WriteByte(tier);msg.WriteUInt16(joint or 0)
            E.Networking.Send(msg)
        end
    end
    function G.updateEffects(dt)
        for i=#effects,1,-1 do
            effects[i].age=effects[i].age+dt
            if effects[i].age>.65 or effects[i].character.Removed then table.remove(effects,i) end
        end
    end
    function G.clearEffects() effects={};soundTimes={} end
    function G.disposeEffects() G.disposed=true;G.clearEffects() end
    if not E.CLIENT then return end
    E.Networking.Receive(C.protocol,function(msg)
        local id,kind,tier,joint=msg.ReadUInt16(),names[msg.ReadByte()],msg.ReadByte(),msg.ReadUInt16()
        if not kind or tier>3 then return end
        local character=E.Entity.FindEntityByID(id)
        if not character or not E.LuaUserData.IsTargetType(character,'Barotrauma.Character') then return end
        receive(character,kind,tier,joint)
    end)
    local gui=type(E.GUI)=='table' and E.GUI.GUI or E.GUI
    local sorts=E.LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
    E.LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.BlendState')
    local blend=E.LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
    function G.drawEffects(batch,cam)
        for _,fx in ipairs(effects) do
            local character=fx.character
            if not character.IsDead then
                local pos=character.WorldPosition
                local xmin,xmax,ymin,ymax=pos.X-18,pos.X+18,pos.Y-35,pos.Y+35
                U.each(character.AnimController.Limbs,function(limb)
                    if not limb.IsSevered then
                        local p=limb.WorldPosition
                        xmin=math.min(xmin,p.X-12);xmax=math.max(xmax,p.X+12)
                        ymin=math.min(ymin,p.Y-12);ymax=math.max(ymax,p.Y+12)
                    end
                end)
                local cx,cy=(xmin+xmax)/2,(ymin+ymax)/2
                local rx,ry=(xmax-xmin)*.65,(ymax-ymin)*.59
                local pulse=.6+.4*math.abs(math.sin(fx.age*57+(character.ID or 0)))
                local fade=math.max(0,1-fx.age/.65)*pulse
                local color=E.Color(255,fx.kind=='heal' and 75 or 28,36,math.floor(175*fade))
                local previous
                for i=0,56 do
                    local angle=i*math.pi*2/56
                    local jitter=1+.018*math.sin(i*7+fx.age*91)
                    local p=cam.WorldToScreen(E.Vector2(cx+math.cos(angle)*rx*jitter,cy+math.sin(angle)*ry*jitter))
                    if previous and (i%7~=0 or fx.tier>=2) then
                        gui.DrawLine(batch,previous,p,color,0,math.max(1,cam.Zoom*1.5))
                    end
                    previous=p
                end
                -- Thin moving interference bands: shader-like shimmer without
                -- an opaque bubble or a copied movie texture.
                for band=1,5 do
                    local v=((band/5+fx.age*1.1)%1)*2-1
                    local width=rx*math.sqrt(math.max(0,1-v*v))
                    local y=cy+v*ry
                    gui.DrawLine(batch,cam.WorldToScreen(E.Vector2(cx-width,y)),cam.WorldToScreen(E.Vector2(cx+width,y)),
                        E.Color(255,20,30,math.floor(26*fade)),0,math.max(1,cam.Zoom))
                end
            end
        end
    end
    G.patch('draw','Barotrauma.GameScreen','DrawMap',function(screen,p)
        if G.visualError then return end
        local batch=p['spriteBatch']
        batch.Begin(sorts.Deferred,blend.NonPremultiplied)
        local ok,err=pcall(G.drawEffects,batch,screen.Cam)
        batch.End()
        if not ok then G.visualError=tostring(err);E.printerror('[Aegis headsets] '..G.visualError) end
    end,true)
end
return M
