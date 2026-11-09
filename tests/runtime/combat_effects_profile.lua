-- Disposable GPU probe. CombatProfileStartup measures each console command.
if not CLIENT then return end
LuaUserData.RegisterType('Barotrauma.GameMain')
LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.GraphicsDevice')
local gm=LuaUserData.CreateStatic('Barotrauma.GameMain')
local SB=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.SpriteBatch')
local Blend=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
local Sort=LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
local G=BMTCombat
local batch=SB(gm.Instance.GraphicsDevice)
local cam=gm.GameScreen.Cam
local oldAuthority,oldRemote=G.authoritative,G.remote
local P={};CombatEffectProfile=P
function P.prepare(kind,count,sameOwner,offscreen)
    G.authoritative=false;G.clearVisuals()
    G.remote={received=G.now,rings={},shields={}}
    local pos=cam.WorldViewCenter
    P.point={x=pos.X+(offscreen and 10000 or 0),y=pos.Y};P.endpoint={x=P.point.x+80,y=pos.Y+20}
    for i=1,count do G.onEffect(kind,P.point,0,sameOwner and 7 or i,P.endpoint) end
end
function P.events(kind,count)
    for i=1,count do G.onEffect(kind,P.point,0,i,P.endpoint) end
end
function P.draw(count)
    for i=1,count do
        batch.Begin(Sort.Deferred,Blend.NonPremultiplied)
        local ok,err=pcall(G.draw,batch,cam)
        batch.End();assert(ok,err)
    end
end
function P.finish()
    G.clearVisuals();G.authoritative=oldAuthority;G.remote=oldRemote;batch.Dispose()
end
File.Write('LocalMods/MULTI-TOOL-V2/combat-profile-ready.txt','PASS GPU probe ready')
