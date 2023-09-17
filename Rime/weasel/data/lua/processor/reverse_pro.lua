local prefix_len
local symbol
local keyMap={['space']=-1,['0']=9,['1']=0,['2']=1,['3']=2,['4']=3,['5']=4,['6']=5,['7']=6,['8']=7,['9']=8,['KP_0']=9,['KP_1']=0,['KP_2']=1,['KP_3']=2,['KP_4']=3,['KP_5']=4,['KP_6']=5,['KP_7']=6,['KP_8']=7,['KP_9']=8,}
return
{
 init=function(env)
  symbol=env.engine.schema.config:get_string("recognizer/lua/"..env.name_space)
  prefix_len=#symbol
 end,
 func=function(key,env)
  local ctx=env.engine.context
  if ctx:has_menu() then
   local index=keyMap[key:repr()]
   if not index then
    return 2
   end
   local seg=ctx.composition:back()
   if index>-1 then
    local page_size=env.engine.schema.page_size
    seg.selected_index=index+math.floor(seg.selected_index/page_size)*page_size
   end
   local cand=seg:get_selected_candidate()
   if cand.type=="fancha" then
    local ctxlen=#ctx.input
    local result=cand.text:gsub("[^%a;]",""):lower()
    if cand._end~=ctxlen then
     result=result..symbol
     if seg._end==ctxlen then
      result=result..ctx.input:sub(cand._end+1)
     end
    end
    ctx:pop_input(prefix_len+seg.length)
    ctx:push_input(result)
    ctx.caret_pos=#ctx.input
    return 1
   end
  end
 end
}