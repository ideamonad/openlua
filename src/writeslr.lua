dofile("analyse.lua")


--[[----------------------------------------------------------
--          helper functions
----------------------------------------------------------]]--

local function Serialize (obj,outfile,bIsKey)
   if true == obj then
      outfile:write("true")
   elseif false == obj then
      outfile:write("false")
   elseif "string" == type(obj) then
      if bIsKey then
	 outfile:write(obj)
      else
	 outfile:write('"',obj,'"')
      end
   elseif "table" == type(obj) and
      nil ~= obj.Serialize then
      obj:Serialize(outfile)
   elseif "table" == type(obj) then
      outfile:write("{")
      local first = true
      for k,v in pairs(o) do
	 if first then
	    first = false
	 else
	    outfile:write(", ")
	 end
	 if "number" ~= type(k) then
	    Serialize(k,outfile,true)
	    outfile:write(" = ")
	 end
	 Serialize(v,outfile)
      end

      outfile:write("}")
   else
      outfile:write(obj)
   end
end

--把语法文件infilename精简成一个产生式只占一行，
--然后输出到outfilename
local function ReduceNewline(infilename,outfilename)
   local infile = io.open(infilename,"r")
   
   if infile == nil then
      error("Can't open "..infilename.." for reading!")
   end

   local outfile = io.open(outfilename,"w")
   if outfile == nil then
      error("Can't open "..outfilename.." for writing!")
   end

   local first = true
   for lines in infile:lines() do
      local _,ls_end,leftside = string.find(lines,"^%s*([_%a][_%w]*)%s*:")
      if nil ~= leftside then
	 -- 该行产生式的左部是一个新的非终结符
	 outfile:write("\n",leftside," : ") 
	 first = true
      end
      
      local rs_beg,rs_end,rightside
      if nil ~= ls_end then
	 rs_beg = ls_end + 1
      else
	 rs_beg = 1
      end
      
      rs_beg,rs_end,rightside = string.find(lines,"%s*([^|]*[^|%s])",rs_beg + 1)
      while rs_beg ~= nil do
	 if not IsSpaceStr(rightside) then
	    --找到一个新的右部
	    if first then
	       first = false
	    else
	       outfile:write(" | ")
	    end
	    outfile:write(rightside)
	 end
	 rs_beg,rs_end,rightside = string.find(lines,"%s*([^|]*[^|%s])",rs_end + 1)
      end
   end

   infile:close()
   outfile:close()
end

--[[----------------------------------------------------------
--          helper functions end
----------------------------------------------------------]]--


local function WriteRequirements(file)
   file:write(
[[require("common.lua")
require("set.lua")
require("list.lua")
require("prototype.lua")

]])
end

local function WritePrecedence(file)
   file:write([[
-- 运算符优先级表
local precedence = {}
precedence["or"] = 1
precedence["and"] = 2
precedence["<"] = 3
precedence[">"] = 3
precedence["<="] = 3
precedence[">="] = 3
precedence["~="] = 3
precedence["=="] = 3
precedence[".."] = 4
precedence["+"] = 5
precedence["-"] = 5
precedence["*"] = 6
precedence["/"] = 6
precedence["not"] = 7
precedence["-(unary)"] = 7
precedence["^"] = 8

]])
end

local function WriteFunc1(file)
   file:write([[
local function GetSelectorByBinopPrecedence(state)
   local function select(leftop,rightop)
      local bEqual = precedence[leftop] == precedence[rightop]
      if ".." == leftop or "^" == leftop then
	 -- ..运算符和^运算符是右结合的
	 bEqual = false
      end
      
      if precedence[leftop] > precedence[rightop] 
	 or bEqual then
	 return Production{"exp", Rightside{"exp", "binop", "exp"}}
      else
	 return state
      end
   end

   return select
end

]])
end

local function WriteFunc2(file)
   file:write([[
local function GetSelectorByLineNum(prod)
   local function select(lead_linenum,follow_linenum)
      if lead_linenum == follow_linenum then
	 return prod
      else
	 return nil
      end
   end

   return select
end

]])
end

local precedence = {}
precedence["or"] = 1
precedence["and"] = 2
precedence["<"] = 3
precedence[">"] = 3
precedence["<="] = 3
precedence[">="] = 3
precedence["~="] = 3
precedence["=="] = 3
precedence[".."] = 4
precedence["+"] = 5
precedence["-"] = 5
precedence["*"] = 6
precedence["/"] = 6
precedence["not"] = 7
precedence["-(unary)"] = 7
precedence["^"] = 8

-- local binops = 
--    Set{
--    '+' , '-' , '*' , '/' , '^' , '..',
--    '<' , '<=' , '>' , '>=' , '==' , '~=',
--    'and', 'or'
-- }

local function WriteTerminals(file,terminals,name)
   file:write("--  终结符集合\n")
   file:write(name.." = \n")
   terminals:Remove("empty")
   terminals:Serialize(file)
   file:write("\n")
end

local function WriteNonterminals(file,nonterminals,name)
   file:write("--  非终结符集合\n")
   file:write(name.." = \n")
   nonterminals:Remove("empty")
   nonterminals:Serialize(file)
   file:write("\n")
end

local function WriteFollowset(file,followset,name)
   file:write("-- followset\n")
   for nonterminal,follows in pairs(followset) do
      file:write(name.."['"..nonterminal.."'] = ")
      follows:Serialize(file)
      file:write("\n\n")
   end
end

local function WriteFirstset(file,firstset,name)
   file:write("-- firstset\n")
   for symbol,leadings in pairs(firstset) do
      file:write(name.."['"..symbol.."'] = ")
      leadings:Serialize(file)
      file:write("\n\n")
   end
end

local function write_initial_states(file,initialStates,name)
   file:write("-- initialStates\n")
   for symbol,state in pairs(initialStates) do
      file:write(name.."['"..symbol.."'] = "..state,"\n")
   end
end

local function WriteSlrTable(file,slr_table,table_name)
   file:write("-- SLR语法解析表\n\n")
   for i, row in slr_table:TraverseRows() do
      local row_str = table_name.."["..i.."]"
      file:write(row_str.." = {}\n")
      for j, entry in pairs(row) do
	 if 1 < entry:Count() then
	    file:write("\n")
	 end

	 file:write(row_str,'["',j,'"] = ')
	 
	 if 1 < entry:Count() then
	    -- 有冲突的项
	    
	    local unop_exp = Production{"exp", Rightside{"unop", "exp"}}
	    local binop_exp = Production{"exp", Rightside{"exp", "binop", "exp"}}
	    local result_part = Production{"result_part", Rightside{"empty"}}
	    keyname_entry = Set{Production{"var", Rightside{"Name"}}, Production{"keyname", Rightside{"Name"}}}

	    if entry == keyname_entry then
	       file:write([[Production{"keyname", Rightside{"Name"}}]])
	       file:write('\n--')
	    elseif entry:Contains(unop_exp) then
	       local level = precedence[j]
	       if nil == level then
		  -- j不是操作符
	       elseif level < precedence["not"] then
		  -- j的优先级小于unop
		  unop_exp:Serialize(file)
		  file:write('\n--')
	       else 
		  for e in entry:Traverse() do
		     if e ~= unop_exp then
			file:write(e)
			break
		     end
		  end
		  file:write('\n--')
	       end

	    elseif entry:Contains(binop_exp) then
	       file:write("GetSelectorByBinopPrecedence(")
	       for e in entry:Traverse() do
		  if e ~= binop_exp then
		     file:write(e)
		     break
		  end
	       end
	       file:write(')\n--')
	    elseif entry:Contains(result_part) then
	       for e in entry:Traverse() do
		  if e ~= result_part then
		     file:write(e)
		     break
		  end
	       end
	       file:write('\n--')
	    else
	       for e in entry:Traverse() do
		  if IsType(e,Production) then
		     if "prefixexp" == e:GetLeftside() then
			file:write("GetSelectorByLineNum(")
			e:Serialize(file)
			file:write(")\n--")
			break
		     end
		  end
	       end
	    end

	    entry:Serialize(file)
	    file:write("\n")

	 else -- if 1 < entry:Count() then
	    for e in entry:Traverse() do
	       if "table" ~= type(e) then
		  file:write(e)
	       else
		  e:Serialize(file)
	       end
	    end
	 end
	 file:write("\n")
      end
      file:write("\n")
   end
end

local function WriteSlrFile(filename,slrSyntax,name)
   local file = OpenOutputFile(filename)
   if nil == file then
      return
   end

   WriteRequirements(file)
   WritePrecedence(file)
   WriteFunc1(file)
   WriteFunc2(file)

   file:write("\n",name.." = {}\n")
   file:write(name..".start = '"..slrSyntax.start,"'\n")
   file:write(
[[

local firstset = {}
local followset = {}
local initialStates = {}
local parseTable = {}

]])
   file:write(name..".firstset = firstset\n")
   file:write(name..".followset = followset\n")
   file:write(name..".initialStates = initialStates\n")
   file:write(name..".parseTable = parseTable\n\n")
   
   WriteTerminals(file,slrSyntax.terminals,name..".terminals")
   file:write("\n")
   WriteNonterminals(file,slrSyntax.nonterminals,name..".nonterminals")
   file:write("\n")
   WriteFollowset(file,slrSyntax.followset,"followset")
   file:write("\n")
   WriteFirstset(file,slrSyntax.firstset,"firstset")
   file:write("\n")
   write_initial_states(file,slrSyntax.initialStates,"initialStates")
   file:write("\n")
   WriteSlrTable(file,slrSyntax.parseTable,"parseTable")

   file:close()
end

local syntax_fname = "syntax\\openlua-slr.stx"

local file = io.open(syntax_fname,"r")
local syntax = AnalyseSyntax(file)
file:close()

local bSlr
bSlr,syntax.parseTable,syntax.initialStates = EvaluateSlr(syntax)
if bSlr then
   print("syntax is SLR syntax!")
   io.flush()
else
   print("syntax is NOT SLR syntax!")
   io.flush()
end

WriteSlrFile("slr.lua",syntax,"gOpenluaSyntax")