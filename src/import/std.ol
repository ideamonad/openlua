
syntax metablockSyntax :
[[
metablock : block endmeta
]]

transformer meta
   if not lock() then
      return nil,"meta transformers can't internest"
   end
      
   local tree,error = parse(metablockSyntax)
   if nil == tree then
      return nil,error
   end

   local f = loadstring(tree:get_child(1):emit())
   setfenv(f,_METAENV)
   local succeed,msg = pcall(f)
   if not succeed then
      return nil,"metaprogram run error : "..msg
   end

   unlock()
   
   return ""
end

syntax defmacroSyntax :
[[
def : Name macro_parlist Literal

macro_parlist : '(' parname_list ')' | empty
]]

syntax macrocallSyntax :
[[
macrocall : macro_arglist

macro_arglist : '(' explist ')' | empty
]]

meta
   local function walk(parname_list)
      if 3 == parname_list:children_count() then
	 coroutine.yield(walk(parname_list:get_child(1)))
	 return parname_list:get_child(3):emit()
      else
	 return parname_list:get_child(1):emit()
      end
   end

   function allnames(parname_list)
      local f = coroutine.create(walk)
      return function ()
		   local correct,res = coroutine.resume(f,parname_list)
		   if correct then
		      return res
		   end
		   return nil
		end
   end

   local function create_replace(parname,argname)
      return function (id)
	 if id == parname then 
	    return argname
	 else 
	    return id
	 end
      end
   end

   function macrobodysub(macrobody,parnames,arglist)
      if "empty" == arglist:name() then
	 return macrobody
      end

      local i = 0
      for arg in allnames(arglist) do
	 i = i + 1
	 if nil == parnames[i] then
	    break
	 end
	 macrobody = 
	    string.gsub(macrobody,
			"[_%a][_%w]*",
			create_replace(parnames[i],arg))
      end

      return macrobody
   end
endmeta

transformer defmacro
   local tree,error = parse(defmacroSyntax)
   if nil == tree then
      return nil,error
   end

   local macrotext = tree:get_child(3)
   local macroParlist = tree:get_child(2)
   local codestr = "\ntransformer "..tree:get_child(1):emit().. 
[[
local macrobody = 
]]..

macrotext:emit()..

[[
   local parnames = {}
]]

   if "empty" ~= macroParlist:get_child(1):name() then
      local i = 1
      for name in allnames(macroParlist:get_child(2)) do
	 codestr = codestr.."parnames["..i.."] = '"..name.."'\n"
        i = i + 1
      end
   end

   codestr = codestr..
[[
   local tree,error = parse(macrocallSyntax)
   
   if nil == tree then
      return nil,error
   end

   local arglist = tree:get_child(1)

   if "empty" ~= arglist:get_child(1):name() then
      macrobody = macrobodysub(macrobody,parnames,arglist:get_child(2))
   end

   return macrobody
end
]]

   return codestr
end

syntax textSyntax : 
[[
textcall : '(' exp ')'
]]

transformer text
   local tree,error = parse(textSyntax)
   if nil == tree then
      return nil,error
   end

   local f = loadstring("return "..tree:get_child(2):emit())
   setfenv(f,_METAENV)

   return tostring(f())
end

syntax whenSyntax : 
[[
when : '(' exp ')' block elsewhenpart finalpart endwhen

elsewhenpart : elsewhen '(' exp ')' block elsewhenpart
             | empty

finalpart : else block
          | empty
]]

meta
   function pick(part)
      if "empty" == part:get_child(1):name() then
	 return nil
      end
      
      local exp = part:get_child(3)
      local f =loadstring("return "..exp:emit())
      setfenv(f,_METAENV)
      local succeed,cond = pcall(f)
      if not succeed then
	 return nil,"error occurs when get metaexp : "..msg
      end

      if cond then
	 return part:get_child(5)
      end
      
      return pick(part:get_child(6))
   end
endmeta

transformer when
   local tree,error = parse(whenSyntax)
   if nil == tree then
      return nil,error
   end

   local exp = tree:get_child(2)
   local f =loadstring("return "..exp:emit())
   setfenv(f,_METAENV)
   local succeed,res = pcall(f)
   if not succeed then
      return nil,"error occurs when get metaexp : "..msg
   end

   if res then
      
      return tree:get_child(4):emit()
   end
   
   local body,someerror
   local elsewhenpart = tree:get_child(5)
   if "empty" ~= elsewhenpart:name() then
      body,someerror = pick(elsewhenpart)
   end

   if nil ~= someeror then
      return nil, someerror
   end

   if nil ~= body then
      return body:emit()
   end

   -- ·µ»ØfinalpartµÄÄÚÈÝ
   local finalpart = tree:get_child(6)
   if "empty" == finalpart:get_child(1):name() then
      return ""
   else
      return finalpart:get_child(2):emit()
   end
end

syntax loopSyntax :
[[
loop : '(' exp ')' Literal with block endloop
]]

transformer loop
   local tree,error = parse(loopSyntax)
   if nil == tree then
      return nil,error
   end
   
   local exp = tree:get_child(2)
   local f =loadstring("return "..exp:emit())
   setfenv(f,_METAENV)
   local succeed,res = pcall(f)
   if not succeed then
      return nil,"error occurs when get metaexp : "
   end
   
   local codestr = ""
   if true == res then
      codestr = tree:get_child(4):value()
      codestr = codestr.."\nmeta\n"..tree:get_child(6):emit().."\nendmeta"
      codestr = codestr.."\nloop"..tree:emit()
   end

   return codestr
end