from lua_support import LuaCase


class DescendantSonarTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            E={LuaUserData={CreateEnumTable=function() return {Active=0,Passive=1} end}}
            owner={};sonar={Name='Sonar',CurrentMode=1,IsActive=false};suit={Components={sonar}}
            state={item=suit,owner=owner,mode='repair'};power=100;debits=0
            G={authoritative=true,states={[suit]=state},state=function() return state end,
                owner=function() return owner end,equipped=function(c) return c==owner and suit end,
                energy=function() return power end,
                spend=function(i,cost) power=math.max(0,power-cost);debits=debits+1;return 1 end}
            require('DescendantSuit.sonar').install(G,E)
        """)

    def test_sonar_toggle_and_power_are_independent_of_arm_mode(self):
        self.lua.execute("""
            assert(G.toggleSonar(owner,suit));assert(state.sonar and state.mode=='repair')
            G.updateSonar(owner,suit,state,.5)
            assert(sonar.IsActive and sonar.Voltage==1 and power<100 and debits==1)
            assert(G.toggleSonar(owner,suit));assert(not state.sonar and state.mode=='repair')
            local before=power;G.updateSonar(owner,suit,state,1)
            assert(not sonar.IsActive and sonar.Voltage==0 and power==before)
        """)

    def test_foreign_owner_and_empty_battery_cannot_turn_sonar_on(self):
        self.lua.execute("""
            assert(not G.toggleSonar({},suit));assert(not state.sonar)
            power=0;assert(not G.toggleSonar(owner,suit));assert(not state.sonar)
        """)

    def test_empty_battery_stops_pings_and_refill_can_resume_requested_sonar(self):
        self.lua.execute("""
            assert(G.toggleSonar(owner,suit));power=0
            G.updateSonar(owner,suit,state,.1);assert(not sonar.IsActive and sonar.Voltage==0 and debits==0)
            power=10;G.updateSonar(owner,suit,state,.1);assert(sonar.IsActive and power<10)
            G.clearSonars();assert(not sonar.IsActive and sonar.Voltage==0 and not state.sonar)
        """)

    def test_replica_applies_power_state_without_debiting_battery(self):
        self.lua.execute("""
            G.authoritative=false;state.sonar=true;state.charge=80
            G.syncSonar(suit,state);assert(sonar.IsActive and debits==0)
            state.charge=0;G.syncSonar(suit,state);assert(not sonar.IsActive and debits==0)
        """)

    def test_unconscious_owner_and_unequip_stop_native_sonar(self):
        self.lua.execute("""
            assert(G.toggleSonar(owner,suit));owner.IsUnconscious=true
            G.updateSonar(owner,suit,state,.1);assert(not sonar.IsActive and debits==0)
            owner.IsUnconscious=false;G.updateSonar(owner,suit,state,.1);assert(sonar.IsActive)
            G.stopSonar(suit,state);assert(not sonar.IsActive and not state.sonar)
        """)


class DescendantSnapshotTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            function buffer()
                local b={rows={},index=0}
                for _,kind in ipairs({'UInt16','Byte','Boolean','Single'}) do
                    b['Write'..kind]=function(v) b.rows[#b.rows+1]={kind,v} end
                    b['Read'..kind]=function()
                        b.index=b.index+1;local row=assert(b.rows[b.index]);assert(row[1]==kind);return row[2]
                    end
                end
                return b
            end
            function env(server)
                local handlers={};local e={SERVER=server,CLIENT=not server,Character={Controlled=owner},
                    Entity={FindEntityByID=function(id) return entities[id] end}}
                e.Networking={Receive=function(id,fn) handlers[id]=fn end,Start=function() return buffer() end,
                    Send=function(m) sent=m end};return e,handlers
            end
            suit={ID=10};owner={ID=11};enemy={ID=12};entities={[10]=suit,[11]=owner,[12]=enemy}
            local function game(authority)
                local g={now=1,authoritative=authority,alive=true,states={},energy=function() return 80 end,
                    is=function(item) return item==suit end}
                g.state=function(item)
                    g.states[item]=g.states[item] or {item=item};return g.states[item]
                end
                return g
            end
            S=game(true);server,serverHandlers=env(true)
            local s=S.state(suit);s.owner=owner;s.mode='combat';s.shots=5;s.sonar=true
            s.lastPulse={x=400,y=500};s.active=true
            s.target={entity=enemy,kind='combat',point={x=401,y=501}}
            require('DescendantSuit.network').install(S,server)
            C=game(false);client,clientHandlers=env(false)
            require('DescendantSuit.network').install(C,client)
            protocol=require('DescendantSuit.config').protocol
        """)

    def test_pulse_endpoint_and_sonar_state_round_trip_with_target(self):
        self.lua.execute("""
            S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            local s=C.state(suit)
            assert(s.sonar and s.lastPulse.x==400 and s.lastPulse.y==500)
            assert(s.shots==5 and s.target.entity==enemy and s.target.point.x==401 and s.active)
        """)

    def test_smoothed_joint_angles_round_trip_without_overwriting_current_draw_pose(self):
        self.lua.execute("""
            S.state(suit).toolAngles={upper=.4,lower=-1.2,head=.8}
            C.state(suit).drawAngles={upper=.1,lower=-1,head=.2}
            S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            local s=C.state(suit)
            assert(s.toolAngles.upper==.4 and s.toolAngles.lower==-1.2 and s.toolAngles.head==.8)
            assert(s.drawAngles.upper==.1,'network packet snapped displayed joints')
        """)

    def test_minerals_and_torso_reference_rotation_round_trip(self):
        self.lua.execute("""
            local s=S.state(suit);s.minerals=true;s.toolAngles={upper=.2,lower=.3,head=.4};s.toolRotation=1.3
            S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            assert(C.state(suit).minerals and C.state(suit).toolRotation==1.3)
        """)

    def test_pulse_endpoint_remains_when_target_dies_before_snapshot(self):
        self.lua.execute("""
            S.state(suit).target=nil;S.state(suit).active=false
            S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            local s=C.state(suit);assert(not s.target and not s.active)
            assert(s.lastPulse.x==400 and s.lastPulse.y==500)
        """)

    def test_automatic_repair_ownership_round_trips_and_clears_on_the_next_snapshot(self):
        self.lua.execute("""
            S.state(suit).repairing=enemy
            S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            assert(C.state(suit).repairing==enemy)
            S.state(suit).repairing=nil;S.now=S.now+1
            S.sendSnapshot();clientHandlers[protocol..'.snapshot'](sent)
            assert(not C.state(suit).repairing)
        """)

    def test_sonar_request_is_forwarded_to_the_server_authorization_boundary(self):
        self.lua.execute("""
            C.requestMode(suit,'sonar');assert(sent,'sonar request not sent')
            local caller={Character=owner};local authorized=false
            S.authorize=function(c,i,mode) authorized=c==caller and i==suit and mode=='sonar' end
            serverHandlers[protocol..'.mode'](sent,caller)
            assert(authorized)
        """)

    def test_sonar_and_arm_requests_in_one_short_burst_are_both_authorized(self):
        self.lua.execute("""
            local caller={Character=owner};local actions={}
            S.authorize=function(c,i,mode) actions[#actions+1]=mode end
            C.requestMode(suit,'sonar');serverHandlers[protocol..'.mode'](sent,caller)
            C.requestMode(suit,'repair');serverHandlers[protocol..'.mode'](sent,caller)
            assert(#actions==2 and actions[1]=='sonar' and actions[2]=='repair','independent control was dropped')
        """)

    def test_sustained_control_spam_is_still_bounded(self):
        self.lua.execute("""
            local caller={Character=owner};local calls=0
            S.authorize=function() calls=calls+1 end
            for i=1,30 do C.requestMode(suit,'toggle');serverHandlers[protocol..'.mode'](sent,caller) end
            assert(calls>=2 and calls<=4,'initial burst must work without allowing unlimited requests')
            local before=calls;S.now=S.now+1
            C.requestMode(suit,'repair');serverHandlers[protocol..'.mode'](sent,caller)
            assert(calls==before+1,'budget did not recover')
        """)
