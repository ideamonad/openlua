require ( "contract.lua" ) 
Point = { x = 1 , y = 1 } 
function Point : __invariant ( ) 
   return self . x > 0 and self . y > 0 
end 
function Point : New ( o ) 
   o = o or { } 
   setmetatable ( o , self ) 
   rawset ( self , "__index" , self ) 
   o = Contract . EquipInv ( o ) 
   Contract . JustCheckInv ( o ) 
   return o 
end 
local function temp ( self , times ) 
   self . x = self . x * times 
   self . y = self . y * times 
   send ( self , times ) 
end 
Point . Zoom = Contract . EquipAssert ( temp , "self,times" , "times > 10" , "self . x == old ( self . x ) * times and self . y == old ( self . y ) * times" , true ) 
temp = nil 
Point3D = Point : New ( { z = 1 } ) 
function Point3D : __invariant ( ) 
   return self . z > 0 
end 
local function temp ( self , times ) 
   self . x = self . x * times 
   self . y = self . y * times 
   self . z = self . z * times 
   send ( self , times ) 
end 
Point3D . Zoom = Contract . EquipAssert ( temp , "self,times" , "times > 100" , "self . z == old ( self . z ) * times" , true ) 
temp = nil 
r1 = Point : New ( ) 
r1 : Zoom ( 15 ) 
s3 = Point3D : New ( { x = 3 , y = 4 , z = 5 } ) 
s3 : Zoom ( 12 ) ;
s3 : Zoom ( 15 ) 
