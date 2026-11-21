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
-- Generated sprites retain each part but can shift within a cell. These cached
-- UV frames keep the entire part and its local center/arm anchors visible.
local A=require('AegisSuit.atlas')
local frameOverrides={
    coalition={
        helmetClosed={826,12,220,241},
        helmetOpen={1210,12,220,242},
        hand={892,308,124,171},
        thigh={1263,260,143,255},
        boot={458,570,239,158},
    },
    separatists={
        waist={446,80,219,151},
        helmetClosed={822,12,220,241},
        helmetOpen={1206,11,220,242},
        hand={876,308,124,171},
        thigh={1262,260,143,255},
        boot={448,570,239,158},
        upperLink={756,588,336,101},
        lowerLink={1165,600,324,81},
    },
    husk={
        waist={444,80,219,151},
        helmetClosed={828,11,220,241},
        helmetOpen={1212,10,220,242},
        hand={883,308,124,171},
        upperLink={755,588,336,101},
        lowerLink={1164,598,319,81},
    },
    clowns={
        helmetClosed={818,10,220,241},
        helmetOpen={1202,10,220,242},
        hand={876,308,124,171},
        thigh={1242,258,143,255},
        upperLink={760,588,336,101},
        lowerLink={1154,598,319,81},
    },
}
local frames={}
for _,key in ipairs(F.order) do
    frames[key]={}
    for name,r in pairs(A) do frames[key][name]=(frameOverrides[key] or {})[name] or r end
end
function F.frame(key,name)
    local r=frames[key] and frames[key][name]
    assert(r,'unknown faction frame')
    return r
end
return F
