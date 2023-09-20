local entry_exists <const> =function(dir,str)
 local file=io.open(dir,"r");
 if file then
  for line in file:lines() do
   if line==str then
    file:close();
    return true;
   end;
  end;
  file:close();
  return false;
 end;
end;
local save_dict <const> =function(dict_dir,unconfirm)
 local content=entry_exists(dict_dir,unconfirm) and
     io.open(dict_dir,"r"):read("*all"):gsub("\n"..unconfirm:gsub("([%%%(%)%[%]%-*+?%.%^])","%%%1"),"");
 return content and io.open(dict_dir,"w"):write(content):close() and true or
     io.open(dict_dir,"a"):write("\n"..unconfirm):close() and false;
end;
local sucVfail <const> =function(bool) return bool and "用户词已删除" or "已保存为用户词"; end;
local en <const> ={1000000};
en[2]=exist("_dict/_dic_en/user_en.dict.yaml");
return
{
 func=function(_,seg,env)
  local input <const> =env.engine.context.input;
  if input:find(".%-=$") then
   local inp <const> =input:sub(1,-3):gsub("|"," ");
   yield(Candidate("ensaver_cand",seg.start,seg._end,inp,""));
   local code <const> =inp:gsub("[^%a]+",""):lower();
   local unconfirm <const> =inp.."\t"..code.."\t"..en[1];
   yield(Candidate("ensaver_done",seg.start,seg._end,"^",sucVfail(save_dict(en[2],unconfirm))));
   yield(Candidate("ensaver_comment",seg.start,seg._end,"v",unconfirm));
  end;
 end,
};