#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const root=path.resolve(__dirname,'../..'), queue=JSON.parse(fs.readFileSync(path.join(root,'docs/autonomy/QUEUE.json'),'utf8'));
const stateDir=path.join(root,'.autonomy'), statePath=path.join(stateDir,'state.json'), dry=process.argv.includes('--dry-run');
function cmd(command,args){return cp.spawnSync(command,args,{cwd:root,encoding:'utf8',shell:process.platform==='win32',timeout:30000});}
function fatal(message){console.error('BLOCKED: '+message);process.exitCode=2;}
const branch=cmd('git',['branch','--show-current']);const status=cmd('git',['status','--porcelain']);
if(branch.status!==0||status.status!==0) fatal('Git unavailable');
else if(['','main','master'].includes(branch.stdout.trim()))fatal('Refuse default or detached branch');
else if(status.stdout.trim())fatal('Dirty worktree; preserve user changes');
else {
 const state=fs.existsSync(statePath)?JSON.parse(fs.readFileSync(statePath,'utf8')):{schema:1,completed:{},attempts:[]};
 const candidates=queue.tasks.filter(t=>t.status==='READY'&&!t.requires_approval&&!state.completed[t.id]&&!state.attempts.some(a=>a.id===t.id)&&t.depends_on.every(id=>state.completed[id]==='PASS')).sort((a,b)=>a.priority-b.priority);
 const selected=candidates[0];
 if(!selected)console.log('NO_ELIGIBLE_TASK; pending approvals/dependencies or queue exhausted');
 else if(dry)console.log(JSON.stringify({selected,branch:branch.stdout.trim(),mode:'DRY_RUN'},null,2));
 else {
  fs.mkdirSync(stateDir,{recursive:true});
  const lock=path.join(stateDir,'lock');
  let fd;try{fd=fs.openSync(lock,'wx');}catch{fatal('Another controller lock exists; inspect before retry');process.exit(2);}
  try{
   const sha=cmd('git',['rev-parse','HEAD']).stdout.trim();
   const prompt='Aetherwake task '+selected.id+': '+selected.title+'\nRead AGENTS.md and docs/autonomy/README.md. Never merge/push/release or change canon/approval. Work only in this branch and provide exact evidence. Stop after this one task.';
   const result=cp.spawnSync('codex',['exec','--sandbox','workspace-write',prompt],{cwd:root,encoding:'utf8',shell:process.platform==='win32',timeout:45*60*1000,maxBuffer:8*1024*1024});
   state.attempts.push({id:selected.id,base_sha:sha,finished_at:new Date().toISOString(),exit_status:result.status,phase:result.status===0?'REVIEW_REQUIRED':'BLOCKED',error:(result.error&&result.error.message)||null});
   fs.writeFileSync(statePath,JSON.stringify(state,null,2)+'\n');
   console.log(JSON.stringify(state.attempts[state.attempts.length-1]));
   if(result.status!==0)process.exitCode=1;
  }finally{fs.closeSync(fd);fs.unlinkSync(lock);}
 }
}
