local U=require('CombatTool.util')
local T=require('AegisHeadset.treatments')
local M={}
local function id(value) return value and tostring(value.Value or value):lower() or '' end
local amputations={sra_amputation='RightArm',tra_amputation='RightArm',sla_amputation='LeftArm',tla_amputation='LeftArm',
    srl_amputation='RightLeg',trl_amputation='RightLeg',sll_amputation='LeftLeg',tll_amputation='LeftLeg',
    sh_amputation='Head',th_amputation='Head'}
local organs={'heartremoved','lungsremoved','liverremoved','kidneysremoved','brainremoved','eyesremoved'}
local surgical={surgeryincision=true,clampedbleeding=true,drilledbones=true,retractedskin=true,
    sawedbones=true,suturedi=true,caviclean=true}
local ntPreserve={luabotomy=true,luabotomypurger=true,stopcreatureabuse=true,tshocktimeout=true,
    onwheelchair=true,stasisbagoverlay=true,bodybagoverlay=true,afstreptokinase=true,immunity=true}
function M.entries(E,character)
    local health=character.CharacterHealth
    local entries={}
    -- Look at runtime globals, not package dependencies or load order. Both
    -- Classic NT exposes a Lua namespace; NT CS is recognized by prefab ownership.
    U.each(health.GetAllAfflictions(),function(a)
        local prefab=a.Prefab
        local packageName=prefab.ContentPackage and tostring(prefab.ContentPackage.Name):lower() or ''
        local nt=E.NT~=nil or packageName:find('neurotrauma',1,true)~=nil
        local name=id(prefab.Identifier)
        local harmful=false
        if a.GetVitalityDecrease then harmful=a.GetVitalityDecrease(health)>0 end
        local policy=T.classify({id=name,type=id(prefab.AfflictionType),isBuff=prefab.IsBuff,harmful=harmful})
        if nt and not T.policies[name] then
            if ntPreserve[name] then policy=nil end
            if amputations[name] then policy={target=0,anatomy='limb',part=amputations[name]} end
            for _,organ in ipairs(organs) do
                if name==organ then policy={target=0,anatomy='organ',part=organ} end
            end
            -- NT labels physiology and surgical state as buffs. Preserve
            -- blood types/implants, but restore actual healthy physiology.
            if name=='bloodpressure' or name=='bloodamount' then
                policy={target=100,healthyMin=90,healthyMax=110,priority=100}
            end
            if name=='acidosis' or name=='alkalosis' then policy={target=0,priority=95} end
            if surgical[name] then
                local limb=health.GetAfflictionLimb(a)
                policy={target=0,anatomy='surgery',part='0surgery:'..tostring(limb and limb.HealthIndex or -1)}
            end
        end
        entries[#entries+1]={id=name,strength=a.Strength,ref=a,policy=policy}
    end)
    return entries
end
-- Native severing removes joints and subtracts ragdoll mass. Rebuilding the
-- current ragdoll restores both; unhealed severed joints remain severed.
function M.restoreNative(character,jointIndex)
    local ragdoll=character.AnimController
    local remaining={};local index=0
    U.each(ragdoll.LimbJoints,function(joint)
        index=index+1
        if joint.IsSevered and index~=jointIndex then remaining[#remaining+1]=index end
    end)
    local position=character.WorldPosition
    ragdoll.Recreate()
    character.TeleportTo(position)
    local joints={};U.each(ragdoll.LimbJoints,function(joint) joints[#joints+1]=joint end)
    for _,i in ipairs(remaining) do if joints[i] then ragdoll.SeverLimbJoint(joints[i]) end end
end
function M.jobs(character,entries)
    local jobs={}
    for _,entry in ipairs(entries) do
        local p=entry.policy
        if p and p.anatomy and entry.strength>(p.target or 0)+1e-6 then
            local key=(p.anatomy=='surgery' and '0' or '')..p.anatomy..':'..(p.part or entry.id)
            local job=jobs[key] or {key=key,kind=p.anatomy,entries={}}
            job.entries[#job.entries+1]=entry;jobs[key]=job
        end
    end
    local i=0
    U.each(character.AnimController and character.AnimController.LimbJoints,function(joint)
        i=i+1
        if joint.IsSevered then
            local key='native:'..i
            jobs[key]={key=key,kind='limb',jointIndex=i,entries={}}
        end
    end)
    return jobs
end
return M
