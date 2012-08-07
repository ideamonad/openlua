require("common.lua")
require("set.lua")
require("stack.lua")
require("analyse.lua")
require("slr.lua")

local binops = 
    Set{
    '+' , '-' , '*' , '/' , '^' , '..',
    '<' , '<=' , '>' , '>=' , '==' , '~=',
    'and', 'or'
}


local checkpoints = {}

checkpoints["="] = 
    function (str, begin)
        local endpos
        _, endpos = string.find(str,"^==",begin)
        if nil~= endpos then
            return endpos, "=="
        else
            return begin, "="
        end
    end

checkpoints["<"] = 
    function (str, begin)
        local endpos
        _, endpos = string.find(str,"^<=",begin)
        if nil~= endpos then
            return endpos, "<="
        else
            return begin, "<"
        end
    end

checkpoints[">"] = 
    function (str, begin)
        local endpos
        _, endpos = string.find(str,"^>=",begin)
        if nil~= endpos then
            return endpos, ">="
        else
            return begin, ">"
        end
    end

checkpoints["."] = 
    function (str, begin)
        local endpos
        _, endpos = string.find(str,"^%.%.%.",begin)
        if nil ~= endpos then
            return endpos, "..."
        else
            _, endpos = string.find(str,"^%.%.",begin)
            if nil ~= endpos then
                return endpos, ".."
            else
                return begin, "."
            end
        end
    end

checkpoints["~"] = 
    function (str, begin)
        local endpos
        _, endpos = string.find(str,"^~=",begin)
        if nil~= endpos then
            return endpos, "~="
        else
            return
        end
    end

local function IsLeadingId(str,begin)
    if string.find(str,"^[_%a]",begin) then
        return true
    else
        return false
    end
end

local function ScanId(str,begin)
    local endpos,term
    _, endpos, term= string.find(str,"^([_%a][_%w]*)",begin)
    return endpos,term
end

local function IsLeadingNumber(str,begin)
    if string.find(str,"^%d",begin) then
        return true
    else
        return false
    end
end

local function ScanNumber(str, begin)
    local endpos, term

    -- 带指数的number，如 1.2e8、3.0e+4、2.5e-6
    _, endpos, term = string.find(str, "^(%d+%.%d+e[%-%+]?%d+)", begin)
    if nil ~= endpos then
        return endpos, term
    end

    _, endpos, term = string.find(str, "^(%d+%.%d+)", begin)
    if nil ~= endpos then
        return endpos, term
    end

    -- 带指数的number，如 2e8、3e+4、7e-6
    _, endpos, term = string.find(str, "^(%d+e[%-%+]?%d+)", begin)
    if nil ~= endpos then
        return endpos, term
    end

    _, endpos, term = string.find(str, "^(%d+)", begin)
    if nil ~= endpos then
        return endpos, term
    end

    return
end

local function IsLeadingLiteral(str,begin)
    if string.find(str,"^['\"]",begin) then
        return true
    else
        return false
    end
end

local EscapeChars =
    {
    a = "\a",
    b = "\b",
    f = "\f",
    n = "\n",
    r = "\r",
    t = "\t",
    v = "\v",
    ["\\"] =  "\\",
    ['"'] = '"',
    ["'"] = "'",
    ["["] = "[",
    ["]"] = "]"
}

-- 以直接给出字符ASCII值的形式书写字符串还未实现
local function ScanLiteral(line, begin, opensymbol)
    local pos = begin
    local char = string.sub(line,pos,pos)
    local part = ""
    while "" ~= char do
        if opensymbol == char then
            return pos, part, true
        end

        if "\\" == char then
            --开始转义字符
            pos = pos + 1
            char = string.sub(line,pos,pos)
            if "" ~= char then
                char = EscapeChars[char] or char
            else
                -- 一行末尾的'\'标志着字符串是多行的
                return pos, part, false
            end
        end
        
        part = part..char
        pos = pos + 1
        char = string.sub(line,pos,pos)
    end

    return
end

local function IsLeadingRawLiteral(str,begin)
    if string.find(str,"^%[%[",begin) then
        return true
    else
        return false
    end
end

-- 返回的第三个参数表示在line中字符串是否结束
local function ScanRawLiteral(line,begin)
    local endpos, part
    _, endpos, part = string.find(line,"^(.*)%]%]",begin)

    if endpos then
        -- 在当前行中找到了闭合的"]]"
        return endpos, part, true
    else
        return string.len(line), string.sub(line,begin), false
    end
end

local function IsLeadingMultiLineComment(str,begin)
    if string.find(str,"^%-%-%[%[",begin) then
        return true
    else
        return false
    end
end

local function ScanMultiLineComment(line,begin)
    local endpos
    _, endpos = string.find(line,"%-%-%]%]",begin)
    if endpos then
        return endpos, true
    else
        return string.len(line), false
    end
end

local function IsLeadingSingleLineComment(str,begin)
    if string.find(str,"^%-%-",begin) then
        return true
    else
        return false
    end
end

-- input is a IStream object
local function DoScan(input,terminals)
    local pos
    local start_char
    local terminal
    local linenum = 0
    local bComment

    for line in input:lines() do
        linenum = linenum + 1
        pos = 1
        terminal = nil
        pos, _, start_char = string.find(line,"(%S)",pos)
        while pos do
            bComment = false
            if IsLeadingId(line,pos) then
                -- 一个identifier
                pos, terminal = ScanId(line,pos)

                if terminals:Contains(terminal) then
                    terminal = Symbol{"keymark",terminal,linenum,linenum}
                else
                    terminal = Symbol{"Name",terminal,linenum,linenum}
                end

            elseif IsLeadingNumber(line,pos) then
                -- 一个Number
                pos, terminal = ScanNumber(line,pos)
                if nil == terminal then
                    return false, "invalid number"
                end

                terminal = Symbol{"Number",tonumber(terminal),linenum,linenum}

            elseif IsLeadingLiteral(line,pos) then
                --
                local finished, part
                local open_linenum = linenum
                local opensymbol = string.sub(line,pos,pos)
                terminal = ""
                pos = pos + 1
                repeat
                    pos, part, finished = 
                        ScanLiteral(line, pos, opensymbol)
                    if nil == part then
                        return false, "unfinished literal string"
                    end
                    
                    if finished then
                        terminal = terminal..part
                        break
                    end
                    terminal = terminal..part.."\n"
                    line = input:read()
                    linenum = linenum + 1
                    pos = 1
                until nil == line
                
                if nil == line then
                    return false, "unfinished literal string"
                end

                terminal = Symbol{"Literal", terminal, open_linenum,linenum}

            elseif IsLeadingRawLiteral(line,pos) then
                --
                local finished, part
                local open_linenum = linenum
                terminal = ""
                pos = pos + 2
                repeat
                    -- 返回值不会为nil
                    pos, part, finished = ScanRawLiteral(line,pos)
                    if finished then
                        terminal = terminal..part
                        break
                    end
                    terminal = terminal..part.."\n"
                    line = input:read()
                    linenum = linenum + 1
                    pos = 1
                until nil == line
                
                if nil == line then
                    return false, "unfinished literal string"
                end
                
                terminal = Symbol{"Literal",terminal,open_linenum,linenum}

            elseif IsLeadingMultiLineComment(line,pos) then
                -- 多行的comment，一定要在单行comment之前判断
                local finished
                bComment = true
                pos = pos + 4
                repeat
                    pos, finished = ScanMultiLineComment(line,pos)
                    if finished then
                        break
                    end
                    line = input:read()
                    linenum = linenum + 1
                    pos = 1
                until nil == line
                
                if nil == line then
                    return false, "unfinished long comment "..linenum
                end

            elseif IsLeadingSingleLineComment(line,pos) then
                -- 单行的comment，跳过当前行
                break
            else
                local check = checkpoints[start_char]
                if check then
                    pos, terminal = check(line,pos)
                elseif terminals:Contains(start_char) then
                    terminal = start_char
                else
                    return false,"Invalid character at line "..linenum
                end
                terminal = Symbol{"keymark",terminal,linenum,linenum}
            end  -- if IsLeadingId(line,pos) then
            
            if false == bComment then
                _,terminals = coroutine.yield(true,terminal)
            end
            pos = pos + 1
            pos, _, start_char = string.find(line,"(%S)",pos)
        end  -- while pos do
        
    end  -- for line in input:lines() do

    -- 传回输入流结束标识
    return true,Symbol{"keymark","eof",linenum,linenum}
end


--[[---------------------------------------------------
Lexer prototype definition
--]]---------------------------------------------------

Lexer = {}
Lexer.__index = Lexer

local _input = {}
local _scanner = {}
local _unget = {}

function Lexer.New(input)
    local o = {
        [_input] = input, 
        [_scanner] = coroutine.create(DoScan),
        [_unget] = Stack{} }
    setmetatable(o,Lexer)

    return o
end

function Lexer:Done()
    return self[_unget]:Empty() and 
        "dead" == coroutine.status(self[_scanner])
end

function Lexer:extract(terminals)
    if not self[_unget]:Empty() then
        local s = self[_unget]:Pop()
        if "Name" == s:name() and 
            terminals:Contains(s:value()) then
            return Symbol{"keymark",s:value(),s.open_line,s.close_line}
        elseif "keymark" == s:type() and 
            "eof" ~= s:value() and
            not terminals:Contains(s:value()) then
            -- 在lexer输入流中不会有empty符号
            return Symbol{"Name",s:value(),s.open_line,s.close_line}
        else
            return s
        end
    end

    if "dead" == coroutine.status(self[_scanner]) then
        return nil
    end

    local co_correct, scan_correct, symbol
    
    co_correct, lex_correct, symbol = 
        coroutine.resume(self[_scanner],self[_input],terminals)
    
    if false == co_correct then
        -- 协程调用出错
        return nil,"error occurs while lexer running: "
    elseif false == lex_correct then
        -- 词法错误
        return nil," lexical error: "..symbol
    else
        return symbol
    end
end

-- unget的符号在输入流中的顺序与unget操作的顺序相反
-- 即每次unget的符号是在输入流的头部
function Lexer:unget(symbol)
    if nil == symbol then
        return
    end
    
    local stype = symbol:type()
    if "keymark" == stype then
        if "empty" == symbol:value() then
            -- empty符号直接抛弃，不应该出现在lexer输入流中
            return
        end
        self[_unget]:Push(symbol)
        
    elseif "Number" == stype or
        "Literal" == stype or "Name" == stype then
        self[_unget]:Push(symbol)
    else
        for _,e in symbol.children:RTraverse() do
            -- 按从后到前的顺序unget
            self:unget(e)
        end
    end
end

function Lexer:peek(terminals)
    if not self[_unget]:Empty() then
        local s = self[_unget]:Top()
        if "Name" == s:name() and 
            terminals:Contains(s:value()) then
            self[_unget]:Pop()
            self[_unget]:Push(
                              Symbol{"keymark",s:value(),s.open_line,s.close_line})
        elseif "keymark" == s:type() and 
            "eof" ~= s:value() and
            not terminals:Contains(s:value())
            and nil ~= ScanId(s:emit(),1) then
            self[_unget]:Pop()
            self[_unget]:Push(
                              Symbol{"Name",s:value(),s.open_line,s.close_line})
        end

        return self[_unget]:Top()
    end

    if "dead" == coroutine.status(self[_scanner]) then
        return nil
    end

    local co_correct, scan_correct, symbol
    
    co_correct, lex_correct, symbol = 
        coroutine.resume(self[_scanner],self[_input],terminals)
    
    if false == co_correct then
        -- 协程调用出错
        return nil,"error occurs while lexer running: "
    elseif false == lex_correct then
        -- 词法错误
        return nil," lexical error: "..symbol
    else
        self[_unget]:Push(symbol)
        return self[_unget]:Top()
    end
end

local _input = nil
local _scanner = nil
local _unget = nil

--[[---------------------------------------------------
Lexer prototype definition end
--]]---------------------------------------------------


--[[---------------------------------------------------
Openlexer prototype definition
--]]---------------------------------------------------
Openlexer = {}
Openlexer.__index = Openlexer

local _lexers = {}
local _terminals = {}

function Openlexer.new(terminals)
    local o = { [_lexers] = Stack{},[_terminals] = terminals }
    
    setmetatable(o,Openlexer)

    return o
end

function Openlexer:push(lexer)
    return self[_lexers]:Push(lexer)
end

function Openlexer:pop()
    return self[_lexers]:Pop()
end

function Openlexer:top()
    return self[_lexers]:top()
end

function Openlexer:get_terminals()
    return self[_terminals]
end

function Openlexer:set_terminals(terminals)
    assert(nil ~= terminals)
    self[_terminals] = terminals
end

function Openlexer:extract()
    local lexers = self[_lexers]
    
    while not lexers:Empty() do
        local symbol,errormsg = lexers:Top():extract(self[_terminals])
        if nil ~= errormsg then
            return symbol,errormsg
        end

        if nil == symbol then
            lexers:Pop()
        elseif "eof" == symbol:name()
            and 1 < lexers:Count() then
            -- 输入流还未真正结束
            lexers:Pop()
        else
            return symbol
        end
    end
    
    return nil
end

function Openlexer:unget(symbol)
    if not self[_lexers]:Empty() then
        return self[_lexers]:Top():unget(symbol)
    end
end

function Openlexer:peek()
    local lexers = self[_lexers]
    
    while not lexers:Empty() do
        local symbol,errormsg = lexers:Top():peek(self[_terminals])
        if nil ~= errormsg then
            return symbol,errormsg
        end

        if nil == symbol then
            lexers:Pop()
        elseif "eof" == symbol:name()
            and 1 < lexers:Count() then
            -- 输入流还未真正结束
            lexers:Pop()
        else
            return symbol
        end
    end
    
    return nil   
end

local _lexers = nil
local _terminals = nil

--[[---------------------------------------------------
Openlexer prototype definition end
--]]---------------------------------------------------


local function GetNextAction(slr,stateStack,symbolStack,symbol)
    local state = stateStack:Top()
    local row = slr[state]
    
    if nil == row then
        return nil
    end

    local action
    
    if not IsType(symbol,Symbol) then
        -- should never be here
        assert(false,"not a valid symbol !")
    else
        action = row[symbol:name()]
    end

    if nil == action then
        return nil
    elseif "number" == type(action) then
        -- 新的状态
        return action
    elseif IsType(action,Production) then
        -- 产生式
        return action
    elseif "function" == type(action) then
        -- 有冲突的项，需要根据当前栈来判断下一步动作
        if binops:Contains(symbol:name()) then
            local last_binop = symbolStack:Get(2)
            if nil == last_binop then
                return nil
            end
            assert("binop" == last_binop:name())
            action = action(last_binop:value(),symbol:value())
        else
            -- 其它冲突的项，有4个与prefixexp规约有关，
            -- 要通过当前符号的行号与栈顶符号的行号比较来解决
            action = 
                action(symbolStack:Top().close_line,symbol.open_line)
        end
        return action
    else
        -- should never be here
        assert(false,"unknown action type")
    end
end

-- 规约成功返回true, 否则返回false
local function Reduce(slr,stateStack,symbolStack,prod)
    local symbol
    local rs = prod:GetRightside()
    local openLine,closeLine
    local ls = prod:GetLeftside()
    local leftSymbol
    local stackPos
    
    if "binop" == ls then
        leftSymbol = Symbol{ls, rs:Get(1)}
    else
        leftSymbol = Symbol{ls, ls}
    end
    leftSymbol.children = List{}

    -- 弹出栈顶元素
    -- 对产生式的右部做逆序遍历
    stackPos = 0
    for _, e in rs:RTraverse() do
        if "empty" == e then
            if not symbolStack:Empty() then
                openLine = symbolStack:Top().close_line
                closeLine = symbolStack:Top().close_line
            else
                closeLine,openLine = 1,1
            end
            leftSymbol.children:Append(
                                       Symbol{"keymark","empty",openLine,closeLine})
            break
        end

        stackPos = stackPos + 1
        symbol = symbolStack:Get(stackPos)
        if nil == symbol then
            -- 符号栈已经没有那么多符号了
            return false
        end

        openLine = symbol.open_line
        if nil == closeLine then
            -- 确定leftSymbol的结束行，注意最先弹出的符号是最末尾的符号
            closeLine = symbol.close_line
        end

        assert(symbol:name() == e)
        leftSymbol.children:InsertHead(symbol)
    end
    
    for i = 1,stackPos do
        stateStack:Pop()
        symbolStack:Pop()
    end

    leftSymbol.open_line = openLine
    leftSymbol.close_line = closeLine

    local nextState = GetNextAction(slr,stateStack,symbolStack,leftSymbol)
    
    assert("number" == type(nextState))
    
    stateStack:Push(nextState)
    symbolStack:Push(leftSymbol)

    return true
end

local metaEnv = {}
setmetatable(metaEnv,{__index = _G})
metaEnv._METAENV = metaEnv

local _LOCKSTATUS = {}
function metaEnv.lock()
    local info = debug.getinfo(2,"f")
    if _LOCKSTATUS[info.func] then
        -- func已经被lock住，不能被再次lock
        return false
    else
        _LOCKSTATUS[info.func] = true
        return true
    end
end

function metaEnv.unlock()
    local info = debug.getinfo(2,"f")
    if _LOCKSTATUS[info.func] then
        _LOCKSTATUS[info.func] = false      
        return true
    else
        return false
    end
end

local _LOCKSTATUS = nil

local metastatProcessors = {}

local function normalize_path(path)
    if "/" ~= string.sub(lfs.currentdir(),1,1) then
        -- windows
        path = string.gsub(path,"\\","/")
    end

    return string.gsub(path,"/+","/")
end

local function dir(path)
    return string.gsub(path,"[^/]+$","")
end

local function notdir(path)
    local base
    _, _, base = string.find(path,"([^/]*)$")
    return base
end

function metastatProcessors.import_module(body)
    local importName = body:get_child(2):value()

    return slr_compile_file(importName,gOpenluaSyntax)
end

function metastatProcessors.syntaxdef(def)
    local name = def:get_child(2):value()
    local body = def:get_child(4):value()
    local openluaNonterminals = gOpenluaSyntax.nonterminals
    local openluaFirstset = gOpenluaSyntax.firstset
    local openluaFollowset = gOpenluaSyntax.followset
    local firstset = {}
    local followset = {}

    for nt in openluaNonterminals:Traverse() do
        followset[nt] = openluaFollowset[nt]
        firstset[nt] = openluaFirstset[nt]
    end

    local syntax = AnalyseSyntax(IStream{body},firstset,followset)
    if nil == syntax then
        return false,
        "syntax "..name.." definition's format is invalid !"
    end
    
    syntax.terminals:Subtract(openluaNonterminals)
    
    local redefNonterminals = syntax.nonterminals * openluaNonterminals
    if not redefNonterminals:Empty() then
        -- 用户自定义语法重新定义了openlua语法的非终结符，
        -- 这是不允许的
        return false,
        "syntax "..name.." redefined openlua's nonterminal."
    end
    
    if nil ~= get_ll_conflict(syntax) then
        return false,
        "syntax "..name.." is not a LL1 syntax !"
    end

    metaEnv[name] = syntax
    return true
end

local transformers = {}
function metastatProcessors.transformerdef(def)
    local name = def:get_child(2):value()
    local body = def:get_child(3):emit()
    local func,errormsg = loadstring(body)
    if nil == func then 
        return false,
        "transformerdef "..name.." error : "..errormsg
    end
    
    setfenv(func,metaEnv)
    transformers[name] = func

    return true
end

local function dispatch_metastat(processorTable,symbol)
    --local body = symbol:get_child(1)
    local processor = processorTable[symbol:name()]
    --assert(nil ~= processor)
    if nil == processor then
        return true
    end

    return processor(symbol)
end

-- 如果发生转换并成功返回true，没有发生转换返回false
-- 否则返回nil和出错信息
local function transform_if_possible(openlexer)
    local token
    local bTransformed = false

    repeat
        token = openlexer:peek()
        if nil == token then
            return nil, "no input"
        end

        if "Name" == token:type() and
            nil ~= transformers[token:value()] then
            -- 把token从输入流中取走
            openlexer:extract()
            local codeString,terror = 
                transformers[token:value()]()
            terror = terror or ""
            if nil == codeString then
                return nil,
                "Parse error occurs when "..token:value()..
                    " transforming : "..terror
            end
            -- transformer调用必须返回字符串
            if "string" ~= type(codeString) then
                return nil,"transformer "..token:value()..
                    " must return a string "
            end
            
            bTransformed = true
            openlexer:push(Lexer.New(IStream{codeString}))
        else
            break
        end
    until false
    
    return bTransformed
end

-- 第一个返回值为语法树，如解析失败其为nil；
-- 第二个返回值为当前的lookhead
-- 第三个返回值为出错信息(如果有的话)
function slr_parse(openlexer,slr,nonterminal,initial_state,followTerm)
    -- 将起始状态压入栈中
    local stateStack = Stack{initial_state}
    local symbolStack = Stack{}
    local symbol,errormsg
    local action
    -- 标识openlexer是否扫描到nonterminal末尾的下一个符号的标志
    local bTryReduce = false
    local fakeFollowTerm = Symbol{"keymark",followTerm,0,0}
    local bTransformed
    
    symbol,errormsg = openlexer:peek()
    while symbol do
        while true do
            if bTryReduce then
                action = GetNextAction(slr,stateStack,symbolStack,fakeFollowTerm )
            else
                action = GetNextAction(slr,stateStack,symbolStack,symbol)
            end

            if not IsType(action,Production) then
                bTransformed,errormsg = transform_if_possible(openlexer)
                if nil ~= errormsg then
                    return nil,
                    {msg = errormsg,
                        stateStack = stateStack,
                        symbolStack = symbolStack}
                end
                if bTransformed then
                    break
                end
            end

            if nil == action then
                if not bTryReduce then
                    -- 嗯，出了一次错，再给它一个机会让它试着把目前为止
                    -- 输入的所有terminals规约成nonterminal
                    bTryReduce = true
                else
                    if 1 <= symbolStack:Count() and
                        nonterminal == symbolStack:Bottom():name() then
                        -- 接收
                        while 1 < symbolStack:Count() do
                            stateStack:Pop()
                            openlexer:unget(symbolStack:Pop())
                        end
                        
                        return symbolStack:Top()
                    else
                        -- 没办法规约成指定的nonterminal
                        return nil,
                        {msg = "unexpected token, ",
                            stateStack = stateStack,
                            symbolStack = symbolStack}
                    end
                end
            elseif "number" == type(action) then
                if bTryReduce then
                    -- 原来是采用被注释了的条件判断，和现在的比，哪种更合理？
                    --if 1 == symbolStack:Count() and
                    --    nonterminal == symbolStack:Top():name() then
                    if 1 <= symbolStack:Count() and
                        nonterminal == symbolStack:Bottom():name() then
                        -- 接收
                        while 1 < symbolStack:Count() do
                            stateStack:Pop()
                            openlexer:unget(symbolStack:Pop())
                        end
                        
                        return symbolStack:Top()
                    else
                        --debug
                        stateStack:Print()
                        symbolStack:Print()

                        -- 尝试规约不成功
                        return nil,
                        {msg = "not specified nonterminal, ",
                            stateStack = stateStack,
                            symbolStack = symbolStack}
                    end
                else
                    --symbol是nonterminal的一部分，执行shift动作
                    openlexer:extract()
                    stateStack:Push(action)
                    symbolStack:Push(symbol)
                    break;
                end
            elseif IsType(action,Production) then
                if 1 == symbolStack:Count()
                    and nonterminal == symbolStack:Top():name() then
                    -- 接收
                    return symbolStack:Top()
                end

                --规约
                if false == Reduce(slr,stateStack,symbolStack,action) then
                    if 1 <= symbolStack:Count() and
                        nonterminal == symbolStack:Bottom():name() then
                        -- 接收
                        while 1 < symbolStack:Count() do
                            stateStack:Pop()
                            openlexer:unget(symbolStack:Pop())
                        end
                        
                        return symbolStack:Top()
                    else
                        return nil,
                        {msg = "reduce error,",
                            stateStack = stateStack,
                            symbolStack = symbolStack}
                    end
                end

                local topSym = symbolStack:Top()
                if "metastat" == topSym:name() then
                    stateStack:Pop()
                    symbolStack:Pop()
                else
                    local correct,deferror = 
                        dispatch_metastat(metastatProcessors,topSym)
                    if not correct then
                        return nil,
                        {msg = "metastat error : "..deferror,
                            stateStack = stateStack,
                            symbolStack = symbolStack}
                    end
                end
            else
                -- should never be here
                assert(false,"unknown action type, ")
            end -- if nil == action then
        end -- while true do
        symbol,errormsg = openlexer:peek()
    end -- while symbol do

    if errormsg then
        -- 词法部分出错
        return nil,
        {msg = errormsg,
            stateStack = stateStack,symbolStack = symbolStack}
    else
        return nil,
        {msg = "unkonwn error occured when parsing, ",
            stateStack = stateStack,symbolStack = symbolStack}
    end
end

local function openlua_parse(openlexer,nonterminal)
    return slr_parse(openlexer,
                     gOpenluaSyntax.parseTable,
                     nonterminal,
                     gOpenluaSyntax.initialStates[nonterminal],
                     gOpenluaSyntax.followset[nonterminal]:GetOne())

end

local function create_meta_parser(openlexer,basicTerminals)
    return function (llSyntax)
               local oldTerminals = openlexer:get_terminals()
               local newTerminals = basicTerminals + llSyntax.terminals
               openlexer:set_terminals(newTerminals)

               local result = pack(ll_parse(openlexer,llSyntax,llSyntax.start))
               openlexer:set_terminals(oldTerminals)
               return unpack(result)
           end
end

function slr_compile_string(str,slrSyntax)
    local openlexer = Openlexer.new(slrSyntax.terminals)
    openlexer:push(Lexer.New(IStream{str}))

    -- 保存旧的parse函数
    local oldParser = metaEnv.parse
    metaEnv.parse = create_meta_parser(openlexer,slrSyntax.terminals)

    local start = slrSyntax.start
    local parseTree, error = 
        slr_parse(openlexer,
                  slrSyntax.parseTable,
                  start,
                  slrSyntax.initialStates[start],
                  slrSyntax.followset[start]:GetOne())

    -- 恢复旧的parse函数
    metaEnv.parse = oldParser

    local lookhead = openlexer:peek()

    if nil == lookhead then
        --print(error.msg)
        return nil,error.msg
    end

    if parseTree then
        if "eof" == lookhead:name() then
            --Parse successfully
            return parseTree
        else
            return nil, "Parse error occurs when encountering '"..
                lookhead:value().."' at line "..lookhead.open_line
            --lookhead:Print()
        end
    else
        return nil,error.msg.." '"..lookhead:value()..
            "' at line "..lookhead.open_line
    end
end

local compiled_files = {}
function slr_compile_file(sourcename,slrSyntax,objname)
    sourcename = normalize_path(sourcename)
    local srcpath = dir(sourcename)
    local last_workdir = lfs.currentdir()

    if "" ~= srcpath and nil == lfs.chdir(srcpath) then
        return false,string.format("no such directory:%s",srcpath)
    end

    sourcename = lfs.currentdir().."/"..notdir(sourcename)

    if compiled_files[sourcename] then
        lfs.chdir(last_workdir)
        return true
    end

    local srcfile = OpenInputFile(sourcename)
    if nil == srcfile then
        lfs.chdir(last_workdir)
        return false, "can't open "..sourcename.." file!"
    end
    
    local openlexer = Openlexer.new(slrSyntax.terminals)
    openlexer:push(Lexer.New(srcfile))

    -- 保存旧的parse函数
    local oldParser = metaEnv.parse
    metaEnv.parse = create_meta_parser(openlexer,slrSyntax.terminals)

    local start = slrSyntax.start
    local parseTree, error = 
        slr_parse(openlexer,
                  slrSyntax.parseTable,
                  start,
                  slrSyntax.initialStates[start],
                  slrSyntax.followset[start]:GetOne())

    -- 恢复旧的parse函数
    metaEnv.parse = oldParser

    local lookhead = openlexer:peek()

    srcfile:close()

    lfs.chdir(last_workdir)

    if nil == lookhead then
        --print(error.msg)
        return false,error.msg
    end

    if parseTree then
        if "eof" == lookhead:name() then
            --Parse successfully
            objfile = objname and OpenOutputFile(objname)
            if nil ~= objfile then
                objfile:write(parseTree:format())
                objfile:close()
            else
                if nil ~= objname then
                    print("can't create "..objname.." file")
                end
            end

            compiled_files[sourcename] = true

            return true
        else
            return false, "Parse error occurs when encountering '"..
                lookhead:value().."' at line "..lookhead.open_line
            --lookhead:Print()
        end
    else
        return false,error.msg.." '"..lookhead:value()..
            "' at line "..lookhead.open_line
    end
end

function ll_parse(openlexer,syntax,nonterminal)
    local productions = syntax.productions
    local firstset = syntax.firstset
    local followset = syntax.followset
    local nonterminals = syntax.nonterminals
    local terminals = syntax.terminals
    
    local bTransformed,errormsg = transform_if_possible(openlexer)
    if nil ~= errormsg then
        return nil,errormsg
    end

    local token = openlexer:peek()

    if not firstset[nonterminal]:Contains(token:name()) and
        not firstset[nonterminal]:Contains("empty") then
        -- nonterminal既不能为空，它的leading终结符集合也不包括token，
        -- 这说明接下来的输入不可能解析为nonterminal
        return nil,
        token:name().." at line "..token.open_line.."is not part of "..nonterminal
    end

    local rs
    local rsCanDeriveEmpty

    for e in productions[nonterminal]:Traverse() do
        local leadingTerminals = GetLeadingsOfRightside(e,firstset)
        if leadingTerminals:Contains(token:name()) then
            -- token决定了使用nonterminal : e这个产生式
            rs = e
            break
        end

        if leadingTerminals:Contains("empty") then
            -- 找到能导出空串的右部，如果有的话。
            -- LL(1)语法的非终结符至多只可能有一个这种右部
            rsCanDeriveEmpty = e
        end
    end

    local ls = Symbol{
        nonterminal,nonterminal,token.open_line,token.close_line}
    ls.children = List{}

    if nil == rs then
        if nil == rsCanDeriveEmpty then
            -- nonterminal本身有empty产生式，应该被规约为空
            ls.children:Append(
                               Symbol{"keymark","empty",ls.close_line,ls.close_line})
            return ls
        else
            -- nonterminal 本身没有empty产生式，但有能导出empty的右部
            rs = rsCanDeriveEmpty
        end
    end

    local rsPart

    for _,s in rs:Traverse() do
        if nonterminals:Contains(s) then
            rsPart,errormsg = ll_parse(openlexer,syntax,s)
        elseif terminals:Contains(s) then
            bTransformed ,errormsg = transform_if_possible(openlexer)
            if nil ~= errormsg then
                return nil,errormsg
            end
            rsPart = openlexer:peek()
            
            if "empty" == s then
                rsPart = 
                    Symbol{"keymark","empty",rsPart.open_line,rsPart.open_line}
            else
                if s ~= rsPart:name() then
                    errormsg = 
                        "expect "..s.." but got "..rsPart:name()..
                        " at line "..rsPart.open_line
                    rsPart = nil
                else
                    openlexer:extract()
                end
            end
        else
            -- s是openlua中的非终结符
            rsPart,errormsg = openlua_parse(openlexer,s)
            errormsg = errormsg and errormsg.msg.."when parsing "..s
        end -- if nonterminals:Contains(s) then
        
        if nil == rsPart then
            return nil,errormsg
        end

        ls.children:Append(rsPart)
        ls.close_line = rsPart.close_line
    end -- for _,s in rs:Traverse() do

    return ls
end

function ll_compile_file(sourcename,syntax,objname)
    local srcfile = OpenInputFile(sourcename)
    if nil == srcfile then
        return
    end
    
    local openlexer = Openlexer.new(syntax.terminals)
    openlexer:push(Lexer.New(srcfile))
    
    local parseTree = 
        ll_parse(openlexer,syntax,syntax.start)

    local lookhead = openlexer:peek()
    srcfile:close()

    if parseTree then
        if "eof" == lookhead:name() then
            print("Parse successfully!")
            local objfile
            if nil ~= objname then
                objfile = OpenOutputFile(objname)
            end
            if nil == objfile then
                return
            end
            objfile:write(parseTree:format())
            objfile:close()
        else
            print("Parse error ! Not end with eof but "
                  ..lookhead:name().." at line "
                      ..lookhead.open_line.."!")
            lookhead:Print()
        end
    else
        print("Parse error occurs when encountering "
              ..lookhead:name().." at line "
                  ..lookhead.open_line.."!")
        lookhead:Print()
    end
end

local function print_usage()
    local usage_info = 
[[
usage : openlua [options] srcfile [objfile]
Available options are:
-e metastat execute string 'metastat'
]]
    print(usage_info)
end

local srcfile,objfile
do
    local valid_options = {
        ["-e"] = "execute",
    }

    local opt_handlers = {}

    function opt_handlers.execute(arg,i)
        local metastat = arg[i + 1]
        local status, errmsg = slr_compile_string(metastat,gOpenluaSyntax)

        if status then
            return i + 2
        else
            return nil, errmsg
        end
    end

    local i = 1
    local errmsg
    while nil ~= arg[i] do
        local opt_name = valid_options[arg[i]]
        if opt_name then
            i, errmsg = opt_handlers[opt_name](arg,i)
            if nil == i then
                print(errmsg)
                os.exit(-1)
            end
        else
            -- 处理完 options
            break
        end
    end

    srcfile = arg[i]
    objfile = arg[i + 1]
end

if nil == srcfile then
    print_usage()
else
    local succeed ,msg = slr_compile_file(srcfile,gOpenluaSyntax,objfile)
    if succeed then
        print("Compile "..srcfile.." file successfully !")
    else
        print(msg)
        os.exit(-1)
    end
end