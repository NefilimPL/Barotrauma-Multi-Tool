/* Shared math and interaction rules for the local asset preview, not a game adapter. */
(function(root){
"use strict";
const modes=["off","repair","combat","grab"];
const finite=n=>Number.isFinite(n)?n:0;
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function armPose(base,goal,a=86,b=76,bend=-1,reach=a+b){
  const dx=finite(goal.x-base.x),dy=finite(goal.y-base.y);
  const raw=Math.hypot(dx,dy),direction=raw>1e-6?Math.atan2(dy,dx):0;
  const d=clamp(raw,Math.abs(a-b)+.001,Math.min(reach,a+b)-.001);
  const offset=Math.acos(clamp((a*a+d*d-b*b)/(2*a*d),-1,1))*(bend<0?-1:1);
  return {base:{...base},elbow:{x:base.x+a*Math.cos(direction+offset),y:base.y+a*Math.sin(direction+offset)},
    tip:{x:base.x+d*Math.cos(direction),y:base.y+d*Math.sin(direction)}};
}
function repairContact(base,target,reach=162,beam=18){
  const dx=target.x-base.x,dy=target.y-base.y,d=Math.hypot(dx,dy);
  const r=Math.max(0,Math.min(reach,d-Math.min(beam,d)));
  return {reachable:d<=reach+beam,contact:{...target},tip:d>1e-6?
    {x:base.x+dx/d*r,y:base.y+dy/d*r}:{...base}};
}
function toolPose(base,target,rest){
  let goal=rest;
  if(target){
    const dx=target.x-base.x,dy=target.y-base.y,d=Math.hypot(dx,dy);
    const x=d>1e-6?dx/d:1,y=d>1e-6?dy/d:0;
    goal={x:target.x-x*76,y:target.y-y*76};
  }
  const pose=armPose(base,goal,152,132,-1,236);
  pose.angle=target?Math.atan2(target.y-pose.tip.y,target.x-pose.tip.x):0;
  pose.muzzle={x:pose.tip.x+Math.cos(pose.angle)*48,y:pose.tip.y+Math.sin(pose.angle)*48};
  return pose;
}
function setMode(state,mode){
  if(!modes.includes(mode))return false;
  if(state.mode!==mode){state.mode=mode;state.targetId=null;state.action=null;}
  return true;
}
function breathing(e){
  const open=e.hasHull===true&&e.wetHead!==true&&e.oxygen>=50&&e.pressure<20;
  return {open,useTank:false,closedLoop:!open};
}
function energy(source){
  if(!source||!Array.isArray(source.tags)||!source.tags.some(t=>t==="mobilebattery"||t==="reactorfuel")
    ||!(source.maxCondition>0))return 0;
  return clamp(finite(source.condition/source.maxCondition*100),0,100);
}
function chooseAction(mode,targets,options={}){
  if(!options.powered||!modes.includes(mode)||mode==="off")return null;
  const list=targets.filter(t=>{
    if(t.visible!==true||!Number.isFinite(t.distance)||t.distance<0)return false;
    if(mode==="repair")return ["device","wall"].includes(t.kind)&&t.health<1&&t.distance<=420;
    if(mode==="combat")return options.ammo!==false&&t.kind==="enemy"&&t.hostile===true&&t.alive===true&&t.distance<=1800;
    return t.id===(options.indicatedId??options.pinnedId)&&!t.parentInventory&&t.distance<=320
      &&["object","ally","enemy"].includes(t.kind);
  });
  list.sort((a,b)=>{
    if(a.id===options.pinnedId)return -1;if(b.id===options.pinnedId)return 1;
    if(mode==="repair"&&!!a.emergency!==!!b.emergency)return a.emergency?-1:1;
    return a.distance-b.distance||a.id-b.id;
  });
  const target=list[0];return target?{kind:mode==="repair"?(target.kind==="wall"?"weld":"repair"):mode,target}:null;
}
function chooseAI(targets,options={}){
  if(!options.powered)return {mode:"off",action:null};
  const danger=chooseAction("combat",targets.filter(t=>t.threat===true),options);
  if(danger)return {mode:"combat",action:danger};
  const repair=chooseAction("repair",targets,options);
  if(repair)return {mode:"repair",action:repair};
  const rescue=targets.find(t=>t.kind==="ally"&&t.rescue===true&&t.visible===true&&t.distance<=320);
  const action=rescue&&chooseAction("grab",targets,{...options,indicatedId:rescue.id});
  return action?{mode:"grab",action}:{mode:"off",action:null};
}
const sprites={"assembled": {"sheet": "suit", "rect": [1285, 769, 108, 255]}, "torso": {"sheet": "suit", "rect": [113, 5, 179, 251]}, "waist": {"sheet": "suit", "rect": [467, 80, 219, 151]}, "helmetClosed": {"sheet": "suit", "rect": [850, 10, 220, 241]}, "helmetOpen": {"sheet": "suit", "rect": [1234, 10, 220, 242]}, "upperArm": {"sheet": "suit", "rect": [120, 263, 144, 240]}, "forearm": {"sheet": "suit", "rect": [518, 267, 111, 238]}, "hand": {"sheet": "suit", "rect": [907, 308, 124, 171]}, "thigh": {"sheet": "suit", "rect": [1273, 257, 143, 255]}, "calf": {"sheet": "suit", "rect": [136, 515, 117, 253]}, "boot": {"sheet": "suit", "rect": [456, 568, 239, 158]}, "upperLink": {"sheet": "arm", "rect": [792, 590, 336, 101]}, "lowerLink": {"sheet": "arm", "rect": [1185, 598, 319, 81]}, "emitter": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "rotor": {"sheet": "arm", "rect": [461, 777, 229, 247]}, "backpack": {"sheet": "arm", "rect": [461, 777, 229, 247]}, "redEmitter": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "blueEmitter": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "orangeEmitter": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "redBeam": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "blueBeam": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "orangeBeam": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "redSpark": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "blueSpark": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "orangeRing": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "rotor0": {"sheet": "arm", "rect": [461, 777, 229, 247]}, "rotor1": {"sheet": "arm", "rect": [461, 777, 229, 247]}, "rotor2": {"sheet": "arm", "rect": [461, 777, 229, 247]}, "rotor3": {"sheet": "arm", "rect": [461, 777, 229, 247]}, "red": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "blue": {"sheet": "arm", "rect": [45, 841, 293, 113]}, "orange": {"sheet": "arm", "rect": [45, 841, 293, 113]}};
root.DescendantPreview={modes,armPose,repairContact,toolPose,setMode,breathing,energy,chooseAction,chooseAI,sprites};
})(globalThis);

