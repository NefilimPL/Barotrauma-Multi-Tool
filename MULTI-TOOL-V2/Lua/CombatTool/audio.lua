local M={}
function M.install(G,E)
    local tags={shot='aegis_shot',charge='aegis_charge',hit='aegis_bodyhit',
        bounce='aegis_bounce',wallhit='aegis_wallhit',shieldhit='aegis_wallhit',
        ['break']='aegis_wallhit',contact='aegis_bodyhit'}
    function G.playCombatSound(kind,point)
        local tag=tags[kind]
        if not tag then return end
        local ok,err=pcall(E.SoundPlayer.PlaySound,tag,E.Vector2(point.x,point.y))
        if ok then
            if kind=='shot' then pcall(E.SoundPlayer.PlaySound,'aegis_discharge',E.Vector2(point.x,point.y)) end
            return err
        end
        if not ok and not G.audioError then
            G.audioError=tostring(err)
            if E.printerror then E.printerror('[Aegis] Audio failed: '..tostring(err)) end
        end
    end
end
return M
