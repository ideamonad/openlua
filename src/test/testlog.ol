import "../import/log.ol"

LOG function foo(flag)
   if 0 > flag then
      return -1
   elseif 0 < flag then
      return 1
   end
   return 0
end
