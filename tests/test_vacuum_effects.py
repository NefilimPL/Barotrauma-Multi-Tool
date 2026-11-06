from lua_support import LuaCase


class VacuumEffectsTests(LuaCase):
    def setUp(self):
        super().setUp()
        self.lua.execute("""
            plays={};channels={};local vacuum={ID=1,WorldPosition={X=1,Y=2}}
            G={now=1,states={[vacuum]={usedAt=1}},jobs={},pending={},remoteActiveUntil={},
                context=function() return {valid=true,aim=true,pack={}} end,charge=function() return 100 end}
            E={SoundPlayer={PlaySound=function(tag,position)
                plays[#plays+1]=tag;local ch={IsPlaying=true}
                ch.FadeOutAndDispose=function() ch.IsPlaying=false;ch.disposed=true end
                channels[#channels+1]=ch;return ch
            end},Vector2=function(x,y) return {X=x,Y=y} end,
                Vector3=function(x,y,z) return {X=x,Y=y,Z=z} end,
                Entity={FindEntityByID=function() return vacuum end}}
            require('SalvageVacuum.audio').install(G,E)
        """)

    def test_suction_loops_once_and_stops_when_use_ends(self):
        self.lua.execute("""
            G.updateAudio(.016);G.updateAudio(.016)
            assert(#plays==1 and plays[1]=='aegis_vacuum_suction' and channels[1].Looping)
            G.now=2;G.updateAudio(.016);assert(channels[1].disposed)
        """)

    def test_remote_salvage_uses_grinder_sound_and_cleanup_stops_all_channels(self):
        self.lua.execute("""
            G.onSalvage(1);assert(plays[1]=='aegis_vacuum_salvage')
            G.onSalvage(1);assert(#plays==1)
            G.updateAudio(.016);G.clearAudio()
            for _,ch in ipairs(channels) do assert(ch.disposed) end
        """)

    def test_remote_heartbeat_starts_suction_without_local_trigger_and_expires(self):
        self.lua.execute("""
            G.now=10;G.remoteActiveUntil[1]=10.4
            G.updateAudio();assert(#plays==1 and channels[1].Looping)
            G.now=10.5;G.updateAudio();assert(channels[1].disposed)
        """)

    def test_salvage_loop_is_reused_and_expires_after_last_progress_event(self):
        self.lua.execute("""
            G.onSalvage(1);assert(channels[1].Looping)
            G.now=1.3;G.onSalvage(1);assert(#plays==1)
            G.now=1.5;G.updateAudio();assert(not channels[1].disposed)
            G.now=2;G.updateAudio();assert(channels[1].disposed)
        """)

    def test_running_salvage_job_does_not_silence_active_suction(self):
        self.lua.execute("""
            local p={};G.context=function() return {valid=true,aim=true,pack=p} end
            G.jobs[p]={}
            G.updateAudio();assert(plays[1]=='aegis_vacuum_suction')
        """)

    def test_flow_moves_smoothly_inward_and_fades_at_wrap(self):
        self.lua.execute("""
            local V=require('SalvageVacuum.core')
            local a=V.flow(.31,3);local b=V.flow(.311,3)
            assert(b.distance<a.distance and math.abs(a.distance-b.distance)<1)
            assert(a.alpha>=0 and a.alpha<=1)
            local f,t=V.animation(1.01);assert(f>=0 and f<16 and t>0 and t<1)
        """)
