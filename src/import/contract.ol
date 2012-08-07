syntax contractfuncSyntax : 
[[
cf : Name ':' Name '(' optional_parlist ')' pre block post end

pre : require ':' exp end
    | empty

post : ensure ':' exp end
     | empty
]]

transformer contractfunc
   local tree,error = parse(contractfuncSyntax)
   if nil == tree then
      return nil, error
   end
      
   local parList = tree:get_child(5):emit()
   if "" == parList then
      parList = "self"
   else
      parList = "self,"..parList
   end

   local body = tree:get_child(8)
   local bodystr,occurs = 
      string.gsub(body:emit(),
                  "(return)",
                  "send("..parList..") %1")

   if 0 == occurs then
      bodystr = bodystr.."send("..parList..") "
   end

   local codestr = "local function temp("..parList..")"..bodystr.."\nend\n"

   local typename = tree:get_child(1):emit()
   local funcname = tree:get_child(3):emit()

   local pre = tree:get_child(7)
   local post = tree:get_child(9)
   local prestr,poststr

   if "empty" ~= pre:get_child(1):name() then
      prestr = pre:get_child(3):emit()
   else
      prestr = ""
   end

   if "empty" ~= post:get_child(1):name() then
      poststr = post:get_child(3):emit()
   else
      poststr = ""
   end

   local contractParList = 
      "(temp,'"..parList.."','"..prestr.."','"..poststr.."',true)"
   codestr = codestr..
typename.."."..funcname..
" = Contract.EquipAssert"..contractParList.."\n"

   codestr = codestr.."temp = nil"
   return codestr
end

syntax invSyntax :
[[
inv : Name ':' exp end
]]

transformer invariant
   local tree,error = parse(invSyntax)
   if nil == tree then
      return nil, error
   end

   local typename = tree:get_child(1):emit()
   local expstr = tree:get_child(3):emit()

   local codestr = "function "..typename..":__invariant() return "..expstr.." end"

   return codestr
end