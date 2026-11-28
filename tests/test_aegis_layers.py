from lua_support import LuaCase


class SuitLayersTests(LuaCase):
    def test_parts_keep_their_order_behind_the_wearer(self):
        self.lua.execute('''
            local rows,draw,after={},nil,nil
            local function vector(x,y) return {X=x,Y=y} end
            local owner={SelectedItem={},AnimController={Limbs={{ActiveSprite={Depth=.125}},{ActiveSprite={Depth=.127}}},
                GetDepthOffset=function() return .25 end}}
            local suit={Prefab={Identifier={Value='aegisservosuit'}}}
            local state={owner=owner,hasArm=true,hasImpeller=true,mode='repair'}
            local frame=require('AegisSuit.atlas')
            package.loaded['AegisSuit.lights']={install=function() end}
            package.loaded['AegisSuit.ui']={install=function() end}
            local E={Vector2=vector,Rectangle=function(x,y,w,h) return {X=x,Y=y,Width=w,Height=h} end,
                GUI={GUI={Canvas={Rect={Width=300,Height=300}}}},Color={White={}},
                LuaUserData={CreateEnumTable=function() return {None=0} end},Sprite=function(path)
                    local sprite={Depth=.001,Origin=vector(0,0)}
                    sprite.Draw=function(_,_,_,_,_,_,_,depth)
                        rows[#rows+1]={path=path,x=sprite.SourceRect and sprite.SourceRect.X,
                            depth=depth or sprite.Depth}
                    end
                    return sprite
                end}
            local G={states={[suit]=state},now=1,equipped=function() return suit end,
                mount=function() return {x=0,y=0},0,1 end,attachment=function() return {x=0,y=0} end,
                toolPose=function() return {elbow={x=15,y=10},tip={x=40,y=15},
                    muzzle={x=46,y=15},angle=0} end,
                patch=function(_,class,method,fn,isAfter)
                    if class=='Barotrauma.Character' and method=='Draw' then draw,after=fn,isAfter end
                end}
            require('AegisSuit.client').install(G,E,'test')
            local args={spriteBatch={},cam={WorldToScreen=function() return vector(20,20) end}}
            local function render()
                rows={}
                draw(owner,args)
                for i,row in ipairs(rows) do
                    assert(row.depth>.377, 'gear tied with or in front of the wearer')
                    if i>1 then assert(rows[i-1].depth>row.depth, 'gear depths overlap or change order') end
                end
            end
            assert(not after,'deferred character drawing needs gear queued before the wearer')
            render()
            assert(#rows==5)
            assert(rows[1].path:find('impeller') and rows[2].path:find('impeller'))
            assert(rows[3].x==frame.upperLink[1] and rows[4].x==frame.lowerLink[1] and rows[5].x==frame.emitter[1])
            state.mode='combat'
            render()
            assert(#rows==8 and rows[8].path:find('Turrets'))
        ''')


class ModularSuitLayersTests(SuitLayersTests):
    mod_directory = 'System-Aegis-No-Headsets'
