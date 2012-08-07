import "../import/std.ol"

defmacro SIN(angle)
[[
text(math.sin(angle))
]]

defmacro COS(angle)
[[
text(math.cos(angle))
]]

defmacro PI "3.1415926"

meta
  ver = 1
endmeta

when (1 == ver)
   print("ver 1.0")
   local temp1  = SIN(PI / 2)
   local temp2 = SIN(PI)
   local temp3 = SIN(2.18)
elsewhen (2 == ver)
   print("ver 2.0")
   local temp1  = COS(PI / 2)
   local temp2 = COS(PI)
   local temp3 = COS(2.18)
elsewhen (3 == ver)
   print("ver 3.0")
endwhen

meta
  PI6 = PI / 6
  use_sin = false
endmeta

-- when(use_sin)
--    meta count = 0 endmeta

--    local sinTable = {
--       loop(count < 10)
--       [[
-- 	    SIN(text(count * PI6)),
--       ]]
--       with
--          count = count + 1
--       endloop
--    }
-- else
--    meta count = 0 endmeta

--    local cosTable = {
--       loop(count < 10)
--       [[
-- 	    COS(text(count * PI6)),
--       ]]
--       with
--          count = count + 1
--       endloop
--    }
-- endwhen

meta
  i = 0
endmeta

local cubicTable = {}

loop (i < 10)
" cubicTable[text(i)] = text(i * i * i) "
with
   i = i + 1
endloop