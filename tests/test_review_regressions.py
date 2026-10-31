from lua_support import LuaCase


class ReviewRegressionTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute('''
            G=require('CombatTool.game').new({});G.patch=function() end
            gun={ID=1,Condition=100,Prefab={Identifier={Value='combatmultitool'}},Components={{Name='ItemContainer'}}}
            gun.OwnInventory={GetItemAt=function() return nil end}
            function vec(x,y) return setmetatable({X=x,Y=y,LengthSquared=function() return x*x+y*y end},
                {__sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y) end,__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y) end}) end
            Vector={Zero=vec(0,0)}
            currentParent={AddSubObjective=function(o) added=o end}
            manager={CurrentObjective=currentParent}
            bot={IsBot=true,IsDead=false,Inventory={},WorldPosition=vec(0,0),AIController={ObjectiveManager=manager},CanInteractWith=function() return false end}
            gun.ParentInventory=bot.Inventory
            source={kind='Barotrauma.Item',ConditionPercentage=100,WorldPosition=vec(500,0),HasTag=function(tag) return tag=='mobilebattery' end,HasAccess=function() return true end}
            env={InvSlotType={Any=1},Item={ItemList={source}},LuaUserData={IsTargetType=function(o,name) return o.kind==name end},
                AIObjectiveContainItem=function() return {IsCompleted=false,Abandon=false,AddSubObjective=function(o) fetching=o end} end,
                AIObjectiveGetItem=function() fetchCalls=(fetchCalls or 0)+1;return {kind='fetch'} end}
            A=require('CombatTool.ai');A.install(G,env)
        ''')

    def test_distant_source_is_fetched_before_containment(self):
        self.lua.execute('assert(A.resupply(bot,gun,0,currentParent))')
        self.assertEqual(self.lua.globals().fetchCalls,1)

    def test_partial_source_replacement_is_limited_to_requested_slot(self):
        self.lua.execute('''
            old={MaxCondition=100,Condition=.4,HasTag=function(t) return t=='mobilebattery' end}
            shieldSource={MaxCondition=100,Condition=100,HasTag=old.HasTag}
            bot.Inventory.TryPutItem=function(it) moved=it;return true end
            gun.OwnInventory.GetItemAt=function(i) return i==0 and old or shieldSource end
            assert(A.resupply(bot,gun,0,currentParent,1))
        ''')
        self.assertTrue(self.lua.eval('moved==old'))
        self.assertFalse(self.lua.eval('added.RemoveEmpty'))
        self.assertIsNone(self.lua.eval('added.RemoveExistingPredicate'))

    def test_full_bot_inventory_drops_only_replaced_source(self):
        self.lua.execute('''
            old={MaxCondition=100,Condition=.4,HasTag=function(t) return t=='mobilebattery' end,
                Drop=function(character) droppedBy=character end}
            gun.OwnInventory.GetItemAt=function(i) if i==0 then return old end end
            bot.Inventory.TryPutItem=function() return false end
            assert(A.resupply(bot,gun,0,currentParent,1))
        ''')
        self.assertTrue(self.lua.eval('droppedBy==bot'))

    def test_weapon_resupply_preempts_suspended_shield_job(self):
        self.lua.execute('''
            previousJob={IsCompleted=false,Abandon=false,TargetSlot=1}
            state=G.state(gun);state.resupply=previousJob;state.resupplyParent={};state.resupplySlot=1;state.resupplyDeadline=100
            A.resupply(bot,gun,0,currentParent)
        ''')
        self.assertIsNotNone(self.lua.globals().added)
        self.assertEqual(self.lua.globals().added.TargetSlot,0)
        self.assertTrue(self.lua.eval('previousJob.IsCompleted or previousJob.Abandon'))

    def test_suspended_resupply_timeout_is_checked_outside_its_objective(self):
        self.lua.execute('''
            previousJob={IsCompleted=false,Abandon=false,TargetSlot=1}
            state=G.state(gun);state.resupply=previousJob;state.resupplyParent=currentParent;state.resupplySlot=1;state.resupplyDeadline=1
            G.now=2;G.powered=function() return true end
            A.update(state,{bot=true,owner=bot,mode='idle',damage=false})
        ''')
        self.assertTrue(self.lua.eval('previousJob.IsCompleted or previousJob.Abandon'))

    def test_passive_order_inspection_does_not_cancel_actual_combat_charge(self):
        self.lua.execute('''
            state=G.state(gun);state.owner=bot;state.mode='combat';state.chargeStarted=1
            G.transition(state,{owner=bot,mode='weld',bot=true,damage=true},true)
        ''')
        self.assertEqual(self.lua.globals().state.chargeStarted,1)
        self.assertEqual(self.lua.globals().state.mode,'combat')

    def test_world_cast_uses_submarine_position_not_hidden_body_position(self):
        self.lua.execute('''
            env={LuaUserData={IsTargetType=function() return false end,RegisterType=function() end,
                    CreateStatic=function() return {CollisionNone=0,CollisionCharacter=1,CollisionWall=2,CollisionLevel=4,CollisionItemBlocking=8,
                        CollisionProjectile=16,CollisionLagCompensationBody=32} end,CreateEnumTable=function() return {None=0} end},
                Submarine={Loaded={{Position=vec(100,0),WorldPosition=vec(10100,0)}}},
                Vector2=setmetatable(Vector,{__call=function(_,x,y) return vec(x,y) end}),
                ConvertUnits={ToSimUnits=function(v) return v end},Game={World={RayCast=function(_,a,b) lastRayStart=a end}}}
            require('CombatTool.physics').install(G,env)
            G.cast({x=150,y=0},{x=200,y=0},0,nil,true)
        ''')
        self.assertEqual(self.lua.globals().lastRayStart.X,50)

    def test_server_reload_epoch_accepts_low_sequence_snapshots(self):
        self.lua.execute('''
            env={CLIENT=true,Game={IsSingleplayer=false},Timer={GetTime=function() return 100 end},
                Networking={Receive=function(name,fn) if name:find('snapshot') then receiver=fn end end}}
            require('CombatTool.network').install(G,env)
            function packet(epoch,sequence)
                local values={epoch,sequence};local n=0
                return {ReadUInt32=function() n=n+1;return values[n] end,ReadUInt16=function() return 0 end}
            end
            receiver(packet(100,500));receiver(packet(101,1))
        ''')
        self.assertEqual(self.lua.eval('G.remote.epoch'),101)

    def test_hitscan_does_not_cancel_nearer_unshielded_character(self):
        self.lua.execute('''
            hooks={};G.patch=function(id,_,method,fn) hooks[id]=fn end
            G.friendly=function() return false end
            G.cast=function() return nil end
            G.event=function() end
            require('CombatTool.shield').install(G,{Entity={}})
            blocks=0
            G.findShield=function(a,b) if b.x>=100 then return {t=(100-a.x)/(b.x-a.x),x=100,y=0,state={}} end end
            G.blockShield=function() blocks=blocks+1;return true end
            projectile={Item={WorldPosition={X=0,Y=0},body={Enabled=true}},IsActive=true,MaxTargetsToHit=1}
            hooks.hitscan(projectile,{dir={X=1,Y=0}})
        ''')
        self.assertEqual(self.lua.globals().blocks,0)
