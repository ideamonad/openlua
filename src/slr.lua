require("common.lua")
require("set.lua")
require("list.lua")
require("prototype.lua")

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


gOpenluaSyntax = {}
gOpenluaSyntax.start = 'program'

local firstset = {}
local followset = {}
local initialStates = {}
local parseTable = {}

gOpenluaSyntax.firstset = firstset
gOpenluaSyntax.followset = followset
gOpenluaSyntax.initialStates = initialStates
gOpenluaSyntax.parseTable = parseTable

--  终结符集合
gOpenluaSyntax.terminals = 
Set{"Number", "~=", "==", "<=", "while", ")", "nil", "+", "*", "-", ",", "/", ".", "true", "return", "import", "{", "then", "}", "<", ">", "else", ";", "[", "break", "..", "(", ":", "function", "...", "Literal", "or", "local", "transformer", "end", "syntax", "not", "in", "repeat", "elseif", "false", "if", "and", "for", "until", "Name", "=", "]", ">=", "do", "^"}

--  非终结符集合
gOpenluaSyntax.nonterminals = 
Set{"functiondef", "unop", "transformerdef", "optional_compound_stat", "prefixexp", "result_part", "block", "stat", "optional_elseif_part", "colone_name", "init", "explist", "localvar_list", "syntaxdef", "init_part", "binop", "exp", "fieldsep", "optional_fieldlist", "field", "optional_parlist", "parlist", "keyname", "tableconstructor", "var", "optional_stat_list", "parname_list", "fieldlist", "funcbody", "elseif_part", "one_stat", "program", "namelist", "funcname", "optional_else_part", "metastat", "compound_stat", "varlist", "stat_sep", "stat_list", "args", "chunk", "import_module", "dotname_list", "functioncall"}

-- followset
followset['functiondef'] = Set{"~=", "==", "<=", "while", ")", "(", "+", "*", "-", ",", "/", "return", "import", ";", "local", "}", "repeat", ">", "else", "eof", "..", "function", "end", "transformer", "syntax", "<", "do", "elseif", "or", "if", "break", "for", "until", "Name", ">=", "]", "and", "then", "^"}

followset['unop'] = Set{"Number", "not", "Literal", "false", "function", "(", "Name", "-", "nil", "true", "{"}

followset['transformerdef'] = Set{"do", "eof", "while", "function", "(", "transformer", "syntax", "return", "if", "import", "for", ";", "local", "repeat", "break", "Name"}

followset['optional_compound_stat'] = Set{"eof"}

followset['prefixexp'] = Set{"(", "[", ":", "Literal", "{", "."}

followset['result_part'] = Set{"else", "do", "eof", "while", "function", "(", "end", "transformer", "syntax", "return", "elseif", "if", "break", "for", "until", ";", "local", "repeat", "import", "Name"}

followset['block'] = Set{"else", "end", "elseif", "until"}

followset['stat'] = Set{"else", "do", "eof", "while", "function", "(", "end", "transformer", "syntax", "return", "elseif", "if", "break", "for", "until", "Name", "local", "repeat", "import", ";"}

followset['optional_elseif_part'] = Set{"else", "end"}

followset['colone_name'] = Set{"("}

followset['init'] = Set{"else", "do", "eof", "while", "function", "(", "end", "transformer", "syntax", "return", "elseif", "if", "break", "for", "until", "Name", "local", "repeat", "import", ";"}

followset['explist'] = Set{"else", "do", "eof", "while", ")", "(", "end", ",", "transformer", "syntax", "return", "elseif", "if", "break", "for", "until", "Name", "local", "import", "repeat", "function", ";"}

followset['localvar_list'] = Set{"else", "do", "eof", "while", "function", "(", "end", ",", "transformer", "syntax", "return", "elseif", "if", "break", "for", "until", "Name", "local", "=", "repeat", "import", ";"}

followset['syntaxdef'] = Set{"do", "eof", "while", "function", "(", "transformer", "syntax", "return", "if", "import", "for", ";", "local", "repeat", "break", "Name"}

followset['init_part'] = Set{"else", "do", "eof", "while", "function", "(", "end", "transformer", "syntax", "return", "elseif", "if", "break", "for", "until", ";", "local", "repeat", "import", "Name"}

followset['binop'] = Set{"Number", "not", "Literal", "false", "function", "(", "Name", "-", "nil", "true", "{"}

followset['compound_stat'] = Set{"syntax", "do", "return", "eof", "while", "if", "break", "function", "(", "Name", "local", "for", "repeat", "transformer", "import"}

followset['varlist'] = Set{"=", ","}

followset['dotname_list'] = Set{"(", ".", ":"}

followset['funcbody'] = Set{">=", "==", "<=", "while", ")", "(", "+", "*", "-", ",", "/", "return", "import", ";", "then", "}", "repeat", ">", "else", "eof", "..", "function", "or", "transformer", "syntax", "end", "local", "elseif", "do", "if", "break", "for", "until", "Name", "~=", "]", "and", "<", "^"}

followset['optional_parlist'] = Set{")"}

followset['parname_list'] = Set{")", ","}

followset['keyname'] = Set{"="}

followset['field'] = Set{"}", ",", ";"}

followset['var'] = Set{"~=", "==", "<=", "while", ")", "(", "+", "*", "-", ",", "/", ".", "return", "import", "{", "then", "=", "repeat", ">", "else", "eof", "..", "function", "}", "end", "and", ">=", "transformer", "<", "syntax", "Literal", ";", "[", "elseif", "do", "if", "break", "for", "until", "Name", "or", "]", "local", ":", "^"}

followset['optional_stat_list'] = Set{"until", "end", "elseif", "else"}

followset['one_stat'] = Set{"syntax", "do", "return", "eof", "import", "while", "break", "function", "(", "Name", "local", "for", "repeat", "transformer", "if"}

followset['fieldlist'] = Set{"}", ",", ";"}

followset['fieldsep'] = Set{"Number", "not", "Literal", "false", "}", "function", "nil", "{", "true", "-", "(", "Name", "["}

followset['elseif_part'] = Set{"elseif", "else", "end"}

followset['tableconstructor'] = Set{"do", "==", "<=", "while", ")", "(", "+", "*", "-", ",", "/", ".", "return", "import", ";", "then", "}", "<", ">", "else", "eof", "..", "function", "end", "Literal", ":", "transformer", "[", "syntax", "{", "or", ">=", "elseif", "~=", "if", "and", "for", "until", "Name", "local", "]", "repeat", "break", "^"}

followset['program'] = Set{"eof"}

followset['namelist'] = Set{"in", ","}

followset['funcname'] = Set{"("}

followset['optional_else_part'] = Set{"end"}

followset['metastat'] = Set{"syntax", "do", "return", "eof", "if", "while", "import", "function", "(", "Name", "local", "for", "repeat", "transformer", "break"}

followset['exp'] = Set{"~=", "==", "<=", "while", ")", "(", "+", "*", "-", ",", "/", "return", "import", ";", "then", "}", "<", ">", "else", "eof", "..", "function", "end", "transformer", "syntax", "local", ">=", "elseif", "do", "if", "and", "for", "until", "Name", "or", "]", "repeat", "break", "^"}

followset['optional_fieldlist'] = Set{"}"}

followset['stat_sep'] = Set{"else", "do", "eof", "while", "function", "(", "end", "transformer", "syntax", "return", "elseif", "if", "break", "for", "until", "Name", "local", "repeat", "import"}

followset['stat_list'] = Set{"else", "do", "while", "function", "(", "end", "return", "elseif", "if", "break", "for", "until", "Name", "local", "repeat", ";"}

followset['args'] = Set{">=", "==", "<=", "while", ")", "(", "+", "*", "-", ",", "/", ".", "return", "import", "{", "then", "}", "repeat", ">", "else", "eof", "..", "function", "or", "do", ";", "transformer", "~=", "syntax", "local", "Name", "break", "elseif", "end", "if", "and", "for", "until", "[", "<", "]", ":", "Literal", "^"}

followset['chunk'] = Set{"eof"}

followset['import_module'] = Set{"do", "eof", "while", "function", "(", "transformer", "syntax", "return", "if", "import", "for", ";", "local", "repeat", "break", "Name"}

followset['parlist'] = Set{")"}

followset['functioncall'] = Set{">=", "==", "<=", "while", ")", "(", "+", "*", "-", ",", "/", ".", "Literal", "import", "{", "then", "}", "repeat", ">", "else", "eof", "..", "function", "or", "end", "do", "transformer", "<", "syntax", "return", ":", "and", "elseif", "~=", "if", "break", "for", "until", "[", ";", "]", "Name", "local", "^"}


-- firstset
firstset['Number'] = Set{"Number"}

firstset['functiondef'] = Set{"function"}

firstset['do'] = Set{"do"}

firstset['unop'] = Set{"-", "not"}

firstset['transformerdef'] = Set{"transformer"}

firstset['while'] = Set{"while"}

firstset['optional_compound_stat'] = Set{"syntax", "do", "return", "for", "import", "while", "break", "function", "(", "Name", "local", "if", "empty", "transformer", "repeat"}

firstset['prefixexp'] = Set{"(", "Name"}

firstset['block'] = Set{"do", "return", "while", "break", "function", "(", "Name", "local", "if", "empty", "for", "repeat"}

firstset['stat'] = Set{"do", "return", "while", "break", "function", "(", "Name", "local", "repeat", "if", "for"}

firstset['optional_elseif_part'] = Set{"elseif", "empty"}

firstset['colone_name'] = Set{"empty", ":"}

firstset['parname_list'] = Set{"Name"}

firstset['tableconstructor'] = Set{"{"}

firstset['{'] = Set{"{"}

firstset['}'] = Set{"}"}

firstset['one_stat'] = Set{"syntax", "do", "return", "import", "while", "break", "function", "(", "Name", "local", "if", "repeat", "transformer", "for"}

firstset['compound_stat'] = Set{"syntax", "do", "return", "if", "while", "break", "function", "(", "Name", "local", "import", "repeat", "transformer", "for"}

firstset['..'] = Set{".."}

firstset['keyname'] = Set{"Name"}

firstset['or'] = Set{"or"}

firstset['empty'] = Set{"empty"}

firstset['fieldlist'] = Set{"true", "not", "Literal", "false", "function", "nil", "[", "Name", "-", "(", "{", "Number"}

firstset['elseif_part'] = Set{"elseif"}

firstset['program'] = Set{"syntax", "do", "return", "for", "import", "while", "break", "function", "(", "Name", "local", "if", "empty", "transformer", "repeat"}

firstset['funcname'] = Set{"Name"}

firstset['optional_else_part'] = Set{"empty", "else"}

firstset['if'] = Set{"if"}

firstset['in'] = Set{"in"}

firstset['until'] = Set{"until"}

firstset['stat_list'] = Set{"do", "return", "while", "break", "function", "(", "Name", "local", "repeat", "if", "for"}

firstset['args'] = Set{"(", "{", "Literal"}

firstset['chunk'] = Set{"syntax", "do", "return", "for", "import", "while", "break", "function", "(", "Name", "local", "if", "empty", "transformer", "repeat"}

firstset['dotname_list'] = Set{"empty", "."}

firstset['field'] = Set{"true", "not", "Literal", "false", "function", "nil", "[", "{", "-", "Name", "(", "Number"}

firstset['>='] = Set{">="}

firstset['=='] = Set{"=="}

firstset['<='] = Set{"<="}

firstset['Name'] = Set{"Name"}

firstset['for'] = Set{"for"}

firstset['false'] = Set{"false"}

firstset[')'] = Set{")"}

firstset['nil'] = Set{"nil"}

firstset['+'] = Set{"+"}

firstset['*'] = Set{"*"}

firstset['-'] = Set{"-"}

firstset[','] = Set{","}

firstset['/'] = Set{"/"}

firstset['.'] = Set{"."}

firstset['true'] = Set{"true"}

firstset['optional_stat_list'] = Set{"do", "return", "while", "break", "function", "(", "Name", "local", "if", "empty", "for", "repeat"}

firstset['<'] = Set{"<"}

firstset['syntax'] = Set{"syntax"}

firstset['explist'] = Set{"Number", "not", "Literal", "false", "function", "(", "Name", "-", "{", "true", "nil"}

firstset['syntaxdef'] = Set{"syntax"}

firstset['break'] = Set{"break"}

firstset['import'] = Set{"import"}

firstset['~='] = Set{"~="}

firstset['namelist'] = Set{"Name"}

firstset[';'] = Set{";"}

firstset['then'] = Set{"then"}

firstset['='] = Set{"="}

firstset['repeat'] = Set{"repeat"}

firstset['return'] = Set{"return"}

firstset['init_part'] = Set{"=", "empty"}

firstset['local'] = Set{"local"}

firstset['else'] = Set{"else"}

firstset['init'] = Set{"="}

firstset['exp'] = Set{"Number", "not", "Literal", "false", "function", "(", "Name", "-", "{", "true", "nil"}

firstset['optional_fieldlist'] = Set{"true", "not", "Literal", "false", "(", "function", "nil", "[", "{", "-", "empty", "Name", "Number"}

firstset['...'] = Set{"..."}

firstset['result_part'] = Set{"true", "not", "Literal", "false", "function", "nil", "Name", "{", "-", "empty", "(", "Number"}

firstset['optional_parlist'] = Set{"empty", "Name", "..."}

firstset['function'] = Set{"function"}

firstset['>'] = Set{">"}

firstset['var'] = Set{"(", "Name"}

firstset['end'] = Set{"end"}

firstset['binop'] = Set{">=", "==", "<=", "..", ">", "and", "~=", "or", "+", "*", "-", "<", "/", "^"}

firstset['localvar_list'] = Set{"Name"}

firstset['transformer'] = Set{"transformer"}

firstset['('] = Set{"("}

firstset[':'] = Set{":"}

firstset['not'] = Set{"not"}

firstset['fieldsep'] = Set{",", ";"}

firstset['Literal'] = Set{"Literal"}

firstset['varlist'] = Set{"(", "Name"}

firstset['functioncall'] = Set{"(", "Name"}

firstset['metastat'] = Set{"syntax", "transformer", "import"}

firstset['and'] = Set{"and"}

firstset['funcbody'] = Set{"("}

firstset['stat_sep'] = Set{"empty", ";"}

firstset['['] = Set{"["}

firstset['elseif'] = Set{"elseif"}

firstset[']'] = Set{"]"}

firstset['import_module'] = Set{"import"}

firstset['parlist'] = Set{"...", "Name"}

firstset['^'] = Set{"^"}


-- initialStates
initialStates['Number'] = 12
initialStates['functiondef'] = 12
initialStates['~='] = 23
initialStates['unop'] = 12
initialStates['transformerdef'] = 1
initialStates['while'] = 1
initialStates['optional_compound_stat'] = 1
initialStates['prefixexp'] = 1
initialStates['block'] = 24
initialStates['stat'] = 1
initialStates['optional_fieldlist'] = 39
initialStates['colone_name'] = 81
initialStates['Literal'] = 3
initialStates['tableconstructor'] = 10
initialStates['{'] = 3
initialStates['}'] = 23
initialStates['syntaxdef'] = 1
initialStates['compound_stat'] = 1
initialStates['..'] = 23
initialStates['keyname'] = 39
initialStates['or'] = 23
initialStates['fieldlist'] = 39
initialStates['syntax'] = 1
initialStates['program'] = 1
initialStates['elseif'] = 3
initialStates['false'] = 12
initialStates['if'] = 1
initialStates['for'] = 1
initialStates['until'] = 3
initialStates['Name'] = 1
initialStates['args'] = 10
initialStates['chunk'] = 1
initialStates['dotname_list'] = 30
initialStates['optional_else_part'] = 177
initialStates['optional_elseif_part'] = 162
initialStates['>='] = 23
initialStates['=='] = 23
initialStates['<='] = 23
initialStates['elseif_part'] = 162
initialStates['fieldsep'] = 85
initialStates['var'] = 1
initialStates[')'] = 23
initialStates['nil'] = 12
initialStates['+'] = 23
initialStates['*'] = 23
initialStates['result_part'] = 12
initialStates[','] = 14
initialStates['/'] = 23
initialStates['.'] = 3
initialStates['true'] = 12
initialStates['...'] = 82
initialStates['funcname'] = 5
initialStates['parname_list'] = 82
initialStates['explist'] = 12
initialStates['in'] = 68
initialStates['binop'] = 51
initialStates['import'] = 1
initialStates['init_part'] = 44
initialStates['localvar_list'] = 11
initialStates[';'] = 3
initialStates[':'] = 3
initialStates['='] = 14
initialStates['repeat'] = 1
initialStates['init'] = 44
initialStates['>'] = 23
initialStates['field'] = 39
initialStates['else'] = 3
initialStates['funcbody'] = 31
initialStates['exp'] = 12
initialStates['then'] = 23
initialStates['stat_list'] = 24
initialStates['^'] = 23
initialStates['optional_parlist'] = 82
initialStates['function'] = 1
initialStates['<'] = 23
initialStates['and'] = 23
initialStates['end'] = 3
initialStates['optional_stat_list'] = 24
initialStates['do'] = 1
initialStates['transformer'] = 1
initialStates['('] = 1
initialStates['-'] = 12
initialStates['not'] = 12
initialStates['return'] = 1
initialStates['namelist'] = 18
initialStates['varlist'] = 1
initialStates['one_stat'] = 1
initialStates['metastat'] = 1
initialStates['break'] = 1
initialStates['local'] = 1
initialStates['stat_sep'] = 9
initialStates['['] = 3
initialStates['eof'] = 1
initialStates[']'] = 23
initialStates['import_module'] = 1
initialStates['parlist'] = 82
initialStates['functioncall'] = 1

-- SLR语法解析表

parseTable[1] = {}
parseTable[1]["do"] = 26
parseTable[1]["eof"] = Production{"optional_compound_stat", Rightside{"empty"}}
parseTable[1]["transformerdef"] = 27
parseTable[1]["while"] = 19
parseTable[1]["optional_compound_stat"] = 16
parseTable[1]["function"] = 5
parseTable[1]["prefixexp"] = 10
parseTable[1]["stat"] = 20
parseTable[1]["var"] = 14
parseTable[1]["syntaxdef"] = 28
parseTable[1]["metastat"] = 25
parseTable[1]["transformer"] = 13
parseTable[1]["repeat"] = 24
parseTable[1]["syntax"] = 2
parseTable[1]["compound_stat"] = 6
parseTable[1]["program"] = 0
parseTable[1]["return"] = 12
parseTable[1]["varlist"] = 15
parseTable[1]["break"] = 7
parseTable[1]["if"] = 22
parseTable[1]["import"] = 8
parseTable[1]["for"] = 18
parseTable[1]["("] = 17
parseTable[1]["Name"] = 23
parseTable[1]["local"] = 11
parseTable[1]["chunk"] = 21
parseTable[1]["one_stat"] = 4
parseTable[1]["import_module"] = 9
parseTable[1]["functioncall"] = 3

parseTable[2] = {}
parseTable[2]["Name"] = 29

parseTable[3] = {}
parseTable[3]["else"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["do"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["eof"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["while"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["function"] = Production{"stat", Rightside{"functioncall"}}

parseTable[3]["("] = GetSelectorByLineNum(Production{"prefixexp", Rightside{"functioncall"}})
--Set{Production{"stat", Rightside{"functioncall"}}, Production{"prefixexp", Rightside{"functioncall"}}}

parseTable[3]["end"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["transformer"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["."] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[3]["syntax"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3][";"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["import"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["return"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["elseif"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["Name"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["if"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["break"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["for"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["until"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["{"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[3][":"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[3]["local"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["repeat"] = Production{"stat", Rightside{"functioncall"}}
parseTable[3]["Literal"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[3]["["] = Production{"prefixexp", Rightside{"functioncall"}}

parseTable[4] = {}
parseTable[4]["syntax"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["do"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["eof"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["import"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["return"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["while"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["break"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["function"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["("] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["Name"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["local"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["for"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["repeat"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["transformer"] = Production{"compound_stat", Rightside{"one_stat"}}
parseTable[4]["if"] = Production{"compound_stat", Rightside{"one_stat"}}

parseTable[5] = {}
parseTable[5]["funcname"] = 31
parseTable[5]["Name"] = 30

parseTable[6] = {}
parseTable[6]["do"] = 26
parseTable[6]["eof"] = Production{"optional_compound_stat", Rightside{"compound_stat"}}
parseTable[6]["transformerdef"] = 27
parseTable[6]["while"] = 19
parseTable[6]["function"] = 5
parseTable[6]["prefixexp"] = 10
parseTable[6]["var"] = 14
parseTable[6]["stat"] = 20
parseTable[6]["syntaxdef"] = 28
parseTable[6]["syntax"] = 2
parseTable[6]["one_stat"] = 32
parseTable[6]["import_module"] = 9
parseTable[6]["return"] = 12
parseTable[6]["varlist"] = 15
parseTable[6]["("] = 17
parseTable[6]["if"] = 22
parseTable[6]["break"] = 7
parseTable[6]["for"] = 18
parseTable[6]["transformer"] = 13
parseTable[6]["Name"] = 23
parseTable[6]["local"] = 11
parseTable[6]["metastat"] = 25
parseTable[6]["repeat"] = 24
parseTable[6]["import"] = 8
parseTable[6]["functioncall"] = 3

parseTable[7] = {}
parseTable[7]["else"] = Production{"stat", Rightside{"break"}}
parseTable[7]["do"] = Production{"stat", Rightside{"break"}}
parseTable[7]["eof"] = Production{"stat", Rightside{"break"}}
parseTable[7]["while"] = Production{"stat", Rightside{"break"}}
parseTable[7]["function"] = Production{"stat", Rightside{"break"}}
parseTable[7]["("] = Production{"stat", Rightside{"break"}}
parseTable[7]["end"] = Production{"stat", Rightside{"break"}}
parseTable[7]["transformer"] = Production{"stat", Rightside{"break"}}
parseTable[7]["syntax"] = Production{"stat", Rightside{"break"}}
parseTable[7]["return"] = Production{"stat", Rightside{"break"}}
parseTable[7]["elseif"] = Production{"stat", Rightside{"break"}}
parseTable[7]["if"] = Production{"stat", Rightside{"break"}}
parseTable[7]["break"] = Production{"stat", Rightside{"break"}}
parseTable[7]["for"] = Production{"stat", Rightside{"break"}}
parseTable[7]["until"] = Production{"stat", Rightside{"break"}}
parseTable[7]["Name"] = Production{"stat", Rightside{"break"}}
parseTable[7]["local"] = Production{"stat", Rightside{"break"}}
parseTable[7]["repeat"] = Production{"stat", Rightside{"break"}}
parseTable[7][";"] = Production{"stat", Rightside{"break"}}
parseTable[7]["import"] = Production{"stat", Rightside{"break"}}

parseTable[8] = {}
parseTable[8]["Literal"] = 33

parseTable[9] = {}
parseTable[9]["else"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["do"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["eof"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["while"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["function"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["("] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["end"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["transformer"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["syntax"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["return"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["elseif"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["if"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["break"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["for"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["stat_sep"] = 35
parseTable[9][";"] = 34
parseTable[9]["local"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["import"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["repeat"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["Name"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[9]["until"] = Production{"stat_sep", Rightside{"empty"}}

parseTable[10] = {}
parseTable[10]["Literal"] = 38
parseTable[10]["tableconstructor"] = 41
parseTable[10]["{"] = 39
parseTable[10]["args"] = 37
parseTable[10]["["] = 43
parseTable[10]["("] = 40
parseTable[10][":"] = 36
parseTable[10]["."] = 42

parseTable[11] = {}
parseTable[11]["function"] = 46
parseTable[11]["localvar_list"] = 44
parseTable[11]["Name"] = 45

parseTable[12] = {}
parseTable[12]["Number"] = 61
parseTable[12]["functiondef"] = 59
parseTable[12]["do"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["unop"] = 55
parseTable[12]["while"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["prefixexp"] = 10
parseTable[12]["-"] = 54
parseTable[12]["true"] = 50
parseTable[12]["Literal"] = 48
parseTable[12]["explist"] = 47
parseTable[12]["import"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["tableconstructor"] = 56
parseTable[12][";"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["local"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["repeat"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["else"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["exp"] = 51

parseTable[12]["function"] = 58
--Set{Production{"result_part", Rightside{"empty"}}, 58}

parseTable[12]["end"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["transformer"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["{"] = 39
parseTable[12]["syntax"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["not"] = 57
parseTable[12]["result_part"] = 62
parseTable[12]["nil"] = 60
parseTable[12]["elseif"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["false"] = 63
parseTable[12]["if"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["break"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["for"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["until"] = Production{"result_part", Rightside{"empty"}}

parseTable[12]["Name"] = 23
--Set{23, Production{"result_part", Rightside{"empty"}}}

parseTable[12]["eof"] = Production{"result_part", Rightside{"empty"}}

parseTable[12]["("] = 53
--Set{53, Production{"result_part", Rightside{"empty"}}}

parseTable[12]["var"] = 52
parseTable[12]["return"] = Production{"result_part", Rightside{"empty"}}
parseTable[12]["functioncall"] = 49

parseTable[13] = {}
parseTable[13]["Name"] = 64

parseTable[14] = {}
parseTable[14]["Literal"] = Production{"prefixexp", Rightside{"var"}}
parseTable[14]["("] = Production{"prefixexp", Rightside{"var"}}
parseTable[14]["{"] = Production{"prefixexp", Rightside{"var"}}
parseTable[14][":"] = Production{"prefixexp", Rightside{"var"}}
parseTable[14]["="] = Production{"varlist", Rightside{"var"}}
parseTable[14][","] = Production{"varlist", Rightside{"var"}}
parseTable[14]["["] = Production{"prefixexp", Rightside{"var"}}
parseTable[14]["."] = Production{"prefixexp", Rightside{"var"}}

parseTable[15] = {}
parseTable[15]["="] = 65
parseTable[15][","] = 66

parseTable[16] = {}
parseTable[16]["eof"] = Production{"chunk", Rightside{"optional_compound_stat"}}

parseTable[17] = {}
parseTable[17]["Number"] = 61
parseTable[17]["functiondef"] = 59
parseTable[17]["exp"] = 67
parseTable[17]["function"] = 58
parseTable[17]["("] = 53
parseTable[17]["var"] = 52
parseTable[17]["-"] = 54
parseTable[17]["true"] = 50
parseTable[17]["not"] = 57
parseTable[17]["Literal"] = 48
parseTable[17]["false"] = 63
parseTable[17]["tableconstructor"] = 56
parseTable[17]["{"] = 39
parseTable[17]["unop"] = 55
parseTable[17]["nil"] = 60
parseTable[17]["Name"] = 23
parseTable[17]["prefixexp"] = 10
parseTable[17]["functioncall"] = 49

parseTable[18] = {}
parseTable[18]["namelist"] = 68
parseTable[18]["Name"] = 69

parseTable[19] = {}
parseTable[19]["Number"] = 61
parseTable[19]["functiondef"] = 59
parseTable[19]["exp"] = 70
parseTable[19]["function"] = 58
parseTable[19]["("] = 53
parseTable[19]["var"] = 52
parseTable[19]["-"] = 54
parseTable[19]["true"] = 50
parseTable[19]["not"] = 57
parseTable[19]["Literal"] = 48
parseTable[19]["false"] = 63
parseTable[19]["tableconstructor"] = 56
parseTable[19]["Name"] = 23
parseTable[19]["nil"] = 60
parseTable[19]["unop"] = 55
parseTable[19]["prefixexp"] = 10
parseTable[19]["{"] = 39
parseTable[19]["functioncall"] = 49

parseTable[20] = {}
parseTable[20]["else"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["do"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["eof"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["while"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["function"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["("] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["end"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["transformer"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["syntax"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["return"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["elseif"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["if"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["break"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["for"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["until"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["Name"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["local"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20][";"] = 34
parseTable[20]["repeat"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[20]["stat_sep"] = 71
parseTable[20]["import"] = Production{"stat_sep", Rightside{"empty"}}

parseTable[21] = {}
parseTable[21]["eof"] = Production{"program", Rightside{"chunk"}}

parseTable[22] = {}
parseTable[22]["Number"] = 61
parseTable[22]["functiondef"] = 59
parseTable[22]["exp"] = 72
parseTable[22]["function"] = 58
parseTable[22]["nil"] = 60
parseTable[22]["var"] = 52
parseTable[22]["-"] = 54
parseTable[22]["true"] = 50
parseTable[22]["not"] = 57
parseTable[22]["Literal"] = 48
parseTable[22]["false"] = 63
parseTable[22]["tableconstructor"] = 56
parseTable[22]["{"] = 39
parseTable[22]["("] = 53
parseTable[22]["unop"] = 55
parseTable[22]["prefixexp"] = 10
parseTable[22]["Name"] = 23
parseTable[22]["functioncall"] = 49

parseTable[23] = {}
parseTable[23][">="] = Production{"var", Rightside{"Name"}}
parseTable[23]["=="] = Production{"var", Rightside{"Name"}}
parseTable[23]["<="] = Production{"var", Rightside{"Name"}}
parseTable[23]["while"] = Production{"var", Rightside{"Name"}}
parseTable[23][")"] = Production{"var", Rightside{"Name"}}
parseTable[23]["("] = Production{"var", Rightside{"Name"}}
parseTable[23]["+"] = Production{"var", Rightside{"Name"}}
parseTable[23]["*"] = Production{"var", Rightside{"Name"}}
parseTable[23]["-"] = Production{"var", Rightside{"Name"}}
parseTable[23][","] = Production{"var", Rightside{"Name"}}
parseTable[23]["/"] = Production{"var", Rightside{"Name"}}
parseTable[23]["."] = Production{"var", Rightside{"Name"}}
parseTable[23]["return"] = Production{"var", Rightside{"Name"}}
parseTable[23]["import"] = Production{"var", Rightside{"Name"}}
parseTable[23]["{"] = Production{"var", Rightside{"Name"}}
parseTable[23]["then"] = Production{"var", Rightside{"Name"}}
parseTable[23]["="] = Production{"var", Rightside{"Name"}}
parseTable[23]["repeat"] = Production{"var", Rightside{"Name"}}
parseTable[23][">"] = Production{"var", Rightside{"Name"}}
parseTable[23]["else"] = Production{"var", Rightside{"Name"}}
parseTable[23]["eof"] = Production{"var", Rightside{"Name"}}
parseTable[23][".."] = Production{"var", Rightside{"Name"}}
parseTable[23]["function"] = Production{"var", Rightside{"Name"}}
parseTable[23]["}"] = Production{"var", Rightside{"Name"}}
parseTable[23]["end"] = Production{"var", Rightside{"Name"}}
parseTable[23][":"] = Production{"var", Rightside{"Name"}}
parseTable[23]["local"] = Production{"var", Rightside{"Name"}}
parseTable[23]["transformer"] = Production{"var", Rightside{"Name"}}
parseTable[23]["~="] = Production{"var", Rightside{"Name"}}
parseTable[23]["syntax"] = Production{"var", Rightside{"Name"}}
parseTable[23]["or"] = Production{"var", Rightside{"Name"}}
parseTable[23]["Name"] = Production{"var", Rightside{"Name"}}
parseTable[23]["do"] = Production{"var", Rightside{"Name"}}
parseTable[23]["elseif"] = Production{"var", Rightside{"Name"}}
parseTable[23]["break"] = Production{"var", Rightside{"Name"}}
parseTable[23]["if"] = Production{"var", Rightside{"Name"}}
parseTable[23]["and"] = Production{"var", Rightside{"Name"}}
parseTable[23]["for"] = Production{"var", Rightside{"Name"}}
parseTable[23]["until"] = Production{"var", Rightside{"Name"}}
parseTable[23]["["] = Production{"var", Rightside{"Name"}}
parseTable[23][";"] = Production{"var", Rightside{"Name"}}
parseTable[23]["]"] = Production{"var", Rightside{"Name"}}
parseTable[23]["Literal"] = Production{"var", Rightside{"Name"}}
parseTable[23]["<"] = Production{"var", Rightside{"Name"}}
parseTable[23]["^"] = Production{"var", Rightside{"Name"}}

parseTable[24] = {}
parseTable[24]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[24]["do"] = 26
parseTable[24]["while"] = 19
parseTable[24]["function"] = 5
parseTable[24]["prefixexp"] = 10
parseTable[24]["var"] = 14
parseTable[24]["optional_stat_list"] = 75
parseTable[24]["block"] = 74
parseTable[24]["stat"] = 76
parseTable[24]["("] = 17
parseTable[24]["return"] = 12
parseTable[24]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[24]["varlist"] = 15
parseTable[24]["if"] = 22
parseTable[24]["break"] = 7
parseTable[24]["for"] = 18
parseTable[24]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[24]["stat_list"] = 73
parseTable[24]["local"] = 11
parseTable[24]["Name"] = 23
parseTable[24]["repeat"] = 24
parseTable[24]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[24]["functioncall"] = 3

parseTable[25] = {}
parseTable[25]["syntax"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["do"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["eof"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["if"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["return"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["while"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["import"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["function"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["("] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["Name"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["local"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["for"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["repeat"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["transformer"] = Production{"one_stat", Rightside{"metastat"}}
parseTable[25]["break"] = Production{"one_stat", Rightside{"metastat"}}

parseTable[26] = {}
parseTable[26]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[26]["do"] = 26
parseTable[26]["while"] = 19
parseTable[26]["function"] = 5
parseTable[26]["prefixexp"] = 10
parseTable[26]["var"] = 14
parseTable[26]["optional_stat_list"] = 75
parseTable[26]["block"] = 77
parseTable[26]["stat"] = 76
parseTable[26]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[26]["return"] = 12
parseTable[26]["varlist"] = 15
parseTable[26]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[26]["if"] = 22
parseTable[26]["break"] = 7
parseTable[26]["for"] = 18
parseTable[26]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[26]["Name"] = 23
parseTable[26]["local"] = 11
parseTable[26]["("] = 17
parseTable[26]["repeat"] = 24
parseTable[26]["stat_list"] = 73
parseTable[26]["functioncall"] = 3

parseTable[27] = {}
parseTable[27]["else"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["do"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["eof"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["while"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["function"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["("] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["end"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["transformer"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["syntax"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["return"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["elseif"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["if"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["break"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["for"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["until"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["Name"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["local"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27][";"] = 34
parseTable[27]["repeat"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[27]["stat_sep"] = 78
parseTable[27]["import"] = Production{"stat_sep", Rightside{"empty"}}

parseTable[28] = {}
parseTable[28]["else"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["do"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["eof"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["while"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["function"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["("] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["end"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["transformer"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["syntax"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["return"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["elseif"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["if"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["break"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["for"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["until"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28][";"] = 34
parseTable[28]["local"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["stat_sep"] = 79
parseTable[28]["repeat"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["import"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[28]["Name"] = Production{"stat_sep", Rightside{"empty"}}

parseTable[29] = {}
parseTable[29][":"] = 80

parseTable[30] = {}
parseTable[30]["("] = Production{"dotname_list", Rightside{"empty"}}
parseTable[30][":"] = Production{"dotname_list", Rightside{"empty"}}
parseTable[30]["dotname_list"] = 81
parseTable[30]["."] = Production{"dotname_list", Rightside{"empty"}}

parseTable[31] = {}
parseTable[31]["("] = 82
parseTable[31]["funcbody"] = 83

parseTable[32] = {}
parseTable[32]["syntax"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["do"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["eof"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["import"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["return"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["while"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["break"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["function"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["("] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["Name"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["local"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["for"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["repeat"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["transformer"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}
parseTable[32]["if"] = Production{"compound_stat", Rightside{"compound_stat", "one_stat"}}

parseTable[33] = {}
parseTable[33]["do"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["eof"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["while"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["function"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["("] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["transformer"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["syntax"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["return"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["if"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["import"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["for"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33][";"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["local"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["repeat"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["Name"] = Production{"import_module", Rightside{"import", "Literal"}}
parseTable[33]["break"] = Production{"import_module", Rightside{"import", "Literal"}}

parseTable[34] = {}
parseTable[34]["else"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["do"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["eof"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["while"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["function"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["("] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["end"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["transformer"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["syntax"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["return"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["elseif"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["if"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["break"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["for"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["until"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["Name"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["local"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["repeat"] = Production{"stat_sep", Rightside{";"}}
parseTable[34]["import"] = Production{"stat_sep", Rightside{";"}}

parseTable[35] = {}
parseTable[35]["syntax"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["do"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["eof"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["break"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["return"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["if"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["import"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["function"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["("] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["Name"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["local"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["for"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["repeat"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["transformer"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}
parseTable[35]["while"] = Production{"metastat", Rightside{"import_module", "stat_sep"}}

parseTable[36] = {}
parseTable[36]["Name"] = 84

parseTable[37] = {}
parseTable[37]["do"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["=="] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["<="] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["while"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37][")"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["("] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["+"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["*"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["-"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37][","] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["/"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["."] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["Literal"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["import"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["{"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["then"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["}"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["repeat"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37][">"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["else"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["eof"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37][".."] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["function"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["or"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["end"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["local"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["transformer"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["Name"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["syntax"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37][":"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37][";"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["~="] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["elseif"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["break"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["if"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["and"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["for"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["until"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["["] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37][">="] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["]"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["return"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["<"] = Production{"functioncall", Rightside{"prefixexp", "args"}}
parseTable[37]["^"] = Production{"functioncall", Rightside{"prefixexp", "args"}}

parseTable[38] = {}
parseTable[38]["do"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["=="] = Production{"args", Rightside{"Literal"}}
parseTable[38]["<="] = Production{"args", Rightside{"Literal"}}
parseTable[38]["while"] = Production{"args", Rightside{"Literal"}}
parseTable[38][")"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["("] = Production{"args", Rightside{"Literal"}}
parseTable[38]["+"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["*"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["-"] = Production{"args", Rightside{"Literal"}}
parseTable[38][","] = Production{"args", Rightside{"Literal"}}
parseTable[38]["/"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["."] = Production{"args", Rightside{"Literal"}}
parseTable[38]["return"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["import"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["{"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["then"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["}"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["repeat"] = Production{"args", Rightside{"Literal"}}
parseTable[38][">"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["else"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["eof"] = Production{"args", Rightside{"Literal"}}
parseTable[38][".."] = Production{"args", Rightside{"Literal"}}
parseTable[38]["function"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["or"] = Production{"args", Rightside{"Literal"}}
parseTable[38][";"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["Literal"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["transformer"] = Production{"args", Rightside{"Literal"}}
parseTable[38][":"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["syntax"] = Production{"args", Rightside{"Literal"}}
parseTable[38][">="] = Production{"args", Rightside{"Literal"}}
parseTable[38]["<"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["["] = Production{"args", Rightside{"Literal"}}
parseTable[38]["elseif"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["and"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["if"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["break"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["for"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["until"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["Name"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["end"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["]"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["local"] = Production{"args", Rightside{"Literal"}}
parseTable[38]["~="] = Production{"args", Rightside{"Literal"}}
parseTable[38]["^"] = Production{"args", Rightside{"Literal"}}

parseTable[39] = {}
parseTable[39]["Number"] = 61
parseTable[39]["functiondef"] = 59
parseTable[39]["exp"] = 87
parseTable[39]["function"] = 58
parseTable[39]["prefixexp"] = 10
parseTable[39]["var"] = 52
parseTable[39]["-"] = 54
parseTable[39]["fieldlist"] = 85
parseTable[39]["true"] = 50
parseTable[39]["not"] = 57
parseTable[39]["["] = 91
parseTable[39]["Literal"] = 48
parseTable[39]["Name"] = 90
parseTable[39]["false"] = 63
parseTable[39]["unop"] = 55
parseTable[39]["field"] = 89
parseTable[39]["optional_fieldlist"] = 86
parseTable[39]["tableconstructor"] = 56
parseTable[39]["{"] = 39
parseTable[39]["keyname"] = 88
parseTable[39]["}"] = Production{"optional_fieldlist", Rightside{"empty"}}
parseTable[39]["nil"] = 60
parseTable[39]["("] = 53
parseTable[39]["functioncall"] = 49

parseTable[40] = {}
parseTable[40]["Number"] = 61
parseTable[40]["functiondef"] = 59
parseTable[40]["unop"] = 55
parseTable[40]["function"] = 58
parseTable[40]["nil"] = 60
parseTable[40]["var"] = 52
parseTable[40]["-"] = 54
parseTable[40]["true"] = 50
parseTable[40]["not"] = 57
parseTable[40]["Literal"] = 48
parseTable[40]["explist"] = 92
parseTable[40]["false"] = 63
parseTable[40]["{"] = 39
parseTable[40]["tableconstructor"] = 56
parseTable[40]["Name"] = 23
parseTable[40][")"] = 93
parseTable[40]["prefixexp"] = 10
parseTable[40]["("] = 53
parseTable[40]["exp"] = 51
parseTable[40]["functioncall"] = 49

parseTable[41] = {}
parseTable[41]["do"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["=="] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["<="] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["while"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41][")"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["("] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["+"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["*"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["-"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41][","] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["/"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["."] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["return"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["import"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["{"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["then"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["}"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["repeat"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41][">"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["else"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["eof"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41][".."] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["function"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["or"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41][";"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["Literal"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["transformer"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41][":"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["syntax"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41][">="] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["<"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["["] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["elseif"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["and"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["if"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["break"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["for"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["until"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["Name"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["end"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["]"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["local"] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["~="] = Production{"args", Rightside{"tableconstructor"}}
parseTable[41]["^"] = Production{"args", Rightside{"tableconstructor"}}

parseTable[42] = {}
parseTable[42]["Name"] = 94

parseTable[43] = {}
parseTable[43]["Number"] = 61
parseTable[43]["functiondef"] = 59
parseTable[43]["exp"] = 95
parseTable[43]["function"] = 58
parseTable[43]["("] = 53
parseTable[43]["var"] = 52
parseTable[43]["-"] = 54
parseTable[43]["true"] = 50
parseTable[43]["not"] = 57
parseTable[43]["Literal"] = 48
parseTable[43]["false"] = 63
parseTable[43]["tableconstructor"] = 56
parseTable[43]["{"] = 39
parseTable[43]["Name"] = 23
parseTable[43]["nil"] = 60
parseTable[43]["unop"] = 55
parseTable[43]["prefixexp"] = 10
parseTable[43]["functioncall"] = 49

parseTable[44] = {}
parseTable[44]["else"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["do"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["eof"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["while"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["function"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["("] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["end"] = Production{"init_part", Rightside{"empty"}}
parseTable[44][","] = 96
parseTable[44]["transformer"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["syntax"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["Name"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["return"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["elseif"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["import"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["if"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["break"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["for"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["until"] = Production{"init_part", Rightside{"empty"}}
parseTable[44][";"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["local"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["="] = 98
parseTable[44]["repeat"] = Production{"init_part", Rightside{"empty"}}
parseTable[44]["init"] = 97
parseTable[44]["init_part"] = 99

parseTable[45] = {}
parseTable[45]["else"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["do"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["eof"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["while"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["function"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["("] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["end"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45][","] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["transformer"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["syntax"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["return"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["elseif"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["if"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["break"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["for"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["until"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["Name"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["local"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["="] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["repeat"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45][";"] = Production{"localvar_list", Rightside{"Name"}}
parseTable[45]["import"] = Production{"localvar_list", Rightside{"Name"}}

parseTable[46] = {}
parseTable[46]["Name"] = 100

parseTable[47] = {}
parseTable[47]["else"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["do"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["eof"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["while"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["function"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["("] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["end"] = Production{"result_part", Rightside{"explist"}}
parseTable[47][","] = 101
parseTable[47]["transformer"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["syntax"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["return"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["elseif"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["if"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["break"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["for"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["until"] = Production{"result_part", Rightside{"explist"}}
parseTable[47][";"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["local"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["repeat"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["Name"] = Production{"result_part", Rightside{"explist"}}
parseTable[47]["import"] = Production{"result_part", Rightside{"explist"}}

parseTable[48] = {}
parseTable[48][">="] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["=="] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["<="] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["while"] = Production{"exp", Rightside{"Literal"}}
parseTable[48][")"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["("] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["+"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["*"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["-"] = Production{"exp", Rightside{"Literal"}}
parseTable[48][","] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["/"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["return"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["import"] = Production{"exp", Rightside{"Literal"}}
parseTable[48][";"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["then"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["}"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["<"] = Production{"exp", Rightside{"Literal"}}
parseTable[48][">"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["else"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["eof"] = Production{"exp", Rightside{"Literal"}}
parseTable[48][".."] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["function"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["end"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["transformer"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["syntax"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["local"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["break"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["elseif"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["repeat"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["if"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["and"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["for"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["until"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["Name"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["or"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["]"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["~="] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["do"] = Production{"exp", Rightside{"Literal"}}
parseTable[48]["^"] = Production{"exp", Rightside{"Literal"}}

parseTable[49] = {}
parseTable[49]["~="] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["=="] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["<="] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["while"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49][")"] = Production{"exp", Rightside{"functioncall"}}

parseTable[49]["("] = GetSelectorByLineNum(Production{"prefixexp", Rightside{"functioncall"}})
--Set{Production{"exp", Rightside{"functioncall"}}, Production{"prefixexp", Rightside{"functioncall"}}}

parseTable[49]["+"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["*"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["-"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49][","] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["/"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["."] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[49]["return"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["import"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["{"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[49][":"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[49]["}"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["<"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49][">"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["else"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["eof"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49][".."] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["function"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["end"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["then"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["break"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["transformer"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["repeat"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["syntax"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["local"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["or"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["Name"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["elseif"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["do"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["if"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["and"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["for"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["until"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["["] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[49][">="] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["]"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["Literal"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[49][";"] = Production{"exp", Rightside{"functioncall"}}
parseTable[49]["^"] = Production{"exp", Rightside{"functioncall"}}

parseTable[50] = {}
parseTable[50][">="] = Production{"exp", Rightside{"true"}}
parseTable[50]["=="] = Production{"exp", Rightside{"true"}}
parseTable[50]["<="] = Production{"exp", Rightside{"true"}}
parseTable[50]["while"] = Production{"exp", Rightside{"true"}}
parseTable[50][")"] = Production{"exp", Rightside{"true"}}
parseTable[50]["("] = Production{"exp", Rightside{"true"}}
parseTable[50]["+"] = Production{"exp", Rightside{"true"}}
parseTable[50]["*"] = Production{"exp", Rightside{"true"}}
parseTable[50]["-"] = Production{"exp", Rightside{"true"}}
parseTable[50][","] = Production{"exp", Rightside{"true"}}
parseTable[50]["/"] = Production{"exp", Rightside{"true"}}
parseTable[50]["return"] = Production{"exp", Rightside{"true"}}
parseTable[50]["import"] = Production{"exp", Rightside{"true"}}
parseTable[50][";"] = Production{"exp", Rightside{"true"}}
parseTable[50]["then"] = Production{"exp", Rightside{"true"}}
parseTable[50]["}"] = Production{"exp", Rightside{"true"}}
parseTable[50]["<"] = Production{"exp", Rightside{"true"}}
parseTable[50][">"] = Production{"exp", Rightside{"true"}}
parseTable[50]["else"] = Production{"exp", Rightside{"true"}}
parseTable[50]["eof"] = Production{"exp", Rightside{"true"}}
parseTable[50][".."] = Production{"exp", Rightside{"true"}}
parseTable[50]["function"] = Production{"exp", Rightside{"true"}}
parseTable[50]["end"] = Production{"exp", Rightside{"true"}}
parseTable[50]["transformer"] = Production{"exp", Rightside{"true"}}
parseTable[50]["syntax"] = Production{"exp", Rightside{"true"}}
parseTable[50]["local"] = Production{"exp", Rightside{"true"}}
parseTable[50]["break"] = Production{"exp", Rightside{"true"}}
parseTable[50]["elseif"] = Production{"exp", Rightside{"true"}}
parseTable[50]["repeat"] = Production{"exp", Rightside{"true"}}
parseTable[50]["if"] = Production{"exp", Rightside{"true"}}
parseTable[50]["and"] = Production{"exp", Rightside{"true"}}
parseTable[50]["for"] = Production{"exp", Rightside{"true"}}
parseTable[50]["until"] = Production{"exp", Rightside{"true"}}
parseTable[50]["Name"] = Production{"exp", Rightside{"true"}}
parseTable[50]["or"] = Production{"exp", Rightside{"true"}}
parseTable[50]["]"] = Production{"exp", Rightside{"true"}}
parseTable[50]["~="] = Production{"exp", Rightside{"true"}}
parseTable[50]["do"] = Production{"exp", Rightside{"true"}}
parseTable[50]["^"] = Production{"exp", Rightside{"true"}}

parseTable[51] = {}
parseTable[51][">="] = 109
parseTable[51]["=="] = 102
parseTable[51]["<="] = 105
parseTable[51]["while"] = Production{"explist", Rightside{"exp"}}
parseTable[51][")"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["("] = Production{"explist", Rightside{"exp"}}
parseTable[51]["+"] = 110
parseTable[51]["*"] = 113
parseTable[51]["-"] = 114
parseTable[51][","] = Production{"explist", Rightside{"exp"}}
parseTable[51]["/"] = 108
parseTable[51]["return"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["import"] = Production{"explist", Rightside{"exp"}}
parseTable[51][";"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["local"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["repeat"] = Production{"explist", Rightside{"exp"}}
parseTable[51][">"] = 111
parseTable[51]["else"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["eof"] = Production{"explist", Rightside{"exp"}}
parseTable[51][".."] = 103
parseTable[51]["function"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["end"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["binop"] = 106
parseTable[51]["transformer"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["syntax"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["elseif"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["~="] = 116
parseTable[51]["if"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["break"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["for"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["until"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["Name"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["or"] = 115
parseTable[51]["and"] = 104
parseTable[51]["do"] = Production{"explist", Rightside{"exp"}}
parseTable[51]["<"] = 107
parseTable[51]["^"] = 112

parseTable[52] = {}
parseTable[52]["~="] = Production{"exp", Rightside{"var"}}
parseTable[52]["=="] = Production{"exp", Rightside{"var"}}
parseTable[52]["<="] = Production{"exp", Rightside{"var"}}
parseTable[52]["while"] = Production{"exp", Rightside{"var"}}
parseTable[52][")"] = Production{"exp", Rightside{"var"}}

parseTable[52]["("] = GetSelectorByLineNum(Production{"prefixexp", Rightside{"var"}})
--Set{Production{"exp", Rightside{"var"}}, Production{"prefixexp", Rightside{"var"}}}

parseTable[52]["+"] = Production{"exp", Rightside{"var"}}
parseTable[52]["*"] = Production{"exp", Rightside{"var"}}
parseTable[52]["-"] = Production{"exp", Rightside{"var"}}
parseTable[52][","] = Production{"exp", Rightside{"var"}}
parseTable[52]["/"] = Production{"exp", Rightside{"var"}}
parseTable[52]["."] = Production{"prefixexp", Rightside{"var"}}
parseTable[52]["return"] = Production{"exp", Rightside{"var"}}
parseTable[52]["import"] = Production{"exp", Rightside{"var"}}
parseTable[52]["{"] = Production{"prefixexp", Rightside{"var"}}
parseTable[52][":"] = Production{"prefixexp", Rightside{"var"}}
parseTable[52]["}"] = Production{"exp", Rightside{"var"}}
parseTable[52]["<"] = Production{"exp", Rightside{"var"}}
parseTable[52][">"] = Production{"exp", Rightside{"var"}}
parseTable[52]["else"] = Production{"exp", Rightside{"var"}}
parseTable[52]["eof"] = Production{"exp", Rightside{"var"}}
parseTable[52][".."] = Production{"exp", Rightside{"var"}}
parseTable[52]["function"] = Production{"exp", Rightside{"var"}}
parseTable[52]["end"] = Production{"exp", Rightside{"var"}}
parseTable[52]["then"] = Production{"exp", Rightside{"var"}}
parseTable[52]["break"] = Production{"exp", Rightside{"var"}}
parseTable[52]["transformer"] = Production{"exp", Rightside{"var"}}
parseTable[52]["repeat"] = Production{"exp", Rightside{"var"}}
parseTable[52]["syntax"] = Production{"exp", Rightside{"var"}}
parseTable[52]["local"] = Production{"exp", Rightside{"var"}}
parseTable[52]["or"] = Production{"exp", Rightside{"var"}}
parseTable[52]["Name"] = Production{"exp", Rightside{"var"}}
parseTable[52]["elseif"] = Production{"exp", Rightside{"var"}}
parseTable[52]["do"] = Production{"exp", Rightside{"var"}}
parseTable[52]["if"] = Production{"exp", Rightside{"var"}}
parseTable[52]["and"] = Production{"exp", Rightside{"var"}}
parseTable[52]["for"] = Production{"exp", Rightside{"var"}}
parseTable[52]["until"] = Production{"exp", Rightside{"var"}}
parseTable[52]["["] = Production{"prefixexp", Rightside{"var"}}
parseTable[52][">="] = Production{"exp", Rightside{"var"}}
parseTable[52]["]"] = Production{"exp", Rightside{"var"}}
parseTable[52]["Literal"] = Production{"prefixexp", Rightside{"var"}}
parseTable[52][";"] = Production{"exp", Rightside{"var"}}
parseTable[52]["^"] = Production{"exp", Rightside{"var"}}

parseTable[53] = {}
parseTable[53]["Number"] = 61
parseTable[53]["functiondef"] = 59
parseTable[53]["exp"] = 117
parseTable[53]["function"] = 58
parseTable[53]["prefixexp"] = 10
parseTable[53]["var"] = 52
parseTable[53]["-"] = 54
parseTable[53]["true"] = 50
parseTable[53]["not"] = 57
parseTable[53]["Literal"] = 48
parseTable[53]["false"] = 63
parseTable[53]["tableconstructor"] = 56
parseTable[53]["Name"] = 23
parseTable[53]["{"] = 39
parseTable[53]["nil"] = 60
parseTable[53]["unop"] = 55
parseTable[53]["("] = 53
parseTable[53]["functioncall"] = 49

parseTable[54] = {}
parseTable[54]["Number"] = Production{"unop", Rightside{"-"}}
parseTable[54]["not"] = Production{"unop", Rightside{"-"}}
parseTable[54]["Literal"] = Production{"unop", Rightside{"-"}}
parseTable[54]["false"] = Production{"unop", Rightside{"-"}}
parseTable[54]["function"] = Production{"unop", Rightside{"-"}}
parseTable[54]["("] = Production{"unop", Rightside{"-"}}
parseTable[54]["Name"] = Production{"unop", Rightside{"-"}}
parseTable[54]["-"] = Production{"unop", Rightside{"-"}}
parseTable[54]["{"] = Production{"unop", Rightside{"-"}}
parseTable[54]["true"] = Production{"unop", Rightside{"-"}}
parseTable[54]["nil"] = Production{"unop", Rightside{"-"}}

parseTable[55] = {}
parseTable[55]["Number"] = 61
parseTable[55]["functiondef"] = 59
parseTable[55]["exp"] = 118
parseTable[55]["function"] = 58
parseTable[55]["prefixexp"] = 10
parseTable[55]["var"] = 52
parseTable[55]["-"] = 54
parseTable[55]["true"] = 50
parseTable[55]["not"] = 57
parseTable[55]["Literal"] = 48
parseTable[55]["false"] = 63
parseTable[55]["tableconstructor"] = 56
parseTable[55]["Name"] = 23
parseTable[55]["unop"] = 55
parseTable[55]["("] = 53
parseTable[55]["{"] = 39
parseTable[55]["nil"] = 60
parseTable[55]["functioncall"] = 49

parseTable[56] = {}
parseTable[56][">="] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["=="] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["<="] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["while"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56][")"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["("] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["+"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["*"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["-"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56][","] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["/"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["return"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["import"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56][";"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["then"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["}"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["<"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56][">"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["else"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["eof"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56][".."] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["function"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["end"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["transformer"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["syntax"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["local"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["break"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["elseif"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["repeat"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["if"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["and"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["for"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["until"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["Name"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["or"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["]"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["~="] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["do"] = Production{"exp", Rightside{"tableconstructor"}}
parseTable[56]["^"] = Production{"exp", Rightside{"tableconstructor"}}

parseTable[57] = {}
parseTable[57]["Number"] = Production{"unop", Rightside{"not"}}
parseTable[57]["not"] = Production{"unop", Rightside{"not"}}
parseTable[57]["Literal"] = Production{"unop", Rightside{"not"}}
parseTable[57]["false"] = Production{"unop", Rightside{"not"}}
parseTable[57]["function"] = Production{"unop", Rightside{"not"}}
parseTable[57]["("] = Production{"unop", Rightside{"not"}}
parseTable[57]["Name"] = Production{"unop", Rightside{"not"}}
parseTable[57]["-"] = Production{"unop", Rightside{"not"}}
parseTable[57]["{"] = Production{"unop", Rightside{"not"}}
parseTable[57]["true"] = Production{"unop", Rightside{"not"}}
parseTable[57]["nil"] = Production{"unop", Rightside{"not"}}

parseTable[58] = {}
parseTable[58]["("] = 82
parseTable[58]["funcbody"] = 119

parseTable[59] = {}
parseTable[59][">="] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["=="] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["<="] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["while"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59][")"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["("] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["+"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["*"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["-"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59][","] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["/"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["return"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["import"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59][";"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["then"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["}"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["<"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59][">"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["else"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["eof"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59][".."] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["function"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["end"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["transformer"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["syntax"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["local"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["break"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["elseif"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["repeat"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["if"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["and"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["for"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["until"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["Name"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["or"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["]"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["~="] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["do"] = Production{"exp", Rightside{"functiondef"}}
parseTable[59]["^"] = Production{"exp", Rightside{"functiondef"}}

parseTable[60] = {}
parseTable[60][">="] = Production{"exp", Rightside{"nil"}}
parseTable[60]["=="] = Production{"exp", Rightside{"nil"}}
parseTable[60]["<="] = Production{"exp", Rightside{"nil"}}
parseTable[60]["while"] = Production{"exp", Rightside{"nil"}}
parseTable[60][")"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["("] = Production{"exp", Rightside{"nil"}}
parseTable[60]["+"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["*"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["-"] = Production{"exp", Rightside{"nil"}}
parseTable[60][","] = Production{"exp", Rightside{"nil"}}
parseTable[60]["/"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["return"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["import"] = Production{"exp", Rightside{"nil"}}
parseTable[60][";"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["then"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["}"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["<"] = Production{"exp", Rightside{"nil"}}
parseTable[60][">"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["else"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["eof"] = Production{"exp", Rightside{"nil"}}
parseTable[60][".."] = Production{"exp", Rightside{"nil"}}
parseTable[60]["function"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["end"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["transformer"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["syntax"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["local"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["break"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["elseif"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["repeat"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["if"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["and"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["for"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["until"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["Name"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["or"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["]"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["~="] = Production{"exp", Rightside{"nil"}}
parseTable[60]["do"] = Production{"exp", Rightside{"nil"}}
parseTable[60]["^"] = Production{"exp", Rightside{"nil"}}

parseTable[61] = {}
parseTable[61][">="] = Production{"exp", Rightside{"Number"}}
parseTable[61]["=="] = Production{"exp", Rightside{"Number"}}
parseTable[61]["<="] = Production{"exp", Rightside{"Number"}}
parseTable[61]["while"] = Production{"exp", Rightside{"Number"}}
parseTable[61][")"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["("] = Production{"exp", Rightside{"Number"}}
parseTable[61]["+"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["*"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["-"] = Production{"exp", Rightside{"Number"}}
parseTable[61][","] = Production{"exp", Rightside{"Number"}}
parseTable[61]["/"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["return"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["import"] = Production{"exp", Rightside{"Number"}}
parseTable[61][";"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["then"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["}"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["<"] = Production{"exp", Rightside{"Number"}}
parseTable[61][">"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["else"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["eof"] = Production{"exp", Rightside{"Number"}}
parseTable[61][".."] = Production{"exp", Rightside{"Number"}}
parseTable[61]["function"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["end"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["transformer"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["syntax"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["local"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["break"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["elseif"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["repeat"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["if"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["and"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["for"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["until"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["Name"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["or"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["]"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["~="] = Production{"exp", Rightside{"Number"}}
parseTable[61]["do"] = Production{"exp", Rightside{"Number"}}
parseTable[61]["^"] = Production{"exp", Rightside{"Number"}}

parseTable[62] = {}
parseTable[62]["else"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["do"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["eof"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["while"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["function"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["("] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["end"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["transformer"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["syntax"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["return"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["elseif"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["if"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["break"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["for"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["until"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["Name"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["local"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["repeat"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62][";"] = Production{"stat", Rightside{"return", "result_part"}}
parseTable[62]["import"] = Production{"stat", Rightside{"return", "result_part"}}

parseTable[63] = {}
parseTable[63][">="] = Production{"exp", Rightside{"false"}}
parseTable[63]["=="] = Production{"exp", Rightside{"false"}}
parseTable[63]["<="] = Production{"exp", Rightside{"false"}}
parseTable[63]["while"] = Production{"exp", Rightside{"false"}}
parseTable[63][")"] = Production{"exp", Rightside{"false"}}
parseTable[63]["("] = Production{"exp", Rightside{"false"}}
parseTable[63]["+"] = Production{"exp", Rightside{"false"}}
parseTable[63]["*"] = Production{"exp", Rightside{"false"}}
parseTable[63]["-"] = Production{"exp", Rightside{"false"}}
parseTable[63][","] = Production{"exp", Rightside{"false"}}
parseTable[63]["/"] = Production{"exp", Rightside{"false"}}
parseTable[63]["return"] = Production{"exp", Rightside{"false"}}
parseTable[63]["import"] = Production{"exp", Rightside{"false"}}
parseTable[63][";"] = Production{"exp", Rightside{"false"}}
parseTable[63]["then"] = Production{"exp", Rightside{"false"}}
parseTable[63]["}"] = Production{"exp", Rightside{"false"}}
parseTable[63]["<"] = Production{"exp", Rightside{"false"}}
parseTable[63][">"] = Production{"exp", Rightside{"false"}}
parseTable[63]["else"] = Production{"exp", Rightside{"false"}}
parseTable[63]["eof"] = Production{"exp", Rightside{"false"}}
parseTable[63][".."] = Production{"exp", Rightside{"false"}}
parseTable[63]["function"] = Production{"exp", Rightside{"false"}}
parseTable[63]["end"] = Production{"exp", Rightside{"false"}}
parseTable[63]["transformer"] = Production{"exp", Rightside{"false"}}
parseTable[63]["syntax"] = Production{"exp", Rightside{"false"}}
parseTable[63]["local"] = Production{"exp", Rightside{"false"}}
parseTable[63]["break"] = Production{"exp", Rightside{"false"}}
parseTable[63]["elseif"] = Production{"exp", Rightside{"false"}}
parseTable[63]["repeat"] = Production{"exp", Rightside{"false"}}
parseTable[63]["if"] = Production{"exp", Rightside{"false"}}
parseTable[63]["and"] = Production{"exp", Rightside{"false"}}
parseTable[63]["for"] = Production{"exp", Rightside{"false"}}
parseTable[63]["until"] = Production{"exp", Rightside{"false"}}
parseTable[63]["Name"] = Production{"exp", Rightside{"false"}}
parseTable[63]["or"] = Production{"exp", Rightside{"false"}}
parseTable[63]["]"] = Production{"exp", Rightside{"false"}}
parseTable[63]["~="] = Production{"exp", Rightside{"false"}}
parseTable[63]["do"] = Production{"exp", Rightside{"false"}}
parseTable[63]["^"] = Production{"exp", Rightside{"false"}}

parseTable[64] = {}
parseTable[64]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[64]["do"] = 26
parseTable[64]["while"] = 19
parseTable[64]["function"] = 5
parseTable[64]["prefixexp"] = 10
parseTable[64]["var"] = 14
parseTable[64]["optional_stat_list"] = 75
parseTable[64]["block"] = 120
parseTable[64]["stat"] = 76
parseTable[64]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[64]["return"] = 12
parseTable[64]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[64]["stat_list"] = 73
parseTable[64]["if"] = 22
parseTable[64]["break"] = 7
parseTable[64]["for"] = 18
parseTable[64]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[64]["Name"] = 23
parseTable[64]["local"] = 11
parseTable[64]["varlist"] = 15
parseTable[64]["repeat"] = 24
parseTable[64]["("] = 17
parseTable[64]["functioncall"] = 3

parseTable[65] = {}
parseTable[65]["Number"] = 61
parseTable[65]["functiondef"] = 59
parseTable[65]["unop"] = 55
parseTable[65]["function"] = 58
parseTable[65]["("] = 53
parseTable[65]["var"] = 52
parseTable[65]["-"] = 54
parseTable[65]["true"] = 50
parseTable[65]["not"] = 57
parseTable[65]["Literal"] = 48
parseTable[65]["explist"] = 121
parseTable[65]["false"] = 63
parseTable[65]["tableconstructor"] = 56
parseTable[65]["Name"] = 23
parseTable[65]["{"] = 39
parseTable[65]["exp"] = 51
parseTable[65]["prefixexp"] = 10
parseTable[65]["nil"] = 60
parseTable[65]["functioncall"] = 49

parseTable[66] = {}
parseTable[66]["("] = 17
parseTable[66]["Name"] = 23
parseTable[66]["var"] = 123
parseTable[66]["prefixexp"] = 10
parseTable[66]["functioncall"] = 122

parseTable[67] = {}
parseTable[67]["~="] = 116
parseTable[67]["=="] = 102
parseTable[67]["<="] = 105
parseTable[67][".."] = 103
parseTable[67][")"] = 124
parseTable[67]["+"] = 110
parseTable[67]["or"] = 115
parseTable[67]["-"] = 114
parseTable[67]["/"] = 108
parseTable[67]["and"] = 104
parseTable[67]["*"] = 113
parseTable[67][">="] = 109
parseTable[67]["binop"] = 106
parseTable[67]["<"] = 107
parseTable[67][">"] = 111
parseTable[67]["^"] = 112

parseTable[68] = {}
parseTable[68]["in"] = 125
parseTable[68][","] = 126

parseTable[69] = {}
parseTable[69]["in"] = Production{"namelist", Rightside{"Name"}}
parseTable[69][","] = Production{"namelist", Rightside{"Name"}}
parseTable[69]["="] = 127

parseTable[70] = {}
parseTable[70]["do"] = 128
parseTable[70]["=="] = 102
parseTable[70]["<="] = 105
parseTable[70][".."] = 103
parseTable[70]["+"] = 110
parseTable[70]["*"] = 113
parseTable[70]["binop"] = 106
parseTable[70]["/"] = 108
parseTable[70]["and"] = 104
parseTable[70]["-"] = 114
parseTable[70]["~="] = 116
parseTable[70][">="] = 109
parseTable[70]["or"] = 115
parseTable[70]["<"] = 107
parseTable[70][">"] = 111
parseTable[70]["^"] = 112

parseTable[71] = {}
parseTable[71]["syntax"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["do"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["eof"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["if"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["return"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["while"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["import"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["function"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["("] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["Name"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["local"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["for"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["repeat"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["transformer"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}
parseTable[71]["break"] = Production{"one_stat", Rightside{"stat", "stat_sep"}}

parseTable[72] = {}
parseTable[72][">="] = 109
parseTable[72]["=="] = 102
parseTable[72]["<="] = 105
parseTable[72][".."] = 103
parseTable[72]["+"] = 110
parseTable[72]["*"] = 113
parseTable[72]["-"] = 114
parseTable[72]["/"] = 108
parseTable[72]["and"] = 104
parseTable[72]["binop"] = 106
parseTable[72]["~="] = 116
parseTable[72]["then"] = 129
parseTable[72]["or"] = 115
parseTable[72]["<"] = 107
parseTable[72][">"] = 111
parseTable[72]["^"] = 112

parseTable[73] = {}
parseTable[73]["else"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["do"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["eof"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["while"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["function"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["("] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["end"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["transformer"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["syntax"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["return"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["elseif"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["if"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["break"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["for"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["until"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["Name"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["local"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73]["stat_sep"] = 130
parseTable[73]["repeat"] = Production{"stat_sep", Rightside{"empty"}}
parseTable[73][";"] = 34
parseTable[73]["import"] = Production{"stat_sep", Rightside{"empty"}}

parseTable[74] = {}
parseTable[74]["until"] = 131

parseTable[75] = {}
parseTable[75]["until"] = Production{"block", Rightside{"optional_stat_list"}}
parseTable[75]["end"] = Production{"block", Rightside{"optional_stat_list"}}
parseTable[75]["elseif"] = Production{"block", Rightside{"optional_stat_list"}}
parseTable[75]["else"] = Production{"block", Rightside{"optional_stat_list"}}

parseTable[76] = {}
parseTable[76]["else"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["do"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["while"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["function"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["("] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["end"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["return"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["elseif"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["if"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["break"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["for"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["until"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["Name"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["local"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76]["repeat"] = Production{"stat_list", Rightside{"stat"}}
parseTable[76][";"] = Production{"stat_list", Rightside{"stat"}}

parseTable[77] = {}
parseTable[77]["end"] = 132

parseTable[78] = {}
parseTable[78]["syntax"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["do"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["eof"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["break"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["return"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["if"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["import"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["function"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["("] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["Name"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["local"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["for"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["repeat"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["transformer"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}
parseTable[78]["while"] = Production{"metastat", Rightside{"transformerdef", "stat_sep"}}

parseTable[79] = {}
parseTable[79]["syntax"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["do"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["eof"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["break"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["return"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["if"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["import"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["function"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["("] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["Name"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["local"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["for"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["repeat"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["transformer"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}
parseTable[79]["while"] = Production{"metastat", Rightside{"syntaxdef", "stat_sep"}}

parseTable[80] = {}
parseTable[80]["Literal"] = 133

parseTable[81] = {}
parseTable[81]["("] = Production{"colone_name", Rightside{"empty"}}
parseTable[81]["colone_name"] = 135
parseTable[81][":"] = 136
parseTable[81]["."] = 134

parseTable[82] = {}
parseTable[82][")"] = Production{"optional_parlist", Rightside{"empty"}}
parseTable[82]["..."] = 139
parseTable[82]["Name"] = 140
parseTable[82]["parname_list"] = 137
parseTable[82]["parlist"] = 141
parseTable[82]["optional_parlist"] = 138

parseTable[83] = {}
parseTable[83]["else"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["do"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["eof"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["while"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["function"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["("] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["end"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["transformer"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["syntax"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["return"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["elseif"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["if"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["break"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["for"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["until"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["Name"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["local"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["repeat"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83][";"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}
parseTable[83]["import"] = Production{"stat", Rightside{"function", "funcname", "funcbody"}}

parseTable[84] = {}
parseTable[84]["tableconstructor"] = 41
parseTable[84]["{"] = 39
parseTable[84]["args"] = 142
parseTable[84]["Literal"] = 38
parseTable[84]["("] = 40

parseTable[85] = {}
parseTable[85][";"] = 144
parseTable[85]["}"] = Production{"optional_fieldlist", Rightside{"fieldlist"}}
parseTable[85][","] = 145
parseTable[85]["fieldsep"] = 143

parseTable[86] = {}
parseTable[86]["}"] = 146

parseTable[87] = {}
parseTable[87]["~="] = 116
parseTable[87]["=="] = 102
parseTable[87]["<="] = 105
parseTable[87][".."] = 103
parseTable[87]["+"] = 110
parseTable[87]["or"] = 115
parseTable[87]["-"] = 114
parseTable[87][","] = Production{"field", Rightside{"exp"}}
parseTable[87]["/"] = 108
parseTable[87]["and"] = 104
parseTable[87]["*"] = 113
parseTable[87]["^"] = 112
parseTable[87][";"] = Production{"field", Rightside{"exp"}}
parseTable[87][">="] = 109
parseTable[87]["}"] = Production{"field", Rightside{"exp"}}
parseTable[87]["<"] = 107
parseTable[87]["binop"] = 106
parseTable[87][">"] = 111

parseTable[88] = {}
parseTable[88]["="] = 147

parseTable[89] = {}
parseTable[89]["}"] = Production{"fieldlist", Rightside{"field"}}
parseTable[89][","] = Production{"fieldlist", Rightside{"field"}}
parseTable[89][";"] = Production{"fieldlist", Rightside{"field"}}

parseTable[90] = {}
parseTable[90][">="] = Production{"var", Rightside{"Name"}}
parseTable[90]["=="] = Production{"var", Rightside{"Name"}}
parseTable[90]["<="] = Production{"var", Rightside{"Name"}}
parseTable[90]["while"] = Production{"var", Rightside{"Name"}}
parseTable[90][")"] = Production{"var", Rightside{"Name"}}
parseTable[90]["("] = Production{"var", Rightside{"Name"}}
parseTable[90]["+"] = Production{"var", Rightside{"Name"}}
parseTable[90]["*"] = Production{"var", Rightside{"Name"}}
parseTable[90]["-"] = Production{"var", Rightside{"Name"}}
parseTable[90][","] = Production{"var", Rightside{"Name"}}
parseTable[90]["/"] = Production{"var", Rightside{"Name"}}
parseTable[90]["."] = Production{"var", Rightside{"Name"}}
parseTable[90]["return"] = Production{"var", Rightside{"Name"}}
parseTable[90]["import"] = Production{"var", Rightside{"Name"}}
parseTable[90]["{"] = Production{"var", Rightside{"Name"}}
parseTable[90]["then"] = Production{"var", Rightside{"Name"}}

parseTable[90]["="] = Production{"keyname", Rightside{"Name"}}
--Set{Production{"var", Rightside{"Name"}}, Production{"keyname", Rightside{"Name"}}}

parseTable[90]["repeat"] = Production{"var", Rightside{"Name"}}
parseTable[90][">"] = Production{"var", Rightside{"Name"}}
parseTable[90]["else"] = Production{"var", Rightside{"Name"}}
parseTable[90]["eof"] = Production{"var", Rightside{"Name"}}
parseTable[90][".."] = Production{"var", Rightside{"Name"}}
parseTable[90]["function"] = Production{"var", Rightside{"Name"}}
parseTable[90]["}"] = Production{"var", Rightside{"Name"}}
parseTable[90]["end"] = Production{"var", Rightside{"Name"}}
parseTable[90][":"] = Production{"var", Rightside{"Name"}}
parseTable[90]["local"] = Production{"var", Rightside{"Name"}}
parseTable[90]["transformer"] = Production{"var", Rightside{"Name"}}
parseTable[90]["~="] = Production{"var", Rightside{"Name"}}
parseTable[90]["syntax"] = Production{"var", Rightside{"Name"}}
parseTable[90]["or"] = Production{"var", Rightside{"Name"}}
parseTable[90]["Name"] = Production{"var", Rightside{"Name"}}
parseTable[90]["do"] = Production{"var", Rightside{"Name"}}
parseTable[90]["elseif"] = Production{"var", Rightside{"Name"}}
parseTable[90]["break"] = Production{"var", Rightside{"Name"}}
parseTable[90]["if"] = Production{"var", Rightside{"Name"}}
parseTable[90]["and"] = Production{"var", Rightside{"Name"}}
parseTable[90]["for"] = Production{"var", Rightside{"Name"}}
parseTable[90]["until"] = Production{"var", Rightside{"Name"}}
parseTable[90]["["] = Production{"var", Rightside{"Name"}}
parseTable[90][";"] = Production{"var", Rightside{"Name"}}
parseTable[90]["]"] = Production{"var", Rightside{"Name"}}
parseTable[90]["Literal"] = Production{"var", Rightside{"Name"}}
parseTable[90]["<"] = Production{"var", Rightside{"Name"}}
parseTable[90]["^"] = Production{"var", Rightside{"Name"}}

parseTable[91] = {}
parseTable[91]["Number"] = 61
parseTable[91]["functiondef"] = 59
parseTable[91]["exp"] = 148
parseTable[91]["function"] = 58
parseTable[91]["prefixexp"] = 10
parseTable[91]["var"] = 52
parseTable[91]["-"] = 54
parseTable[91]["true"] = 50
parseTable[91]["not"] = 57
parseTable[91]["Literal"] = 48
parseTable[91]["false"] = 63
parseTable[91]["tableconstructor"] = 56
parseTable[91]["{"] = 39
parseTable[91]["Name"] = 23
parseTable[91]["unop"] = 55
parseTable[91]["nil"] = 60
parseTable[91]["("] = 53
parseTable[91]["functioncall"] = 49

parseTable[92] = {}
parseTable[92][")"] = 149
parseTable[92][","] = 101

parseTable[93] = {}
parseTable[93]["do"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["=="] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["<="] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["while"] = Production{"args", Rightside{"(", ")"}}
parseTable[93][")"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["("] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["+"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["*"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["-"] = Production{"args", Rightside{"(", ")"}}
parseTable[93][","] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["/"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["."] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["return"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["import"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["{"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["then"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["}"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["repeat"] = Production{"args", Rightside{"(", ")"}}
parseTable[93][">"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["else"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["eof"] = Production{"args", Rightside{"(", ")"}}
parseTable[93][".."] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["function"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["or"] = Production{"args", Rightside{"(", ")"}}
parseTable[93][";"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["Literal"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["transformer"] = Production{"args", Rightside{"(", ")"}}
parseTable[93][":"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["syntax"] = Production{"args", Rightside{"(", ")"}}
parseTable[93][">="] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["<"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["["] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["elseif"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["and"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["if"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["break"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["for"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["until"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["Name"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["end"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["]"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["local"] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["~="] = Production{"args", Rightside{"(", ")"}}
parseTable[93]["^"] = Production{"args", Rightside{"(", ")"}}

parseTable[94] = {}
parseTable[94][">="] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["=="] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["<="] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["while"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94][")"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["("] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["+"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["*"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["-"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94][","] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["/"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["."] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["return"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["import"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["{"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["then"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["="] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["repeat"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94][">"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["else"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["eof"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94][".."] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["function"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["}"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["end"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94][":"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["local"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["transformer"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["~="] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["syntax"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["or"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["Name"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["do"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["elseif"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["break"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["if"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["and"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["for"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["until"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["["] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94][";"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["]"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["Literal"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["<"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}
parseTable[94]["^"] = Production{"var", Rightside{"prefixexp", ".", "Name"}}

parseTable[95] = {}
parseTable[95]["~="] = 116
parseTable[95]["=="] = 102
parseTable[95]["<="] = 105
parseTable[95][".."] = 103
parseTable[95]["+"] = 110
parseTable[95]["or"] = 115
parseTable[95]["binop"] = 106
parseTable[95]["/"] = 108
parseTable[95]["and"] = 104
parseTable[95]["-"] = 114
parseTable[95][">"] = 111
parseTable[95][">="] = 109
parseTable[95]["]"] = 150
parseTable[95]["<"] = 107
parseTable[95]["*"] = 113
parseTable[95]["^"] = 112

parseTable[96] = {}
parseTable[96]["Name"] = 151

parseTable[97] = {}
parseTable[97]["else"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["do"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["eof"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["while"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["function"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["("] = Production{"init_part", Rightside{"init"}}
parseTable[97]["end"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["transformer"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["syntax"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["return"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["elseif"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["if"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["break"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["for"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["until"] = Production{"init_part", Rightside{"init"}}
parseTable[97][";"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["local"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["repeat"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["Name"] = Production{"init_part", Rightside{"init"}}
parseTable[97]["import"] = Production{"init_part", Rightside{"init"}}

parseTable[98] = {}
parseTable[98]["Number"] = 61
parseTable[98]["functiondef"] = 59
parseTable[98]["exp"] = 51
parseTable[98]["function"] = 58
parseTable[98]["prefixexp"] = 10
parseTable[98]["var"] = 52
parseTable[98]["-"] = 54
parseTable[98]["true"] = 50
parseTable[98]["not"] = 57
parseTable[98]["Literal"] = 48
parseTable[98]["explist"] = 152
parseTable[98]["false"] = 63
parseTable[98]["tableconstructor"] = 56
parseTable[98]["Name"] = 23
parseTable[98]["{"] = 39
parseTable[98]["unop"] = 55
parseTable[98]["nil"] = 60
parseTable[98]["("] = 53
parseTable[98]["functioncall"] = 49

parseTable[99] = {}
parseTable[99]["else"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["do"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["eof"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["while"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["function"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["("] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["end"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["transformer"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["syntax"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["return"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["elseif"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["if"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["break"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["for"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["until"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["Name"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["local"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["repeat"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99][";"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}
parseTable[99]["import"] = Production{"stat", Rightside{"local", "localvar_list", "init_part"}}

parseTable[100] = {}
parseTable[100]["("] = 82
parseTable[100]["funcbody"] = 153

parseTable[101] = {}
parseTable[101]["Number"] = 61
parseTable[101]["functiondef"] = 59
parseTable[101]["unop"] = 55
parseTable[101]["function"] = 58
parseTable[101]["prefixexp"] = 10
parseTable[101]["var"] = 52
parseTable[101]["-"] = 54
parseTable[101]["true"] = 50
parseTable[101]["not"] = 57
parseTable[101]["Literal"] = 48
parseTable[101]["false"] = 63
parseTable[101]["tableconstructor"] = 56
parseTable[101]["{"] = 39
parseTable[101]["Name"] = 23
parseTable[101]["exp"] = 154
parseTable[101]["("] = 53
parseTable[101]["nil"] = 60
parseTable[101]["functioncall"] = 49

parseTable[102] = {}
parseTable[102]["Number"] = Production{"binop", Rightside{"=="}}
parseTable[102]["not"] = Production{"binop", Rightside{"=="}}
parseTable[102]["Literal"] = Production{"binop", Rightside{"=="}}
parseTable[102]["false"] = Production{"binop", Rightside{"=="}}
parseTable[102]["function"] = Production{"binop", Rightside{"=="}}
parseTable[102]["("] = Production{"binop", Rightside{"=="}}
parseTable[102]["Name"] = Production{"binop", Rightside{"=="}}
parseTable[102]["-"] = Production{"binop", Rightside{"=="}}
parseTable[102]["{"] = Production{"binop", Rightside{"=="}}
parseTable[102]["true"] = Production{"binop", Rightside{"=="}}
parseTable[102]["nil"] = Production{"binop", Rightside{"=="}}

parseTable[103] = {}
parseTable[103]["Number"] = Production{"binop", Rightside{".."}}
parseTable[103]["not"] = Production{"binop", Rightside{".."}}
parseTable[103]["Literal"] = Production{"binop", Rightside{".."}}
parseTable[103]["false"] = Production{"binop", Rightside{".."}}
parseTable[103]["function"] = Production{"binop", Rightside{".."}}
parseTable[103]["("] = Production{"binop", Rightside{".."}}
parseTable[103]["Name"] = Production{"binop", Rightside{".."}}
parseTable[103]["-"] = Production{"binop", Rightside{".."}}
parseTable[103]["{"] = Production{"binop", Rightside{".."}}
parseTable[103]["true"] = Production{"binop", Rightside{".."}}
parseTable[103]["nil"] = Production{"binop", Rightside{".."}}

parseTable[104] = {}
parseTable[104]["Number"] = Production{"binop", Rightside{"and"}}
parseTable[104]["not"] = Production{"binop", Rightside{"and"}}
parseTable[104]["Literal"] = Production{"binop", Rightside{"and"}}
parseTable[104]["false"] = Production{"binop", Rightside{"and"}}
parseTable[104]["function"] = Production{"binop", Rightside{"and"}}
parseTable[104]["("] = Production{"binop", Rightside{"and"}}
parseTable[104]["Name"] = Production{"binop", Rightside{"and"}}
parseTable[104]["-"] = Production{"binop", Rightside{"and"}}
parseTable[104]["{"] = Production{"binop", Rightside{"and"}}
parseTable[104]["true"] = Production{"binop", Rightside{"and"}}
parseTable[104]["nil"] = Production{"binop", Rightside{"and"}}

parseTable[105] = {}
parseTable[105]["Number"] = Production{"binop", Rightside{"<="}}
parseTable[105]["not"] = Production{"binop", Rightside{"<="}}
parseTable[105]["Literal"] = Production{"binop", Rightside{"<="}}
parseTable[105]["false"] = Production{"binop", Rightside{"<="}}
parseTable[105]["function"] = Production{"binop", Rightside{"<="}}
parseTable[105]["("] = Production{"binop", Rightside{"<="}}
parseTable[105]["Name"] = Production{"binop", Rightside{"<="}}
parseTable[105]["-"] = Production{"binop", Rightside{"<="}}
parseTable[105]["{"] = Production{"binop", Rightside{"<="}}
parseTable[105]["true"] = Production{"binop", Rightside{"<="}}
parseTable[105]["nil"] = Production{"binop", Rightside{"<="}}

parseTable[106] = {}
parseTable[106]["Number"] = 61
parseTable[106]["functiondef"] = 59
parseTable[106]["exp"] = 155
parseTable[106]["function"] = 58
parseTable[106]["("] = 53
parseTable[106]["var"] = 52
parseTable[106]["-"] = 54
parseTable[106]["true"] = 50
parseTable[106]["not"] = 57
parseTable[106]["Literal"] = 48
parseTable[106]["false"] = 63
parseTable[106]["tableconstructor"] = 56
parseTable[106]["Name"] = 23
parseTable[106]["unop"] = 55
parseTable[106]["{"] = 39
parseTable[106]["nil"] = 60
parseTable[106]["prefixexp"] = 10
parseTable[106]["functioncall"] = 49

parseTable[107] = {}
parseTable[107]["Number"] = Production{"binop", Rightside{"<"}}
parseTable[107]["not"] = Production{"binop", Rightside{"<"}}
parseTable[107]["Literal"] = Production{"binop", Rightside{"<"}}
parseTable[107]["false"] = Production{"binop", Rightside{"<"}}
parseTable[107]["function"] = Production{"binop", Rightside{"<"}}
parseTable[107]["("] = Production{"binop", Rightside{"<"}}
parseTable[107]["Name"] = Production{"binop", Rightside{"<"}}
parseTable[107]["-"] = Production{"binop", Rightside{"<"}}
parseTable[107]["{"] = Production{"binop", Rightside{"<"}}
parseTable[107]["true"] = Production{"binop", Rightside{"<"}}
parseTable[107]["nil"] = Production{"binop", Rightside{"<"}}

parseTable[108] = {}
parseTable[108]["Number"] = Production{"binop", Rightside{"/"}}
parseTable[108]["not"] = Production{"binop", Rightside{"/"}}
parseTable[108]["Literal"] = Production{"binop", Rightside{"/"}}
parseTable[108]["false"] = Production{"binop", Rightside{"/"}}
parseTable[108]["function"] = Production{"binop", Rightside{"/"}}
parseTable[108]["("] = Production{"binop", Rightside{"/"}}
parseTable[108]["Name"] = Production{"binop", Rightside{"/"}}
parseTable[108]["-"] = Production{"binop", Rightside{"/"}}
parseTable[108]["{"] = Production{"binop", Rightside{"/"}}
parseTable[108]["true"] = Production{"binop", Rightside{"/"}}
parseTable[108]["nil"] = Production{"binop", Rightside{"/"}}

parseTable[109] = {}
parseTable[109]["Number"] = Production{"binop", Rightside{">="}}
parseTable[109]["not"] = Production{"binop", Rightside{">="}}
parseTable[109]["Literal"] = Production{"binop", Rightside{">="}}
parseTable[109]["false"] = Production{"binop", Rightside{">="}}
parseTable[109]["function"] = Production{"binop", Rightside{">="}}
parseTable[109]["("] = Production{"binop", Rightside{">="}}
parseTable[109]["Name"] = Production{"binop", Rightside{">="}}
parseTable[109]["-"] = Production{"binop", Rightside{">="}}
parseTable[109]["{"] = Production{"binop", Rightside{">="}}
parseTable[109]["true"] = Production{"binop", Rightside{">="}}
parseTable[109]["nil"] = Production{"binop", Rightside{">="}}

parseTable[110] = {}
parseTable[110]["Number"] = Production{"binop", Rightside{"+"}}
parseTable[110]["not"] = Production{"binop", Rightside{"+"}}
parseTable[110]["Literal"] = Production{"binop", Rightside{"+"}}
parseTable[110]["false"] = Production{"binop", Rightside{"+"}}
parseTable[110]["function"] = Production{"binop", Rightside{"+"}}
parseTable[110]["("] = Production{"binop", Rightside{"+"}}
parseTable[110]["Name"] = Production{"binop", Rightside{"+"}}
parseTable[110]["-"] = Production{"binop", Rightside{"+"}}
parseTable[110]["{"] = Production{"binop", Rightside{"+"}}
parseTable[110]["true"] = Production{"binop", Rightside{"+"}}
parseTable[110]["nil"] = Production{"binop", Rightside{"+"}}

parseTable[111] = {}
parseTable[111]["Number"] = Production{"binop", Rightside{">"}}
parseTable[111]["not"] = Production{"binop", Rightside{">"}}
parseTable[111]["Literal"] = Production{"binop", Rightside{">"}}
parseTable[111]["false"] = Production{"binop", Rightside{">"}}
parseTable[111]["function"] = Production{"binop", Rightside{">"}}
parseTable[111]["("] = Production{"binop", Rightside{">"}}
parseTable[111]["Name"] = Production{"binop", Rightside{">"}}
parseTable[111]["-"] = Production{"binop", Rightside{">"}}
parseTable[111]["{"] = Production{"binop", Rightside{">"}}
parseTable[111]["true"] = Production{"binop", Rightside{">"}}
parseTable[111]["nil"] = Production{"binop", Rightside{">"}}

parseTable[112] = {}
parseTable[112]["Number"] = Production{"binop", Rightside{"^"}}
parseTable[112]["not"] = Production{"binop", Rightside{"^"}}
parseTable[112]["Literal"] = Production{"binop", Rightside{"^"}}
parseTable[112]["false"] = Production{"binop", Rightside{"^"}}
parseTable[112]["function"] = Production{"binop", Rightside{"^"}}
parseTable[112]["("] = Production{"binop", Rightside{"^"}}
parseTable[112]["Name"] = Production{"binop", Rightside{"^"}}
parseTable[112]["-"] = Production{"binop", Rightside{"^"}}
parseTable[112]["{"] = Production{"binop", Rightside{"^"}}
parseTable[112]["true"] = Production{"binop", Rightside{"^"}}
parseTable[112]["nil"] = Production{"binop", Rightside{"^"}}

parseTable[113] = {}
parseTable[113]["Number"] = Production{"binop", Rightside{"*"}}
parseTable[113]["not"] = Production{"binop", Rightside{"*"}}
parseTable[113]["Literal"] = Production{"binop", Rightside{"*"}}
parseTable[113]["false"] = Production{"binop", Rightside{"*"}}
parseTable[113]["function"] = Production{"binop", Rightside{"*"}}
parseTable[113]["("] = Production{"binop", Rightside{"*"}}
parseTable[113]["Name"] = Production{"binop", Rightside{"*"}}
parseTable[113]["-"] = Production{"binop", Rightside{"*"}}
parseTable[113]["{"] = Production{"binop", Rightside{"*"}}
parseTable[113]["true"] = Production{"binop", Rightside{"*"}}
parseTable[113]["nil"] = Production{"binop", Rightside{"*"}}

parseTable[114] = {}
parseTable[114]["Number"] = Production{"binop", Rightside{"-"}}
parseTable[114]["not"] = Production{"binop", Rightside{"-"}}
parseTable[114]["Literal"] = Production{"binop", Rightside{"-"}}
parseTable[114]["false"] = Production{"binop", Rightside{"-"}}
parseTable[114]["function"] = Production{"binop", Rightside{"-"}}
parseTable[114]["("] = Production{"binop", Rightside{"-"}}
parseTable[114]["Name"] = Production{"binop", Rightside{"-"}}
parseTable[114]["-"] = Production{"binop", Rightside{"-"}}
parseTable[114]["{"] = Production{"binop", Rightside{"-"}}
parseTable[114]["true"] = Production{"binop", Rightside{"-"}}
parseTable[114]["nil"] = Production{"binop", Rightside{"-"}}

parseTable[115] = {}
parseTable[115]["Number"] = Production{"binop", Rightside{"or"}}
parseTable[115]["not"] = Production{"binop", Rightside{"or"}}
parseTable[115]["Literal"] = Production{"binop", Rightside{"or"}}
parseTable[115]["false"] = Production{"binop", Rightside{"or"}}
parseTable[115]["function"] = Production{"binop", Rightside{"or"}}
parseTable[115]["("] = Production{"binop", Rightside{"or"}}
parseTable[115]["Name"] = Production{"binop", Rightside{"or"}}
parseTable[115]["-"] = Production{"binop", Rightside{"or"}}
parseTable[115]["{"] = Production{"binop", Rightside{"or"}}
parseTable[115]["true"] = Production{"binop", Rightside{"or"}}
parseTable[115]["nil"] = Production{"binop", Rightside{"or"}}

parseTable[116] = {}
parseTable[116]["Number"] = Production{"binop", Rightside{"~="}}
parseTable[116]["not"] = Production{"binop", Rightside{"~="}}
parseTable[116]["Literal"] = Production{"binop", Rightside{"~="}}
parseTable[116]["false"] = Production{"binop", Rightside{"~="}}
parseTable[116]["function"] = Production{"binop", Rightside{"~="}}
parseTable[116]["("] = Production{"binop", Rightside{"~="}}
parseTable[116]["Name"] = Production{"binop", Rightside{"~="}}
parseTable[116]["-"] = Production{"binop", Rightside{"~="}}
parseTable[116]["{"] = Production{"binop", Rightside{"~="}}
parseTable[116]["true"] = Production{"binop", Rightside{"~="}}
parseTable[116]["nil"] = Production{"binop", Rightside{"~="}}

parseTable[117] = {}
parseTable[117][">="] = 109
parseTable[117]["=="] = 102
parseTable[117]["<="] = 105
parseTable[117][".."] = 103
parseTable[117][")"] = 156
parseTable[117]["+"] = 110
parseTable[117]["*"] = 113
parseTable[117]["-"] = 114
parseTable[117]["/"] = 108
parseTable[117]["and"] = 104
parseTable[117]["~="] = 116
parseTable[117]["^"] = 112
parseTable[117]["binop"] = 106
parseTable[117]["<"] = 107
parseTable[117]["or"] = 115
parseTable[117][">"] = 111

parseTable[118] = {}

parseTable[118]["~="] = Production{"exp", Rightside{"unop", "exp"}}
--Set{116, Production{"exp", Rightside{"unop", "exp"}}}


parseTable[118]["=="] = Production{"exp", Rightside{"unop", "exp"}}
--Set{102, Production{"exp", Rightside{"unop", "exp"}}}


parseTable[118]["<="] = Production{"exp", Rightside{"unop", "exp"}}
--Set{105, Production{"exp", Rightside{"unop", "exp"}}}

parseTable[118]["while"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118][")"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["("] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118]["+"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{110, Production{"exp", Rightside{"unop", "exp"}}}


parseTable[118]["*"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{Production{"exp", Rightside{"unop", "exp"}}, 113}


parseTable[118]["-"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{114, Production{"exp", Rightside{"unop", "exp"}}}

parseTable[118][","] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118]["/"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{108, Production{"exp", Rightside{"unop", "exp"}}}

parseTable[118]["return"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["import"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118][";"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["then"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["}"] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118]["<"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{Production{"exp", Rightside{"unop", "exp"}}, 107}


parseTable[118][">"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{111, Production{"exp", Rightside{"unop", "exp"}}}

parseTable[118]["else"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["eof"] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118][".."] = Production{"exp", Rightside{"unop", "exp"}}
--Set{103, Production{"exp", Rightside{"unop", "exp"}}}

parseTable[118]["function"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["end"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["binop"] = 106
parseTable[118]["transformer"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["syntax"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["break"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["repeat"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["elseif"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["do"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["if"] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118]["and"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{Production{"exp", Rightside{"unop", "exp"}}, 104}

parseTable[118]["for"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["until"] = Production{"exp", Rightside{"unop", "exp"}}
parseTable[118]["Name"] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118]["or"] = Production{"exp", Rightside{"unop", "exp"}}
--Set{115, Production{"exp", Rightside{"unop", "exp"}}}

parseTable[118]["]"] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118][">="] = Production{"exp", Rightside{"unop", "exp"}}
--Set{109, Production{"exp", Rightside{"unop", "exp"}}}

parseTable[118]["local"] = Production{"exp", Rightside{"unop", "exp"}}

parseTable[118]["^"] = 112
--Set{112, Production{"exp", Rightside{"unop", "exp"}}}


parseTable[119] = {}
parseTable[119]["do"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["=="] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["<="] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["while"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119][")"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["("] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["+"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["*"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["-"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119][","] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["/"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["return"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["import"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119][";"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["local"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["}"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["repeat"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119][">"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["else"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["eof"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119][".."] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["function"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["or"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["transformer"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["syntax"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["<"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["then"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["elseif"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["and"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["if"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["break"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["for"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["until"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["Name"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119][">="] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["]"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["end"] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["~="] = Production{"functiondef", Rightside{"function", "funcbody"}}
parseTable[119]["^"] = Production{"functiondef", Rightside{"function", "funcbody"}}

parseTable[120] = {}
parseTable[120]["end"] = 157

parseTable[121] = {}
parseTable[121]["else"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["do"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["eof"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["while"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["function"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["("] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["end"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121][","] = 101
parseTable[121]["transformer"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["syntax"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["return"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["elseif"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["if"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["break"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["for"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["until"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["Name"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["local"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["repeat"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121][";"] = Production{"stat", Rightside{"varlist", "=", "explist"}}
parseTable[121]["import"] = Production{"stat", Rightside{"varlist", "=", "explist"}}

parseTable[122] = {}
parseTable[122]["("] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[122]["["] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[122][":"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[122]["Literal"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[122]["{"] = Production{"prefixexp", Rightside{"functioncall"}}
parseTable[122]["."] = Production{"prefixexp", Rightside{"functioncall"}}

parseTable[123] = {}
parseTable[123]["Literal"] = Production{"prefixexp", Rightside{"var"}}
parseTable[123]["("] = Production{"prefixexp", Rightside{"var"}}
parseTable[123]["{"] = Production{"prefixexp", Rightside{"var"}}
parseTable[123][":"] = Production{"prefixexp", Rightside{"var"}}
parseTable[123]["="] = Production{"varlist", Rightside{"varlist", ",", "var"}}
parseTable[123][","] = Production{"varlist", Rightside{"varlist", ",", "var"}}
parseTable[123]["["] = Production{"prefixexp", Rightside{"var"}}
parseTable[123]["."] = Production{"prefixexp", Rightside{"var"}}

parseTable[124] = {}
parseTable[124]["("] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[124]["["] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[124][":"] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[124]["Literal"] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[124]["{"] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[124]["."] = Production{"prefixexp", Rightside{"(", "exp", ")"}}

parseTable[125] = {}
parseTable[125]["Number"] = 61
parseTable[125]["functiondef"] = 59
parseTable[125]["exp"] = 51
parseTable[125]["function"] = 58
parseTable[125]["prefixexp"] = 10
parseTable[125]["var"] = 52
parseTable[125]["-"] = 54
parseTable[125]["true"] = 50
parseTable[125]["not"] = 57
parseTable[125]["Literal"] = 48
parseTable[125]["explist"] = 158
parseTable[125]["false"] = 63
parseTable[125]["tableconstructor"] = 56
parseTable[125]["{"] = 39
parseTable[125]["unop"] = 55
parseTable[125]["Name"] = 23
parseTable[125]["("] = 53
parseTable[125]["nil"] = 60
parseTable[125]["functioncall"] = 49

parseTable[126] = {}
parseTable[126]["Name"] = 159

parseTable[127] = {}
parseTable[127]["Number"] = 61
parseTable[127]["functiondef"] = 59
parseTable[127]["unop"] = 55
parseTable[127]["function"] = 58
parseTable[127]["prefixexp"] = 10
parseTable[127]["var"] = 52
parseTable[127]["-"] = 54
parseTable[127]["true"] = 50
parseTable[127]["not"] = 57
parseTable[127]["Literal"] = 48
parseTable[127]["false"] = 63
parseTable[127]["tableconstructor"] = 56
parseTable[127]["Name"] = 23
parseTable[127]["exp"] = 160
parseTable[127]["("] = 53
parseTable[127]["{"] = 39
parseTable[127]["nil"] = 60
parseTable[127]["functioncall"] = 49

parseTable[128] = {}
parseTable[128]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[128]["do"] = 26
parseTable[128]["while"] = 19
parseTable[128]["function"] = 5
parseTable[128]["prefixexp"] = 10
parseTable[128]["var"] = 14
parseTable[128]["optional_stat_list"] = 75
parseTable[128]["block"] = 161
parseTable[128]["stat"] = 76
parseTable[128]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[128]["return"] = 12
parseTable[128]["varlist"] = 15
parseTable[128]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[128]["if"] = 22
parseTable[128]["break"] = 7
parseTable[128]["for"] = 18
parseTable[128]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[128]["Name"] = 23
parseTable[128]["local"] = 11
parseTable[128]["("] = 17
parseTable[128]["repeat"] = 24
parseTable[128]["stat_list"] = 73
parseTable[128]["functioncall"] = 3

parseTable[129] = {}
parseTable[129]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[129]["do"] = 26
parseTable[129]["while"] = 19
parseTable[129]["function"] = 5
parseTable[129]["("] = 17
parseTable[129]["var"] = 14
parseTable[129]["optional_stat_list"] = 75
parseTable[129]["block"] = 162
parseTable[129]["stat"] = 76
parseTable[129]["stat_list"] = 73
parseTable[129]["return"] = 12
parseTable[129]["varlist"] = 15
parseTable[129]["prefixexp"] = 10
parseTable[129]["if"] = 22
parseTable[129]["break"] = 7
parseTable[129]["for"] = 18
parseTable[129]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[129]["Name"] = 23
parseTable[129]["local"] = 11
parseTable[129]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[129]["repeat"] = 24
parseTable[129]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[129]["functioncall"] = 3

parseTable[130] = {}
parseTable[130]["else"] = Production{"optional_stat_list", Rightside{"stat_list", "stat_sep"}}
parseTable[130]["do"] = 26
parseTable[130]["while"] = 19
parseTable[130]["function"] = 5
parseTable[130]["prefixexp"] = 10
parseTable[130]["end"] = Production{"optional_stat_list", Rightside{"stat_list", "stat_sep"}}
parseTable[130]["stat"] = 163
parseTable[130]["return"] = 12
parseTable[130]["elseif"] = Production{"optional_stat_list", Rightside{"stat_list", "stat_sep"}}
parseTable[130]["varlist"] = 15
parseTable[130]["if"] = 22
parseTable[130]["break"] = 7
parseTable[130]["for"] = 18
parseTable[130]["until"] = Production{"optional_stat_list", Rightside{"stat_list", "stat_sep"}}
parseTable[130]["Name"] = 23
parseTable[130]["local"] = 11
parseTable[130]["var"] = 14
parseTable[130]["repeat"] = 24
parseTable[130]["("] = 17
parseTable[130]["functioncall"] = 3

parseTable[131] = {}
parseTable[131]["Number"] = 61
parseTable[131]["functiondef"] = 59
parseTable[131]["exp"] = 164
parseTable[131]["function"] = 58
parseTable[131]["prefixexp"] = 10
parseTable[131]["var"] = 52
parseTable[131]["-"] = 54
parseTable[131]["true"] = 50
parseTable[131]["not"] = 57
parseTable[131]["Literal"] = 48
parseTable[131]["false"] = 63
parseTable[131]["tableconstructor"] = 56
parseTable[131]["{"] = 39
parseTable[131]["unop"] = 55
parseTable[131]["nil"] = 60
parseTable[131]["("] = 53
parseTable[131]["Name"] = 23
parseTable[131]["functioncall"] = 49

parseTable[132] = {}
parseTable[132]["else"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["do"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["eof"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["while"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["function"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["("] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["end"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["transformer"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["syntax"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["return"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["elseif"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["if"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["break"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["for"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["until"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["Name"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["local"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["repeat"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132][";"] = Production{"stat", Rightside{"do", "block", "end"}}
parseTable[132]["import"] = Production{"stat", Rightside{"do", "block", "end"}}

parseTable[133] = {}
parseTable[133]["do"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["eof"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["while"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["function"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["("] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["transformer"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["syntax"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["return"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["if"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["import"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["for"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133][";"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["local"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["repeat"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["Name"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}
parseTable[133]["break"] = Production{"syntaxdef", Rightside{"syntax", "Name", ":", "Literal"}}

parseTable[134] = {}
parseTable[134]["Name"] = 165

parseTable[135] = {}
parseTable[135]["("] = Production{"funcname", Rightside{"Name", "dotname_list", "colone_name"}}

parseTable[136] = {}
parseTable[136]["Name"] = 166

parseTable[137] = {}
parseTable[137][")"] = Production{"parlist", Rightside{"parname_list"}}
parseTable[137][","] = 167

parseTable[138] = {}
parseTable[138][")"] = 168

parseTable[139] = {}
parseTable[139][")"] = Production{"parlist", Rightside{"..."}}

parseTable[140] = {}
parseTable[140][")"] = Production{"parname_list", Rightside{"Name"}}
parseTable[140][","] = Production{"parname_list", Rightside{"Name"}}

parseTable[141] = {}
parseTable[141][")"] = Production{"optional_parlist", Rightside{"parlist"}}

parseTable[142] = {}
parseTable[142]["do"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["=="] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["<="] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["while"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142][")"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["("] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["+"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["*"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["-"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142][","] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["/"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["."] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["Literal"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["import"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["{"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["then"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["}"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["repeat"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142][">"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["else"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["eof"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142][".."] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["function"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["or"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["end"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["local"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["transformer"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["Name"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["syntax"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142][":"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142][";"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["~="] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["elseif"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["break"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["if"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["and"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["for"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["until"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["["] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142][">="] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["]"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["return"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["<"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}
parseTable[142]["^"] = Production{"functioncall", Rightside{"prefixexp", ":", "Name", "args"}}

parseTable[143] = {}
parseTable[143]["Number"] = 61
parseTable[143]["functiondef"] = 59
parseTable[143]["exp"] = 87
parseTable[143]["function"] = 58
parseTable[143]["prefixexp"] = 10
parseTable[143]["var"] = 52
parseTable[143]["-"] = 54
parseTable[143]["true"] = 50
parseTable[143]["not"] = 57
parseTable[143]["Literal"] = 48
parseTable[143]["nil"] = 60
parseTable[143]["false"] = 63
parseTable[143]["Name"] = 90
parseTable[143]["unop"] = 55
parseTable[143]["field"] = 169
parseTable[143]["tableconstructor"] = 56
parseTable[143]["{"] = 39
parseTable[143]["keyname"] = 88
parseTable[143]["}"] = Production{"optional_fieldlist", Rightside{"fieldlist", "fieldsep"}}
parseTable[143]["["] = 91
parseTable[143]["("] = 53
parseTable[143]["functioncall"] = 49

parseTable[144] = {}
parseTable[144]["Number"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["not"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["Literal"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["false"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["["] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["function"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["nil"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["{"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["Name"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["}"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["("] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["-"] = Production{"fieldsep", Rightside{";"}}
parseTable[144]["true"] = Production{"fieldsep", Rightside{";"}}

parseTable[145] = {}
parseTable[145]["Number"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["not"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["Literal"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["false"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["["] = Production{"fieldsep", Rightside{","}}
parseTable[145]["function"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["nil"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["{"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["Name"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["}"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["("] = Production{"fieldsep", Rightside{","}}
parseTable[145]["-"] = Production{"fieldsep", Rightside{","}}
parseTable[145]["true"] = Production{"fieldsep", Rightside{","}}

parseTable[146] = {}
parseTable[146]["do"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["=="] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["<="] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["while"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146][")"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["("] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["+"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["*"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["-"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146][","] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["/"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["."] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["Literal"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["import"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146][";"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["then"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["}"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["<"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146][">"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["else"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["eof"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146][".."] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["function"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["end"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146][":"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["break"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["transformer"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["repeat"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["syntax"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["or"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["local"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["Name"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["elseif"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["~="] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["if"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["and"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["for"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["until"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["["] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146][">="] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["]"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["{"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["return"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}
parseTable[146]["^"] = Production{"tableconstructor", Rightside{"{", "optional_fieldlist", "}"}}

parseTable[147] = {}
parseTable[147]["Number"] = 61
parseTable[147]["functiondef"] = 59
parseTable[147]["exp"] = 170
parseTable[147]["function"] = 58
parseTable[147]["nil"] = 60
parseTable[147]["var"] = 52
parseTable[147]["-"] = 54
parseTable[147]["true"] = 50
parseTable[147]["not"] = 57
parseTable[147]["Literal"] = 48
parseTable[147]["false"] = 63
parseTable[147]["tableconstructor"] = 56
parseTable[147]["Name"] = 23
parseTable[147]["{"] = 39
parseTable[147]["unop"] = 55
parseTable[147]["("] = 53
parseTable[147]["prefixexp"] = 10
parseTable[147]["functioncall"] = 49

parseTable[148] = {}
parseTable[148][">="] = 109
parseTable[148]["=="] = 102
parseTable[148]["<="] = 105
parseTable[148][".."] = 103
parseTable[148]["+"] = 110
parseTable[148]["or"] = 115
parseTable[148]["binop"] = 106
parseTable[148]["/"] = 108
parseTable[148]["and"] = 104
parseTable[148]["-"] = 114
parseTable[148]["~="] = 116
parseTable[148]["*"] = 113
parseTable[148]["]"] = 171
parseTable[148]["<"] = 107
parseTable[148][">"] = 111
parseTable[148]["^"] = 112

parseTable[149] = {}
parseTable[149]["do"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["=="] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["<="] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["while"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149][")"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["("] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["+"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["*"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["-"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149][","] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["/"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["."] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["return"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["import"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["{"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["then"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["}"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["repeat"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149][">"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["else"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["eof"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149][".."] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["function"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["or"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149][";"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["Literal"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["transformer"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149][":"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["syntax"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149][">="] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["<"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["["] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["elseif"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["and"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["if"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["break"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["for"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["until"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["Name"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["end"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["]"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["local"] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["~="] = Production{"args", Rightside{"(", "explist", ")"}}
parseTable[149]["^"] = Production{"args", Rightside{"(", "explist", ")"}}

parseTable[150] = {}
parseTable[150][">="] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["=="] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["<="] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["while"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150][")"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["("] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["+"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["*"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["-"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150][","] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["/"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["."] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["return"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["import"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["{"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["then"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["="] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["repeat"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150][">"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["else"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["eof"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150][".."] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["function"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["}"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["end"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150][":"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["local"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["transformer"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["~="] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["syntax"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["or"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["Name"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["do"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["elseif"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["break"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["if"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["and"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["for"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["until"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["["] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150][";"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["]"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["Literal"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["<"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}
parseTable[150]["^"] = Production{"var", Rightside{"prefixexp", "[", "exp", "]"}}

parseTable[151] = {}
parseTable[151]["else"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["do"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["eof"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["while"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["function"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["("] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["end"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151][","] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["transformer"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["syntax"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["return"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["elseif"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["if"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["break"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["for"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["until"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["Name"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["local"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["="] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["repeat"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151][";"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}
parseTable[151]["import"] = Production{"localvar_list", Rightside{"localvar_list", ",", "Name"}}

parseTable[152] = {}
parseTable[152]["else"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["do"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["eof"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["while"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["function"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["("] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["end"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152][","] = 101
parseTable[152]["transformer"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["syntax"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["return"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["elseif"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["if"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["break"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["for"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["until"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["Name"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["local"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["repeat"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152][";"] = Production{"init", Rightside{"=", "explist"}}
parseTable[152]["import"] = Production{"init", Rightside{"=", "explist"}}

parseTable[153] = {}
parseTable[153]["else"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["do"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["eof"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["while"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["function"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["("] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["end"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["transformer"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["syntax"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["return"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["elseif"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["if"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["break"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["for"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["until"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["Name"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["local"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["repeat"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153][";"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}
parseTable[153]["import"] = Production{"stat", Rightside{"local", "function", "Name", "funcbody"}}

parseTable[154] = {}
parseTable[154]["do"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["=="] = 102
parseTable[154]["<="] = 105
parseTable[154]["while"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154][")"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["("] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["+"] = 110
parseTable[154]["*"] = 113
parseTable[154]["-"] = 114
parseTable[154][","] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["/"] = 108
parseTable[154]["return"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["import"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154][";"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["local"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["<"] = 107
parseTable[154][">"] = 111
parseTable[154]["else"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["eof"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154][".."] = 103
parseTable[154]["function"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["end"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["binop"] = 106
parseTable[154]["transformer"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["syntax"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["elseif"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["or"] = 115
parseTable[154]["if"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["and"] = 104
parseTable[154]["for"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["until"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["Name"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["repeat"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["~="] = 116
parseTable[154][">="] = 109
parseTable[154]["break"] = Production{"explist", Rightside{"explist", ",", "exp"}}
parseTable[154]["^"] = 112

parseTable[155] = {}

parseTable[155]["~="] = GetSelectorByBinopPrecedence(116)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 116}


parseTable[155]["=="] = GetSelectorByBinopPrecedence(102)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 102}


parseTable[155]["<="] = GetSelectorByBinopPrecedence(105)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 105}

parseTable[155]["while"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155][")"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["("] = Production{"exp", Rightside{"exp", "binop", "exp"}}

parseTable[155]["+"] = GetSelectorByBinopPrecedence(110)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 110}


parseTable[155]["*"] = GetSelectorByBinopPrecedence(113)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 113}


parseTable[155]["-"] = GetSelectorByBinopPrecedence(114)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 114}

parseTable[155][","] = Production{"exp", Rightside{"exp", "binop", "exp"}}

parseTable[155]["/"] = GetSelectorByBinopPrecedence(108)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 108}

parseTable[155]["return"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["import"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155][";"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["then"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["}"] = Production{"exp", Rightside{"exp", "binop", "exp"}}

parseTable[155]["<"] = GetSelectorByBinopPrecedence(107)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 107}


parseTable[155][">"] = GetSelectorByBinopPrecedence(111)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 111}

parseTable[155]["else"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["eof"] = Production{"exp", Rightside{"exp", "binop", "exp"}}

parseTable[155][".."] = GetSelectorByBinopPrecedence(103)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 103}

parseTable[155]["function"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["end"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["binop"] = 106
parseTable[155]["transformer"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["syntax"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["break"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["repeat"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["elseif"] = Production{"exp", Rightside{"exp", "binop", "exp"}}

parseTable[155][">="] = GetSelectorByBinopPrecedence(109)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 109}

parseTable[155]["if"] = Production{"exp", Rightside{"exp", "binop", "exp"}}

parseTable[155]["and"] = GetSelectorByBinopPrecedence(104)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 104}

parseTable[155]["for"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["until"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["Name"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["do"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["]"] = Production{"exp", Rightside{"exp", "binop", "exp"}}
parseTable[155]["local"] = Production{"exp", Rightside{"exp", "binop", "exp"}}

parseTable[155]["or"] = GetSelectorByBinopPrecedence(115)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 115}


parseTable[155]["^"] = GetSelectorByBinopPrecedence(112)
--Set{Production{"exp", Rightside{"exp", "binop", "exp"}}, 112}


parseTable[156] = {}
parseTable[156][">="] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["=="] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["<="] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["while"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156][")"] = Production{"exp", Rightside{"(", "exp", ")"}}

parseTable[156]["("] = GetSelectorByLineNum(Production{"prefixexp", Rightside{"(", "exp", ")"}})
--Set{Production{"exp", Rightside{"(", "exp", ")"}}, Production{"prefixexp", Rightside{"(", "exp", ")"}}}

parseTable[156]["+"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["*"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["-"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156][","] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["/"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["."] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[156]["return"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["import"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156][";"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["then"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["}"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["<"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156][">"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["else"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["eof"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156][".."] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["function"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["end"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["{"] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[156]["Literal"] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[156]["transformer"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156][":"] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[156]["syntax"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["["] = Production{"prefixexp", Rightside{"(", "exp", ")"}}
parseTable[156]["local"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["break"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["elseif"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["repeat"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["if"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["and"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["for"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["until"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["Name"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["or"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["]"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["~="] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["do"] = Production{"exp", Rightside{"(", "exp", ")"}}
parseTable[156]["^"] = Production{"exp", Rightside{"(", "exp", ")"}}

parseTable[157] = {}
parseTable[157]["do"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["eof"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["while"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["function"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["("] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["transformer"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["syntax"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["return"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["if"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["import"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["for"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157][";"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["local"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["repeat"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["Name"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}
parseTable[157]["break"] = Production{"transformerdef", Rightside{"transformer", "Name", "block", "end"}}

parseTable[158] = {}
parseTable[158][","] = 101
parseTable[158]["do"] = 172

parseTable[159] = {}
parseTable[159]["in"] = Production{"namelist", Rightside{"namelist", ",", "Name"}}
parseTable[159][","] = Production{"namelist", Rightside{"namelist", ",", "Name"}}

parseTable[160] = {}
parseTable[160]["~="] = 116
parseTable[160]["=="] = 102
parseTable[160]["<="] = 105
parseTable[160][".."] = 103
parseTable[160]["+"] = 110
parseTable[160]["*"] = 113
parseTable[160]["-"] = 114
parseTable[160][","] = 173
parseTable[160]["/"] = 108
parseTable[160]["and"] = 104
parseTable[160]["^"] = 112
parseTable[160]["or"] = 115
parseTable[160][">="] = 109
parseTable[160]["<"] = 107
parseTable[160]["binop"] = 106
parseTable[160][">"] = 111

parseTable[161] = {}
parseTable[161]["end"] = 174

parseTable[162] = {}
parseTable[162]["elseif_part"] = 176
parseTable[162]["else"] = Production{"optional_elseif_part", Rightside{"empty"}}
parseTable[162]["end"] = Production{"optional_elseif_part", Rightside{"empty"}}
parseTable[162]["elseif"] = 175
parseTable[162]["optional_elseif_part"] = 177

parseTable[163] = {}
parseTable[163]["else"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["do"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["while"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["function"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["("] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["end"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["return"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["elseif"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["if"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["break"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["for"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["until"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["Name"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["local"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163]["repeat"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}
parseTable[163][";"] = Production{"stat_list", Rightside{"stat_list", "stat_sep", "stat"}}

parseTable[164] = {}
parseTable[164]["~="] = 116
parseTable[164]["=="] = 102
parseTable[164]["<="] = 105
parseTable[164]["while"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["("] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["+"] = 110
parseTable[164]["*"] = 113
parseTable[164]["-"] = 114
parseTable[164]["/"] = 108
parseTable[164]["return"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["import"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164][";"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["local"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["<"] = 107
parseTable[164][">"] = 111
parseTable[164]["else"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["eof"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164][".."] = 103
parseTable[164]["function"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["end"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["binop"] = 106
parseTable[164]["transformer"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["syntax"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["elseif"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["or"] = 115
parseTable[164]["if"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["and"] = 104
parseTable[164]["for"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["until"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["Name"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["do"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164][">="] = 109
parseTable[164]["repeat"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["break"] = Production{"stat", Rightside{"repeat", "block", "until", "exp"}}
parseTable[164]["^"] = 112

parseTable[165] = {}
parseTable[165]["("] = Production{"dotname_list", Rightside{"dotname_list", ".", "Name"}}
parseTable[165][":"] = Production{"dotname_list", Rightside{"dotname_list", ".", "Name"}}
parseTable[165]["."] = Production{"dotname_list", Rightside{"dotname_list", ".", "Name"}}

parseTable[166] = {}
parseTable[166]["("] = Production{"colone_name", Rightside{":", "Name"}}

parseTable[167] = {}
parseTable[167]["..."] = 179
parseTable[167]["Name"] = 178

parseTable[168] = {}
parseTable[168]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[168]["do"] = 26
parseTable[168]["while"] = 19
parseTable[168]["function"] = 5
parseTable[168]["prefixexp"] = 10
parseTable[168]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[168]["optional_stat_list"] = 75
parseTable[168]["block"] = 180
parseTable[168]["stat"] = 76
parseTable[168]["var"] = 14
parseTable[168]["return"] = 12
parseTable[168]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[168]["varlist"] = 15
parseTable[168]["if"] = 22
parseTable[168]["break"] = 7
parseTable[168]["for"] = 18
parseTable[168]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[168]["stat_list"] = 73
parseTable[168]["local"] = 11
parseTable[168]["Name"] = 23
parseTable[168]["repeat"] = 24
parseTable[168]["("] = 17
parseTable[168]["functioncall"] = 3

parseTable[169] = {}
parseTable[169]["}"] = Production{"fieldlist", Rightside{"fieldlist", "fieldsep", "field"}}
parseTable[169][","] = Production{"fieldlist", Rightside{"fieldlist", "fieldsep", "field"}}
parseTable[169][";"] = Production{"fieldlist", Rightside{"fieldlist", "fieldsep", "field"}}

parseTable[170] = {}
parseTable[170]["~="] = 116
parseTable[170]["=="] = 102
parseTable[170]["<="] = 105
parseTable[170][".."] = 103
parseTable[170]["+"] = 110
parseTable[170]["or"] = 115
parseTable[170]["-"] = 114
parseTable[170][","] = Production{"field", Rightside{"keyname", "=", "exp"}}
parseTable[170]["/"] = 108
parseTable[170]["and"] = 104
parseTable[170][">"] = 111
parseTable[170][">="] = 109
parseTable[170][";"] = Production{"field", Rightside{"keyname", "=", "exp"}}
parseTable[170]["binop"] = 106
parseTable[170]["}"] = Production{"field", Rightside{"keyname", "=", "exp"}}
parseTable[170]["<"] = 107
parseTable[170]["*"] = 113
parseTable[170]["^"] = 112

parseTable[171] = {}
parseTable[171]["="] = 181

parseTable[172] = {}
parseTable[172]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[172]["do"] = 26
parseTable[172]["while"] = 19
parseTable[172]["function"] = 5
parseTable[172]["prefixexp"] = 10
parseTable[172]["var"] = 14
parseTable[172]["optional_stat_list"] = 75
parseTable[172]["block"] = 182
parseTable[172]["stat"] = 76
parseTable[172]["("] = 17
parseTable[172]["return"] = 12
parseTable[172]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[172]["stat_list"] = 73
parseTable[172]["if"] = 22
parseTable[172]["break"] = 7
parseTable[172]["for"] = 18
parseTable[172]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[172]["Name"] = 23
parseTable[172]["local"] = 11
parseTable[172]["varlist"] = 15
parseTable[172]["repeat"] = 24
parseTable[172]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[172]["functioncall"] = 3

parseTable[173] = {}
parseTable[173]["Number"] = 61
parseTable[173]["functiondef"] = 59
parseTable[173]["unop"] = 55
parseTable[173]["function"] = 58
parseTable[173]["("] = 53
parseTable[173]["var"] = 52
parseTable[173]["-"] = 54
parseTable[173]["true"] = 50
parseTable[173]["not"] = 57
parseTable[173]["Literal"] = 48
parseTable[173]["false"] = 63
parseTable[173]["tableconstructor"] = 56
parseTable[173]["Name"] = 23
parseTable[173]["nil"] = 60
parseTable[173]["{"] = 39
parseTable[173]["exp"] = 183
parseTable[173]["prefixexp"] = 10
parseTable[173]["functioncall"] = 49

parseTable[174] = {}
parseTable[174]["else"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["do"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["eof"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["while"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["function"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["("] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["end"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["transformer"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["syntax"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["return"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["elseif"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["if"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["break"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["for"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["until"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["Name"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["local"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["repeat"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174][";"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}
parseTable[174]["import"] = Production{"stat", Rightside{"while", "exp", "do", "block", "end"}}

parseTable[175] = {}
parseTable[175]["Number"] = 61
parseTable[175]["functiondef"] = 59
parseTable[175]["unop"] = 55
parseTable[175]["function"] = 58
parseTable[175]["nil"] = 60
parseTable[175]["var"] = 52
parseTable[175]["-"] = 54
parseTable[175]["true"] = 50
parseTable[175]["not"] = 57
parseTable[175]["Literal"] = 48
parseTable[175]["false"] = 63
parseTable[175]["tableconstructor"] = 56
parseTable[175]["{"] = 39
parseTable[175]["Name"] = 23
parseTable[175]["("] = 53
parseTable[175]["exp"] = 184
parseTable[175]["prefixexp"] = 10
parseTable[175]["functioncall"] = 49

parseTable[176] = {}
parseTable[176]["elseif"] = 185
parseTable[176]["else"] = Production{"optional_elseif_part", Rightside{"elseif_part"}}
parseTable[176]["end"] = Production{"optional_elseif_part", Rightside{"elseif_part"}}

parseTable[177] = {}
parseTable[177]["optional_else_part"] = 186
parseTable[177]["else"] = 187
parseTable[177]["end"] = Production{"optional_else_part", Rightside{"empty"}}

parseTable[178] = {}
parseTable[178][")"] = Production{"parname_list", Rightside{"parname_list", ",", "Name"}}
parseTable[178][","] = Production{"parname_list", Rightside{"parname_list", ",", "Name"}}

parseTable[179] = {}
parseTable[179][")"] = Production{"parlist", Rightside{"parname_list", ",", "..."}}

parseTable[180] = {}
parseTable[180]["end"] = 188

parseTable[181] = {}
parseTable[181]["Number"] = 61
parseTable[181]["functiondef"] = 59
parseTable[181]["unop"] = 55
parseTable[181]["function"] = 58
parseTable[181]["prefixexp"] = 10
parseTable[181]["var"] = 52
parseTable[181]["-"] = 54
parseTable[181]["true"] = 50
parseTable[181]["not"] = 57
parseTable[181]["Literal"] = 48
parseTable[181]["false"] = 63
parseTable[181]["tableconstructor"] = 56
parseTable[181]["{"] = 39
parseTable[181]["Name"] = 23
parseTable[181]["exp"] = 189
parseTable[181]["nil"] = 60
parseTable[181]["("] = 53
parseTable[181]["functioncall"] = 49

parseTable[182] = {}
parseTable[182]["end"] = 190

parseTable[183] = {}
parseTable[183]["~="] = 116
parseTable[183]["=="] = 102
parseTable[183]["<="] = 105
parseTable[183][".."] = 103
parseTable[183]["+"] = 110
parseTable[183]["or"] = 115
parseTable[183]["-"] = 114
parseTable[183][","] = 192
parseTable[183]["/"] = 108
parseTable[183]["and"] = 104
parseTable[183]["^"] = 112
parseTable[183]["*"] = 113
parseTable[183][">="] = 109
parseTable[183]["binop"] = 106
parseTable[183]["<"] = 107
parseTable[183]["do"] = 191
parseTable[183][">"] = 111

parseTable[184] = {}
parseTable[184]["~="] = 116
parseTable[184]["=="] = 102
parseTable[184]["<="] = 105
parseTable[184][".."] = 103
parseTable[184]["+"] = 110
parseTable[184]["or"] = 115
parseTable[184]["-"] = 114
parseTable[184]["/"] = 108
parseTable[184]["and"] = 104
parseTable[184][">="] = 109
parseTable[184][">"] = 111
parseTable[184]["then"] = 193
parseTable[184]["*"] = 113
parseTable[184]["<"] = 107
parseTable[184]["binop"] = 106
parseTable[184]["^"] = 112

parseTable[185] = {}
parseTable[185]["Number"] = 61
parseTable[185]["functiondef"] = 59
parseTable[185]["unop"] = 55
parseTable[185]["function"] = 58
parseTable[185]["nil"] = 60
parseTable[185]["var"] = 52
parseTable[185]["-"] = 54
parseTable[185]["true"] = 50
parseTable[185]["not"] = 57
parseTable[185]["Literal"] = 48
parseTable[185]["false"] = 63
parseTable[185]["tableconstructor"] = 56
parseTable[185]["{"] = 39
parseTable[185]["exp"] = 194
parseTable[185]["Name"] = 23
parseTable[185]["prefixexp"] = 10
parseTable[185]["("] = 53
parseTable[185]["functioncall"] = 49

parseTable[186] = {}
parseTable[186]["end"] = 195

parseTable[187] = {}
parseTable[187]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[187]["do"] = 26
parseTable[187]["while"] = 19
parseTable[187]["function"] = 5
parseTable[187]["prefixexp"] = 10
parseTable[187]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[187]["optional_stat_list"] = 75
parseTable[187]["block"] = 196
parseTable[187]["stat"] = 76
parseTable[187]["var"] = 14
parseTable[187]["return"] = 12
parseTable[187]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[187]["Name"] = 23
parseTable[187]["if"] = 22
parseTable[187]["break"] = 7
parseTable[187]["for"] = 18
parseTable[187]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[187]["stat_list"] = 73
parseTable[187]["local"] = 11
parseTable[187]["varlist"] = 15
parseTable[187]["repeat"] = 24
parseTable[187]["("] = 17
parseTable[187]["functioncall"] = 3

parseTable[188] = {}
parseTable[188]["do"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["=="] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["<="] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["while"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188][")"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["("] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["+"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["*"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["-"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188][","] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["/"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["return"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["import"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188][";"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["then"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["}"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["repeat"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188][">"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["else"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["eof"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188][".."] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["function"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["end"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["transformer"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["syntax"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["local"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["<"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["elseif"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["and"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["if"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["break"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["for"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["until"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["Name"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["~="] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["]"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["or"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188][">="] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}
parseTable[188]["^"] = Production{"funcbody", Rightside{"(", "optional_parlist", ")", "block", "end"}}

parseTable[189] = {}
parseTable[189][">="] = 109
parseTable[189]["=="] = 102
parseTable[189]["<="] = 105
parseTable[189][".."] = 103
parseTable[189]["+"] = 110
parseTable[189]["or"] = 115
parseTable[189]["binop"] = 106
parseTable[189][","] = Production{"field", Rightside{"[", "exp", "]", "=", "exp"}}
parseTable[189]["/"] = 108
parseTable[189]["and"] = 104
parseTable[189]["-"] = 114
parseTable[189]["*"] = 113
parseTable[189][";"] = Production{"field", Rightside{"[", "exp", "]", "=", "exp"}}
parseTable[189]["~="] = 116
parseTable[189]["}"] = Production{"field", Rightside{"[", "exp", "]", "=", "exp"}}
parseTable[189]["<"] = 107
parseTable[189][">"] = 111
parseTable[189]["^"] = 112

parseTable[190] = {}
parseTable[190]["else"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["do"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["eof"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["while"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["function"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["("] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["end"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["transformer"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["syntax"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["return"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["elseif"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["if"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["break"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["for"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["until"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["Name"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["local"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["repeat"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190][";"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}
parseTable[190]["import"] = Production{"stat", Rightside{"for", "namelist", "in", "explist", "do", "block", "end"}}

parseTable[191] = {}
parseTable[191]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[191]["do"] = 26
parseTable[191]["while"] = 19
parseTable[191]["function"] = 5
parseTable[191]["("] = 17
parseTable[191]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[191]["optional_stat_list"] = 75
parseTable[191]["block"] = 197
parseTable[191]["stat"] = 76
parseTable[191]["Name"] = 23
parseTable[191]["return"] = 12
parseTable[191]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[191]["var"] = 14
parseTable[191]["if"] = 22
parseTable[191]["break"] = 7
parseTable[191]["for"] = 18
parseTable[191]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[191]["stat_list"] = 73
parseTable[191]["local"] = 11
parseTable[191]["varlist"] = 15
parseTable[191]["repeat"] = 24
parseTable[191]["prefixexp"] = 10
parseTable[191]["functioncall"] = 3

parseTable[192] = {}
parseTable[192]["Number"] = 61
parseTable[192]["functiondef"] = 59
parseTable[192]["exp"] = 198
parseTable[192]["function"] = 58
parseTable[192]["("] = 53
parseTable[192]["var"] = 52
parseTable[192]["-"] = 54
parseTable[192]["true"] = 50
parseTable[192]["not"] = 57
parseTable[192]["Literal"] = 48
parseTable[192]["false"] = 63
parseTable[192]["tableconstructor"] = 56
parseTable[192]["{"] = 39
parseTable[192]["nil"] = 60
parseTable[192]["Name"] = 23
parseTable[192]["unop"] = 55
parseTable[192]["prefixexp"] = 10
parseTable[192]["functioncall"] = 49

parseTable[193] = {}
parseTable[193]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[193]["do"] = 26
parseTable[193]["while"] = 19
parseTable[193]["function"] = 5
parseTable[193]["("] = 17
parseTable[193]["var"] = 14
parseTable[193]["optional_stat_list"] = 75
parseTable[193]["block"] = 199
parseTable[193]["stat"] = 76
parseTable[193]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[193]["return"] = 12
parseTable[193]["varlist"] = 15
parseTable[193]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[193]["if"] = 22
parseTable[193]["break"] = 7
parseTable[193]["for"] = 18
parseTable[193]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[193]["stat_list"] = 73
parseTable[193]["local"] = 11
parseTable[193]["Name"] = 23
parseTable[193]["repeat"] = 24
parseTable[193]["prefixexp"] = 10
parseTable[193]["functioncall"] = 3

parseTable[194] = {}
parseTable[194][">="] = 109
parseTable[194]["=="] = 102
parseTable[194]["<="] = 105
parseTable[194][".."] = 103
parseTable[194]["+"] = 110
parseTable[194]["*"] = 113
parseTable[194]["binop"] = 106
parseTable[194]["/"] = 108
parseTable[194]["and"] = 104
parseTable[194]["or"] = 115
parseTable[194]["~="] = 116
parseTable[194]["then"] = 200
parseTable[194]["-"] = 114
parseTable[194]["<"] = 107
parseTable[194][">"] = 111
parseTable[194]["^"] = 112

parseTable[195] = {}
parseTable[195]["else"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["do"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["eof"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["while"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["function"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["("] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["end"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["transformer"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["syntax"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["return"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["elseif"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["if"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["break"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["for"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["until"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["Name"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["local"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["repeat"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195][";"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}
parseTable[195]["import"] = Production{"stat", Rightside{"if", "exp", "then", "block", "optional_elseif_part", "optional_else_part", "end"}}

parseTable[196] = {}
parseTable[196]["end"] = Production{"optional_else_part", Rightside{"else", "block"}}

parseTable[197] = {}
parseTable[197]["end"] = 201

parseTable[198] = {}
parseTable[198]["~="] = 116
parseTable[198]["=="] = 102
parseTable[198]["<="] = 105
parseTable[198][".."] = 103
parseTable[198]["+"] = 110
parseTable[198]["*"] = 113
parseTable[198]["binop"] = 106
parseTable[198]["/"] = 108
parseTable[198]["and"] = 104
parseTable[198][">"] = 111
parseTable[198][">="] = 109
parseTable[198]["do"] = 202
parseTable[198]["-"] = 114
parseTable[198]["<"] = 107
parseTable[198]["or"] = 115
parseTable[198]["^"] = 112

parseTable[199] = {}
parseTable[199]["elseif"] = Production{"elseif_part", Rightside{"elseif", "exp", "then", "block"}}
parseTable[199]["else"] = Production{"elseif_part", Rightside{"elseif", "exp", "then", "block"}}
parseTable[199]["end"] = Production{"elseif_part", Rightside{"elseif", "exp", "then", "block"}}

parseTable[200] = {}
parseTable[200]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[200]["do"] = 26
parseTable[200]["while"] = 19
parseTable[200]["function"] = 5
parseTable[200]["prefixexp"] = 10
parseTable[200]["var"] = 14
parseTable[200]["optional_stat_list"] = 75
parseTable[200]["block"] = 203
parseTable[200]["stat"] = 76
parseTable[200]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[200]["return"] = 12
parseTable[200]["varlist"] = 15
parseTable[200]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[200]["if"] = 22
parseTable[200]["break"] = 7
parseTable[200]["for"] = 18
parseTable[200]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[200]["stat_list"] = 73
parseTable[200]["local"] = 11
parseTable[200]["("] = 17
parseTable[200]["repeat"] = 24
parseTable[200]["Name"] = 23
parseTable[200]["functioncall"] = 3

parseTable[201] = {}
parseTable[201]["else"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["do"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["eof"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["while"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["function"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["("] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["end"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["transformer"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["syntax"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["return"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["elseif"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["if"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["break"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["for"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["until"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["Name"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["local"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["repeat"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201][";"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}
parseTable[201]["import"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", "do", "block", "end"}}

parseTable[202] = {}
parseTable[202]["else"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[202]["do"] = 26
parseTable[202]["while"] = 19
parseTable[202]["function"] = 5
parseTable[202]["("] = 17
parseTable[202]["var"] = 14
parseTable[202]["optional_stat_list"] = 75
parseTable[202]["block"] = 204
parseTable[202]["stat"] = 76
parseTable[202]["varlist"] = 15
parseTable[202]["return"] = 12
parseTable[202]["elseif"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[202]["stat_list"] = 73
parseTable[202]["if"] = 22
parseTable[202]["break"] = 7
parseTable[202]["for"] = 18
parseTable[202]["until"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[202]["Name"] = 23
parseTable[202]["local"] = 11
parseTable[202]["prefixexp"] = 10
parseTable[202]["repeat"] = 24
parseTable[202]["end"] = Production{"optional_stat_list", Rightside{"empty"}}
parseTable[202]["functioncall"] = 3

parseTable[203] = {}
parseTable[203]["elseif"] = Production{"elseif_part", Rightside{"elseif_part", "elseif", "exp", "then", "block"}}
parseTable[203]["else"] = Production{"elseif_part", Rightside{"elseif_part", "elseif", "exp", "then", "block"}}
parseTable[203]["end"] = Production{"elseif_part", Rightside{"elseif_part", "elseif", "exp", "then", "block"}}

parseTable[204] = {}
parseTable[204]["end"] = 205

parseTable[205] = {}
parseTable[205]["else"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["do"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["eof"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["while"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["function"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["("] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["end"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["transformer"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["syntax"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["return"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["elseif"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["if"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["break"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["for"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["until"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["Name"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["local"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["repeat"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205][";"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}
parseTable[205]["import"] = Production{"stat", Rightside{"for", "Name", "=", "exp", ",", "exp", ",", "exp", "do", "block", "end"}}

