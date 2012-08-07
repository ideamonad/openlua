--[[-----------------------------------

name : common base functions library
creation time : 2005/08/01
author : soloist
description : This file implements some base functions
              which will be used frequently.

--]]-----------------------------------



--[[-----------------------------------------
    a common metatable for primogenitors
--]]-----------------------------------------

primogenitor_mt = {}

function primogenitor_mt.__call(t,...)
   return t.New(arg[1])
end

primogenitor_mt.__metatable = "It's not your business!"

function primogenitor_mt.__newindex(t,k,v)
   error("Primogenitor can not be changed!",2)
end

--[[----------------------------------------------
    a common metatable for primogenitors
--]]----------------------------------------------



function Clone(t)
   if "table" == type(t) then
      local clone = {}
      for k,v in pairs(t) do
	 clone[k] = Clone(v)
      end
      return clone
   else
      return t
   end
end

function pack(...)
   return arg
end

function IsSpaceStr(s)
   local first,last = string.find(s,"%s*")
   if 1 == first and string.len(s) == last then
      return true
   else
      return false
   end
end

function IsType(obj,type)
   local mt = getmetatable(obj)

   while nil ~= mt do
      if rawequal(mt,type) then
	 return true
      end
      mt = getmetatable(mt)
   end

   return false
end

local _endmarker = {}
function _endmarker:Serialize(file)
   file:write("Endmarker()")
end

function _endmarker:Print()
   self:Serialize(io.output())
   io.output():write("\n")
end

function _endmarker:tostring()
   return "Endmarker()"
end

function Endmarker()
   return _endmarker
end

local _acceptflag = {}
function _acceptflag:Serialize(file)
   file:write("AcceptFlag()")
end

function _acceptflag:Print()
   self:Serialize(io.output())
   io.output():write("\n")
end

function _acceptflag:tostring()
   return "AcceptFlag()"
end

function AcceptFlag()
   return _acceptflag
end


function OpenInputFile(filename)
    if "file" ~= lfs.attributes(filename,"mode") then
        print(filename.." is not a file")
        return nil
    end

   local file = io.open(filename,"r")

   if nil == file then
      print("Can't open "..filename.."!")
   end

   return file
end

function OpenOutputFile(filename)
   local file = io.open(filename, "w")

   if nil == file then
      print("Can't open "..filename.." for writing!")
   end
   
   return file
end