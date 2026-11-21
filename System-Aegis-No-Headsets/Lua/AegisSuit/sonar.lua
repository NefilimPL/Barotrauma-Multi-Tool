local U=require('AegisCombat.util')
local C=require('AegisSuit.config')
local M={}
function M.install(G,E)
    local modes=E.LuaUserData.CreateEnumTable('Barotrauma.Items.Components.Sonar+Mode')
    local watched={}
    function G.syncSonar(item,state)
        if not item or item.Removed then return nil,false end
        local sonar=U.component(item,'Sonar')
        if not sonar then return nil,false end
        watched[item]={component=sonar,state=state}
        local owner=state.owner or G.owner(item)
        local charge=G.authoritative and G.energy(item) or (state.charge or G.energy(item))
        local powered=state.sonar==true and owner and not owner.IsDead and not owner.IsUnconscious and
            G.equipped(owner)==item and charge>0
        powered=powered==true
        sonar.Voltage=powered and 1 or 0;sonar.IsActive=powered
        local mode=state.sonarActive==false and modes.Passive or modes.Active
        sonar.UseMineralScanner=powered and state.minerals==true and state.sonarActive~=false
        if state.sonar and sonar.CurrentMode~=mode then sonar.CurrentMode=mode end
        state.sonarPowered=powered
        return sonar,powered
    end
    function G.stopSonar(item,state)
        local entry=watched[item]
        local sonar=entry and entry.component or (not item.Removed and U.component(item,'Sonar'))
        if sonar and not item.Removed then
            sonar.IsActive=false;sonar.Voltage=0;sonar.CurrentMode=modes.Passive
            sonar.UseMineralScanner=false
        end
        if state then state.sonar=false;state.sonarPowered=false end
        watched[item]=nil
    end
    function G.toggleSonar(owner,item)
        if not G.authoritative or G.equipped(owner)~=item or owner.IsUnconscious or not U.component(item,'Sonar') then return false end
        local state=G.state(item)
        if not state.sonar and G.energy(item)<=0 then return false end
        state.sonar=not state.sonar
        G.syncSonar(item,state)
        return true
    end
    function G.setSonarMode(owner,item,active)
        if not G.authoritative or G.equipped(owner)~=item or owner.IsUnconscious or
            G.energy(item)<=0 or not U.component(item,'Sonar') then return false end
        local state=G.state(item);state.sonar=true;state.sonarActive=active==true
        G.syncSonar(item,state);return true
    end
    function G.toggleMinerals(owner,item)
        local sonar=U.component(item,'Sonar')
        if not G.authoritative or G.equipped(owner)~=item or owner.IsUnconscious or G.energy(item)<=0 or
            not sonar or not sonar.HasMineralScanner then return false end
        local s=G.state(item)
        s.minerals=not (s.minerals==true and s.sonarActive~=false)
        s.sonar=true;s.sonarActive=true
        G.syncSonar(item,s);return true
    end
    function G.updateSonar(owner,item,state,dt)
        local _,powered=G.syncSonar(item,state)
        if G.authoritative and powered then
            G.spend(item,C.sonarRate*(state.sonarActive==false and .25 or 1)*dt)
            G.syncSonar(item,state)
        end
    end
    function G.clearSonars()
        for item,entry in pairs(watched) do G.stopSonar(item,entry.state) end
    end
end
return M
