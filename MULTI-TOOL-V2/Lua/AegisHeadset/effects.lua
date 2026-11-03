local C=require('AegisHeadset.config')
local Medical=require('AegisHeadset.medical')
local Leds=require('AegisHeadset.leds')
local M={}
function M.install(G,E)
    local kinds={pressure=1,heal=2,hit=3,restore=4,warning=5}
    local names={'pressure','heal','hit','restore','warning'}
    local effects,soundTimes={},{}
    local function play(tag,character)
        if E.Character and E.Character.Controlled==character then E.SoundPlayer.PlaySound(tag,1)
        else E.SoundPlayer.PlaySound(tag,character.WorldPosition) end
    end
    local function receive(character,kind,tier,joint)
        if G.disposed or not character or character.Removed then return end
        if kind=='warning' then
            local tags={[0]='empty',[1]='critical',[2]='low'}
            if tags[tier] then play('aegis_headset_warning_'..tags[tier],character) end
            return
        end
        if kind=='restore' and not G.authoritative and not character.IsDead then Medical.restoreNative(character,joint) end
        local active
        for _,fx in ipairs(effects) do if fx.character==character then active=fx;break end end
        if not active then
            active={character=character,channels={}}
            effects[#effects+1]=active
        end
        active.channels[kind]={age=0,tier=tier,kind=kind}
        if #effects>C.maxEffects then table.remove(effects,1) end
        local nextSound=soundTimes[character] or 0
        if (kind=='hit' and G.now>=nextSound) or tier==0 then
            soundTimes[character]=G.now+C.soundInterval
            local tags={[0]='empty',[1]='critical',[2]='low',[3]='high'}
            play('aegis_headset_'..tags[tier],character)
        end
    end
    function G.emit(character,item,kind,joint)
        local s=G.state(item)
        local energy=G.energy(item)
        local tier=energy<=0 and 0 or energy<=C.criticalEnergy and 1 or energy<=C.lowEnergy and 2 or 3
        s.effectTimes=s.effectTimes or {}
        if kind~='restore' and kind~='warning' and G.now<(s.effectTimes[kind] or 0) and not (tier==0 and not s.emptySignaled) then return end
        if kind~='restore' and kind~='warning' and tier==0 and s.emptySignaled then return end
        if kind~='warning' then s.emptySignaled=tier==0 end
        s.effectTimes[kind]=G.now+(kind=='hit' and C.hitInterval or C.effectInterval)
        if E.CLIENT then receive(character,kind,tier,joint) end
        if E.SERVER and E.Game.Server then
            local msg=E.Networking.Start(C.protocol)
            msg.WriteUInt16(character.ID);msg.WriteByte(kinds[kind]);msg.WriteByte(tier);msg.WriteUInt16(joint or 0)
            E.Networking.Send(msg)
        end
    end
    function G.checkPower(character,item)
        local state=G.state(item)
        local energy=G.energy(item)
        local tier=energy<=0 and 0 or energy<=C.criticalEnergy and 1 or energy<=C.lowEnergy and 2 or 3
        local cell=G.source(item)
        if state.warningCell~=cell then state.warningCell=cell;state.warningTier=nil;state.nextWarning=0 end
        if tier<3 and (state.warningTier~=tier or (tier>0 and G.now>=(state.nextWarning or 0))) then
            G.emit(character,item,'warning')
            state.nextWarning=G.now+(tier==1 and C.criticalAlarmInterval or C.lowAlarmInterval)
        end
        state.warningTier=tier
    end
    function G.updateEffects(dt)
        for i=#effects,1,-1 do
            local active=effects[i]
            for kind,fx in pairs(active.channels) do
                fx.age=fx.age+dt
                if fx.age>C.indicatorDuration then active.channels[kind]=nil end
            end
            if not next(active.channels) or active.character.Removed then table.remove(effects,i) end
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
        for _,active in ipairs(effects) do
            local character=active.character
            local fx=active.channels.hit or active.channels.heal or active.channels.restore or active.channels.pressure
            if not character.IsDead then
                local item=G.equipped(character)
                local pulse=.3+.7*math.abs(math.cos(fx.age*30))
                if fx.tier<=1 then pulse=pulse*(.3+.7*math.abs(math.sin(fx.age*100))) end
                local fade=math.max(0,1-fx.age/C.indicatorDuration)*pulse
                local healing=fx.kind=='heal' or fx.kind=='restore'
                local r,g,b=healing and 40 or 255,healing and 145 or 25,healing and 255 or 25
                for _,led in ipairs(item and Leds.positions(E,character,item) or {}) do
                    local radius=(fx.kind=='hit' and 2.4 or 1.8)*led.scale
                    for row=-2,2 do
                        local y=radius*row/3
                        local half=math.sqrt(radius*radius-y*y)
                        gui.DrawLine(batch,cam.WorldToScreen(E.Vector2(led.x-half,led.y+y)),
                            cam.WorldToScreen(E.Vector2(led.x+half,led.y+y)),
                            E.Color(r,g,b,math.floor(70*fade)),0,math.max(1,math.floor(cam.Zoom*led.scale+.5)))
                    end
                    gui.DrawLine(batch,cam.WorldToScreen(E.Vector2(led.x-.45*led.scale,led.y)),
                        cam.WorldToScreen(E.Vector2(led.x+.45*led.scale,led.y)),
                        E.Color(r,g,b,math.floor(255*fade)),0,
                        math.max(3,math.floor(cam.Zoom*led.scale*1.5+.5)))
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
