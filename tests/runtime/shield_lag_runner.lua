-- Run after copying shield_frontal_matrix.lua to the isolated server Lua/Tests.
assert(SERVER and Game.RoundStarted)
BMTFrontalEdge=nil
local angles={math.pi,0,math.pi+.5,math.pi-.5,.5,-.5}
local index,all,passed,failed=0,{},0,0
local function nextCase()
    index=index+1
    if index>#angles+1 then
        all[#all+1]='TOTAL passed='..passed..' failed='..failed
        File.Write('LocalMods/MULTI-TOOL-V2/shield-lag-matrix-results.txt',table.concat(all,'\n'))
        BMTFrontalDone=nil;BMTFrontalAngle=nil;BMTFrontalLag=nil;BMTFrontalControl=nil
        print('[SHIELD MATRIX] '..all[#all])
        assert(failed==0 and passed==97,'native shield matrix failed; read shield-lag-matrix-results.txt')
        return
    end
    BMTFrontalAngle=angles[index] or math.pi
    BMTFrontalLag=160
    BMTFrontalControl=index>#angles
    dofile('LocalMods/MULTI-TOOL-V2/Lua/Tests/shield_frontal_matrix.lua')
end
BMTFrontalDone=function(lines)
    all[#all+1]='CASE '..index..' control='..tostring(BMTFrontalControl)
    for _,line in ipairs(lines) do
        all[#all+1]=line
        if line:sub(1,5)=='PASS ' then passed=passed+1 end
        if line:sub(1,5)=='FAIL ' then failed=failed+1 end
    end
    nextCase()
end
nextCase()
