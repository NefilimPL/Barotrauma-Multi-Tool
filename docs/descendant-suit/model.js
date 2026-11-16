/* Shared math and interaction rules for the local asset preview, not a game adapter. */
(function(root){
"use strict";
const modes=["off","repair","combat","grab"];
const finite=n=>Number.isFinite(n)?n:0;
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function armPose(base,goal,a=86,b=76,bend=-1){
  const dx=finite(goal.x-base.x),dy=finite(goal.y-base.y);
  const raw=Math.hypot(dx,dy),direction=raw>1e-6?Math.atan2(dy,dx):0;
  const d=clamp(raw,Math.abs(a-b)+.001,a+b-.001);
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
function setMode(state,mode){
  if(!modes.includes(mode))return false;
  if(state.mode!==mode){state.mode=mode;state.targetId=null;state.action=null;}
  return true;
}
function breathing(e){
  const open=e.hasHull===true&&e.wetHead!==true&&e.oxygen>=50&&e.pressure<20;
  return {open,useTank:!open};
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
    if(mode==="repair")return ["device","wall"].includes(t.kind)&&t.health<1&&t.distance<=180;
    if(mode==="combat")return t.kind==="enemy"&&t.hostile===true&&t.alive===true&&t.distance<=420;
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
const sprites={
  assembled:{sheet:"suit",rect:[0,0,335,1015]},
  torso:{sheet:"suit",rect:[785,100,255,320]},waist:{sheet:"suit",rect:[795,410,235,125]},
  helmetClosed:{sheet:"suit",rect:[1040,60,250,245]},helmetOpen:{sheet:"suit",rect:[1295,45,240,260]},
  upperArm:{sheet:"suit",rect:[1055,300,175,185]},forearm:{sheet:"suit",rect:[1080,495,165,160]},
  hand:{sheet:"suit",rect:[1100,640,150,115]},thigh:{sheet:"suit",rect:[745,600,200,280]},
  calf:{sheet:"suit",rect:[945,690,140,220]},boot:{sheet:"suit",rect:[940,890,190,120]},
  backpack:{sheet:"suit",rect:[1240,305,290,435]},
  upperLink:{sheet:"arm",rect:[270,60,435,145]},lowerLink:{sheet:"arm",rect:[730,50,325,145]},
  wrist:{sheet:"arm",rect:[1060,75,210,100]},claw:{sheet:"arm",rect:[1290,20,235,185]},
  red:{sheet:"arm",rect:[160,215,290,190]},blue:{sheet:"arm",rect:[615,215,290,190]},
  orange:{sheet:"arm",rect:[1075,215,290,190]},
  redBeam:{sheet:"arm",rect:[40,425,1460,55]},blueBeam:{sheet:"arm",rect:[40,490,1460,55]},
  orangeBeam:{sheet:"arm",rect:[40,565,1460,65]},
  redSpark:{sheet:"arm",rect:[265,640,110,110]},blueSpark:{sheet:"arm",rect:[725,640,125,115]},
  orangeRing:{sheet:"arm",rect:[1195,625,115,120]},
  rotor0:{sheet:"arm",rect:[20,755,275,260]},rotor1:{sheet:"arm",rect:[325,755,275,260]},
  rotor2:{sheet:"arm",rect:[615,755,275,260]},rotor3:{sheet:"arm",rect:[910,755,275,260]}
};
root.DescendantPreview={modes,armPose,repairContact,setMode,breathing,energy,chooseAction,chooseAI,sprites};
})(globalThis);

