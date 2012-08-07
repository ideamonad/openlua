import "std.ol"

syntax logfuncSyntax :
[[
logfunc : function funcname funcbody
]]

transformer LOG
   local tree,errormsg = parse(logfuncSyntax)
   if nil == tree then
      return nil,errormsg
   end

   local funcname = tree:get_child(2)
   local parlist = tree:get_child(3):get_child(2)
   local body = tree:get_child(3):get_child(4)
   
   local codestr = "function "..funcname:emit().."("..parlist:emit()..")\n"
   codestr = codestr.." print(\"enter "..funcname:emit().."\"); "
   local bodystr,occurs = 
      string.gsub(body:emit(),
		  "(return)",
		  " print(\"leave "..funcname:emit().."\"); %1")

   if 0 == occurs then
      bodystr = bodystr.." print(\"leave "..funcname:emit().."\");"
   end

   codestr = codestr..bodystr.." end"
   
   return codestr
end