local dict={}
do
 local word={}
 local file=io.open(exist("ts_fanganlianxi.txt"),"r")
 for line in file:lines() do
  local a,b=line:match("^(.-)\t(.+)$")
  if a and b then
   word[a]=b
  end
 end
 file:close()

 local map={}
 local file=io.open(exist("ts_fanganlianxi_algebra.txt"),"r")
 for line in file:lines() do
  local a,b=line:match("^(.-)\t(.+)$")
  if a and b then
   map[a]=b
  end
 end
 file:close()

 for k,v in pairs(word) do
  table.insert(dict,{k,(v:gsub("%a+",map) or v)})
 end
end
local limit=#dict
math.randomseed(os.time())

local cands={}
cands.tab={}
cands.insert=function(self)
 local dict=dict[math.random(1,limit)]
 table.insert(self.tab,{["text"]=dict[1],["code"]=dict[2],["pattern"]=dict[2]:gsub(" ","")})
 return self
end
cands.remove=function(self)
 table.remove(self.tab,1)
 return self
end
for i=1,10 do
 cands:insert()
end

local status={
 ["hit_table"]={},
 ["hit_count"]=0,
 ["lianxu"]=0,
 ["duan"]=false,
 ["combo"]=0,
 ["time_limit"]=5,
 ["time_last"]=nil,
 ["now"]=os.time()
}
status.reset=function(self)
 self.hit_table={}
 self.hit_count=0
 self.lianxu=0
 self.duan=false
 self.combo=0
 self.time_limit=5
 self.time_last=nil
 self.now=os.time()
end
status.hit_update=function(self,time)
 if self.hit_table[1] and os.time()-self.hit_table[1][1]>(time or 60) then
  self.hit_count=self.hit_count-(self.hit_table[1][2])
  table.remove(self.hit_table,1)
  self:hit_update(time)
 end
end
status.lianxu_update=function(self,input)
 if self.lianxu then
  if #input<self.lianxu then
   self.combo=0
   local a=self.lianxu-#input==1
   self.lianxu=false
   if a then return true end
  elseif #input-self.lianxu<=1 then
   self.lianxu=#input
  end
 else
  self.combo=0
 end
end
status.print_combo=function(self)
 local str=tostring(self.combo)
 if #str>1 then return str.." " end
 local combo_map={["1"]="１",["2"]="２",["3"]="３",["4"]="４",["5"]="５",["6"]="６",["7"]="７",["8"]="８",["9"]="９",["0"]="０"}
 str=str:gsub("[0-9]",combo_map)
 return str
end
status.time_used=function(self)
 return self.now-self.time_last
end
local tip_map={}
tip_map.wrong={"Wrong!","Try harder!","Open your Eyes!","What is wrong with you?","Don't hit that.","You blind?","Stop.","Go do something else.","Wait...","What?","Why.","Idiot.","Can't even worse.","I wish that did't..."}
return
{
 function(_,env)
  if not env.engine.context:has_menu() then return 2 end
  if _:repr()=="space" then return 1 end
  status.now=os.time()
  local ctx=env.engine.context
  local ctx_inp=ctx.input
  local ctx_inp_l=#ctx_inp
  local input=ctx_inp:sub(2)
  if status:lianxu_update(input) then
   tips(env,"I see that.")
  end
  local key=_:repr()
  if key=="x" then--clear
   ctx:pop_input(ctx_inp_l-1)
   return 1
  elseif key=="c" then
   ctx:pop_input((ctx_inp_l-1)%2 and 2 or 1)
   return 1
  elseif key=="v" then--skip
   cands:remove():insert()
   ctx:push_input("z")
   ctx:pop_input(1)
   return 1
  elseif key=="b" then--reset
   status:reset()
   return 1
  end
  if input==cands.tab[1].pattern then
   cands:remove():insert()
   table.insert(status.hit_table,{os.time(),utf8.len(cands.tab[1].text)})
   ctx:pop_input(ctx_inp_l-1)
   status.hit_count=status.hit_count+utf8.len(cands.tab[1].text)
   if status.combo~=0 and status:time_used()>status.time_limit then
    tips(env,"Wait too long!")
    status.lianxu=false
   else
    if not status.time_last or status:time_used()>60 then
     tips(env,"First!")--第一击
    elseif status.lianxu then
     if status.combo>4 then
      tips(env,status:print_combo().."Combo!")--五连起显示连击次数
     else
      local len=utf8.len(cands.tab[1].text)
      if status:time_used()<len*(1.5-0.125*len) then
       tips(env,"Excellent!")
      else
       tips(env,"Perfect!")
      end
     end
    end
    status.lianxu=0
    status.combo=status.combo+1
   end
   status.time_last=os.time()
   return 1
  elseif #input==#(cands.tab[1].pattern) then
   ctx:pop_input(ctx_inp_l-1)
   if status.combo>4 then
    tips(env,"So sad!")
   else
    tips(env,tip_map.wrong[math.random(1,#tip_map.wrong)])
   end
   status.lianxu=false
   return 1
  end
  return 2
 end,
 function(input,seg,env)
  status:hit_update()
  tips(env,"〔"..status.hit_count.."/min〕")
  for i=1,#cands.tab do
   local cand=Candidate("",seg.start,seg._end,cands.tab[i].text,cands.tab[i].code)
   cand.preedit=input:sub(2)
   yield(cand)
  end
 end
}