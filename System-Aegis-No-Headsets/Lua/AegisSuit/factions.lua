-- Cosmetic families share all gameplay rules; identifiers persist with native item saves.
local U=require('AegisCombat.util')
local F={order={'pirates','descendens','coalition','separatists','husk','clowns'},
    baseIds={suit='aegisservosuit',servo='aegisservomodule',impeller='aegisimpellermodule'},ids={}}
local records={}
function F.id(kind,key)
    local base=F.baseIds[kind]
    return base and base..(key=='pirates' and '' or key) or nil
end
for kind in pairs(F.baseIds) do
    F.ids[kind]={}
    for _,key in ipairs(F.order) do
        local id=F.id(kind,key);F.ids[kind][#F.ids[kind]+1]=id
        records[id]={kind=kind,key=key}
    end
end
F.suitIds=F.ids.suit
function F.is(item,kind)
    local r=records[U.itemId(item)]
    return r~=nil and r.kind==kind
end
function F.key(item)
    local r=records[U.itemId(item)]
    return r and r.key or 'pirates'
end
local assets={atlas='suit-v2.png',housing='impeller-housing.png',servo='servo-module.png',
    impeller='impeller-module.png',packed='packed-suit.png',rack='rack-suit.png',window='rack-window-v2.png'}
function F.path(key,asset)
    local name=assert(assets[asset],'unknown faction asset')
    if key=='pirates' then
        return 'Assets/'..((asset=='servo' or asset=='impeller') and 'AegisModules/' or 'AegisSuit/')..name
    end
    assert(records[F.id('suit',key)],'unknown faction palette')
    return 'Assets/Factions/'..key..'/'..name
end
-- Every style uses the same atlas slots and servo pivot coordinates.
local frames=require('AegisSuit.atlas')
function F.frame(key,name)
    assert(records[F.id('suit',key)],'unknown faction')
    local frame=frames[name]
    assert(frame,'unknown faction frame')
    return frame
end
return F
