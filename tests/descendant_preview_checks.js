/* Run with the actual preview model in a browser or a JavaScript host. */
globalThis.runDescendantPreviewChecks=function(C){
  const out=[];
  function test(name,fn){try{fn();out.push({name,pass:true});}catch(e){out.push({name,pass:false,error:e.message});}}
  function ok(value,message){if(!value)throw new Error(message||"Assertion failed");}
  function near(a,b){ok(Math.abs(a-b)<0.0001,a+" != "+b);}
  if(!C){test("preview model is available",()=>ok(false,"Missing DescendantPreview model"));return out;}
  test("arm cannot extend beyond its two physical links",()=>{
    for(const goal of [{x:1000,y:0},{x:-1000,y:0},{x:0,y:1000},{x:0,y:-1000}]){
      const p=C.armPose({x:0,y:0},goal,86,76,-1);
      near(Math.hypot(p.elbow.x,p.elbow.y),86);
      near(Math.hypot(p.tip.x-p.elbow.x,p.tip.y-p.elbow.y),76);
      ok(Math.hypot(p.tip.x,p.tip.y)<=162.0001);
    }
  });
  test("coincident target produces a finite folded pose",()=>{
    const p=C.armPose({x:5,y:7},{x:5,y:7},86,76,1);
    ok([p.tip.x,p.tip.y,p.elbow.x,p.elbow.y].every(Number.isFinite));
  });
  test("repair contact is placed at the damaged object",()=>{
    const p=C.repairContact({x:0,y:0},{x:170,y:0},162,18);
    ok(p.reachable);near(p.contact.x,170);near(p.contact.y,0);
    ok(Math.hypot(p.tip.x,p.tip.y)<=162);
    ok(Math.hypot(p.contact.x-p.tip.x,p.contact.y-p.tip.y)<=18.0001);
  });
  test("distant repair target cannot receive a beam",()=>{
    ok(!C.repairContact({x:0,y:0},{x:181,y:0},162,18).reachable);
  });
  test("repair contact follows a moving target",()=>{
    const a=C.repairContact({x:0,y:0},{x:100,y:0},162,18);
    const b=C.repairContact({x:0,y:0},{x:0,y:-100},162,18);
    near(a.contact.x,100);near(b.contact.x,0);near(b.contact.y,-100);
  });
  test("switching modes releases the previous grab",()=>{
    const state={mode:"grab",targetId:8,action:{kind:"grab"}};
    ok(C.setMode(state,"repair"));
    ok(state.mode==="repair"&&state.targetId===null&&state.action===null);
    ok(!C.setMode(state,"repair+combat"));
  });
  test("submersion closes the helmet even with room oxygen",()=>{
    const s=C.breathing({hasHull:true,wetHead:true,oxygen:100,pressure:0});
    ok(!s.open&&s.useTank);
  });
  test("breathable room air opens the helmet without tank consumption",()=>{
    const s=C.breathing({hasHull:true,wetHead:false,oxygen:100,pressure:0});
    ok(s.open&&!s.useTank);
  });
  test("vacuum and dangerous pressure keep the helmet closed",()=>{
    ok(C.breathing({hasHull:true,wetHead:false,oxygen:0,pressure:0}).useTank);
    ok(C.breathing({hasHull:true,wetHead:false,oxygen:100,pressure:90}).useTank);
    ok(C.breathing({hasHull:false,wetHead:false,oxygen:100,pressure:0}).useTank);
  });
  test("battery and reactor rod are accepted but an oxygen tank is not",()=>{
    near(C.energy({tags:["mobilebattery"],condition:25,maxCondition:50}),50);
    near(C.energy({tags:["reactorfuel"],condition:10,maxCondition:20}),50);
    near(C.energy({tags:["oxygensource"],condition:100,maxCondition:100}),0);
    near(C.energy({tags:["mobilebattery"],condition:0,maxCondition:100}),0);
  });
  const targets=[
    {id:1,kind:"device",distance:100,visible:true,health:.3},
    {id:2,kind:"wall",distance:120,visible:true,health:.4,emergency:true},
    {id:3,kind:"enemy",distance:200,visible:true,hostile:true,alive:true,threat:true},
    {id:4,kind:"ally",distance:80,visible:true,alive:true,rescue:true}
  ];
  test("repair mode can weld a wall",()=>{
    const a=C.chooseAction("repair",[targets[1]],{powered:true});
    ok(a.kind==="weld"&&a.target.id===2);
  });
  test("repair mode stays attached to its valid device target",()=>{
    const a=C.chooseAction("repair",targets,{powered:true,pinnedId:1});
    ok(a.kind==="repair"&&a.target.id===1);
  });
  test("blocked targets cannot be repaired, shot or grabbed",()=>{
    for(const mode of ["repair","combat","grab"]){
      const list=targets.map(t=>({...t,visible:false}));
      ok(C.chooseAction(mode,list,{powered:true,indicatedId:4})===null);
    }
  });
  test("combat ignores allies and dead creatures",()=>{
    const a=C.chooseAction("combat",[
      {...targets[3],kind:"enemy",hostile:false},
      {...targets[2],alive:false}
    ],{powered:true});
    ok(a===null);
  });
  test("grab selects one indicated living target",()=>{
    const a=C.chooseAction("grab",targets,{powered:true,indicatedId:4});
    ok(a.kind==="grab"&&a.target.id===4);
    ok(C.chooseAction("grab",targets,{powered:true})===null);
  });
  test("grab cannot pull an item out of someone else's inventory",()=>{
    ok(C.chooseAction("grab",[{id:9,kind:"object",distance:30,visible:true,parentInventory:true}],
      {powered:true,indicatedId:9})===null);
  });
  test("empty power source prevents every arm action",()=>{
    for(const mode of ["repair","combat","grab"]){
      ok(C.chooseAction(mode,targets,{powered:false,indicatedId:4})===null);
    }
  });
  test("AI chooses only one action and switches to emergency welding after danger",()=>{
    const a=C.chooseAI(targets,{powered:true});
    ok(a.mode==="combat"&&a.action.kind==="combat"&&a.action.target.id===3);
    const b=C.chooseAI(targets.filter(t=>t.id!==3),{powered:true});
    ok(b.mode==="repair"&&b.action.kind==="weld"&&b.action.target.id===2);
  });
  test("AI can rescue an indicated crewmate when other work is absent",()=>{
    const a=C.chooseAI([targets[3]],{powered:true});
    ok(a.mode==="grab"&&a.action.target.id===4);
    ok(C.chooseAI(targets,{powered:false}).action===null);
  });
  test("all source rectangles stay inside the two PNG sheets",()=>{
    for(const [name,r] of Object.entries(C.sprites)){
      ok(r.rect.length===4&&r.rect.every(Number.isFinite),name);
      const [x,y,w,h]=r.rect;
      ok(x>=0&&y>=0&&w>0&&h>0&&x+w<=1536&&y+h<=1024,name);
      ok(r.sheet==="suit"||r.sheet==="arm",name);
    }
  });
  return out;
};
