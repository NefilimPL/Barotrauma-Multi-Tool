local U=require('CombatTool.util')
local P={}
function P.install(G,E)
    local function is(value,name) return value and E.LuaUserData.IsTargetType(value,'Barotrauma.'..name) end
    local collisionMask,collisionNone
    function G.friendly(a,b) return a and b and (a==b or a.IsFriendly(b)) or false end
    function G.direction(item)
        local angle=item.body.TransformedRotation
        return {x=math.cos(angle),y=math.sin(angle)},angle
    end
    function G.muzzle(item)
        local ranged=U.component(item,'RangedWeapon')
        local offset=E.ConvertUnits.ToDisplayUnits(ranged.TransformedBarrelPos)
        return U.point(item.WorldPosition+offset)
    end
    -- Ray-cast each submarine coordinate space and outside space, admitting
    -- only fixtures that belong to that space. All public positions are world units.
    function G.cast(a,b,radius,owner,wallsOnly,allCharacters)
        if not collisionMask then
            E.LuaUserData.RegisterType('Barotrauma.Physics')
            local physics=E.LuaUserData.CreateStatic('Barotrauma.Physics')
            -- Match native projectile categories: platforms, stairs and the
            -- repair-only body spanning a breached wall are not bullet walls.
            collisionMask=physics.CollisionCharacter+physics.CollisionWall+physics.CollisionLevel+
                physics.CollisionItemBlocking+physics.CollisionProjectile+physics.CollisionLagCompensationBody
            collisionNone=physics.CollisionNone
        end
        local nearest=nil
        local dx,dy=b.x-a.x,b.y-a.y
        local length=math.sqrt(dx*dx+dy*dy)
        if length<1e-7 then return nil end
        local nx,ny=-dy/length,dx/length
        local spaces={{sub=nil}}
        U.each(E.Submarine.Loaded,function(sub) spaces[#spaces+1]={sub=sub} end)
        local rails=radius and radius>0 and {-1,-.5,0,.5,1} or {0}
        for _,space in ipairs(spaces) do
            local sub=space.sub
            -- Native projectile code uses sub.SimPosition, i.e. display-space
            -- Position. WorldPosition additionally contains HiddenSubPosition.
            local offset=sub and sub.Position or E.Vector2.Zero
            for _,rail in ipairs(rails) do
                local rx,ry=nx*(radius or 0)*rail,ny*(radius or 0)*rail
                local va=E.ConvertUnits.ToSimUnits(E.Vector2(a.x+rx,a.y+ry)-offset)
                local vb=E.ConvertUnits.ToSimUnits(E.Vector2(b.x+rx,b.y+ry)-offset)
                E.Game.World.RayCast(function(fixture,point,normal,fraction)
                    if fixture.IsSensor or fixture.CollidesWith==collisionNone then return -1 end
                    local data=fixture.Body.UserData
                    local kind,target=nil,nil
                    if is(data,'Limb') then
                        if not wallsOnly and data.character and data.character.Submarine==sub
                            and not data.character.Removed and not data.character.IsDead
                            and data.character~=owner and (allCharacters or not G.friendly(owner,data.character)) then
                            kind,target='character',data.character
                        end
                    elseif is(data,'Structure') then
                        if data.Submarine==sub then kind='wall' end
                    else
                        local item=is(data,'Item') and data or is(fixture.UserData,'Item') and fixture.UserData
                        if not item and is(data,'Items.Components.ItemComponent') then item=data.Item end
                        if item then
                            local door=U.component(item,'Door')
                            if door and item.Submarine==sub and not door.CanBeTraversed then kind='wall' end
                        elseif not sub and data and not is(data,'Submarine') and
                            (E.LuaUserData.IsTargetType(data,'Voronoi2.VoronoiCell') or is(data,'LevelObject')) then kind='wall' end
                    end
                    if kind and (not nearest or fraction<nearest.t) then
                        local world=E.ConvertUnits.ToDisplayUnits(point)+offset
                        -- Return the center of the swept ring, not the offset rail.
                        nearest={t=fraction,x=world.X-rx,y=world.Y-ry,nx=normal.X,ny=normal.Y,kind=kind,target=target}
                    end
                    return 1
                end,va,vb,collisionMask)
            end
        end
        return nearest
    end
    function G.damage(target,position,owner,burn,blunt,stun,impulse)
        local afflictions={}
        if burn>0 then afflictions[#afflictions+1]=E.AfflictionPrefab.Prefabs['burn'].Instantiate(burn) end
        if blunt>0 then afflictions[#afflictions+1]=E.AfflictionPrefab.Prefabs['blunttrauma'].Instantiate(blunt) end
        -- Let native friendly-fire protection gate the impulse with the damage.
        local kick=impulse and E.Vector2(impulse.x,impulse.y) or E.Vector2.Zero
        target.AddDamage(E.Vector2(position.x,position.y),afflictions,stun or 0,true,kick,owner,1)
    end
    function G.shock(target,position,owner,burn,stun)
        -- Native DamageLimb applies its stun argument BEFORE checking friendly
        -- fire. Afflictions are applied AFTER that check, protecting allies from
        -- both the burn and the electrical stagger when friendly fire is off.
        local afflictions={E.AfflictionPrefab.Prefabs['burn'].Instantiate(burn),
            E.AfflictionPrefab.Prefabs['stun'].Instantiate(stun)}
        target.AddDamage(E.Vector2(position.x,position.y),afflictions,0,true,E.Vector2.Zero,owner,1)
    end
end
return P
