/* Standalone local asset viewer; no framework, network service or installation. */
(async function(){
"use strict";
const C=DescendantPreview,canvas=document.getElementById("scene"),ctx=canvas.getContext("2d");
const $=id=>document.getElementById(id),asset="../../MULTI-TOOL-V2/Assets/DescendantSuit/";
const images={};
await Promise.all(["suit","arm"].map(key=>new Promise((resolve,reject)=>{
  const im=new Image();im.onload=()=>{images[key]=im;resolve();};im.onerror=()=>reject(new Error("Nie można wczytać "+key));im.src=asset+key+".png";
})));
const state={mode:"repair",targetId:1,action:null};
const at={x:480,y:390},base={x:420,y:282};
let targets=[],sparks=[],time=0,last=0,helmetOpen=1,tip={x:455,y:320},audioEnabled=false;
const loops={},oneshots={},colors={repair:"#71ccff",weld:"#71ccff",combat:"#ff4545",grab:"#ffad42"};
function reset(){targets=[
  {id:1,kind:"device",x:570,y:262,health:.3,label:"Urządzenie"},
  {id:2,kind:"wall",x:307,y:345,health:.45,emergency:true,label:"Uszkodzona ściana"},
  {id:3,kind:"enemy",x:790,y:240,health:1,alive:true,hostile:true,threat:true,label:"Przeciwnik"},
  {id:4,kind:"ally",x:680,y:455,health:.3,alive:true,rescue:true,label:"Ranny nurek"}
];sparks=[];state.targetId=1;}
reset();
function one(name){if(!audioEnabled)return;const a=new Audio(asset+"Audio/"+name+".ogg");a.volume=.22;a.play().catch(()=>{});}
function soundLoop(slot,name){
  if(loops[slot]&&loops[slot].name!==name){loops[slot].audio.pause();delete loops[slot];}
  if(!audioEnabled||!name){if(loops[slot]){loops[slot].audio.pause();delete loops[slot];}return;}
  if(!loops[slot]){const a=new Audio(asset+"Audio/"+name+".ogg");a.loop=true;a.volume=slot==="motor"?.12:.20;a.play().catch(()=>{});loops[slot]={name,audio:a};}
}
$("audio").onclick=()=>{audioEnabled=!audioEnabled;$("audio").textContent=audioEnabled?"Wyłącz dźwięk":"Włącz dźwięk";one("switch");};
for(const [name,label]of Object.entries({repair:"Naprawa",weld:"Spawanie",combat:"Promień bojowy",grab:"Chwytak",impeller:"Wirnik",servo:"Serwo",helmet:"Hełm",switch:"Przełącznik"})){
  const b=document.createElement("button");b.textContent=label;b.onclick=()=>{audioEnabled=true;$("audio").textContent="Wyłącz dźwięk";one(name);};$("sounds").append(b);
}
function mode(m){C.setMode(state,m);$("ai").checked=false;one("switch");}
document.querySelectorAll("[data-mode]").forEach(b=>b.onclick=()=>mode(b.dataset.mode));
$("device").onclick=()=>{mode("repair");state.targetId=1;};
$("wall").onclick=()=>{mode("repair");state.targetId=2;};
$("rescue").onclick=()=>{mode("grab");state.targetId=4;};
$("reset").onclick=reset;
function sprite(key,x,y,w,h,angle=0,alpha=1){const s=C.sprites[key];ctx.save();ctx.translate(x,y);ctx.rotate(angle);ctx.globalAlpha=alpha;ctx.drawImage(images[s.sheet],...s.rect,-w/2,-h/2,w,h);ctx.restore();}
function drawLink(key,a,b,span,origin){
  const s=C.sprites[key],r=s.rect,d=Math.hypot(b.x-a.x,b.y-a.y),scale=d/span;
  ctx.save();ctx.translate(a.x,a.y);ctx.rotate(Math.atan2(b.y-a.y,b.x-a.x));
  ctx.drawImage(images[s.sheet],...r,-origin[0]*scale,-origin[1]*scale,r[2]*scale,r[3]*scale);ctx.restore();
}
function line(a,b,color,width){ctx.strokeStyle=color;ctx.lineWidth=width;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();}
function suit(swim){
  const sway=swim?Math.sin(time*5)*.07:Math.sin(time*1.8)*.008;
  ctx.fillStyle="#182329";
  ctx.beginPath();ctx.roundRect(at.x-24,at.y-108,52,163,19);ctx.fill();
  ctx.fillRect(at.x-3,at.y-128,26,40);
  for(const offset of [-10,15]){ctx.beginPath();ctx.roundRect(at.x+offset-13,at.y+48,29,153,12);ctx.fill();}
  sprite("backpack",at.x-70,at.y-55,87,130);
  for(const [offset,shade]of [[-10,.6],[15,1]]){
    sprite("thigh",at.x+offset,at.y+80,65,91,sway*(offset<0?-1:1),shade);
    sprite("calf",at.x+offset+4,at.y+158,45,71,-sway,shade);
    sprite("boot",at.x+offset+12,at.y+207,65,41,0,shade);
  }
  sprite("waist",at.x,at.y+38,100,53);
  sprite("torso",at.x,at.y-43,111,139);
  ctx.fillStyle="#bd9f86";ctx.beginPath();ctx.ellipse(at.x+10,at.y-143,25,35,0,0,Math.PI*2);ctx.fill();
  sprite("helmetClosed",at.x+12,at.y-144,116,114,-helmetOpen*.1,1-helmetOpen);
  sprite("helmetOpen",at.x+10,at.y-148-helmetOpen*4,111,120,0,helmetOpen);
  sprite("upperArm",at.x-3,at.y-41,58,61,.03);
  sprite("forearm",at.x+5,at.y+12,54,52,-.07);
  sprite("hand",at.x+8,at.y+54,42,32);
  sprite("rotor"+(swim?Math.floor(time*18)%4:0),at.x-80,at.y+5,52,50);
}
function target(t){
  ctx.save();ctx.translate(t.x,t.y);
  if(t.kind==="device"){
    ctx.fillStyle="#43535a";ctx.strokeStyle="#91a7ad";ctx.lineWidth=2;ctx.fillRect(-35,-30,70,60);ctx.strokeRect(-35,-30,70,60);
    ctx.fillStyle="#63d4c9";ctx.fillRect(-21,-15,27,7);ctx.fillStyle="#1c292f";ctx.fillRect(-22,2,42,17);
  }else if(t.kind==="wall"){
    ctx.fillStyle="#3a4b54";ctx.fillRect(-17,-60,34,120);ctx.strokeStyle="#9cafba";ctx.strokeRect(-17,-60,34,120);
    if(t.health<1){ctx.strokeStyle="#75c7ec";ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(-8,-30);ctx.lineTo(8,-12);ctx.lineTo(-6,4);ctx.lineTo(9,26);ctx.stroke();}
  }else if(t.kind==="enemy"){
    ctx.fillStyle="#704c51";ctx.strokeStyle="#cf8991";ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(0,0,38,19,-.2,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.fillStyle="#ffb0a7";ctx.fillRect(-28,-4,6,4);
    for(let n=0;n<4;n++)line({x:-18+n*13,y:15},{x:-24+n*13,y:30},"#aa7e82",3);
  }else{
    ctx.rotate(-.35);ctx.fillStyle="#657e87";ctx.fillRect(-25,-12,52,24);ctx.fillStyle="#b8c6c7";ctx.beginPath();ctx.arc(36,0,15,0,Math.PI*2);ctx.fill();ctx.fillStyle="#283e4c";ctx.beginPath();ctx.arc(40,0,9,0,Math.PI*2);ctx.fill();
    line({x:-23,y:-6},{x:-51,y:-13},"#839ba3",11);line({x:-23,y:7},{x:-50,y:18},"#839ba3",11);
  }
  ctx.restore();ctx.font="13px system-ui";ctx.fillStyle="#b8c9d0";ctx.textAlign="center";ctx.fillText(t.label,t.x,t.y+(t.kind==="wall"?88:60));
  if(t.kind==="wall"||t.kind==="device"||t.kind==="enemy"){
    ctx.fillStyle="#17262c";ctx.fillRect(t.x-32,t.y+37,64,5);ctx.fillStyle=t.kind==="enemy"?"#d8858a":"#76c9b1";ctx.fillRect(t.x-32,t.y+37,64*Math.max(0,t.health),5);
  }
}
let drag=null;
function pointer(e){const r=canvas.getBoundingClientRect();return {x:(e.clientX-r.left)*canvas.width/r.width,y:(e.clientY-r.top)*canvas.height/r.height};}
canvas.onpointerdown=e=>{const p=pointer(e);drag=targets.find(t=>Math.hypot(t.x-p.x,t.y-p.y)<50);if(drag){canvas.setPointerCapture(e.pointerId);state.targetId=drag.id;}};
canvas.onpointermove=e=>{if(drag){const p=pointer(e);drag.x=p.x;drag.y=p.y;}};
canvas.onpointerup=()=>drag=null;canvas.onpointercancel=()=>drag=null;
let oldOpen=true,oldTarget=null;
function frame(now){
  const dt=Math.min(.05,(now-last)/1000||1/60);last=now;time+=dt;
  const water=$("water").checked,blocked=$("blocked").checked,hasEnemy=$("enemy").checked;
  const charge=Number($("charge").value),powered=charge>0&&$("source").value!=="none";
  const open=C.breathing({hasHull:!water,wetHead:water,oxygen:Number($("air").value),pressure:0}).open;
  helmetOpen+=(Number(open)-helmetOpen)*(1-Math.exp(-dt*9));if(open!==oldOpen){one("helmet");oldOpen=open;}
  const list=targets.filter(t=>t.kind!=="enemy"||hasEnemy).map(t=>({...t,distance:Math.hypot(t.x-base.x,t.y-base.y),visible:!blocked,alive:t.health>0}));
  let action;
  if($("ai").checked){const pick=C.chooseAI(list,{powered});C.setMode(state,pick.mode);action=pick.action;}
  else action=C.chooseAction(state.mode,list,{powered,pinnedId:state.targetId,indicatedId:state.targetId||4});
  state.action=action;
  document.querySelectorAll("[data-mode]").forEach(b=>b.classList.toggle("selected",state.mode===b.dataset.mode));
  const t=action&&targets.find(t=>t.id===action.target.id),kind=action&&action.kind;
  const goal=t?(kind==="repair"||kind==="weld"?C.repairContact(base,t,162,18).tip:{x:t.x,y:t.y}):{x:455,y:320};
  const blend=1-Math.exp(-dt*12);tip.x+=(goal.x-tip.x)*blend;tip.y+=(goal.y-tip.y)*blend;
  const pose=C.armPose(base,tip,86,76,-1);
  const close=!t||!(kind==="repair"||kind==="weld")||Math.hypot(t.x-pose.tip.x,t.y-pose.tip.y)<=31;
  const working=action&&close;
  let energyRate=water&&powered?.12:0;
  if(t&&working){
    if(kind==="repair"||kind==="weld")t.health=Math.min(1,t.health+dt*(kind==="weld"?.12:.06));
    if(kind==="combat")t.health=Math.max(0,t.health-dt*.04);
    if(kind==="grab"&&drag!==t){const d=Math.hypot(t.x-at.x,t.y-at.y);if(d>120){t.x+=(at.x-t.x)*dt*.7;t.y+=(at.y-t.y)*dt*.7;}}
    const costs={repair:.4,weld:.6,combat:1,grab:.5};
    energyRate+=costs[kind];
  }
  if(powered)$("charge").value=String(Math.max(0,charge-energyRate*dt*($("source").value==="rod"?.25:1)));
  soundLoop("beam",working?kind:null);soundLoop("motor",water&&powered?"impeller":null);
  const current=t&&t.id;if(current&&current!==oldTarget)one("servo");oldTarget=current;
  ctx.clearRect(0,0,canvas.width,canvas.height);
  ctx.strokeStyle="#bfd7de0b";ctx.lineWidth=1;
  for(let x=0;x<1180;x+=40){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,800);ctx.stroke();}
  for(let y=0;y<800;y+=40){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(1180,y);ctx.stroke();}
  ctx.fillStyle="#78929f";ctx.font="12px system-ui";ctx.textAlign="left";ctx.fillText(water?"ZANURZENIE / WIRNIKI":"POWIETRZE / AUTOMATYCZNY HEŁM",30,35);
  ctx.setLineDash([4,7]);ctx.strokeStyle="#73c3d22b";ctx.beginPath();ctx.arc(base.x,base.y,180,0,Math.PI*2);ctx.stroke();ctx.setLineDash([]);
  suit(water&&powered);
  targets.filter(t=>t.kind!=="enemy"||hasEnemy).forEach(target);
  if(blocked){ctx.fillStyle="#38474e";ctx.fillRect(622,170,20,320);ctx.strokeStyle="#728791";ctx.strokeRect(622,170,20,320);}
  drawLink("upperLink",base,pose.elbow,310,[65,75]);drawLink("lowerLink",pose.elbow,pose.tip,230,[65,75]);
  const angle=t?Math.atan2(t.y-pose.tip.y,t.x-pose.tip.x):.5;
  const head=kind==="combat"?"red":kind==="grab"?"orange":"blue";
  const r=C.sprites[head].rect;ctx.save();ctx.translate(pose.tip.x,pose.tip.y);ctx.rotate(angle);ctx.drawImage(images.arm,...r,-82*.17,-95*.17,r[2]*.17,r[3]*.17);ctx.restore();
  if(working){
    const color=colors[kind];ctx.save();ctx.shadowBlur=12;ctx.shadowColor=color;line(pose.tip,t,color,3);line(pose.tip,t,"#effaff",.9);ctx.restore();
    if(kind==="repair"||kind==="weld"){
      for(let n=0;n<Math.ceil(dt*150);n++){const a=Math.random()*Math.PI*2,v=120+Math.random()*260;sparks.push({x:t.x,y:t.y,vx:Math.cos(a)*v,vy:Math.sin(a)*v,life:.15+Math.random()*.2,age:0});}
      const glow=ctx.createRadialGradient(t.x,t.y,0,t.x,t.y,30);glow.addColorStop(0,"#eaffffdd");glow.addColorStop(.15,"#67caff88");glow.addColorStop(1,"#67caff00");ctx.fillStyle=glow;ctx.fillRect(t.x-30,t.y-30,60,60);
    }else if(kind==="grab"){ctx.strokeStyle="#ffad42";ctx.lineWidth=2;ctx.beginPath();ctx.arc(t.x,t.y,30+Math.sin(time*5)*3,0,Math.PI*2);ctx.stroke();}
  }
  sparks=sparks.filter(p=>p.age<p.life).slice(-100);
  for(const p of sparks){p.age+=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=250*dt;ctx.globalAlpha=Math.max(0,1-p.age/p.life);line({x:p.x-p.vx*.02,y:p.y-p.vy*.02},p,"#dcfaff",2);}
  ctx.globalAlpha=1;
  $("chargeLabel").textContent=Math.floor(Number($("charge").value))+"%";$("airLabel").textContent=$("air").value+"%";
  const actionLabels={repair:"Naprawa urządzenia",weld:"Spawanie ściany",combat:"Promień bojowy",grab:"Holowanie celu"};
  $("state").textContent=(working?actionLabels[kind]:action?"Ramię ustawia się przy celu":powered?"Oczekiwanie na cel":"Brak zasilania")+"\nHełm: "+(open?"odsłonięty":"zamknięty")+"\nTlen z butli: "+(open?"nie jest zużywany":"wymagany")+"\nAktywne funkcje ramienia: "+(working?"1":"0");
  requestAnimationFrame(frame);
}
const checks=runDescendantPreviewChecks(C),passed=checks.filter(c=>c.pass).length;
$("checks").textContent=passed+" / "+checks.length+" sprawdzeń zakończonych poprawnie.";
requestAnimationFrame(frame);
})().catch(e=>{document.getElementById("state").textContent=e.message;console.error(e);});
