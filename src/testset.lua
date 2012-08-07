--[[----------------------------------------------
Õë¶Ôset.luaµÄ²âÊÔ´úÂë
--]]----------------------------------------------

dofile("set.lua")

local empty = Set{}
assert(empty:Count() == 0)
assert(empty:Empty())
local number1 = Set{1979}
assert(number1:Count() == 1)
assert(number1:Contains(1979))
local string1 = Set{"djf"}
assert(string1:Count() == 1)
assert(string1:Contains("djf"))
local bool2 = Set{true,false,true,false}
assert(bool2:Count() == 2)
assert(bool2:Contains(true) and bool2:Contains(false))

local set2 = Set{1,1,1979,1979,"soloist","soloist"}
assert(set2:Count() == 3)

local set3 = Set{Set{3,5},Set{5,3}}
assert(set3:Count() == 1)
assert(set3:Contains(Set{3,5}))

local set4 = Set{1,1,"temp","temp",Set{3,5},Set{5,3,"djf"},Set{3,5,"djf"}}
assert(set4:Count() == 4)
assert(set4:Contains(1))
assert(set4:Contains("temp"))
assert(set4:Contains(Set{3,5}))
assert(set4:Contains(Set{3,5,"djf"}))

local other = Set{1979,{4,5},{4,5}}
assert(other:Count() == 3)


-- test relational operations

local function TestLess(set1,set2)
   assert(set1 ~= set2)
   assert(set2 ~= set1)
   assert(set1 <= set2)
   assert(set2 >= set1)
   assert(set1 < set2)
   assert(set2 > set1)
   assert(not (set1 >= set2))
   assert(not (set1 > set2))
   assert(not (set2 <= set1))
   assert(not (set2 < set1))
end

local function TestLessOrEqual(set1,set2)
   assert(set1 <= set2)
   assert(set2 >= set1)
   assert(not (set1 > set2))
   assert(not (set2 < set1))
end

local function TestEqual(set1,set2)
   assert(set1 == set2)
   assert(set2 == set1)
   assert(set1 <= set2)
   assert(set1 >= set2)
   assert(set2 <= set1)
   assert(set2 >= set1)
   assert(not (set1 > set2))
   assert(not (set1 < set2))
   assert(not (set2 > set1))
   assert(not (set2 < set1))
end

local function TestNotEqual(set1,set2)
   assert(set1 ~= set2)
   assert(set2 ~= set1)
   assert(not (set1 == set2))
   assert(not (set2 == set1))
end

TestEqual(empty,Set{})
TestEqual(empty,empty)
TestLess(empty,number1)
TestLess(empty,string1)
TestLess(empty,bool2)
TestNotEqual(number1,string1)
TestNotEqual(string1,bool2)
TestNotEqual(number1,bool2)

local set4 = Set{1,1,"temp","temp",Set{3,5},Set{5,3,"djf"},Set{3,5,"djf"}}
TestEqual(set4,set4)
local set5 = Set{1,"temp",Set{5,3},Set{5,3,"djf"}}
TestEqual(set5,set5)
TestEqual(set5,set4)
local set6 = Set{1,"temp","temp",1,Set{5,3,3,3,3,5}}
TestEqual(set6,set6)
TestLess(set6,set5)


-- test set arithmatic operations

local function TestCommutative(set1,set2)
   TestEqual(set1 + set2,set2 + set1)
   TestEqual(set1 * set2,set2 * set1)
end

local function TestIdentity(set)
   local empty = Set{}
   TestCommutative(empty,set)
   TestEqual(set,set + empty)
   TestEqual(empty,set * empty)
   TestEqual(set,set + set)
   TestEqual(set,set * set)
   TestEqual(set,set - empty)
   TestEqual(empty,empty - set)
   TestEqual(empty, set - set)
end

TestIdentity(empty)
TestIdentity(number1)
TestIdentity(string1)
TestIdentity(bool2)

local a1 = Set{56,78,"you"}
local a2 = Set{78,33,"we","you"}
local a3 = Set{56,78,33,"you","we"}
TestIdentity(a1)
TestIdentity(a2)
TestIdentity(a3)
TestCommutative(a1,a2)
TestEqual(a1 + a2,a3)
TestEqual(a1 * a2,Set{78,"you"})
TestEqual(a1 - a2,Set{56})
TestEqual(a2 - a1,Set{33,"we"})

local b1 = Set{"soloist","soloist","game",1979,1979,Set{5,7,9,"temp"}}
local b2 = Set{"game","game",33,Set{5,7,9,"temp"},Set{"another"}}
local b3 = Set{"soloist","game",1979,33,Set{5,7,9,"temp"},Set{"another"}}
local b4 = Set{Set{5,7,9,"temp"},"game"}
local b2_b1 = Set{33,Set{"another"}}
TestIdentity(b1)
TestIdentity(b2)
TestIdentity(b3)
TestIdentity(b4)
TestCommutative(b1,b2)
TestEqual(b1 + b2, b3)
TestEqual(b1 * b2,b4)
TestEqual(b1 - b2,Set{"soloist",1979})
TestEqual(b2 - b1 ,b2_b1)

---------------------

local a1 = Set{5,7,9,Set{1979}}
assert(a1:Add(5) == false)
assert(a1 == Set{5,7,9,Set{1979}})
assert(a1:Add(11) == true)
assert(a1 == Set{5,7,9,11,Set{1979}})
assert(a1:Add(Set{1979}) == false)
assert(a1:Add(Set{"temp"}) == true)
assert(a1:Remove(Set{55,66}) == false)
assert(a1:Remove(Set{1979}) == true)
assert(a1 == Set{5,7,9,11,Set{"temp"}})

local b1 = Set{5,"temp",Set{1979,"who"}}
local b2 = Set{Set{1979,"who"}}
assert(b1:Union(b2) == false)
assert(b1 == Set{5,"temp",Set{1979,"who"}})
local b3 = Set{1979,"chang"}
assert(b1:Union(b3) == true)
Set.Print(b1)
assert(b1 == Set{5,"temp",Set{1979,"who"},1979,"chang"})

local c = 0
for e in b1:Traverse() do
   c = c + 1
end
assert(c == 5)