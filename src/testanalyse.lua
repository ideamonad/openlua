dofile"prototype.lua"

local r1 = Rightside{"function", "name","funcbody"}
local r2 = Rightside{"for","var","step"}
local r3 = Rightside{"function", "name","funcbody"}

assert(r1 ~= r2)
assert(r1 == r3)

local i1 = Item.New("func",r1)
local i2 = Item.New("func",r3)
assert(i1:DotPos() == 1)
assert(i1:NextSymbol() == "function")
assert(i1 == i2)

assert(i1:Goto("some") == nil)
local i3 = i1:Goto("function")
assert(i3:NextSymbol() == "name")
local i4 = i3:Goto("name")
assert(i4:NextSymbol() == "funcbody")
local i5 = i4:Goto("funcbody")
assert(i5:NextSymbol() == nil)

local pt = ParseTable.New()
pt:Set(1,"a",1979)
assert(pt:Get(1,"a") == 1979)
pt:Set("bc","name","temp")
assert(pt:Get("bc","name") == "temp")