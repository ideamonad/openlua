import "../import/contract.ol"

require("contract.lua")

Point = {x = 1,y = 1}

invariant Point : self.x > 0 and self.y > 0 end

function Point:New(o)
   o = o or {}
   setmetatable(o,self)
   rawset(self,"__index",self)
   o = Contract.EquipInv(o)
   Contract.JustCheckInv(o)
   return  o
end

contractfunc Point:Zoom(times)
   require : times > 10 end
   
   self.x = self.x * times
   self.y = self.y * times
   
   ensure : 
     self.x == old(self.x) * times and
     self.y == old(self.y) * times 
   end
end

Point3D = Point:New({z = 1})

invariant Point3D : self.z > 0 end

contractfunc Point3D:Zoom(times)
   require : times > 100 end

   self.x = self.x * times
   self.y = self.y * times
   self.z = self.z * times

   ensure : self.z == old(self.z) * times end
end

r1 = Point:New() --OK
--r1:Zoom(0.5) -- 前置断言检查失败
r1:Zoom(15) -- OK
--s1 = Point3D:New({x = -3,y = -3}) --Point不变式检查失败
--s2 = Point3D:New({z = -5}) --Point3D不变式检查失败
s3 = Point3D:New({x = 3,y = 4,z = 5}) --OK
--s3:Zoom(-2) -- 前置断言检查失败
s3:Zoom(12);
s3:Zoom(15) -- OK
