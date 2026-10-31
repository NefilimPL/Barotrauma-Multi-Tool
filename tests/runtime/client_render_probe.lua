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
        for frame=0,15 do
            for _,angle in ipairs({0,math.pi/2,math.pi,-math.pi/2}) do
                G.now=frame/25
                G.remote={received=G.now,shields={{x=0,y=0,angle=angle,energy=100}},rings={}}
                for _,kind in ipairs({'shieldhit','break','contact','hit','bounce','shot','charge'}) do
                    G.onEffect(kind,{x=0,y=0},angle,0)
                end
                G.updateVisuals(.02)
                batch.Begin(Sort.Deferred,Blend.NonPremultiplied)
                G.draw(batch,cam)
                batch.End()
            end
        end
        G.authoritative=previous
        batch.Dispose();batch=nil
        assert(not G.visualError,G.visualError)
    end)
    File.Write('LocalMods/MULTI-TOOL-V2/client-results.txt',
        ok and 'PASS native client GPU rendering: 16 frames, 4 aim angles, 7 effect kinds' or 'FAIL '..tostring(err))
    if not ok then print('[BMT CLIENT] '..tostring(err)) end
end,4000)
