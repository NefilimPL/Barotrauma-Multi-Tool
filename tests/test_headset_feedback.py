from lua_support import LuaCase


class HeadsetFeedbackTests(LuaCase):
    def test_server_warning_has_distinct_wire_kind_and_no_power_cost(self):
        self.lua.execute('''
            cell.Condition=20;G.checkPower(char,item)
            assert(#sent==1 and sent[1].bytes[1]==5 and sent[1].bytes[2]==2)
            assert(cell.Condition==20)
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            sent={}
            E={SERVER=true,Game={IsSingleplayer=false,Server={}},Networking={}}
            E.Networking.Start=function()
                local msg={bytes={},ids={}}
                msg.WriteByte=function(v) msg.bytes[#msg.bytes+1]=v end
                msg.WriteUInt16=function(v) msg.ids[#msg.ids+1]=v end
                return msg
            end
            E.Networking.Send=function(msg) sent[#sent+1]=msg end
            G=require('AegisHeadset.game').new(E)
            require('AegisHeadset.effects').install(G,E)
            cell={Condition=100,MaxCondition=100,HasTag=function() return true end}
            item={OwnInventory={GetItemAt=function() return cell end}}
            char={ID=42}
        ''')

    def test_power_levels_are_sent_for_distinct_audio_tiers(self):
        self.lua.execute('''
            for _,charge in ipairs({100,20,10,0}) do
                G.now=G.now+1;cell.Condition=charge;G.emit(char,item,'hit')
            end
            assert(#sent==4)
            for i=1,4 do assert(sent[i].bytes[2]==4-i and sent[i].ids[1]==42) end
        ''')

    def test_continuous_power_use_is_rate_limited_and_empty_alarm_is_once(self):
        self.lua.execute('''
            for i=1,60 do G.now=i/60;G.emit(char,item,'pressure') end
            assert(#sent<=3)
            cell.Condition=0;G.now=2
            for i=1,60 do G.now=G.now+1/60;G.emit(char,item,'pressure') end
            local empty=0
            for _,msg in ipairs(sent) do if msg.bytes[2]==0 then empty=empty+1 end end
            assert(empty==1)
        ''')

    def test_regrowth_delivery_is_never_suppressed_by_previous_empty_alarm(self):
        self.lua.execute('''
            cell.Condition=0;G.emit(char,item,'hit')
            G.emit(char,item,'restore',3)
            assert(#sent==2 and sent[2].bytes[1]==4 and sent[2].ids[2]==3)
        ''')
