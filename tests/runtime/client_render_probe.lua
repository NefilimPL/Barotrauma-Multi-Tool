-- Isolated client only. Exercise production rendering against a real GPU batch.
if not CLIENT then return end
Timer.Wait(function()
    local batch
    local ok,err=pcall(function()
        assert(BMTCombat and BMTCombat.draw,'client renderer did not initialize')
        LuaUserData.RegisterType('Barotrauma.GameMain')
        LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.GraphicsDevice')
        local gm=LuaUserData.CreateStatic('Barotrauma.GameMain')
        local SB=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.SpriteBatch')
        local Blend=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
        local Sort=LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
        batch=SB(gm.Instance.GraphicsDevice)
        local cam=gm.GameScreen.Cam
        local G=BMTCombat
        local previous=G.authoritative
        G.authoritative=false
        local listener=gm.SoundManager.ListenerPosition
        for _,kind in ipairs({'shot','hit','bounce','wallhit','charge'}) do
            local channel=G.playCombatSound(kind,{x=listener.X,y=listener.Y})
            assert(channel,'native sound did not create a spatial channel: '..kind..' '..tostring(G.audioError))
            channel.Dispose()
        end
        local audio=G.playCombatSound
        G.playCombatSound=nil -- The frame stress test must not emit hundreds of simultaneous sounds.
        for frame=0,15 do
            for _,angle in ipairs({0,math.pi/2,math.pi,-math.pi/2}) do
                G.now=frame/25
                local ring=require('CombatTool.core').ring({x=150,y=0},{x=math.cos(angle),y=math.sin(angle)},1)
                ring.id=1;ring.age=frame/25
                ring.trail={{x=120,y=0,age=ring.age-.05},{x=150,y=0,age=ring.age}}
                G.remote={received=G.now,shields={{x=0,y=0,angle=angle,energy=100}},rings={ring}}
                for _,kind in ipairs({'shieldhit','break','contact','hit','bounce','wallhit','shot','charge'}) do
                    G.onEffect(kind,{x=0,y=0},angle,0)
                end
                G.updateVisuals(.02)
                batch.Begin(Sort.Deferred,Blend.NonPremultiplied)
                G.draw(batch,cam)
                batch.End()
            end
        end
        G.playCombatSound=audio
        G.authoritative=previous
        batch.Dispose();batch=nil
        assert(not G.visualError,G.visualError)
        assert(not G.audioError,G.audioError)
    end)
    File.Write('LocalMods/MULTI-TOOL-V2/client-results.txt',
        ok and 'PASS native GPU: 16 frames, 4 angles, animated rings/trails, 8 effect kinds; 5 native spatial audio channels' or 'FAIL '..tostring(err))
    if not ok then print('[BMT CLIENT] '..tostring(err)) end
end,4000)
