local sources, paths = {}, {}
sources["engine"] = [=[
local ac=...local bc={}bc.VERSION="1.0.0"
local cc={fps=20,frameTime=1 /20,deltaHistorySize=10}
local dc={running=false,activeScene=nil,manualViewport=false,consoleEnabled=true,lastDeltaTime=0,deltaHistory={},lastTime=0,currentFPS=0,frameCount=0,fpsTimer=0,transition=nil}local _d={update={},render={},event={}}bc.ecs=ac("core.ecs")
bc.scene=ac("core.scene")bc.thread=ac("core.thread")local ad=ac("core.buffer")
bc.buffer=ad.new()bc.renderer=bc.buffer;bc.rgb=ad.rgb;bc.color=ad.color
bc.input=ac("core.input")bc.loader=ac("core.loader")bc.flimg=bc.loader.flimg
bc.inputMapper=ac("core.input_mapper")bc.ui=ac("core.ui")bc.tween=ac("core.tween")
bc.timer=ac("core.timer")bc.camera=ac("core.camera")bc.tilemap=ac("core.tilemap")
bc.event=ac("core.event").new()bc.logger=ac("core.logger")bc.math=ac("core.math")
bc.physics=ac("core.physics")bc.audio=ac("core.audio")bc.ai=ac("core.ai")
bc.pathfinding=ac("core.pathfinding")bc.serialization=ac("core.serialization")
bc.network=ac("core.network")bc.server=ac("core.server")bc.storage=ac("core.storage")
bc.db=ac("core.db")bc.particles=ac("core.particles")
bc.console=ac("core.console")bc.error=ac("core.error")local bd=ac("core.debug")local cd=bc.error
bc.scene.setBuffer(bc.buffer)
function bc.addRenderLayer(aaa,baa)return bc.buffer:addLayer(aaa,baa)end
function bc.getRenderLayer(aaa)return bc.buffer:getLayer(aaa)end
function bc.removeRenderLayer(aaa)return bc.buffer:removeLayer(aaa)end
bc.logger._consoleHook=function(aaa,baa)bc.console.addLine(aaa,baa)end;local function dd(aaa,...)bc.event:emit(aaa,...)
if
dc.activeScene and dc.activeScene.event then dc.activeScene.event:emit(aaa,...)end end
bc.network._emit=dd;bc.server._emit=dd
bc.thread.errorHandler=function(aaa)
bc.buffer:restorePalette()cd.report(aaa)dc.running=false end;local __a=_G and _G.debug
local function a_a(aaa)return
(__a and __a.traceback)and
__a.traceback(tostring(aaa),2)or tostring(aaa)end;function bc.onError(aaa)cd.handler=aaa end
function bc._reportError(aaa,baa)
bc.buffer:restorePalette()cd.report(aaa,baa)dc.running=false end;function bc.setFPS(aaa)cc.fps=aaa;cc.frameTime=1 /aaa end;function bc.getTargetFPS()return
cc.fps end;function bc.getFPS()return dc.currentFPS end;function bc.getDeltaTime()return
dc.lastDeltaTime end;function bc.onUpdate(aaa)
table.insert(_d.update,aaa)end;function bc.onRender(aaa)
table.insert(_d.render,aaa)end
function bc.onEvent(aaa)table.insert(_d.event,aaa)end
function bc.setScene(aaa)
if dc.activeScene then if dc.activeScene.event then
dc.activeScene.event:emit("unload")end;if dc.activeScene.onUnload then
dc.activeScene:onUnload()end end;bc.tween.stopAll()cd._shouldStop=false;dc.activeScene=aaa
bc.scene.activeScene=aaa;if dc.activeScene and dc.activeScene.onLoad then
dc.activeScene:onLoad()end
if
dc.activeScene and dc.activeScene.event then dc.activeScene.event:emit("load")end
bc.logger.info("Scene changed: ".. (
dc.activeScene and(dc.activeScene.name or"Unnamed")or"none"))end;function bc.getScene()return dc.activeScene end;function bc.transition(aaa,baa)
dc.transition={target=aaa,duration=baa or 1,elapsed=0,stage="out"}end;function bc.isTransitioning()return
dc.transition~=nil end;function bc.setViewport(aaa,baa)dc.manualViewport=true
bc.buffer:setSize(aaa,baa)
if dc.activeScene then dc.activeScene._staticDirty=true end end;function bc.setDesignResolution(aaa,baa)
bd.designW,bd.designH=aaa,baa end
function bc.setMinResolution(aaa,baa)bd.minW=aaa;bd.minH=baa end;function bc.getDesignResolution()return bd.designW,bd.designH end
function bc.getViewportOffset()
if
not bd.designW or not bd.designH then return 0,0 end;local aaa,baa=bc.buffer:getSize()
return
math.floor((aaa-bd.designW)/2),math.floor((baa-bd.designH)/2)end
function bc.screenToViewport(aaa,baa)local caa,daa=bc.getViewportOffset()return aaa-caa,baa-daa end
function bc.showDebug(aaa,baa)bd.enabled=aaa;if baa~=nil then bd.alwaysOnTop=baa end end
function bc._renderDebug()if not bd.enabled then return end
local aaa=string.format("FPS: %d | Upd: %dms | Draw: %dms",bd.fps,bd.updateTime,bd.drawTime)local baa=0
if dc.activeScene and dc.activeScene._staticElements then baa=#
dc.activeScene._staticElements end
local caa=string.format("Entities: %d (Dyn) | %d (Stat)",bd.dynamicCount or 0,baa)bc.buffer:drawText(1,1,aaa,"0","f")
bc.buffer:drawText(1,2,caa,"7","f")if dc.activeScene then dc.activeScene._rowsToRestore[1]=true
dc.activeScene._rowsToRestore[2]=true end
if bd.showLogs then
local daa=bc.logger.getHistory()
for _ba,aba in ipairs(daa)do
bc.buffer:drawText(1,3 +_ba,aba.text,aba.color,"f")if dc.activeScene then
dc.activeScene._rowsToRestore[3 +_ba]=true end end end end;function bc.enableConsole(aaa)dc.consoleEnabled=aaa
if not aaa then bc.console.close()end end;function bc.isConsoleEnabled()
return dc.consoleEnabled end
function bc.disableConsole()bc.enableConsole(false)end
function bc._renderDebugTop()
if not bd.enabled or not bd.alwaysOnTop then return end;local aaa,baa=bc.buffer:getSize()
local caa=string.format("FPS: %d | Upd: %dms | Draw: %dms",bd.fps,bd.updateTime,bd.drawTime)local daa=0
if dc.activeScene and dc.activeScene._staticElements then daa=#
dc.activeScene._staticElements end
local _ba=string.format("Entities: %d (Dyn) | %d (Stat)",bd.dynamicCount or 0,daa)bc.buffer:drawText(1,1,caa,"0","f")
bc.buffer:drawText(1,2,_ba,"7","f")if dc.activeScene then dc.activeScene._rowsToRestore[1]=true
dc.activeScene._rowsToRestore[2]=true end
if bd.showLogs then
local aba=bc.logger.getHistory()
for bba,cba in ipairs(aba)do
bc.buffer:drawText(1,3 +bba,cba.text,cba.color,"f")if dc.activeScene then
dc.activeScene._rowsToRestore[3 +bba]=true end end end end
local function b_a()local aaa=os.epoch("utc")/1000;local baa=aaa-dc.lastTime
dc.lastTime=aaa;table.insert(dc.deltaHistory,baa)
if#dc.deltaHistory>
cc.deltaHistorySize then table.remove(dc.deltaHistory,1)end;local caa=0;for daa,_ba in ipairs(dc.deltaHistory)do caa=caa+_ba end;dc.lastDeltaTime=
caa/#dc.deltaHistory end
local function c_a()if not dc.transition then return end;dc.transition.elapsed=dc.transition.elapsed+
dc.lastDeltaTime
local aaa=dc.transition.duration/2;local baa=0
if dc.transition.stage=="out"then
baa=math.min(1,dc.transition.elapsed/aaa)
if dc.transition.elapsed>=aaa then
bc.setScene(dc.transition.target)dc.transition.stage="in"end else
baa=math.max(0,1 - (dc.transition.elapsed-aaa)/aaa)if dc.transition.elapsed>=dc.transition.duration then
dc.transition=nil;return end end;local caa,daa=bc.buffer:getSize()
local _ba=math.floor((daa/2)*baa)
if _ba>0 then bc.buffer:drawRect(1,1,caa,_ba," ","0","f")bc.buffer:drawRect(1,
daa-_ba+1,caa,_ba," ","0","f")end end
local function d_a()local aaa=os.epoch("utc")local baa,caa=term.getSize()
if bd.minW and bd.minH and(
baa<bd.minW or caa<bd.minH)then
bd.unsupportedResolution=true;term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)term.clear()term.setCursorPos(1,1)
term.write("Terminal size not supported.")term.setCursorPos(1,2)
term.write(string.format("Required: %dx%d | Current: %dx%d",bd.minW,bd.minH,baa,caa))os.sleep(0.2)dc.lastTime=os.epoch("utc")/1000;return end;bd.unsupportedResolution=false;b_a()
bc.tween.update(dc.lastDeltaTime)bc.timer.update(dc.lastDeltaTime)if dc.activeScene then
dc.activeScene:update(dc.lastDeltaTime)end
if dc.activeScene then
local dba,_ca=pcall(function()return
dc.activeScene:select("pos","sprite")end)
if dba and _ca then bd.dynamicCount=#_ca else bd.dynamicCount=0 end else bd.dynamicCount=0 end;if cd._shouldStop then dc.running=false;return end;for dba,_ca in ipairs(_d.update)do
_ca(dc.lastDeltaTime)end
bd.updateTime=os.epoch("utc")-aaa;bc.input._endFrame()local daa=os.epoch("utc")
if dc.transition and
dc.activeScene then dc.activeScene._staticDirty=true end;if dc.activeScene then dc.activeScene:draw()end;for dba,_ca in
ipairs(_d.render)do _ca()end;c_a()if dc.consoleEnabled then
bc.console.draw(bc.buffer)end;bc._renderDebugTop()
bc.buffer:present()bd.drawTime=os.epoch("utc")-daa
dc.frameCount=dc.frameCount+1;local _ba=os.clock()
if _ba-dc.fpsTimer>=1 then dc.currentFPS=dc.frameCount
bd.fps=dc.frameCount;dc.frameCount=0;dc.fpsTimer=_ba end;local aba=(os.epoch("utc")-aaa)/1000
local bba=math.max(0,cc.frameTime-aba)local cba=os.startTimer(bba)repeat local dba,_ca=os.pullEvent("timer")until
tid==cba end
local function _aa(aaa)local baa=false;if dc.activeScene and dc.activeScene.ui then
local daa,_ba=bc.getViewportOffset()
baa=dc.activeScene.ui:handleEvent(aaa,daa,_ba)end
local caa=false
if dc.consoleEnabled then local daa=bc.console.isOpen()
caa=bc.console.handleEvent(aaa,baa)
if
daa and not bc.console.isOpen()and dc.activeScene then dc.activeScene._staticDirty=true end end
if baa then
if aaa[1]=="mouse_click"then bc.input.clear()end elseif not caa then
bc.input.processEvent(table.unpack(aaa))bc.network.processEvent(aaa)
bc.server.processEvent(aaa)
bc.event:emit(aaa[1],table.unpack(aaa,2))if dc.activeScene and dc.activeScene.event then
dc.activeScene.event:emit(aaa[1],table.unpack(aaa,2))end
if dc.activeScene and
dc.activeScene.onEvent then
local daa,_ba=xpcall(dc.activeScene.onEvent,a_a,aaa)if not daa then bc._reportError(_ba)end end end
if aaa[1]=="term_resize"and not dc.manualViewport then
local daa,_ba=term.getSize()bc.buffer:setSize(daa,_ba)if dc.activeScene then
dc.activeScene._staticDirty=true end end;for daa,_ba in ipairs(_d.event)do _ba(aaa)end
bc.thread.update(table.unpack(aaa))end
function bc.start()dc.running=true;dc.lastTime=os.epoch("utc")/1000
dc.fpsTimer=os.clock()bc.audio.refresh()
bc.console.setEnv(setmetatable({Engine=bc,print=function(...)local aaa={}for i=1,select("#",...)do
aaa[i]=tostring(select(i,...))end
bc.console.print(table.concat(aaa,"\t"))end},{__index=_G}))
bc.thread.start(function()while dc.running do d_a()end end)
while dc.running do local aaa={os.pullEvent()}_aa(aaa)end;bc.buffer:restorePalette()end
function bc.stop()dc.running=false;bc.buffer:restorePalette()end;function bc.isRunning()return dc.running end;return bc
]=]
paths["engine"] = "engine"
sources["flimg"] = [=[

local dba={VERSION=1,MAGIC="FLMG",MODE_PIXEL="pixel",MODE_CELL="cell",ENCODING_RAW=0,ENCODING_RLE=1}local _ca,aca,bca,cca=string.char,string.byte,string.sub,string.rep
local dca,_da,ada=math.floor,math.min,math.max;local bda={pixel=1,cell=2}local cda={[1]="pixel",[2]="cell"}
local dda={[0]=0xF0F0F0,0xF2B233,0xE57FD8,0x99B2F2,0xDEDE6C,0x7FCC19,0xF2B2CC,0x4C4C4C,0x999999,0x4C99B2,0xB266E5,0x3366CC,0x7F664C,0x57A64E,0xCC4C4C,0x111111}dba.NATIVE_RGB=dda;local function __b(b_c,c_c)
error("FLIMG: "..b_c,(c_c or 1)+1)end
local function a_b(b_c,c_c,d_c,_ac)if
type(b_c)~="number"or b_c~=dca(b_c)or b_c<d_c or b_c>_ac then
__b(c_c..
" must be an integer from "..d_c.." to ".._ac,2)end;return b_c end;local function b_b(b_c)return _ca(b_c)end;local function c_b(b_c)return
_ca(b_c%256,dca(b_c/256)%256)end;local function d_b(b_c)
if b_c<0 then b_c=b_c+65536 end;return c_b(b_c)end
local function _ab(b_c)return
_ca(b_c%256,dca(b_c/256)%256,dca(
b_c/65536)%256,dca(b_c/16777216)%256)end;local aab={}aab.__index=aab;function aab.new(b_c)return
setmetatable({data=b_c,pos=1,size=#b_c},aab)end
function aab:take(b_c,c_c)if b_c<0 or
self.pos+b_c-1 >self.size then
__b("truncated ".. (c_c or"data")..
" at byte "..self.pos,2)end;local d_c=bca(self.data,self.pos,
self.pos+b_c-1)
self.pos=self.pos+b_c;return d_c end
function aab:u8(b_c)local c_c=aca(self.data,self.pos)if c_c==nil then
__b("truncated ".. (b_c or"u8"),2)end;self.pos=self.pos+1;return c_c end;function aab:u16(b_c)local c_c,d_c=aca(self:take(2,b_c),1,2)
return c_c+d_c*256 end
function aab:i16(b_c)local c_c=self:u16(b_c)return c_c>=
32768 and c_c-65536 or c_c end
function aab:u32(b_c)local c_c,d_c,_ac,aac=aca(self:take(4,b_c),1,4)return c_c+d_c*256 +_ac*
65536 +aac*16777216 end;local function bab(b_c,c_c)return b_c% (c_c*2)>=c_c end
local function cab(b_c,c_c)
if
type(b_c)=="string"then local d_c=b_c:gsub("#","")
if d_c:match("^%x%x%x$")then d_c=
d_c:sub(1,1):rep(2)..
d_c:sub(2,2):rep(2)..d_c:sub(3,3):rep(2)elseif
d_c:match("^%x%x%x%x%x%x%x%x$")then d_c=d_c:sub(3)end;if not d_c:match("^%x%x%x%x%x%x$")then
__b((c_c or"color")..
" must be #RGB, #RRGGBB, #AARRGGBB, or 0xRRGGBB",2)end
b_c=tonumber(d_c,16)end;return a_b(b_c,c_c or"color",0,0xFFFFFF)end
local function dab(b_c,c_c,d_c,_ac)local aac,bac=c_c or 1,#b_c
while aac+7 <=bac do
local cac,dac,_bc,abc,bbc,cbc,dbc,_cc=aca(b_c,aac,aac+7)
local acc=

cac>_ac and cac or dac>_ac and dac or _bc>_ac and _bc or abc>_ac and abc or bbc>_ac and bbc or cbc>_ac and cbc or
dbc>_ac and dbc or
_cc>_ac and _cc;if acc then
__b(d_c.." references missing palette index "..acc,2)end;aac=aac+8 end
while aac<=bac do local cac=aca(b_c,aac)if cac>_ac then
__b(d_c..
" references missing palette index "..cac,2)end;aac=aac+1 end end
local function _bb(b_c,c_c,d_c,_ac)
if type(b_c)=="string"then
if#b_c~=c_c then __b(d_c..
" has width "..#b_c..", expected "..c_c,2)end;dab(b_c,1,d_c,_ac)return b_c end;if type(b_c)~="table"or#b_c~=c_c then
__b(d_c..
" must be a byte string or an array of width "..c_c,2)end;local aac={}
for x=1,c_c do local bac=a_b(b_c[x],d_c..
" pixel "..x,0,255)if bac>_ac then
__b(d_c.." pixel "..x..
" references missing palette index "..bac,2)end;aac[x]=_ca(bac)end;return table.concat(aac)end
local function abb(b_c,c_c,d_c,_ac)if type(b_c)~="table"then
__b(d_c.." must be {text, foreground, background}",2)end;local aac,bac,cac=b_c[1]or b_c.text,b_c[2]or b_c.fg,
b_c[3]or b_c.bg
if

type(aac)~="string"or
type(bac)~="string"or type(cac)~="string"or#aac~=c_c or#bac~=c_c or#cac~=c_c then
__b(d_c..
" planes must be byte strings of width "..c_c,2)end;dab(bac,1,d_c.." foreground",_ac)
dab(cac,1,d_c.." background",_ac)return{aac,bac,cac}end
local function bbb(b_c,c_c,d_c)local _ac={}
if b_c=="pixel"then local aac=cca("\0",c_c)for y=1,d_c do _ac[y]=aac end else
local aac=cca("\0",c_c)for y=1,d_c do _ac[y]={aac,aac,aac}end end;return _ac end
local function cbb(b_c,c_c)local d_c={}
if b_c=="pixel"then for y=1,#c_c do d_c[y]=c_c[y]end else for y=1,#c_c do local _ac=c_c[y]
d_c[y]={_ac[1],_ac[2],_ac[3]}end end;return d_c end
local function dbb(b_c)
if type(b_c)~="table"then __b("image must be a table",2)end;local c_c=b_c.mode or"pixel"if not bda[c_c]then
__b("mode must be 'pixel' or 'cell'",2)end
local d_c=a_b(b_c.width,"width",1,65535)local _ac=a_b(b_c.height,"height",1,65535)local aac={}if
type(b_c.palette)~="table"or#b_c.palette<1 or
#b_c.palette>255 then
__b("palette must contain 1 to 255 colors",2)end
for i=1,#b_c.palette do aac[i]=cab(b_c.palette[i],
"palette color "..i)end;local bac=b_c.layers;if
type(bac)~="table"or#bac<1 or#bac>255 then
__b("layers must contain 1 to 255 layer descriptors",2)end;local cac={}
for i=1,#bac do
local bbc=bac[i]if type(bbc)~="table"then
__b("layer "..i.." must be a table",2)end
local cbc=bbc.name or("Layer "..i)if type(cbc)~="string"or#cbc>255 then
__b("layer "..i.." name is too long",2)end
cac[i]={name=cbc,x=a_b(bbc.x or 1,"layer "..i.." x",
-32768,32767),y=a_b(bbc.y or 1,"layer "..i.." y",-32768,32767),width=a_b(
bbc.width or d_c,"layer "..i.." width",1,65535),height=a_b(bbc.height or _ac,
"layer "..i.." height",1,65535),z=a_b(bbc.z or i,"layer "..i.." z",
-32768,32767),visible=bbc.visible~=false}end;local dac=b_c.frames
if
type(dac)~="table"or#dac<1 or#dac>65535 then __b("frames must contain 1 to 65535 frames",2)end;local _bc,abc={},{}
for frameIndex=1,#dac do local bbc=dac[frameIndex]if type(bbc)~="table"then
__b("frame "..frameIndex..
" must be a table",2)end;local cbc=bbc.layers or bbc
local dbc={duration=a_b(
bbc.duration or b_c.defaultDuration or 100,"frame "..
frameIndex.." duration",1,65535),layers={}}
for layerIndex=1,#cac do local _cc=cac[layerIndex]local acc=cbc[layerIndex]local bcc
if acc==nil and
abc[layerIndex]~=nil then bcc=cbb(c_c,abc[layerIndex])elseif acc==
nil then bcc=bbb(c_c,_cc.width,_cc.height)else
bcc=acc.rows or acc;if type(bcc)~="table"or#bcc~=_cc.height then
__b("frame "..frameIndex..
" layer "..
layerIndex.." must have ".._cc.height.." rows",2)end;local ccc={}
for y=1,_cc.height
do local dcc="frame "..
frameIndex.." layer "..layerIndex.." row "..y
ccc[y]=
c_c=="pixel"and _bb(bcc[y],_cc.width,dcc,#aac)or
abb(bcc[y],_cc.width,dcc,#aac)end;bcc=ccc end;dbc.layers[layerIndex]={rows=bcc}abc[layerIndex]=bcc end;_bc[frameIndex]=dbc end
return
{format="FLIMG",version=1,mode=c_c,width=d_c,height=_ac,palette=aac,layers=cac,frames=_bc,loop=b_c.loop~=false,pingPong=b_c.pingPong==true,keyframeInterval=a_b(b_c.keyframeInterval or 16,"keyframeInterval",1,255)}end;function dba.normalize(b_c)return dbb(b_c)end
function dba.rleEncode(b_c)if type(b_c)~="string"then
__b("rleEncode expects a string",2)end;local c_c,d_c,_ac={},#b_c,1
while _ac<=d_c do
local aac=aca(b_c,_ac)local bac=1;while
bac<128 and _ac+bac<=d_c and aca(b_c,_ac+bac)==aac do bac=bac+1 end
if bac>=3 then
c_c[#c_c+1]=_ca(257 -bac,aac)_ac=_ac+bac else local cac=_ac;local dac=0
while _ac<=d_c and dac<128 do aac=aca(b_c,_ac)
local _bc=1;while
_bc<128 and _ac+_bc<=d_c and aca(b_c,_ac+_bc)==aac do _bc=_bc+1 end;if _bc>=3 then break end
local abc=_da(_bc,128 -dac)_ac=_ac+abc;dac=dac+abc;if abc<_bc then break end end;c_c[#c_c+1]=_ca(dac-1)
c_c[#c_c+1]=bca(b_c,cac,_ac-1)end end;return table.concat(c_c)end
function dba.rleDecode(b_c,c_c)if type(b_c)~="string"then
__b("rleDecode expects a string",2)end;local d_c,_ac,aac=aab.new(b_c),{},0
while
d_c.pos<=d_c.size do local cac=d_c:u8("RLE control byte")
if cac<=127 then local dac=cac+1
_ac[#_ac+1]=d_c:take(dac,"RLE literal")aac=aac+dac elseif cac>=129 then local dac=257 -cac
_ac[#_ac+1]=cca(_ca(d_c:u8("RLE repeated byte")),dac)aac=aac+dac end;if c_c and aac>c_c then
__b("RLE output exceeds expected length",2)end end;local bac=table.concat(_ac)if c_c and#bac~=c_c then
__b("RLE produced "..#bac..
" bytes, expected "..c_c,2)end;return bac end;local function _cb(b_c,c_c,d_c)
return aca(b_c[1],d_c)~=aca(c_c[1],d_c)or aca(b_c[2],d_c)~=
aca(c_c[2],d_c)or aca(b_c[3],d_c)~=
aca(c_c[3],d_c)end
local function acb(b_c,c_c,d_c,_ac,aac,bac)if bac then return 1,
1,_ac,aac end;local cac,dac,_bc,abc=_ac+1,aac+1,0,0
for y=1,aac do
local bbc,cbc=c_c[y],d_c[y]
if bbc~=cbc then
for x=1,_ac do local dbc;if b_c=="pixel"then dbc=aca(bbc,x)~=aca(cbc,x)else
dbc=_cb(bbc,cbc,x)end
if dbc then if x<cac then cac=x end
if x>_bc then _bc=x end;if y<dac then dac=y end;if y>abc then abc=y end end end end end;if _bc==0 then return nil end;return cac,dac,_bc,abc end
local function bcb(b_c,c_c,d_c,_ac,aac,bac)local cac={}
if b_c=="pixel"then
for y=_ac,bac do cac[#cac+1]=bca(c_c[y],d_c,aac)end else for plane=1,3 do
for y=_ac,bac do cac[#cac+1]=bca(c_c[y][plane],d_c,aac)end end end;return table.concat(cac)end
local function ccb(b_c,c_c,d_c,_ac,aac,bac)local cac=dba.rleEncode(bac)local dac,_bc=dba.ENCODING_RAW,bac;if#cac<#bac then
dac,_bc=dba.ENCODING_RLE,cac end;return
table.concat({b_b(b_c),c_b(c_c-1),c_b(d_c-1),c_b(_ac-c_c+1),c_b(
aac-d_c+1),b_b(dac),_ab(#bac),_ab(#_bc),_bc})end
function dba.encode(b_c,c_c)local d_c=dbb(b_c)c_c=c_c or{}
local _ac=a_b(c_c.keyframeInterval or d_c.keyframeInterval,"keyframeInterval",1,255)local aac,bac={},{}
for frameIndex=1,#d_c.frames do
local bbc=frameIndex==1 or(frameIndex-1)%_ac==0;local cbc={}
for layerIndex=1,#d_c.layers do local _cc=d_c.layers[layerIndex]
local acc=d_c.frames[frameIndex].layers[layerIndex].rows
local bcc=frameIndex>1 and
d_c.frames[frameIndex-1].layers[layerIndex].rows or bbb(d_c.mode,_cc.width,_cc.height)
local ccc,dcc,_dc,adc=acb(d_c.mode,acc,bcc,_cc.width,_cc.height,bbc)if ccc then local bdc=bcb(d_c.mode,acc,ccc,dcc,_dc,adc)
cbc[#cbc+1]=ccb(layerIndex,ccc,dcc,_dc,adc,bdc)end end;local dbc=b_b(#cbc)..table.concat(cbc)
aac[frameIndex]=dbc
bac[frameIndex]={duration=d_c.frames[frameIndex].duration,keyframe=bbc,length=#dbc}end
local cac=(d_c.loop and 1 or 0)+ (d_c.pingPong and 2 or 0)
local dac={dba.MAGIC,b_b(dba.VERSION),b_b(bda[d_c.mode]),b_b(cac),c_b(d_c.width),c_b(d_c.height),b_b(
#d_c.palette),b_b(#d_c.layers),c_b(#d_c.frames),b_b(_ac),b_b(0)}for i=1,#d_c.palette do local bbc=d_c.palette[i]
dac[#dac+1]=_ca(dca(bbc/65536),dca(
bbc/256)%256,bbc%256)end
for i=1,#d_c.layers do
local bbc=d_c.layers[i]
dac[#dac+1]=table.concat({b_b(#bbc.name),bbc.name,d_b(bbc.x),d_b(bbc.y),c_b(bbc.width),c_b(bbc.height),d_b(bbc.z),b_b(
bbc.visible and 1 or 0)})end;local _bc,abc=0,{}
for i=1,#bac do local bbc=bac[i]
abc[i]=c_b(bbc.duration)..
b_b(bbc.keyframe and 1 or 0).._ab(_bc).._ab(bbc.length)_bc=_bc+bbc.length end;return
table.concat(dac)..table.concat(abc)..table.concat(aac)end;local function dcb(b_c,c_c,d_c)
return bca(b_c,1,c_c-1)..d_c..bca(b_c,c_c+#d_c)end
local function _db(b_c,c_c,d_c,_ac,aac,bac,cac)local dac=1
if b_c=="pixel"then for row=_ac,_ac+bac-1 do local _bc=bca(cac,dac,
dac+aac-1)
c_c[row]=dcb(c_c[row],d_c,_bc)dac=dac+aac end else
local _bc={{},{},{}}
for plane=1,3 do for row=_ac,_ac+bac-1 do
_bc[plane][row]=bca(cac,dac,dac+aac-1)dac=dac+aac end end;for row=_ac,_ac+bac-1 do local abc=c_c[row]
c_c[row]={dcb(abc[1],d_c,_bc[1][row]),dcb(abc[2],d_c,_bc[2][row]),dcb(abc[3],d_c,_bc[3][row])}end end end
function dba.decode(b_c)if type(b_c)~="string"then
__b("decode expects a binary string",2)end;local c_c=aab.new(b_c)
if
c_c:take(4,"magic")~=dba.MAGIC then __b("invalid magic bytes",2)end;local d_c=c_c:u8("version")if d_c~=dba.VERSION then
__b("unsupported version "..d_c,2)end;local _ac=c_c:u8("mode")local aac=cda[_ac]
if
not aac then __b("unsupported mode ".._ac,2)end;local bac=c_c:u8("flags")
local cac,dac=c_c:u16("width"),c_c:u16("height")if cac==0 or dac==0 then
__b("canvas dimensions must be non-zero",2)end
local _bc,abc=c_c:u8("palette count"),c_c:u8("layer count")local bbc=c_c:u16("frame count")
local cbc=c_c:u8("keyframe interval")c_c:u8("reserved byte")if _bc==0 or abc==0 or bbc==0 then
__b("palette, layer, and frame counts must be non-zero",2)end;if cbc==0 then
__b("keyframe interval must be non-zero",2)end;local dbc={}
for i=1,_bc do
local _dc,adc,bdc=aca(c_c:take(3,"palette"),1,3)dbc[i]=_dc*65536 +adc*256 +bdc end;local _cc={}
for i=1,abc do local _dc=c_c:u8("layer name length")
local adc={name=c_c:take(_dc,"layer name"),x=c_c:i16("layer x"),y=c_c:i16("layer y"),width=c_c:u16("layer width"),height=c_c:u16("layer height"),z=c_c:i16("layer z"),visible=bab(c_c:u8("layer flags"),1)}if adc.width==0 or adc.height==0 then
__b("layer dimensions must be non-zero",2)end;_cc[i]=adc end;local acc={}
for i=1,bbc do
acc[i]={duration=c_c:u16("frame duration"),keyframe=bab(c_c:u8("frame flags"),1),offset=c_c:u32("frame offset"),length=c_c:u32("frame length")}if acc[i].duration==0 then
__b("frame duration must be non-zero",2)end end;local bcc=c_c.pos;local ccc,dcc={},{}for i=1,abc do
dcc[i]=bbb(aac,_cc[i].width,_cc[i].height)end
for frameIndex=1,bbc do local _dc=acc[frameIndex]if
_dc.offset+_dc.length>c_c.size-bcc+1 then
__b("frame "..
frameIndex.." points outside the file",2)end
local adc=aab.new(bca(b_c,bcc+_dc.offset,
bcc+_dc.offset+_dc.length-1))local bdc={}for layerIndex=1,abc do
bdc[layerIndex]=_dc.keyframe and
bbb(aac,_cc[layerIndex].width,_cc[layerIndex].height)or cbb(aac,dcc[layerIndex])end
local cdc=adc:u8("frame patch count")local ddc={}
for patchIndex=1,cdc do local a_d=adc:u8("patch layer")local b_d=_cc[a_d]
if not b_d then __b(
"patch references missing layer "..a_d,2)end;if ddc[a_d]then
__b("frame has multiple patches for layer "..a_d,2)end;ddc[a_d]=true;local c_d,d_d=adc:u16("patch x")+1,
adc:u16("patch y")+1
local _ad,aad=adc:u16("patch width"),adc:u16("patch height")local bad=adc:u8("patch encoding")
local cad,dad=adc:u32("raw length"),adc:u32("payload length")if _ad==0 or aad==0 or c_d+_ad-1 >b_d.width or
d_d+aad-1 >b_d.height then
__b("patch lies outside layer "..a_d,2)end;local _bd=_ad*aad* (
aac=="cell"and 3 or 1)if cad~=_bd then
__b("patch raw length does not match its dimensions",2)end
local abd=adc:take(dad,"patch payload")local bbd
if bad==dba.ENCODING_RAW then bbd=abd;if#bbd~=cad then
__b("raw patch length mismatch",2)end elseif bad==dba.ENCODING_RLE then
bbd=dba.rleDecode(abd,cad)else
__b("unsupported patch encoding "..bad,2)end;if aac=="pixel"then dab(bbd,1,"pixel patch",_bc)else
dab(bbd,_ad*aad+1,"cell color patch",_bc)end
_db(aac,bdc[a_d],c_d,d_d,_ad,aad,bbd)end;if adc.pos~=adc.size+1 then
__b("unused bytes in frame "..frameIndex,2)end
if _dc.keyframe then for layerIndex=1,abc do
if not ddc[layerIndex]then __b(
"keyframe omits layer "..layerIndex,2)end end end;local __d={duration=_dc.duration,layers={}}
for layerIndex=1,abc do
__d.layers[layerIndex]={rows=bdc[layerIndex]}dcc[layerIndex]=bdc[layerIndex]end;ccc[frameIndex]=__d end
return
{format="FLIMG",version=d_c,mode=aac,width=cac,height=dac,palette=dbc,layers=_cc,frames=ccc,loop=bab(bac,1),pingPong=bab(bac,2),keyframeInterval=cbc}end
local function adb(b_c)
if fs and fs.open then
local aac=fs.open(b_c,"rb")or fs.open(b_c,"r")if not aac then
__b("cannot open "..tostring(b_c),2)end;local bac=aac.readAll()aac.close()
return bac end;local c_c,d_c=io.open(b_c,"rb")if not c_c then
__b("cannot open "..tostring(b_c)..
": "..tostring(d_c),2)end;local _ac=c_c:read("*a")
c_c:close()return _ac end
local function bdb(b_c,c_c)
if fs and fs.open then
local aac=fs.open(b_c,"wb")or fs.open(b_c,"w")if not aac then
__b("cannot write "..tostring(b_c),2)end;aac.write(c_c)aac.close()return end;local d_c,_ac=io.open(b_c,"wb")if not d_c then
__b("cannot write "..tostring(b_c)..
": "..tostring(_ac),2)end;d_c:write(c_c)
d_c:close()end;function dba.load(b_c)return dba.decode(adb(b_c))end;function dba.save(b_c,c_c,d_c)
local _ac=dba.encode(c_c,d_c)bdb(b_c,_ac)return#_ac end
local function cdb(b_c,c_c,d_c,_ac,aac)local bac={}for offset=0,
aac-1 do local cac=aca(c_c,_ac+offset)
bac[offset+1]=cac==0 and bca(b_c,d_c+offset,d_c+
offset)or _ca(cac)end;return

bca(b_c,1,d_c-1)..table.concat(bac)..bca(b_c,d_c+aac)end
function dba.compose(b_c,c_c)
b_c=b_c.format=="FLIMG"and b_c or dbb(b_c)local d_c=b_c.frames[c_c or 1]
if not d_c then __b("frame "..
tostring(c_c).." does not exist",2)end;local _ac=bbb(b_c.mode,b_c.width,b_c.height)local aac={}for i=1,#b_c.layers
do aac[i]=i end
table.sort(aac,function(bac,cac)
local dac,_bc=b_c.layers[bac],b_c.layers[cac]
return dac.z==_bc.z and bac<cac or dac.z<_bc.z end)
for bac,cac in ipairs(aac)do local dac=b_c.layers[cac]
if dac.visible then
local _bc=d_c.layers[cac].rows;local abc=ada(1,2 -dac.x)
local bbc=_da(dac.width,b_c.width-dac.x+1)
for sy=1,dac.height do local cbc=dac.y+sy-1
if
cbc>=1 and cbc<=b_c.height and abc<=bbc then local dbc,_cc=dac.x+abc-1,bbc-abc+1
if b_c.mode=="pixel"then
_ac[cbc]=cdb(_ac[cbc],_bc[sy],dbc,abc,_cc)else local acc=_ac[cbc]
_ac[cbc]={cdb(acc[1],_bc[sy][1],dbc,abc,_cc),cdb(acc[2],_bc[sy][2],dbc,abc,_cc),cdb(acc[3],_bc[sy][3],dbc,abc,_cc)}end end end end end;return _ac end
local function ddb(b_c,c_c,d_c)local _ac=c_c[d_c]if _ac then return _ac end;if#b_c>=255 then
__b("imported image uses more than 255 colors",2)end;b_c[#b_c+1]=d_c;c_c[d_c]=#b_c;return#
b_c end
function dba.fromBimg(b_c)if
type(b_c)~="table"or type(b_c[1])~="table"or type(b_c[1][1])~="table"then
__b("invalid BIMG table",2)end;local c_c,d_c=#b_c[1][1][1],
#b_c[1]local _ac,aac={},{}
local function bac(dac)local _bc=tonumber(dac,16)return _bc and
ddb(_ac,aac,dda[_bc])or 0 end;local cac={}
for frameIndex=1,#b_c do local dac,_bc=b_c[frameIndex],{}if#dac~=d_c then
__b("BIMG frame dimensions differ",2)end
for y=1,d_c do local abc=dac[y]
if
type(abc)~="table"or
#abc[1]~=c_c or#abc[2]~=c_c or#abc[3]~=c_c then __b("invalid BIMG line",2)end;local bbc,cbc={},{}
for x=1,c_c do
bbc[x]=_ca(bac(abc[2]:sub(x,x)))cbc[x]=_ca(bac(abc[3]:sub(x,x)))end
_bc[y]={abc[1],table.concat(bbc),table.concat(cbc)}end
cac[frameIndex]={duration=dca(( (b_c.secondsPerFrame or 0.2)*1000)+0.5),layers={{rows=_bc}}}end;return
dbb({mode="cell",width=c_c,height=d_c,palette=_ac,layers={{name="BIMG"}},frames=cac,loop=true})end;local function __c(b_c,c_c)return
type(b_c)=="string"and b_c:sub(c_c,c_c)or b_c[c_c]end
local function a_c(b_c)
if
type(b_c)~="number"or b_c<1 or b_c>32768 then return nil end;local c_c=1
for index=0,15 do if b_c==c_c then return index end;c_c=c_c*2 end end
function dba.fromSprite(b_c,c_c)c_c=c_c or{}if type(b_c)~="table"then
__b("invalid sprite table",2)end
local d_c=a_b(b_c.width,"sprite width",1,65535)local _ac=a_b(b_c.height,"sprite height",1,65535)
local aac=a_b(b_c.frameCount or
#b_c,"sprite frame count",1,65535)local bac,cac={},{}
local function dac(abc)if
abc==nil or abc==false or abc==" "or abc==""then return 0 end;if c_c.resolveColor then
abc=c_c.resolveColor(abc)end
if type(abc)=="string"and#abc==1 then
local cbc=tonumber(abc,16)if cbc then return ddb(bac,cac,dda[cbc])end end;local bbc=a_c(abc)if bbc then return ddb(bac,cac,dda[bbc])end;return
ddb(bac,cac,cab(abc,"sprite color"))end;local _bc={}
for frameIndex=1,aac do local abc=b_c[frameIndex]
if
type(abc)~="table"or not abc[1]or not abc[2]or not abc[3]then
__b(
"sprite frame "..frameIndex.." must have character, foreground, and background layers",2)end;local bbc={}
for y=1,_ac do local cbc,dbc,_cc=abc[1][y],abc[2][y],abc[3][y]if
type(cbc)~="table"and type(cbc)~="string"then
__b("invalid sprite character row",2)end;local acc,bcc,ccc={},{},{}
for x=1,d_c do
local dcc=__c(cbc,x)if type(dcc)~="string"or#dcc~=1 then
__b("invalid sprite character",2)end
acc[x]=dcc==" "and"\0"or dcc;bcc[x]=_ca(dac(__c(dbc,x)))
ccc[x]=_ca(dac(__c(_cc,x)))end
bbc[y]={table.concat(acc),table.concat(bcc),table.concat(ccc)}end
_bc[frameIndex]={duration=dca((
(b_c.secondsPerFrame or c_c.secondsPerFrame or 0.1)*1000)+0.5),layers={{rows=bbc}}}end;if#bac==0 then bac[1]=dda[15]end;return
dbb({mode="cell",width=d_c,height=_ac,palette=bac,layers={{name="Sprite"}},frames=_bc,loop=
b_c.loop~=false})end;return dba
]=]
paths["flimg"] = "flimg"
sources["core.ai"] = [=[
local aa={}local ba={}
function ba.new(ab,bb,cb)
assert(ab=="once"or ab=="repeat","BrainTimer.new — invalid kind '"..
tostring(ab).."'")
assert(type(bb)=="number"and bb>=0,"BrainTimer.new — invalid seconds (must be non-negative number)")
assert(type(cb)=="function","BrainTimer.new — fn must be a function")
return{kind=ab,interval=(ab=="repeat")and bb or nil,remaining=bb,fn=cb}end;local ca={}
function ca.new(ab,bb,cb)
assert(type(ab)=="string","BrainTransition.new — from must be a string")
assert(type(bb)=="string","BrainTransition.new — to must be a string")
assert(type(cb)=="function","BrainTransition.new — cond must be a function")return{from=ab,to=bb,cond=cb}end;local da={}
function da.new(ab,bb,cb,db)return{onEnter=ab,onUpdate=bb,onExit=cb,onDraw=db}end;local _b={}_b.__index=_b
function _b.new(ab,bb,cb)local db=setmetatable({},_b)
db._states=ab or{}db._transitions={}db._stack={}db._timers={}db.current=nil
db.previousState=nil;db.timer=0;db.memory={}db.id=nil;db.scene=nil;if cb then
for _c,ac in pairs(cb)do db[_c]=ac end end;if bb then db:start(bb)end;return db end
function _b:addState(ab,bb)
assert(type(ab)=="string","Brain:addState — name must be a string")local db=bb or{}
self._states[ab]=da.new(db.onEnter,db.onUpdate,db.onExit,db.onDraw)end;function _b:addTransition(ab,bb,cb)
table.insert(self._transitions,ca.new(ab,bb,cb))end
function _b:start(ab)
assert(self._states[ab],
"Brain:start — unknown state '"..tostring(ab).."'")self._stack={ab}self._timers={}self.current=ab;self.previousState=nil
self.timer=0;local bb=self._states[ab]
if bb and bb.onEnter then bb.onEnter(self,nil)end end
function _b:go(ab)
assert(self._states[ab],"Brain:go — unknown state '"..tostring(ab).."'")if ab==self.current then return end;local bb=self.current
if bb then
local db=self._states[bb]if db and db.onExit then db.onExit(self,ab)end end
if#self._stack==0 then table.insert(self._stack,ab)else self._stack[#
self._stack]=ab end;self.previousState=bb;self.current=ab;self.timer=0;self._timers={}
local cb=self._states[ab]if cb and cb.onEnter then cb.onEnter(self,bb)end end
function _b:push(ab)
assert(self._states[ab],"Brain:push — unknown state '"..tostring(ab).."'")local bb=self.current;if bb then local db=self._states[bb]if db and db.onExit then
db.onExit(self,ab)end end
table.insert(self._stack,ab)self.previousState=bb;self.current=ab;self.timer=0;self._timers={}
local cb=self._states[ab]if cb and cb.onEnter then cb.onEnter(self,bb)end end
function _b:pop()if#self._stack<=1 then return end;local ab=self.current
local bb=self._states[ab]table.remove(self._stack)
local cb=self._stack[#self._stack]if bb and bb.onExit then bb.onExit(self,cb)end
self.previousState=ab;self.current=cb;self.timer=0;self._timers={}
local db=self._states[cb]if db and db.onEnter then db.onEnter(self,ab)end end;function _b:after(ab,bb)
table.insert(self._timers,ba.new("once",ab,bb))end;function _b:every(ab,bb)
table.insert(self._timers,ba.new("repeat",ab,bb))end
function _b:_tickTimers(ab)local bb=1
while
bb<=#self._timers do local cb=self._timers[bb]cb.remaining=cb.remaining-ab
if
cb.remaining<=0 then cb.fn(self)if cb.kind=="repeat"then cb.remaining=cb.interval;bb=bb+1 else
table.remove(self._timers,bb)end else bb=bb+1 end end end
function _b:update(ab)if not self.current then return end;for cb,db in ipairs(self._transitions)do
if db.from==
self.current and db.cond(self)then self:go(db.to)break end end
self.timer=self.timer+ab;self:_tickTimers(ab)
local bb=self._states[self.current]
if bb and bb.onUpdate then local cb=bb.onUpdate(self,ab)if
cb and cb~=self.current then self:go(cb)end end end
function _b:draw()if not self.current then return end
local ab=self._states[self.current]if ab and ab.onDraw then ab.onDraw(self)end end;function _b:is(ab)return self.current==ab end;function _b:was(ab)return
self.previousState==ab end
function _b:timeInState()return self.timer end;function _b:stackDepth()return#self._stack end
function _b:stateCount()local ab=0;for bb in
pairs(self._states)do ab=ab+1 end;return ab end
function aa.canSee(ab,bb,cb,db,_c)local ac=cb.components.pos[ab]
local bc=cb.components.pos[bb]if not ac or not bc then return false end;if
db and ac:dist(bc)>db then return false end
local cc,dc,_d,ad=cb:castRay(ac.x,ac.y,bc.x,bc.y,db or 100,ab,_c)return(not cc)or(ad==bb)end
function aa.canHear(ab,bb,cb,db)local _c=cb.components.pos[ab]
local ac=cb.components.pos[bb]if not _c or not ac then return false end
return _c:dist(ac)<=db end
function aa.nearest(ab,bb,cb,db)local _c=bb.components.pos[ab]
if not _c then return nil,nil end;local ac,bc=nil,db or math.huge;local cc=bb.components.tags
local dc=bb.components.pos
for _d,ad in pairs(dc)do if _d~=ab then
local bd=not cb or(cc and cc[_d]and cc[_d][cb])
if bd then local cd=_c:dist(ad)if cd<bc then bc=cd;ac=_d end end end end;return ac,bc end
function aa.system(ab)
return
function(bb,cb,db)local _c=db.brain;if not _c then return end
for ac,bc in ipairs(cb)do local cc=_c[bc]if cc then cc.id=bc
cc.scene=ab;cc:update(bb)end end end end;aa.Brain=_b;aa.BrainState=da;aa.BrainTimer=ba;aa.BrainTransition=ca;return aa
]=]
paths["core.ai"] = "core/ai"
sources["core.audio"] = [=[
local _a=...local aa=_a("core.logger")local ba=_a("core.thread")
local ca={_speakers={},_initialized=false,_currentSong=nil,_songThread=nil,_sfxLibrary={},_muted=false,_masterVolume=1.0}
function ca.refresh()
ca._speakers={peripheral.find("speaker")}ca._initialized=true
if#ca._speakers==0 then
aa.warn("Audio: No speakers found. Audio disabled.")else
aa.info(string.format("Audio: %d speaker(s) detected.",#ca._speakers))end end
function ca.isReady()return ca._initialized and#ca._speakers>0 end;function ca.getSpeakerCount()return#ca._speakers end;function ca.setMuted(da)
ca._muted=da==true end;function ca.isMuted()return ca._muted end;function ca.setVolume(da)
ca._masterVolume=math.max(0,math.min(1,da))end
function ca.getVolume()return ca._masterVolume end
function ca.playNote(da,_b,ab)if ca._muted then return end
if not ca._initialized then ca.refresh()end;if#ca._speakers==0 then return end
local bb=math.max(0,math.min(3,(ab or 1)*ca._masterVolume))local cb=da or"harp"local db=_b or 12
for _c,ac in ipairs(ca._speakers)do pcall(function()
ac.playNote(cb,bb,db)end)end end;function ca.registerSfx(da,_b)if not da or type(_b)~="table"then
aa.error("Audio: Invalid SFX registration")return end
ca._sfxLibrary[da]=_b end
function ca.playSfx(da)
local _b=ca._sfxLibrary[da]if not _b then
aa.error("Audio: Unknown SFX '"..tostring(da).."'")return end
ba.start(function()for ab,bb in ipairs(_b)do if bb.delay then
os.sleep(bb.delay)end
ca.playNote(bb.instrument,bb.pitch,bb.volume)end end)end
function ca.hasSfx(da)return ca._sfxLibrary[da]~=nil end;function ca.unregisterSfx(da)ca._sfxLibrary[da]=nil end;function ca.getSfxList()
local da={}
for _b in pairs(ca._sfxLibrary)do table.insert(da,_b)end;return da end
function ca.playSong(da,_b)if not da then
aa.error("Audio: playSong called with nil songData")return end;if
not da.tempo or da.tempo<=0 then
aa.error("Audio: Invalid or missing tempo in songData")return end;ca.stopSong()
ca._currentSong=da
ca._songThread=ba.start(function()local ab=1 /da.tempo;local bb=true
while bb do
for tick=0,da.length do
if ca._currentSong~=da then return end;local cb=da.ticks[tick]
if cb then for db,_c in ipairs(cb)do
ca.playNote(_c.instrument,_c.pitch,_c.volume)end end;os.sleep(ab)end;if not _b then bb=false end end end)end
function ca.stopSong()
if ca._songThread then ba.stop(ca._songThread)ca._songThread=nil end;ca._currentSong=nil end;function ca.isSongPlaying()return ca._currentSong~=nil end;function ca.getCurrentSong()return
ca._currentSong end
function ca.stopAll()ca.stopSong()end;return ca
]=]
paths["core.audio"] = "core/audio"
sources["core.buffer"] = [=[
local daa=...local _ba=daa("core.color")local aba=daa("flimg")local bba={}
local cba=_ba.encode("0")local dba=_ba.encode("f")local _ca,aca=string.rep,string.char
local bca=table.move or
function(bcb,ccb,dcb,_db,adb)
adb=adb or bcb;if adb==bcb and _db>ccb and _db<=dcb then for i=dcb,ccb,-1 do
adb[_db+i-ccb]=bcb[i]end else
for i=ccb,dcb do adb[_db+i-ccb]=bcb[i]end end;return adb end;local cca={}cca.__index=cca;local dca={}dca.__index=dca;local _da={}for mask=0,31 do
_da[mask]=string.char(128 +mask)end;local ada={}
local function bda(bcb,ccb,dcb)
local _db=_ba.getRGB(bcb:byte())local cdb=_ba.getRGB(ccb:byte())
local ddb=_ba.getRGB(dcb:byte())
local __c,a_c,b_c=_db[1]-cdb[1],_db[2]-cdb[2],_db[3]-cdb[3]
local c_c,d_c,_ac=_db[1]-ddb[1],_db[2]-ddb[2],_db[3]-ddb[3]local aac=__c*__c+a_c*a_c+b_c*b_c;local bac=
c_c*c_c+d_c*d_c+_ac*_ac;return aac<=bac and 0 or 1 end
local function cda(bcb,ccb,dcb,_db,adb,bdb)local cdb=bcb..ccb..dcb.._db..adb..bdb
local ddb=ada[cdb]if ddb then return ddb[1],ddb[2],ddb[3]end
local __c={bcb,ccb,dcb,_db,adb,bdb}local a_c,b_c={},{}
for i=1,6 do local _bc=__c[i]if a_c[_bc]==nil then a_c[_bc]=1
b_c[#b_c+1]=_bc else a_c[_bc]=a_c[_bc]+1 end end;local c_c,d_c;for _bc,abc in ipairs(b_c)do
if not c_c or a_c[abc]>a_c[c_c]then d_c,c_c=c_c,abc elseif
not d_c or a_c[abc]>a_c[d_c]then d_c=abc end end
if not d_c then
ddb={" ",c_c,c_c}ada[cdb]=ddb;return ddb[1],ddb[2],ddb[3]end;local _ac={}
for i=1,6 do local _bc=__c[i]if _bc==c_c then _ac[i]=0 elseif _bc==d_c then _ac[i]=1 else
_ac[i]=bda(_bc,c_c,d_c)end end;local aac=_ac[6]local bac=0;if _ac[1]~=aac then bac=bac+1 end;if _ac[2]~=aac then
bac=bac+2 end;if _ac[3]~=aac then bac=bac+4 end;if _ac[4]~=aac then
bac=bac+8 end;if _ac[5]~=aac then bac=bac+16 end;local cac,dac;if aac==0 then
cac,dac=d_c,c_c else cac,dac=c_c,d_c end;ddb={_da[bac],cac,dac}
ada[cdb]=ddb;return ddb[1],ddb[2],ddb[3]end
local function dda(bcb,ccb,dcb,_db,adb)local bdb,cdb,ddb={},{},{}
for y=1,ccb do local __c,a_c,b_c={},{},{}
if
dcb~=nil or _db~=nil or adb~=nil then for x=1,bcb do __c[x],a_c[x],b_c[x]=dcb,_db,adb end end;bdb[y],cdb[y],ddb[y]=__c,a_c,b_c end;return bdb,cdb,ddb end
local function __b(bcb)local ccb=bcb._owner;bcb._ox,bcb._oy=0,0;bcb._clipX1,bcb._clipY1=1,1
bcb._clipX2,bcb._clipY2=ccb._w,ccb._h;bcb._stack,bcb._stackN={},0 end
local function a_b(bcb,ccb,dcb,_db,adb)local bdb=bcb._owner;ccb,dcb=math.max(1,ccb),math.max(1,dcb)
_db,adb=math.min(bdb._w,_db),math.min(bdb._h,adb)if ccb>_db or dcb>adb then return end;if ccb<bcb._dirtyX1 then
bcb._dirtyX1=ccb end
if dcb<bcb._dirtyY1 then bcb._dirtyY1=dcb end;if _db>bcb._dirtyX2 then bcb._dirtyX2=_db end;if adb>bcb._dirtyY2 then
bcb._dirtyY2=adb end end;local function b_b(bcb)bcb._dirtyX1,bcb._dirtyY1=math.huge,math.huge
bcb._dirtyX2,bcb._dirtyY2=0,0 end
local function c_b(bcb)local ccb=bcb._owner
if bcb._opaque then
bcb._text,bcb._fg,bcb._bg=dda(ccb._w,ccb._h," ",cba,dba)else bcb._text,bcb._fg,bcb._bg=dda(ccb._w,ccb._h)end;bcb._spFg,bcb._spBg,bcb._spBits=nil,nil,nil
bcb._spX1,bcb._spY1=math.huge,math.huge;bcb._spX2,bcb._spY2=0,0;__b(bcb)b_b(bcb)
a_b(bcb,1,1,ccb._w,ccb._h)end
local function d_b(bcb,ccb,dcb,_db)
local adb=setmetatable({_owner=bcb,name=ccb,zIndex=dcb or 0,visible=true,_opaque=_db==true,_sequence=bcb._nextSequence},dca)bcb._nextSequence=bcb._nextSequence+1;c_b(adb)return adb end;local function _ab(bcb,ccb,dcb)
return
ccb>=bcb._clipX1 and ccb<=bcb._clipX2 and dcb>=bcb._clipY1 and dcb<=bcb._clipY2 end;local function aab(bcb,ccb,dcb)if
bcb._opaque and ccb==nil then return _ba.encode(dcb)end
return _ba.encode(ccb)end
local function bab(bcb)
if bcb._spBits then return end;bcb._spFg,bcb._spBg,bcb._spBits={},{},{}end
local function cab(bcb)return(bcb._clipX1 -1)*2 +1, (bcb._clipY1 -1)*3 +1,
bcb._clipX2 *2,bcb._clipY2 *3 end
local function dab(bcb,ccb,dcb,_db,adb)local bdb=bcb._owner._w*2;local cdb=(dcb-1)*bdb+ccb
bcb._spFg[cdb]=_db;if adb~=nil then bcb._spBg[cdb]=adb end
bcb._spBits[cdb]=true end
local function _bb(bcb,ccb,dcb,_db,adb)local bdb=math.floor((ccb+1)/2)
local cdb=math.floor((dcb+2)/3)local ddb=math.floor((_db+1)/2)
local __c=math.floor((adb+2)/3)if bdb<bcb._spX1 then bcb._spX1=bdb end;if cdb<bcb._spY1 then
bcb._spY1=cdb end;if ddb>bcb._spX2 then bcb._spX2=ddb end;if
__c>bcb._spY2 then bcb._spY2=__c end;a_b(bcb,bdb,cdb,ddb,__c)end
local function abb(bcb,ccb)
if type(bcb)=="string"then return bcb:sub(ccb,ccb)end;return bcb and bcb[ccb]or nil end
function dca:getSize()return self._owner._w,self._owner._h end;function dca:getVirtualSize()
return self._owner._w*2,self._owner._h*3 end
function dca:setVisible(bcb)bcb=bcb~=false
if
self.visible~=bcb then self.visible=bcb;self._owner:_markFullComposition()end;return self end
function dca:setZIndex(bcb)bcb=tonumber(bcb)or 0
if self.zIndex~=bcb then self.zIndex=bcb
self._owner:_sortLayers()self._owner:_markFullComposition()end;return self end
function dca:push(bcb,ccb,dcb,_db)
bcb,ccb=math.floor(bcb or 1),math.floor(ccb or 1)dcb,_db=math.floor(dcb or 0),math.floor(_db or 0)
local adb,bdb=self._stackN,self._stack;bdb[adb+1],bdb[adb+2]=self._ox,self._oy
bdb[adb+3],bdb[adb+4]=self._clipX1,self._clipY1;bdb[adb+5],bdb[adb+6]=self._clipX2,self._clipY2
self._stackN=adb+6;local cdb,ddb=self._ox+bcb-1,self._oy+ccb-1
self._ox,self._oy=cdb,ddb;self._clipX1=math.max(self._clipX1,cdb+1)self._clipY1=math.max(self._clipY1,
ddb+1)
self._clipX2=math.min(self._clipX2,cdb+dcb)self._clipY2=math.min(self._clipY2,ddb+_db)return self end
function dca:pop()local bcb,ccb=self._stackN,self._stack;if bcb<6 then
error("Obsidian Buffer: clip stack underflow",2)end
self._ox,self._oy=ccb[bcb-5],ccb[bcb-4]self._clipX1,self._clipY1=ccb[bcb-3],ccb[bcb-2]self._clipX2,self._clipY2=ccb[
bcb-1],ccb[bcb]for i=bcb-5,bcb do ccb[i]=nil end;self._stackN=
bcb-6;return self end
function dca:setClip(bcb,ccb,dcb,_db)local adb=self._owner
self._clipX1=math.max(1,math.floor(bcb or 1))
self._clipY1=math.max(1,math.floor(ccb or 1))
self._clipX2=math.min(adb._w,math.floor(dcb or adb._w))
self._clipY2=math.min(adb._h,math.floor(_db or adb._h))return self end;function dca:clearClip()local bcb=self._owner;self._clipX1,self._clipY1=1,1
self._clipX2,self._clipY2=bcb._w,bcb._h;return self end
function dca:clear(bcb,ccb,dcb)
local _db=self._owner;local adb,bdb,cdb
if self._opaque then
adb=bcb==nil and" "or tostring(bcb):sub(1,1)bdb=_ba.encode(ccb,"0")or cba
cdb=_ba.encode(dcb,"f")or dba else adb=
bcb~=nil and bcb~=false and tostring(bcb):sub(1,1)or nil
bdb=_ba.encode(ccb)cdb=_ba.encode(dcb)end
self._text,self._fg,self._bg=dda(_db._w,_db._h,adb,bdb,cdb)self._spFg,self._spBg,self._spBits=nil,nil,nil
self._spX1,self._spY1=math.huge,math.huge;self._spX2,self._spY2=0,0;a_b(self,1,1,_db._w,_db._h)
return self end
function dca:drawText(bcb,ccb,dcb,_db,adb)bcb,ccb=math.floor(bcb or 1)+self._ox,
math.floor(ccb or 1)+self._oy
dcb=tostring(dcb or"")if
ccb<self._clipY1 or ccb>self._clipY2 or#dcb==0 then return self end;local bdb=1
local cdb,ddb=bcb,bcb+#dcb-1;if cdb<self._clipX1 then bdb=bdb+self._clipX1 -cdb
cdb=self._clipX1 end
ddb=math.min(ddb,self._clipX2)if cdb>ddb then return self end;local __c=aab(self,_db,"0")
local a_c=aab(self,adb,"f")local b_c,c_c,d_c=self._text[ccb],self._fg[ccb],self._bg[ccb]
for tx=cdb,ddb
do b_c[tx]=dcb:sub(bdb,bdb)if __c~=nil then c_c[tx]=__c end;if
a_c~=nil then d_c[tx]=a_c end;bdb=bdb+1 end;a_b(self,cdb,ccb,ddb,ccb)return self end
function dca:drawLine(bcb,ccb,dcb,_db)local adb=self._owner._w;ccb=tostring(ccb or"")if#ccb<adb then ccb=
ccb.._ca(" ",adb-#ccb)elseif#ccb>adb then
ccb=ccb:sub(1,adb)end
return self:drawText(1,bcb,ccb,dcb,_db)end
function dca:drawRect(bcb,ccb,dcb,_db,adb,bdb,cdb)
dcb,_db=math.floor(dcb or 0),math.floor(_db or 0)if dcb<=0 or _db<=0 then return self end
local ddb=tostring(adb or" ")local __c;if#ddb==1 then __c=_ca(ddb,dcb)else
__c=(ddb.._ca(" ",dcb)):sub(1,dcb)end;for dy=0,_db-1 do
self:drawText(bcb,ccb+dy,__c,bdb,cdb)end;return self end
function dca:drawSprite(bcb,ccb,dcb,_db,adb)if
not bcb or not bcb[1]or not bcb[2]or not bcb[3]then return self end;local bdb=
math.floor((ccb or 1)- (_db or 0))+self._ox
local cdb=math.floor((dcb or 1)-
(adb or 0))+self._oy
for rowIndex=1,#bcb[1]do local ddb=cdb+rowIndex-1
if ddb>=self._clipY1 and
ddb<=self._clipY2 then local __c=bcb[1][rowIndex]
local a_c=bcb[2][rowIndex]local b_c=bcb[3][rowIndex]local c_c=type(__c)=="string"and#__c or#
(__c or{})
local d_c,_ac,aac=self._text[ddb],self._fg[ddb],self._bg[ddb]local bac,cac=math.huge,0
for column=1,c_c do local dac=bdb+column-1
if _ab(self,dac,ddb)then local _bc=false
local abc=abb(__c,column)local bbc=abb(a_c,column)local cbc=abb(b_c,column)if abc and abc~=" "then
d_c[dac],_bc=abc,true end;if bbc and bbc~=" "then
_ac[dac],_bc=_ba.encode(bbc),true end;if cbc and cbc~=" "then
aac[dac],_bc=_ba.encode(cbc),true end;if _bc then if dac<bac then bac=dac end
if dac>cac then cac=dac end end end end;if bac<=cac then a_b(self,bac,ddb,cac,ddb)end end end;return self end
local function bbb(bcb)if bcb._obsidianPalette then return bcb._obsidianPalette end;local ccb={}
for paletteIndex=1,#
bcb.palette do local dcb,_db=bcb.palette[paletteIndex]for nativeIndex=0,15 do
if dcb==
aba.NATIVE_RGB[nativeIndex]then _db=_ba.encode(2 ^nativeIndex)break end end;ccb[paletteIndex]=_db or
_ba.encode(_ba.rgb(dcb))end;bcb._obsidianPalette=ccb
bcb._composedFrames=bcb._composedFrames or{}return ccb end
function dca:drawImage(bcb,ccb,dcb,_db,adb,bdb)if type(bcb)~="table"or bcb.format~="FLIMG"then
error("Obsidian: drawImage expects a decoded FLIMG image",2)end;_db=math.max(1,math.min(#
bcb.frames,_db or 1))
local cdb=
bcb._composedFrames and bcb._composedFrames[_db]
if not cdb then cdb=aba.compose(bcb,_db)
bcb._composedFrames=bcb._composedFrames or{}bcb._composedFrames[_db]=cdb end;local ddb=bbb(bcb)
local __c=math.floor((ccb or 1)- (adb or 0))+self._ox
local a_c=math.floor((dcb or 1)- (bdb or 0))+self._oy
if bcb.mode=="pixel"then local b_c,c_c,d_c,_ac=cab(self)
local aac,bac=(__c-1)*2,(a_c-1)*3;local cac,dac,_bc,abc=math.huge,math.huge,0,0
for sourceY=1,bcb.height do local bbc=bac+sourceY
if bbc>=c_c and
bbc<=_ac then local cbc=cdb[sourceY]
for sourceX=1,bcb.width do
local dbc,_cc=aac+sourceX,cbc:byte(sourceX)
if _cc~=0 and dbc>=b_c and dbc<=d_c then local acc=ddb[_cc]if not acc then
error(
"Obsidian: FLIMG palette index ".._cc.." is missing",2)end;bab(self)
dab(self,dbc,bbc,acc)if dbc<cac then cac=dbc end;if bbc<dac then dac=bbc end
if dbc>_bc then _bc=dbc end;if bbc>abc then abc=bbc end end end end end;if cac<=_bc then _bb(self,cac,dac,_bc,abc)end;return self end
for sourceY=1,bcb.height do local b_c=a_c+sourceY-1
if
b_c>=self._clipY1 and b_c<=self._clipY2 then local c_c,d_c,_ac=cdb[sourceY],math.huge,0
for sourceX=1,bcb.width do local aac=__c+sourceX-1
if
_ab(self,aac,b_c)then local bac=c_c[1]:byte(sourceX)
local cac,dac=c_c[2]:byte(sourceX),c_c[3]:byte(sourceX)local _bc=false
if bac~=0 then self._text[b_c][aac],_bc=aca(bac),true end
if cac~=0 then self._fg[b_c][aac],_bc=ddb[cac],true end
if dac~=0 then self._bg[b_c][aac],_bc=ddb[dac],true end
if _bc then if aac<d_c then d_c=aac end;if aac>_ac then _ac=aac end end end end;if d_c<=_ac then a_b(self,d_c,b_c,_ac,b_c)end end end;return self end
function dca:drawSubpixel(bcb,ccb,dcb,_db)bcb,ccb=math.floor(bcb or 1)+self._ox*2,
math.floor(ccb or 1)+self._oy*3
local adb,bdb,cdb,ddb=cab(self)if bcb<adb or bcb>cdb or ccb<bdb or ccb>ddb then
return self end;local __c=_ba.encode(dcb)
if not __c then return self end;local a_c;if _db~=nil and _db~=false and _db~=" "then
a_c=_ba.encode(_db)end;bab(self)
dab(self,bcb,ccb,__c,a_c)_bb(self,bcb,ccb,bcb,ccb)return self end
function dca:drawSubpixelRect(bcb,ccb,dcb,_db,adb,bdb)
dcb,_db=math.floor(dcb or 0),math.floor(_db or 0)if dcb<=0 or _db<=0 then return self end;local cdb=math.floor(bcb or 1)+
self._ox*2
local ddb=math.floor(ccb or 1)+self._oy*3;local __c,a_c=cdb+dcb-1,ddb+_db-1;local b_c,c_c,d_c,_ac=cab(self)
cdb,ddb=math.max(cdb,b_c),math.max(ddb,c_c)__c,a_c=math.min(__c,d_c),math.min(a_c,_ac)if
cdb>__c or ddb>a_c then return self end;local aac=_ba.encode(adb)
if not aac then return self end;local bac;if bdb~=nil and bdb~=false and bdb~=" "then
bac=_ba.encode(bdb)end;bab(self)for py=ddb,a_c do for px=cdb,__c do
dab(self,px,py,aac,bac)end end
_bb(self,cdb,ddb,__c,a_c)return self end
function dca:drawSubpixelLine(bcb,ccb,dcb,_db,adb)bcb,ccb=math.floor(bcb)+self._ox*2,math.floor(ccb)+
self._oy*3
dcb,_db=math.floor(dcb)+
self._ox*2,math.floor(_db)+self._oy*3;local bdb=_ba.encode(adb)if not bdb then return self end;bab(self)
local cdb,ddb,__c,a_c=cab(self)
local b_c,c_c=math.max(cdb,math.min(bcb,dcb)),math.max(ddb,math.min(ccb,_db))
local d_c,_ac=math.min(__c,math.max(bcb,dcb)),math.min(a_c,math.max(ccb,_db))local aac,bac=math.abs(dcb-bcb),math.abs(_db-ccb)local cac,dac=
bcb<dcb and 1 or-1,ccb<_db and 1 or-1
local _bc=aac-bac
while true do if
bcb>=cdb and bcb<=__c and ccb>=ddb and ccb<=a_c then dab(self,bcb,ccb,bdb)end;if
bcb==dcb and ccb==_db then break end;local abc=2 *_bc;if abc>-bac then
_bc,bcb=_bc-bac,bcb+cac end
if abc<aac then _bc,ccb=_bc+aac,ccb+dac end end
if b_c<=d_c and c_c<=_ac then _bb(self,b_c,c_c,d_c,_ac)end;return self end;dca.drawPixel=dca.drawSubpixel
function dca:clearSubpixels()if self._spX1 <=self._spX2 and
self._spY1 <=self._spY2 then
a_b(self,self._spX1,self._spY1,self._spX2,self._spY2)end;self._spFg,self._spBg,self._spBits=
nil,nil,nil
self._spX1,self._spY1=math.huge,math.huge;self._spX2,self._spY2=0,0;return self end
function dca:copyTo(bcb)bcb.t,bcb.f,bcb.b=bcb.t or{},bcb.f or{},bcb.b or{}
local ccb,dcb=self._owner._w,self._owner._h
for y=1,dcb do
bcb.t[y],bcb.f[y],bcb.b[y]=bcb.t[y]or{},bcb.f[y]or{},bcb.b[y]or{}bca(self._text[y],1,ccb,1,bcb.t[y])
bca(self._fg[y],1,ccb,1,bcb.f[y])bca(self._bg[y],1,ccb,1,bcb.b[y])end
if self._spBits then local _db=ccb*2 *dcb*3
bcb.spFg,bcb.spBg,bcb.spBits={},{},{}bca(self._spFg,1,_db,1,bcb.spFg)
bca(self._spBg,1,_db,1,bcb.spBg)bca(self._spBits,1,_db,1,bcb.spBits)else
bcb.spFg,bcb.spBg,bcb.spBits=nil,nil,nil end;return bcb end
function dca:copyFrom(bcb)local ccb,dcb=self._owner._w,self._owner._h;for y=1,dcb do
if
bcb.t and bcb.t[y]then bca(bcb.t[y],1,ccb,1,self._text[y])
bca(bcb.f[y],1,ccb,1,self._fg[y])bca(bcb.b[y],1,ccb,1,self._bg[y])end end
if
bcb.spBits then local _db=ccb*2 *dcb*3;self._spFg,self._spBg,self._spBits={},{},{}
bca(bcb.spFg,1,_db,1,self._spFg)bca(bcb.spBg,1,_db,1,self._spBg)
bca(bcb.spBits,1,_db,1,self._spBits)self._spX1,self._spY1,self._spX2,self._spY2=1,1,ccb,dcb else self._spFg,self._spBg,self._spBits=
nil,nil,nil
self._spX1,self._spY1,self._spX2,self._spY2=math.huge,math.huge,0,0 end;a_b(self,1,1,ccb,dcb)return self end
function dca:restoreLine(bcb,ccb)local dcb,_db=self._owner._w,self._owner._h
if
bcb<1 or bcb>_db or not ccb.t or not ccb.t[bcb]then return self end;bca(ccb.t[bcb],1,dcb,1,self._text[bcb])
bca(ccb.f[bcb],1,dcb,1,self._fg[bcb])bca(ccb.b[bcb],1,dcb,1,self._bg[bcb])
local adb=dcb*2;if ccb.spBits then bab(self)end
if self._spBits then
for subRow=(bcb-1)*3 +1,bcb*3 do local bdb=
(subRow-1)*adb+1;local cdb=bdb+adb-1
if ccb.spBits then
bca(ccb.spFg,bdb,cdb,bdb,self._spFg)bca(ccb.spBg,bdb,cdb,bdb,self._spBg)
bca(ccb.spBits,bdb,cdb,bdb,self._spBits)else for index=bdb,cdb do
self._spFg[index],self._spBg[index],self._spBits[index]=nil,nil,nil end end end;self._spX1,self._spY1,self._spX2,self._spY2=1,1,dcb,_db end;a_b(self,1,bcb,dcb,bcb)return self end;function dca:present()return self._owner:present()end
local function cbb(bcb)
bcb._screenT,bcb._screenF,bcb._screenB=dda(bcb._w,bcb._h," ",cba,dba)bcb._lastT,bcb._lastF,bcb._lastB={},{},{}bcb._dirty={}for y=1,bcb._h do
bcb._dirty[y]=true end end
function bba.new(bcb,ccb,dcb)if type(bcb)=="table"then dcb,bcb,ccb=bcb,nil,nil end;local _db=dcb or
term;local adb,bdb=_db.getSize()
local cdb=setmetatable({_term=_db,_w=bcb or adb,_h=ccb or bdb,_layers={},_layerByName={},_nextSequence=1,_fullComposition=true,BufferModule=bba},cca)cdb._mapper=_ba.newMapper(_db)
cdb._default=d_b(cdb,"default",0,true)
cdb._layers[1],cdb._layerByName.default=cdb._default,cdb._default;cbb(cdb)return cdb end
function cca:_sortLayers()
table.sort(self._layers,function(bcb,ccb)if bcb.zIndex==ccb.zIndex then return
bcb._sequence<ccb._sequence end
return bcb.zIndex<ccb.zIndex end)end;function cca:_markFullComposition()self._fullComposition=true
for y=1,self._h do self._dirty[y]=true end end;function cca:getSize()
return self._w,self._h end
function cca:getVirtualSize()return self._w*2,self._h*3 end
function cca:setSize(bcb,ccb)bcb,ccb=math.floor(bcb),math.floor(ccb)if
bcb<1 or ccb<1 then return self end;self._w,self._h=bcb,ccb;for dcb,_db in ipairs(self._layers)do
c_b(_db)end;cbb(self)self._fullComposition=true;return self end;function cca:getTarget()return self._term end
function cca:addLayer(bcb,ccb)
assert(
type(bcb)=="string"and bcb~="","Buffer:addLayer requires a name")if self._layerByName[bcb]then
error("Obsidian Buffer: layer already exists: "..bcb,2)end
local dcb=d_b(self,bcb,ccb or 0,false)self._layers[#self._layers+1]=dcb
self._layerByName[bcb]=dcb;self:_sortLayers()self:_markFullComposition()
return dcb end;cca.createLayer=cca.addLayer;function cca:getLayer(bcb)
return self._layerByName[bcb]end
function cca:getLayers()local bcb={}for ccb,dcb in ipairs(self._layers)do
bcb[ccb]=dcb end;return bcb end
function cca:removeLayer(bcb)local ccb=
type(bcb)=="string"and self._layerByName[bcb]or bcb;if not ccb or
ccb==self._default then return false end;for dcb,_db in ipairs(self._layers)do
if
_db==ccb then table.remove(self._layers,dcb)break end end;self._layerByName[ccb.name]=
nil;self:_markFullComposition()return true end;function cca:getDefaultLayer()return self._default end;local function dbb(bcb)return
cda(bcb[1],bcb[2],bcb[3],bcb[4],bcb[5],bcb[6])end
function cca:_composeCell(bcb,ccb)
local dcb,_db,adb=" ",cba,dba;local bdb;local cdb
for ddb,__c in ipairs(self._layers)do
if __c.visible then
local a_c,b_c,c_c=__c._text[ccb][bcb],__c._fg[ccb][bcb],__c._bg[ccb][bcb]
if a_c~=nil or b_c~=nil or c_c~=nil then if bdb then dcb,_db,adb=dbb(bdb)
bdb=nil end;if a_c~=nil then dcb=a_c end
if b_c~=nil then _db=b_c end;if c_c~=nil then adb=c_c end end
if __c._spBits then
if not cdb then local _ac=self._w*2;local aac=(ccb-1)*3 +1
local bac=(bcb-1)*2 +1
cdb={(aac-1)*_ac+bac,(aac-1)*_ac+bac+1,aac*_ac+bac,
aac*_ac+bac+1,(aac+1)*_ac+bac,(aac+1)*_ac+bac+1}end;local d_c=false
for i=1,6 do local _ac=cdb[i]if
__c._spBits[_ac]or __c._spBg[_ac]~=nil then d_c=true;break end end
if d_c then if not bdb then bdb={adb,adb,adb,adb,adb,adb}end;for i=1,6 do
local _ac=cdb[i]
if __c._spBits[_ac]then bdb[i]=__c._spFg[_ac]or _db elseif
__c._spBg[_ac]~=nil then bdb[i]=__c._spBg[_ac]end end end end end end;if bdb then dcb,_db,adb=dbb(bdb)end;return dcb,_db,adb end
function cca:_compose()local bcb,ccb,dcb,_db=math.huge,math.huge,0,0
if self._fullComposition then
bcb,ccb,dcb,_db=1,1,self._w,self._h else
for adb,bdb in ipairs(self._layers)do
if bdb._dirtyX1 <bcb then bcb=bdb._dirtyX1 end;if bdb._dirtyY1 <ccb then ccb=bdb._dirtyY1 end;if bdb._dirtyX2 >dcb then
dcb=bdb._dirtyX2 end
if bdb._dirtyY2 >_db then _db=bdb._dirtyY2 end end end;if bcb>dcb or ccb>_db then return false end
bcb,ccb=math.max(1,bcb),math.max(1,ccb)
dcb,_db=math.min(self._w,dcb),math.min(self._h,_db)
for y=ccb,_db do
local adb,bdb,cdb=self._screenT[y],self._screenF[y],self._screenB[y]
for x=bcb,dcb do adb[x],bdb[x],cdb[x]=self:_composeCell(x,y)end;self._dirty[y]=true end;for adb,bdb in ipairs(self._layers)do b_b(bdb)end
self._fullComposition=false;return true end
local function _cb(bcb,ccb)for x=1,#bcb do ccb[bcb:byte(x)]=true end end
function cca:present()self:_compose()local bcb=false;for y=1,self._h do
if self._dirty[y]then bcb=true;break end end;if not bcb then return self end
local ccb,dcb,_db={},{},{}local adb={}
for y=1,self._h do
ccb[y]=table.concat(self._screenT[y])dcb[y]=table.concat(self._screenF[y])
_db[y]=table.concat(self._screenB[y])_cb(dcb[y],adb)_cb(_db[y],adb)end;local bdb,cdb=self._mapper:build(adb)
for y=1,self._h do
if
cdb or self._dirty[y]then local ddb,__c,a_c=ccb[y],dcb[y],_db[y]
if
cdb or ddb~=self._lastT[y]or
__c~=self._lastF[y]or a_c~=self._lastB[y]then self._term.setCursorPos(1,y)
self._term.blit(ddb,(__c:gsub(".",bdb)),(a_c:gsub(".",bdb)))
self._lastT[y],self._lastF[y],self._lastB[y]=ddb,__c,a_c end;self._dirty[y]=false end end;return self end;cca.flush=cca.present
function cca:invalidate()
self._lastT,self._lastF,self._lastB={},{},{}self:_markFullComposition()return self end
function cca:restorePalette()self._mapper:restore()return self end;function cca:compileSubpixels()self:_compose()return self end
local acb={"push","pop","setClip","clearClip","clear","drawText","drawLine","drawRect","drawSprite","drawImage","drawSubpixel","drawSubpixelRect","drawSubpixelLine","drawPixel","clearSubpixels","copyTo","copyFrom","restoreLine"}
for bcb,ccb in ipairs(acb)do cca[ccb]=function(dcb,...)
return dcb._default[ccb](dcb._default,...)end end;bba.rgb=_ba.rgb;bba.color=_ba;bba.Buffer=cca;bba.Surface=dca;return bba
]=]
paths["core.buffer"] = "core/buffer"
sources["core.camera"] = [=[
local c={}local d={}d.__index=d
function c.new(_a)
assert(_a and _a.camera,"camera.new: scene must have a .camera vec2")local aa=setmetatable({},d)aa._scene=_a;aa._targetX=_a.camera.x
aa._targetY=_a.camera.y;aa.lerpFactor=0.1;aa._followId=nil;aa._followComp="pos"aa._deadzone=nil;aa._boundsX1=
nil;aa._boundsY1=nil;aa._boundsX2=nil;aa._boundsY2=nil;aa.offsetX=0
aa.offsetY=0;aa._shakeIntensity=0;aa._shakeDuration=0;aa._shakeDurationMax=0
aa._shakeOffsetX=0;aa._shakeOffsetY=0;aa._flashColor="0"aa._flashDuration=0;_a._camera=aa
return aa end
function d:follow(_a,aa)aa=aa or{}self._followId=_a;self._followComp=aa.comp or"pos"if
aa.lerp~=nil then self.lerpFactor=aa.lerp end;if aa.deadzone then
self._deadzone=aa.deadzone end end;function d:unfollow()self._followId=nil end
function d:setBounds(_a,aa,ba,ca)self._boundsX1=_a
self._boundsY1=aa;self._boundsX2=ba;self._boundsY2=ca end;function d:clearBounds()self._boundsX1,self._boundsY1=nil,nil
self._boundsX2,self._boundsY2=nil,nil end;function d:setOffset(_a,aa)
self.offsetX=_a or 0;self.offsetY=aa or 0 end
function d:moveTo(_a,aa)self._targetX=_a+
self.offsetX;self._targetY=aa+self.offsetY
self:_applyBounds()self._scene.camera.x=self._targetX
self._scene.camera.y=self._targetY end
function d:pan(_a,aa)self._targetX=self._targetX+ (_a or 0)self._targetY=self._targetY+ (aa or
0)self:_applyBounds()
self._scene.camera.x=self._targetX;self._scene.camera.y=self._targetY end
function d:update(_a)local aa=self._scene
if self._followId then
local ca=aa.components[self._followComp]local da=ca and ca[self._followId]
if da then
local _b=da.x+self.offsetX;local ab=da.y+self.offsetY
if self._deadzone then
local bb=self._deadzone.w*0.5;local cb=self._deadzone.h*0.5;local db=self._targetX
local _c=self._targetY
if _b<db-bb then self._targetX=_b+bb elseif _b>db+bb then self._targetX=_b-bb end
if ab<_c-cb then self._targetY=ab+cb elseif ab>_c+cb then self._targetY=ab-cb end else self._targetX=_b;self._targetY=ab end end end;self:_applyBounds()
local ba=math.min(1,self.lerpFactor* (_a*60))
aa.camera.x=aa.camera.x+ (self._targetX-aa.camera.x)*ba
aa.camera.y=aa.camera.y+ (self._targetY-aa.camera.y)*ba
if self._shakeDuration>0 then
self._shakeDuration=self._shakeDuration-_a
if self._shakeDuration<=0 then self._shakeDuration=0;self._shakeOffsetX=0
self._shakeOffsetY=0;aa._staticDirty=true else
local ca=self._shakeDuration/self._shakeDurationMax;local da=self._shakeIntensity*ca;self._shakeOffsetX=
(math.random()-0.5)*2 *da;self._shakeOffsetY=
(math.random()-0.5)*2 *da end end;if self._flashDuration>0 then
self._flashDuration=self._flashDuration-_a end end;function d:shake(_a,aa)self._shakeIntensity=_a or 1;self._shakeDuration=aa or 0.5
self._shakeDurationMax=self._shakeDuration end
function d:flash(_a,aa)self._flashColor=
_a or"0"self._flashDuration=aa or 0.2 end;function d:isShaking()return self._shakeDuration>0 end;function d:getShakeOffset()return
self._shakeOffsetX,self._shakeOffsetY end;function d:isFlashing()return
self._flashDuration>0 end;function d:getFlashColor()
return self._flashColor end
function d:worldToScreen(_a,aa)local ba=self._scene;local ca,da
if
ba and ba.ui and
ba.ui.buf and type(ba.ui.buf.getSize)=="function"then ca,da=ba.ui.buf:getSize()else ca,da=term.getSize()end;local _b,ab=debug.designW,debug.designH;local bb,cb=0,0
if _b and ab then
bb=math.max(0,math.floor((ca-_b)/2))cb=math.max(0,math.floor((da-ab)/2))end
local db=math.floor(_a-ba.camera.x+bb)+1
local _c=math.floor(aa-ba.camera.y+cb)+1;return db,_c end
function d:screenToWorld(_a,aa)local ba=self._scene;local ca,da
if ba and ba.ui and ba.ui.buf and
type(ba.ui.buf.getSize)=="function"then
ca,da=ba.ui.buf:getSize()else ca,da=term.getSize()end;local _b,ab=debug.designW,debug.designH;local bb,cb=0,0
if _b and ab then
bb=math.max(0,math.floor((ca-_b)/2))cb=math.max(0,math.floor((da-ab)/2))end;local db=(_a-1)+ba.camera.x-bb;local _c=
(aa-1)+ba.camera.y-cb;return db,_c end;function d:getPosition()
return self._scene.camera.x,self._scene.camera.y end
function d:_applyBounds()
if self._boundsX1 ~=nil and self._targetX<
self._boundsX1 then self._targetX=self._boundsX1 end
if
self._boundsY1 ~=nil and self._targetY<self._boundsY1 then self._targetY=self._boundsY1 end
if
self._boundsX2 ~=nil and self._targetX>self._boundsX2 then self._targetX=self._boundsX2 end
if
self._boundsY2 ~=nil and self._targetY>self._boundsY2 then self._targetY=self._boundsY2 end end;return c
]=]
paths["core.camera"] = "core/camera"
sources["core.color"] = [=[
local ad={}local bd=math.floor;local cd=string.char
local dd={[0]=0xF0F0F0,0xF2B233,0xE57FD8,0x99B2F2,0xDEDE6C,0x7FCC19,0xF2B2CC,0x4C4C4C,0x999999,0x4C99B2,0xB266E5,0x3366CC,0x7F664C,0x57A64E,0xCC4C4C,0x111111}local __a={}local a_a={}local b_a={}
for i=0,15 do local aca=("%x"):format(i)__a[i]=aca
a_a[aca]=i;a_a[aca:upper()]=i;b_a[2 ^i]=i end;local function c_a(aca)
return bd(aca/65536)/255,bd(aca/256)%256 /255, (aca%256)/255 end;local d_a={}for i=0,15 do
d_a[i]={c_a(dd[i])}end;local _aa=16;local aaa={}local baa=0x1000000
for i=0,15 do aaa[dd[i]]=i end
local function caa(aca)if aca<0 then return 0 end;if aca>1 then return 1 end;return aca end
local function daa(aca,bca,cca)
if type(aca)=="string"then local dca=aca:gsub("#","")
if dca:match("^%x%x%x$")then dca=
dca:sub(1,1):rep(2)..
dca:sub(2,2):rep(2)..dca:sub(3,3):rep(2)elseif
dca:match("^%x%x%x%x%x%x%x%x$")then dca=dca:sub(3)elseif not dca:match("^%x%x%x%x%x%x$")then
error(
"Obsidian: invalid RGB color '"..tostring(aca).."' (expected #RGB, #RRGGBB or #AARRGGBB)",3)end;return c_a(tonumber(dca,16))end;if type(aca)~="number"then
error("Obsidian: invalid color value "..tostring(aca),3)end
if bca==nil then if
aca<0 or aca>0xFFFFFF or aca%1 ~=0 then
error("Obsidian: invalid RGB number "..
tostring(aca).." (expected 0x000000-0xFFFFFF)",3)end
return c_a(aca)end;if type(bca)~="number"or type(cca)~="number"then
error("Obsidian: rgb requires three numeric components",3)end
if aca>1 or bca>1 or
cca>1 then aca,bca,cca=aca/255,bca/255,cca/255 end;return caa(aca),caa(bca),caa(cca)end
local function _ba(aca,bca,cca)local dca,_da,ada=daa(aca,bca,cca)
local bda=bd(dca*255 +0.5)*65536 +bd(_da*255 +
0.5)*256 +bd(ada*255 +0.5)local cda=aaa[bda]if cda then return cda end
if _aa>255 then local __b,a_b=0,math.huge;for index=0,255 do
local b_b=d_a[index]local c_b=(dca-b_b[1])^2 + (_da-b_b[2])^2 +
(ada-b_b[3])^2
if c_b<a_b then __b,a_b=index,c_b end end
aaa[bda]=__b;return __b end;local dda=_aa;_aa=_aa+1;d_a[dda]={dca,_da,ada}aaa[bda]=dda;return dda end;function ad.rgb(aca,bca,cca)return baa+_ba(aca,bca,cca)end
local function aba(aca)
if
aca==nil or aca==false or aca==" "then return nil end;if type(aca)=="string"then
if#aca==1 and a_a[aca]~=nil then return a_a[aca]end;return _ba(aca)end
if
type(aca)=="number"then
if aca>=baa then local cca=aca-baa
if cca>=0 and cca<=255 and d_a[cca]then return cca end
error("Obsidian: invalid RGB color handle "..tostring(aca),3)end;local bca=b_a[aca]if bca~=nil then return bca end;return _ba(aca)end
error("Obsidian: unsupported color value "..tostring(aca),3)end;function ad.encode(aca,bca)if aca==nil then aca=bca end;local cca=aba(aca)return
cca~=nil and cd(cca)or nil end;function ad.indexOf(aca)return
aba(aca)end;function ad.getRGB(aca)return d_a[aca]end
ad.identityMap={}for i=0,15 do ad.identityMap[cd(i)]=__a[i]end;local bba={}
bba.__index=bba
local function cba(aca,bca)
local cca,dca,_da=aca[1]-bca[1],aca[2]-bca[2],aca[3]-bca[3]return cca*cca+dca*dca+_da*_da end
local function dba(aca,bca)local cca=aca.getPaletteColour or aca.getPaletteColor;if cca then local dca,_da,ada,bda=pcall(cca,
2 ^bca)
if dca and _da~=nil then return{_da,ada,bda}end end
return{c_a(dd[bca])}end
function ad.newMapper(aca)local bca={}for i=0,15 do bca[i]=dba(aca,i)end;return
setmetatable({term=aca,native=bca,overridden={},previousSlot={},previousMap={}},bba)end
local function _ca(aca,bca,cca,dca)
local _da=aca.term.setPaletteColour or aca.term.setPaletteColor;if not _da then return end
if aca.overridden[bca]==dca then return end;_da(2 ^bca,cca[1],cca[2],cca[3])
aca.overridden[bca]=dca end
function bba:build(aca)
local bca=self.term.setPaletteColour or self.term.setPaletteColor;local cca,dca={},{}
for i=0,15 do cca[cd(i)]=__a[i]
if aca[i]then dca[i]=i
if bca and
self.overridden[i]~=nil then
bca(2 ^i,self.native[i][1],self.native[i][2],self.native[i][3])self.overridden[i]=nil end end end;local _da={}
for cda in pairs(aca)do if cda>15 then _da[#_da+1]=cda end end;table.sort(_da)local ada={}
if bca then
local function cda(a_b,b_b)dca[b_b]=a_b
self.previousSlot[a_b]=b_b;_ca(self,b_b,d_a[a_b],a_b)cca[cd(a_b)]=__a[b_b]end;local dda={}for a_b,b_b in ipairs(_da)do local c_b=self.previousSlot[b_b]
if c_b~=nil and
dca[c_b]==nil then cda(b_b,c_b)else dda[#dda+1]=b_b end end;local __b=0
for a_b,b_b in
ipairs(dda)do while __b<=15 and dca[__b]~=nil do __b=__b+1 end;if __b<=15 then
cda(b_b,__b)__b=__b+1 else ada[#ada+1]=b_b end end else for i=0,15 do dca[i]=i end;ada=_da end
for cda,dda in ipairs(ada)do local __b,a_b=15,math.huge
for slot=0,15 do local b_b=dca[slot]
if b_b~=nil then local c_b=b_b<=15 and
self.native[b_b]or d_a[b_b]
local d_b=cba(d_a[dda],c_b)if d_b<a_b then __b,a_b=slot,d_b end end end;cca[cd(dda)]=__a[__b]end;local bda=false
for cda,dda in pairs(cca)do local __b=self.previousMap[cda]if
__b~=nil and __b~=dda then bda=true;break end end;self.previousMap=cca;return cca,bda end
function bba:restore()
local aca=self.term.setPaletteColour or self.term.setPaletteColor
if aca then for bca in pairs(self.overridden)do local cca=self.native[bca]
aca(2 ^bca,cca[1],cca[2],cca[3])end end;self.overridden,self.previousSlot,self.previousMap={},{},{}end;return ad
]=]
paths["core.color"] = "core/color"
sources["core.console"] = [=[
local ca={}local da=10;local _b="> "local ab=300
local bb={open=false,input="",scroll=0,history={},cmdHist={},cmdIdx=0,env=nil,commands={}}function ca.isOpen()return bb.open end
function ca.open()bb.open=true;bb.scroll=0 end
function ca.close()bb.open=false;bb.input=""bb.cmdIdx=0;bb.scroll=0 end
function ca.toggle()if bb.open then ca.close()else ca.open()end end;function ca.setEnv(_c)bb.env=_c end
local function cb(_c,ac)local bc={}
for cc in
(tostring(_c).."\n"):gmatch("([^\n]*)\n")do
if#cc==0 then table.insert(bc,"")elseif#cc<=ac then table.insert(bc,cc)else
local dc={}for ad in cc:gmatch("%S+")do table.insert(dc,ad)end
local _d=""
for ad,bd in ipairs(dc)do
if#_d==0 then
if#bd>ac then while#bd>ac do
table.insert(bc,bd:sub(1,ac))bd=bd:sub(ac+1)end;_d=bd else _d=bd end elseif#_d+1 +#bd<=ac then _d=_d.." "..bd else table.insert(bc,_d)
_d=bd end end;if#_d>0 then table.insert(bc,_d)end end end;return bc end;local db=48
function ca.addLine(_c,ac)local bc=cb(tostring(_c),db-2)
for cc,dc in ipairs(bc)do table.insert(bb.history,{text=dc,fg=
ac or"0"})end
while#bb.history>ab do table.remove(bb.history,1)end end
function ca.print(_c)ca.addLine(tostring(_c),"b")end
function ca.addCommand(_c,ac,bc)bb.commands[_c]={fn=ac,desc=bc or""}end;function ca.removeCommand(_c)bb.commands[_c]=nil end
function ca.exec(_c)
if _c==""then return end;if bb.cmdHist[#bb.cmdHist]~=_c then
table.insert(bb.cmdHist,_c)end;bb.cmdIdx=0;bb.scroll=0
ca.addLine(_b.._c,"7")
if _c=="help"then ca.addLine("  Registered commands:","7")
local cd=false;for dd,__a in pairs(bb.commands)do cd=true;local a_a="  "..dd;if __a.desc~=""then a_a=a_a..
"  —  "..__a.desc end
ca.addLine(a_a,"b")end;if not cd then
ca.addLine("  (none registered)","8")end;return end;local ac,bc=_c:match("^(%S+)(.*)$")
if ac and bb.commands[ac]then local cd={}
for b_a in(bc or
""):gmatch("%S+")do table.insert(cd,b_a)end;local dd=_G.print;_G.print=ca.print
local __a,a_a=pcall(bb.commands[ac].fn,table.unpack(cd))_G.print=dd;if not __a then
ca.addLine("  "..tostring(a_a),"e")end;return end;local cc=bb.env or _ENV
local dc,_d=load("return ".._c,"console","t",cc)if not dc then dc,_d=load(_c,"console","t",cc)end
if not dc then ca.addLine(
"  "..tostring(_d),"e")return end;local ad=table.pack(pcall(dc))local bd=ad[1]
if not bd then ca.addLine("  "..
tostring(ad[2]),"e")elseif ad.n>1 then local cd={}for i=2,ad.n do
cd[i-1]=tostring(ad[i])end
ca.addLine("  = "..table.concat(cd,", "),"5")end end
function ca.handleEvent(_c,ac)local bc=_c[1]
if not bb.open then if
not ac and bc=="key"and _c[2]==keys.f1 then ca.open()return true end;return false end;if bc=="term_resize"then return false end
if bc=="char"then
bb.input=bb.input.._c[2]elseif bc=="key"then local cc=_c[2]
if cc==keys.f1 then ca.close()return true elseif cc==keys.enter then
ca.exec(bb.input)bb.input=""bb.cmdIdx=0 elseif cc==keys.backspace then
bb.input=bb.input:sub(1,-2)elseif cc==keys.up then if#bb.cmdHist>0 then
bb.cmdIdx=math.min(bb.cmdIdx+1,#bb.cmdHist)
bb.input=bb.cmdHist[#bb.cmdHist-bb.cmdIdx+1]end elseif cc==keys.down then
if
bb.cmdIdx>1 then bb.cmdIdx=bb.cmdIdx-1
bb.input=bb.cmdHist[#bb.cmdHist-bb.cmdIdx+1]else bb.cmdIdx=0;bb.input=""end elseif cc==keys.pageUp then local dc=da-3;bb.scroll=math.min(bb.scroll+math.floor(dc/2),#
bb.history-dc)
bb.scroll=math.max(0,bb.scroll)elseif cc==keys.pageDown then
bb.scroll=math.max(0,bb.scroll-math.floor((da-3)/2))end elseif bc=="mouse_scroll"then bb.scroll=bb.scroll-_c[2]local cc=da-3
bb.scroll=math.max(0,math.min(bb.scroll,math.max(0,
#bb.history-cc)))end;return true end
function ca.draw(_c)if not bb.open then return end;local ac,bc=_c:getSize()local cc=bc-da+1
db=ac;_c:drawRect(1,cc,ac,da," ","f","8")
_c:drawRect(1,cc,ac,1," ","0","7")local dc=" Obsidian Console   F1 toggle  PgUp/PgDn scroll"
_c:drawText(1,cc,dc:sub(1,ac),"0","7")local _d=da-3;local ad=#bb.history
local bd=math.max(1,ad-_d+1 -bb.scroll)local cd=math.min(ad,bd+_d-1)local dd=cc+1
for i=bd,cd do
local d_a=bb.history[i]_c:drawText(2,dd,d_a.text,d_a.fg,"8")dd=dd+1 end
if bb.scroll>0 then local d_a=string.format(" ^%d ",bb.scroll)_c:drawText(ac-#
d_a,cc+1,d_a,"5","8")end;local __a=cc+da-2
_c:drawRect(1,__a,ac,1,string.rep("\140",ac),"7","8")local a_a=cc+da-1;local b_a=ac-#_b-1
local c_a=_b..bb.input:sub(-b_a)_c:drawRect(1,a_a,ac,1," ","f","0")
_c:drawText(1,a_a,c_a:sub(1,ac),"f","0")end;return ca
]=]
paths["core.console"] = "core/console"
sources["core.db"] = [=[
local ba=...local ca=ba("core.logger")local da={}local _b={}_b.__index=_b
local function ab(cb,db)
for _c,ac in pairs(db)do
local bc=cb[_c]if type(ac)=="function"then if not ac(bc)then return false end else
if bc~=ac then return false end end end;return true end;local function bb(cb)if type(cb)~="table"then return cb end;local db={}
for _c,ac in pairs(cb)do db[_c]=bb(ac)end;return db end
function da.open(cb,db)db=
db or{}local _c=setmetatable({},_b)_c._name=cb
_c._dir=db.dir or"db/"_c._autosave=(db.autosave~=false)_c._records={}_c._nextId=1;local ac=fs.combine(_c._dir,
cb..".dat")
if fs.exists(ac)then
local bc=fs.open(ac,"r")
if bc then
local cc,dc=pcall(textutils.unserialize,bc.readAll())bc.close()
if cc and dc then _c._records=dc.records or{}
_c._nextId=dc.nextId or 1
ca.info("DB: Loaded collection '"..
cb.."' ("..#_c._records.." records)")else
ca.error("DB: Failed to parse '"..ac.."'")end end end;return _c end
function _b:insert(cb)local db=bb(cb)
if db._id==nil then db._id=self._nextId
self._nextId=self._nextId+1 else if type(db._id)=="number"and db._id>=self._nextId then self._nextId=
db._id+1 end end;table.insert(self._records,db)if self._autosave then
self:flush()end;return bb(db)end;function _b:insertMany(cb)local db={}
for _c,ac in ipairs(cb)do db[#db+1]=self:insert(ac)end;return db end
function _b:update(cb,db)local _c=0
for ac,bc in
ipairs(self._records)do if ab(bc,cb)then
for cc,dc in pairs(db)do if cc~="_id"then bc[cc]=bb(dc)end end;_c=_c+1 end end;if _c>0 and self._autosave then self:flush()end;return _c end;function _b:upsert(cb,db)local _c=self:findOne(cb)
if _c then
self:update({_id=_c._id},db)return"updated"else self:insert(db)return"inserted"end end
function _b:delete(cb)
local db={}local _c=0;for ac,bc in ipairs(self._records)do
if ab(bc,cb)then _c=_c+1 else db[#db+1]=bc end end;self._records=db;if
_c>0 and self._autosave then self:flush()end;return _c end
function _b:clear()local cb=#self._records;self._records={}self._nextId=1;if self._autosave then
self:flush()end;return cb end
function _b:find(cb,db)db=db or{}local _c={}for ac,bc in ipairs(self._records)do if not cb or ab(bc,cb)then
_c[#_c+1]=bb(bc)end end
if db.orderBy then
local ac=db.orderBy;local bc=db.desc==true
table.sort(_c,function(cc,dc)local _d,ad=cc[ac],dc[ac]
if _d==nil then return false end;if ad==nil then return true end;if bc then return _d>ad else return _d<ad end end)end
if db.offset or db.limit then local ac=(db.offset or 0)+1;local bc=db.limit and
(ac+db.limit-1)or#_c;local cc={}for i=ac,math.min(bc,#_c)
do cc[#cc+1]=_c[i]end;return cc end;return _c end
function _b:findOne(cb)for db,_c in ipairs(self._records)do
if not cb or ab(_c,cb)then return bb(_c)end end;return nil end;function _b:findById(cb)return self:findOne({_id=cb})end
function _b:count(cb)if
not cb then return#self._records end;local db=0;for _c,ac in
ipairs(self._records)do if ab(ac,cb)then db=db+1 end end;return db end
function _b:flush()
if not fs.exists(self._dir)then fs.makeDir(self._dir)end
local cb=fs.combine(self._dir,self._name..".dat")local db=fs.open(cb,"w")if not db then
ca.error("DB: Failed to open '"..cb.."' for writing")return false end
local _c,ac=pcall(function()
db.write(textutils.serialize({records=self._records,nextId=self._nextId}))end)db.close()if not _c then
ca.error("DB: Failed to flush '"..
self._name.."': "..tostring(ac))end;return _c end
function _b:drop()self:clear()
local cb=fs.combine(self._dir,self._name..".dat")if fs.exists(cb)then fs.delete(cb)end
ca.info("DB: Dropped collection '"..
self._name.."'")end;function _b:disableAutosave()self._autosave=false end;function _b:enableAutosave()
self._autosave=true end;return da
]=]
paths["core.db"] = "core/db"
sources["core.debug"] = [=[

return
{enabled=false,showLogs=false,alwaysOnTop=true,updateTime=0,drawTime=0,fps=0,dynamicCount=0,designW=nil,designH=nil,minW=nil,minH=nil,unsupportedResolution=false}
]=]
paths["core.debug"] = "core/debug"
sources["core.ecs"] = [=[
local c={}c.__index=c
function c.new()local _a=setmetatable({},c)_a._nextId=1
_a._entities={}_a._store={}_a._tags={}_a._index={}return _a end;function c:spawn()local _a=self._nextId;self._nextId=_a+1;self._entities[_a]=true
self._tags[_a]={}return _a end;function c:alive(_a)return
self._entities[_a]==true end
function c:despawn(_a)if not
self:alive(_a)then
logger.warn("ECS: Attempted to despawn non-existent entity "..tostring(_a))return end
for aa in pairs(
self._tags[_a]or{})do self:detach(_a,aa)end;self._entities[_a]=nil;self._tags[_a]=nil end;function c:entities()local _a={}
for aa in pairs(self._entities)do table.insert(_a,aa)end;return _a end
function c:count()local _a=0;for aa in
pairs(self._entities)do _a=_a+1 end;return _a end
function c:attach(_a,aa,ba)if _a==nil then
logger.error("ECS: attach() called with nil entity (component='"..tostring(aa).."')")return end;if aa==nil then
logger.error(
"ECS: attach() called with nil component for entity "..tostring(_a))return end;if
not self:alive(_a)then
logger.error("ECS: attach() called on dead entity "..tostring(_a))return end
if
not self._store[aa]then self._store[aa]={}self._index[aa]={}end;self._store[aa][_a]=ba
self._tags[_a][aa]=true;self._index[aa][_a]=true end
function c:get(_a,aa)if not self:alive(_a)then return nil end
local ba=self._store[aa]return ba and ba[_a]end;function c:has(_a,aa)return
self._tags[_a]~=nil and self._tags[_a][aa]==true end
function c:detach(_a,aa)if not
self:alive(_a)then return end;if self._store[aa]then
self._store[aa][_a]=nil end;if self._tags[_a]then
self._tags[_a][aa]=nil end;if self._index[aa]then
self._index[aa][_a]=nil end end
function c:components(_a)if not self:alive(_a)then return{}end;local aa={}
for ba in pairs(
self._tags[_a]or{})do aa[ba]=self:get(_a,ba)end;return aa end
function c:update(_a,aa,ba)local ca=self:get(_a,aa)if ca then local da=ba(ca)if da~=nil then
self:attach(_a,aa,da)end end end
function c:select(...)local _a={...}if#_a==0 then return self:entities()end
local aa=_a[1]local ba=math.huge
for _b,ab in ipairs(_a)do local bb=self._index[ab]if not bb then return{}end
local cb=self:countType(ab)if cb<ba then ba=cb;aa=ab end end;local ca=self._index[aa]local da={}
for _b in pairs(ca)do local ab=true
local bb=self._tags[_b]
for cb,db in ipairs(_a)do if not bb[db]then ab=false;break end end;if ab then table.insert(da,_b)end end;return da end
function c:selectAny(...)local _a={...}if#_a==0 then return{}end;local aa={}
for ca,da in ipairs(_a)do
local _b=self._index[da]if _b then for ab in pairs(_b)do aa[ab]=true end end end;local ba={}for ca in pairs(aa)do table.insert(ba,ca)end;return ba end
function c:exclude(...)local _a={...}local aa={}
for ba in pairs(self._entities)do local ca=false
local da=self._tags[ba]for _b,ab in ipairs(_a)do if da[ab]then ca=true;break end end;if not ca then
table.insert(aa,ba)end end;return aa end;function c:first(...)local _a=self:select(...)return _a[1]end
function c:each(...)
local _a={...}local aa=self:select(...)local ba=0
return
function()ba=ba+1;local ca=aa[ba]
if not ca then return nil end;local da={}
for _b,ab in ipairs(_a)do table.insert(da,self:get(ca,ab))end;return ca,table.unpack(da)end end
function c:forEach(_a,...)for aa in self:each(...)do _a(aa)end end;function c:countWith(...)return#self:select(...)end;function c:types()
local _a={}for aa in pairs(self._store)do table.insert(_a,aa)end;return
_a end
function c:countType(_a)
local aa=self._index[_a]if not aa then return 0 end;local ba=0;for ca in pairs(aa)do ba=ba+1 end;return ba end
function c:stats()local _a={}for aa,ba in pairs(self._index)do local ca=0;for da in pairs(ba)do ca=ca+1 end
_a[aa]=ca end;return
{entities=self:count(),types=#self:types(),components=_a}end
function c:clear()self._nextId=1;self._entities={}self._tags={}for _a in pairs(self._store)do
self._store[_a]={}self._index[_a]={}end end
function c:debug()logger.info("=== ECS World Debug ===")logger.info(
"Entities: "..self:count())
logger.info(
"Component Types: "..#self:types())for _a,aa in ipairs(self:types())do
logger.info("  - "..aa..": "..
self:countType(aa).." instances")end
for _a in pairs(self._entities)do
local aa={}
for ba in pairs(self._tags[_a])do table.insert(aa,ba)end
logger.info("Entity "..
_a..": ["..table.concat(aa,", ").."]")end end;local d={}function d.createWorld()return c.new()end
function d.new()return c.new()end;return d
]=]
paths["core.ecs"] = "core/ecs"
sources["core.error"] = [=[
local aa=...local ba=aa("core.logger")
local ca={handler=nil,_shouldStop=false}
local function da(ab)ba.error("[PANIC] "..tostring(ab))end
local function _b(ab)da(ab)local bb,cb=ab,nil;local db=ab:find("\nstack traceback:")if db then bb=ab:sub(1,db-
1)cb=ab:sub(db+1)end
local _c,ac=term.getSize()term.setBackgroundColor(colors.black)
term.clear()term.setBackgroundColor(colors.red)
term.setCursorPos(1,1)term.clearLine()local bc=" OBSIDIAN ERROR "
term.setCursorPos(math.max(1,math.floor(
(_c-#bc)/2)+1),1)term.setTextColor(colors.white)term.write(bc)
term.setBackgroundColor(colors.black)local cc=3;term.setTextColor(colors.yellow)for _d in
bb:gmatch("[^\n]+")do if cc>ac-5 then break end;term.setCursorPos(2,cc)
term.write(_d:sub(1,_c-2))cc=cc+1 end
if cb and
cc<ac-2 then cc=cc+1
if cc<=ac-2 then term.setCursorPos(2,cc)
term.setTextColor(colors.lightGray)term.write("Stack Traceback:")cc=cc+1 end
for _d in cb:gmatch("[^\n]+")do if cc>ac-2 then break end
if _d~="stack traceback:"then
local ad=

_d:find("/core/")or _d:find("engine%.lua")or _d:find("error%.lua")or _d:find("%[C%]")
term.setTextColor(ad and colors.gray or colors.white)term.setCursorPos(3,cc)
term.write(_d:sub(1,_c-3))cc=cc+1 end end end;term.setBackgroundColor(colors.gray)
term.setTextColor(colors.white)term.setCursorPos(1,ac)term.clearLine()
local dc=" Press any key to exit  |  crash saved to obsidian.log "
term.setCursorPos(math.max(1,math.floor((_c-#dc)/2)+1),ac)term.write(dc:sub(1,_c))os.pullEvent("key")end
function ca.report(ab,bb)local cb
if bb and#tostring(bb)>0 then cb=tostring(ab)..
"\n"..tostring(bb)else cb=tostring(ab)end;if ca.handler then ca.handler(cb)else _b(cb)end
ca._shouldStop=true end;return ca
]=]
paths["core.error"] = "core/error"
sources["core.event"] = [=[
local d=...local _a=d("core.logger")local aa={}aa.__index=aa;function aa.new()return
setmetatable({_listeners={}},aa)end
function aa:on(ba,ca)if
not self._listeners[ba]then self._listeners[ba]={}end;local da={}
self._listeners[ba][da]=ca;return
function()local _b=self._listeners[ba]if _b then _b[da]=nil end end end;function aa:once(ba,ca)local da
da=self:on(ba,function(...)da()ca(...)end)return da end
function aa:emit(ba,...)
local ca=self._listeners[ba]if not ca then return end
for da,_b in pairs(ca)do local ab,bb=pcall(_b,...)if not ab then
_a.error(string.format("EventEmitter '%s' handler failed: %s",ba,tostring(bb)))end end end;function aa:off(ba)self._listeners[ba]=nil end;function aa:clear()
self._listeners={}end;return aa
]=]
paths["core.event"] = "core/event"
sources["core.input"] = [=[

local c={keysDown={},keysDownPrevious={},mouseDown={},mouseDownPrevious={},mouseX=0,mouseY=0,_keyHooks={},_comboHooks={},_nextHookId=0,_defaultRepeatDelay=0.4,_defaultRepeatInterval=0.12}
function c.processEvent(_a,...)local aa,ba,ca=...
if _a=="key"then c.keysDown[aa]=true
if c.isJustPressed(aa)then
local da=c._keyHooks[aa]
if da then local _b=os.clock()
for ab,bb in ipairs(da)do
local cb,db=pcall(bb.handler,aa,{event="pressed"})if not cb then end;local _c=false
if bb.opts then
if bb.opts.repeatable~=nil then
_c=bb.opts.repeatable elseif bb.opts["repeat"]~=nil then _c=bb.opts["repeat"]elseif
bb.opts.repeating~=nil then _c=bb.opts.repeating elseif bb.opts.repeats~=nil then _c=bb.opts.repeats end end
if _c then bb._holding=true;local ac=bb.opts.repeatDelay or bb.opts.repeatInterval or
c._defaultRepeatDelay;bb._nextRepeat=
_b+ (ac or c._defaultRepeatDelay)end end end end
for da,_b in ipairs(c._comboHooks)do local ab=true;for bb,cb in ipairs(_b.keys)do if not c.keysDown[cb]then ab=false
break end end
if
ab and not _b._fired then _b._fired=true;pcall(_b.handler,_b.keys)end end elseif _a=="key_up"then c.keysDown[aa]=false;for _b,ab in ipairs(c._comboHooks)do
for bb,cb in ipairs(ab.keys)do if
cb==aa then ab._fired=false;break end end end
local da=c._keyHooks[aa]if da then
for _b,ab in ipairs(da)do ab._holding=false;ab._nextRepeat=nil end end elseif
_a=="mouse_click"or _a=="mouse_drag"then c.mouseDown[aa]=true;c.mouseX=ba;c.mouseY=ca elseif _a=="mouse_up"then
c.mouseDown[aa]=false;c.mouseX=ba;c.mouseY=ca elseif _a=="mouse_scroll"then c.mouseX=ba;c.mouseY=ca elseif
_a=="mouse_move"then c.mouseX=aa;c.mouseY=ba end end
function c._endFrame()local _a=os.clock()
for aa,ba in pairs(c._keyHooks)do
for ca,da in ipairs(ba)do
if
da._holding and da._nextRepeat and _a>=da._nextRepeat then
local _b,ab=pcall(da.handler,aa,{event="repeat"})if not _b then end
local bb=(da.opts and da.opts.repeatInterval)or c._defaultRepeatInterval;da._nextRepeat=_a+bb end end end
for aa,ba in pairs(c.keysDown)do c.keysDownPrevious[aa]=ba end
for aa,ba in pairs(c.mouseDown)do c.mouseDownPrevious[aa]=ba end
for aa in pairs(c.keysDownPrevious)do if not c.keysDown[aa]then
c.keysDownPrevious[aa]=nil end end
for aa in pairs(c.mouseDownPrevious)do if not c.mouseDown[aa]then
c.mouseDownPrevious[aa]=nil end end end
function c.clear()c.keysDown={}c.keysDownPrevious={}c.mouseDown={}c.mouseDownPrevious={}end;function c.isKeyDown(_a)if type(_a)=="string"then _a=keys[_a]end;return
c.keysDown[_a]==true end;function c.isJustPressed(_a)if
type(_a)=="string"then _a=keys[_a]end
return c.keysDown[_a]==true and not(
c.keysDownPrevious[_a]==true)end;function c.isJustReleased(_a)if
type(_a)=="string"then _a=keys[_a]end
return
not(c.keysDown[_a]==true)and c.keysDownPrevious[_a]==true end;function c.isMouseDown(_a)return
c.mouseDown[_a]==true end
function c.isMouseJustPressed(_a)return

c.mouseDown[_a]==true and not(c.mouseDownPrevious[_a]==true)end;function c.isMouseJustReleased(_a)
return not(c.mouseDown[_a]==true)and c.mouseDownPrevious[_a]==
true end;function c.getMousePos()
return c.mouseX,c.mouseY end;local function d(_a)
if type(_a)=="string"then return keys[_a]end;return _a end
function c.onKey(_a,aa,ba)ba=ba or{}
c._nextHookId=c._nextHookId+1;local ca=c._nextHookId;local da={}
if type(_a)=="table"then for _b,ab in ipairs(_a)do local bb=d(ab)if bb~=nil then
table.insert(da,bb)end end else local _b=d(_a)if
_b~=nil then table.insert(da,_b)end end;if#da==0 then return nil end
for _b,ab in ipairs(da)do if not c._keyHooks[ab]then
c._keyHooks[ab]={}end
table.insert(c._keyHooks[ab],{id=ca,handler=aa,opts=ba,_holding=false,_nextRepeat=nil})end;return ca end
function c.offKey(_a)for aa,ba in pairs(c._keyHooks)do for i=#ba,1,-1 do
if ba[i].id==_a then table.remove(ba,i)end end
if#ba==0 then c._keyHooks[aa]=nil end end end
function c.onCombo(_a,aa,ba)ba=ba or{}c._nextHookId=c._nextHookId+1;local ca=c._nextHookId
local da={}
for _b,ab in ipairs(_a)do local bb=d(ab)if bb~=nil then table.insert(da,bb)end end;if#da==0 then return nil end
table.insert(c._comboHooks,{id=ca,keys=da,handler=aa,opts=ba,_fired=false})return ca end;function c.offCombo(_a)
for i=#c._comboHooks,1,-1 do if c._comboHooks[i].id==_a then
table.remove(c._comboHooks,i)end end end;function c.clearHooks()
c._keyHooks={}c._comboHooks={}c._nextHookId=0 end;return c
]=]
paths["core.input"] = "core/input"
sources["core.input_mapper"] = [=[
local d=...local _a=d("core.input")local aa={mappings={}}
function aa.bind(ba,ca)if type(ca)~="table"then
ca={ca}end;aa.mappings[ba]=ca end
function aa.isActive(ba)local ca=aa.mappings[ba]if not ca then return false end;for da,_b in ipairs(ca)do if
_a.isKeyDown(_b)then return true end end;return false end
function aa.loadDefaultWASD()aa.bind("up",{keys.w,keys.up})
aa.bind("down",{keys.s,keys.down})aa.bind("left",{keys.a,keys.left})
aa.bind("right",{keys.d,keys.right})aa.bind("jump",{keys.space})
aa.bind("use",{keys.e,keys.enter})end;return aa
]=]
paths["core.input_mapper"] = "core/input_mapper"
sources["core.loader"] = [=[
local ca=...local da=ca("core.logger")local _b=ca("flimg")
local ab={basePath=nil,spriteCache={},imageCache={},uiCache={},emitterCache={}}ab.flimg=_b
local function bb(_c)
if not _c or _c:sub(1,1)=="/"then return _c end
if ab.basePath then return fs.combine(ab.basePath,_c)end
if shell then local ac=shell.getRunningProgram()if ac then return
fs.combine(fs.getDir(ac),_c)end end;return _c end;function ab.setBasePath(_c)ab.basePath=_c end;local function cb(_c)local ac={}for i=1,#_c do
ac[i]=_c:sub(i,i)end;return ac end
local function db(_c)
local ac=bb(_c)
if not fs.exists(ac)then return false,"File not found: "..ac end;local bc=fs.open(ac,"r")if not bc then
return false,"Could not open file: "..ac end;local cc=bc.readAll()bc.close()
local dc,_d=pcall(textutils.unserialize,cc)
if not dc or _d==nil then return false,"Failed to unserialize: "..ac end;return true,_d,ac end
function ab._processSprite(_c)if not _c then return end
for i=1,(_c.frameCount or#_c)do local ac=_c[i]if ac then
for layer=1,3 do if ac[layer]then
for bc,cc in
ipairs(ac[layer])do if type(cc)=="string"then ac[layer][bc]=cb(cc)end end end end end end end
function ab._validateSprite(_c,ac)if not ac or type(ac)~="table"then
return false,"File is not a valid table."end
local bc={"width","height","frameCount"}for cc,dc in ipairs(bc)do
if not ac[dc]then return false,"Missing field: "..dc end end
for f=1,ac.frameCount do local cc=ac[f]
if
not cc or#cc~=3 then return false,
string.format("Frame %d must have exactly 3 layers (Chars, Fore, Back).",f)end
for layer=1,3 do
if#cc[layer]~=ac.height then
return false,string.format("Frame %d, layer %d: row count (%d) does not match height (%d).",f,layer,
#cc[layer],ac.height)end
for r=1,ac.height do local dc=cc[layer][r]local _d=#dc
if _d~=ac.width then return false,
string.format("Frame %d, layer %d, row %d: length (%d) does not match width (%d).",f,layer,r,_d,ac.width)end
if type(dc)=="table"then
for c=1,ac.width do local ad=dc[c]local bd
if layer==1 then
bd=type(ad)=="string"and#ad==1 else
bd=type(ad)=="number"or
(type(ad)=="string"and(
#ad==1 or ad:match("^#%x%x%x$")or ad:match("^#%x%x%x%x%x%x$")or
ad:match("^#%x%x%x%x%x%x%x%x$")))end
if not bd then local cd=tostring(ad)return false,
string.format("Frame %d, layer %d, row %d, column %d: invalid %s value '%s'.",f,layer,r,c,
layer==1 and"character"or"color",cd)end end end end end end;return true end
function ab.loadSprite(_c)local ac=bb(_c)
if ab.spriteCache[ac]then return ab.spriteCache[ac]end;local bc,cc,dc=db(_c)
if not bc then da.error("Loader: "..cc)return nil,cc end;local _d,ad=ab._validateSprite(_c,cc)if not _d then
da.error("Loader: Validation error in "..
_c..": "..ad)return nil,ad end
ab._processSprite(cc)cc.path=_c;ab.spriteCache[dc]=cc
da.info("Loader: Cached sprite: "..dc)return cc end
function ab.loadImage(_c)local ac=bb(_c)
if ab.imageCache[ac]then return ab.imageCache[ac]end
if not fs.exists(ac)then return nil,"File not found: "..ac end;local bc=fs.open(ac,"rb")or fs.open(ac,"r")if not bc then return nil,
"Could not open file: "..ac end
local cc=bc.readAll()bc.close()local dc,_d=pcall(_b.decode,cc)if not dc then
da.error("Loader: "..tostring(_d))return nil,tostring(_d)end;_d.path=_c
ab.imageCache[ac]=_d
da.info("Loader: Cached FLIMG image: "..ac)return _d end
function ab.loadUI(_c)local ac=bb(_c)
if ab.uiCache[ac]then return ab.uiCache[ac]end;local bc,cc,dc=db(_c)
if not bc then da.error("Loader: "..cc)return nil,cc end;ab.uiCache[dc]=cc;return cc end
function ab.loadEmitter(_c)local ac=bb(_c)
if ab.emitterCache[ac]then return ab.emitterCache[ac]end;local bc,cc,dc=db(_c)
if not bc then da.error("Loader: "..cc)return nil,cc end;if cc.sprite then ab._processSprite(cc.sprite)end
ab.emitterCache[dc]=cc;return cc end
function ab.unload(_c)local ac=bb(_c)ab.spriteCache[ac]=nil
ab.imageCache[ac]=nil;ab.uiCache[ac]=nil;ab.emitterCache[ac]=nil;da.info("Loader: Unloaded asset: "..
tostring(ac))end;function ab.clearCache()ab.spriteCache={}ab.imageCache={}ab.uiCache={}ab.emitterCache={}
da.info("Loader: Asset cache cleared.")end;return ab
]=]
paths["core.loader"] = "core/loader"
sources["core.logger"] = [=[

local d={history={},maxHistory=8,logFile="obsidian.log",level="info",fileEnabled=true,_fileInitialized=false,_consoleHook=nil}local _a={INFO="0",WARN="1",ERROR="e",DEBUG="7"}
local aa={debug=1,DEBUG=1,info=2,INFO=2,warn=3,WARN=3,error=4,ERROR=4,off=5}
function d.setLevel(ba)if aa[ba]==nil then
error("Obsidian logger: unknown level "..tostring(ba),2)end;d.level=ba end;function d.setFileEnabled(ba)d.fileEnabled=ba~=false end
function d._add(ba,ca)local da=
aa[d.level]or aa.info
if(aa[ba]or aa.info)<da then return end;local _b=os.date("%H:%M:%S")
local ab=string.format("[%s] [%s] %s",_b,ba,tostring(ca))local bb={level=ba,text=ab,color=_a[ba]or"0"}
table.insert(d.history,bb)
if#d.history>d.maxHistory then table.remove(d.history,1)end
if d.fileEnabled then local cb=d._fileInitialized and"a"or"w"
local db=fs.open(d.logFile,cb)
if db then d._fileInitialized=true;db.writeLine(ab)db.close()end end
if d._consoleHook then d._consoleHook(ab,_a[ba]or"0")end end;function d.info(ba)d._add("INFO",ba)end;function d.warn(ba)
d._add("WARN",ba)end;function d.error(ba)d._add("ERROR",ba)end;function d.debug(ba)
d._add("DEBUG",ba)end;function d.getHistory()return d.history end;return d
]=]
paths["core.logger"] = "core/logger"
sources["core.math"] = [=[
local ab=math.sqrt;local bb=math.cos;local cb=math.sin;local db=math.atan2
local _c=math.floor;local ac=math.abs;local bc=math.min;local cc=math.max;local dc={}local _d={}_d.__index=_d
function dc.vec2(ad,bd)local cd={x=
ad or 0,y=bd or 0}setmetatable(cd,_d)return cd end
function _d.__add(ad,bd)return dc.vec2(ad.x+bd.x,ad.y+bd.y)end
function _d.__sub(ad,bd)return dc.vec2(ad.x-bd.x,ad.y-bd.y)end
function _d.__eq(ad,bd)return ad.x==bd.x and ad.y==bd.y end
function _d.__mul(ad,bd)
if type(ad)=="number"then return dc.vec2(bd.x*ad,bd.y*ad)end
if type(bd)=="number"then return dc.vec2(ad.x*bd,ad.y*bd)end;return dc.vec2(ad.x*bd.x,ad.y*bd.y)end
function _d.__div(ad,bd)return dc.vec2(ad.x/bd,ad.y/bd)end;function _d.__unm(ad)return dc.vec2(-ad.x,-ad.y)end;function _d.__tostring(ad)return
string.format("Vec2(%.2f, %.2f)",ad.x,ad.y)end;function _d:dist(ad)if not ad then return
math.huge end
return dc.dist(self.x,self.y,ad.x,ad.y)end
function _d:sqDist(ad)
if not ad then return math.huge end;local bd=self.x-ad.x;local cd=self.y-ad.y;return bd*bd+cd*cd end;function _d:len()
return ab(self.x*self.x+self.y*self.y)end;function _d:sqLen()return
self.x*self.x+self.y*self.y end
function _d:normalize()local ad=self:len()if
ad==0 then return dc.vec2(0,0)end;return
dc.vec2(self.x/ad,self.y/ad)end
function _d:lerp(ad,bd)return
dc.vec2(dc.lerp(self.x,ad.x,bd),dc.lerp(self.y,ad.y,bd))end
function _d:dot(ad)return self.x*ad.x+self.y*ad.y end;function _d:unpack()return self.x,self.y end
function _d:set(ad,bd)
if ad~=nil then self.x=ad end;if bd~=nil then self.y=bd end;return self end
function _d:add(ad)self.x=self.x+ad.x;self.y=self.y+ad.y;return self end
function _d:mul(ad)self.x=self.x*ad;self.y=self.y*ad;return self end
function _d:limit(ad)local bd=self:sqLen()
if bd>ad*ad then local cd=ab(bd)self.x,self.y=(self.x/cd)*ad,(
self.y/cd)*ad end;return self end
function _d:cross(ad)return self.x*ad.y-self.y*ad.x end;function _d:clone()return dc.vec2(self.x,self.y)end
function _d:rotate(ad)
local bd=bb(ad)local cd=cb(ad)return
dc.vec2(self.x*bd-self.y*cd,self.x*cd+self.y*bd)end;function dc.lerp(ad,bd,cd)return ad+ (bd-ad)*cd end
function dc.applyDamping(ad,bd,cd)local dd=(1 -bd)^ (cd*
20)ad.x=ad.x*dd;ad.y=ad.y*dd end;function dc.isVec2(ad)
return type(ad)=="table"and getmetatable(ad)==_d end
function dc.clamp(ad,bd,cd)return bc(cc(ad,bd),cd)end
function dc.dist(ad,bd,cd,dd)local __a=ad-cd;local a_a=bd-dd;return ab(__a*__a+a_a*a_a)end
function dc.normalize(ad,bd)local cd=ab(ad*ad+bd*bd)
if cd==0 then return dc.vec2(0,0)end;return dc.vec2(ad/cd,bd/cd)end;function dc.normalizeRaw(ad,bd)local cd=ab(ad*ad+bd*bd)if cd==0 then return 0,0,0 end;return ad/cd,
bd/cd,cd end;function dc.round(ad)return _c(
ad+0.5)end;function dc.sign(ad)
if ad>0 then return 1 elseif ad<0 then return-1 else return 0 end end;function dc.angleBetween(ad,bd,cd,dd)
return db(dd-bd,cd-ad)end;function dc.fromAngle(ad,bd)bd=bd or 1;return
dc.vec2(bb(ad)*bd,cb(ad)*bd)end;return dc
]=]
paths["core.math"] = "core/math"
sources["core.network"] = [=[
local ca=...local da=ca("core.logger")
local _b={modemSide=nil,isOpen=false,isHost=false,serverId=nil,clients={},_protocol=nil,_hostname=nil,_connectCallback=nil,_connecting=false,_emit=function()end,_heartbeatInterval=10,_heartbeatTimeout=30,_lastPingTime={},_heartbeatThread=nil}local ab={}local bb={}
function _b.onMessage(_c)table.insert(ab,_c)return
function()for ac,bc in ipairs(ab)do if bc==_c then
table.remove(ab,ac)break end end end end;function _b.offMessage(_c)
for ac,bc in ipairs(ab)do if bc==_c then table.remove(ab,ac)break end end end
function _b.onMessageType(_c,ac)if not bb[_c]then
bb[_c]={}end;table.insert(bb[_c],ac)
return function()local bc=bb[_c]
if not bc then return end
for cc,dc in ipairs(bc)do if dc==ac then table.remove(bc,cc)break end end end end
function _b.offMessageType(_c,ac)local bc=bb[_c]if not bc then return end;for cc,dc in ipairs(bc)do if dc==ac then
table.remove(bc,cc)break end end end
local function cb()if _b._heartbeatThread then return end;local _c=ca("core.thread")
_b._heartbeatThread=_c.start(function()
while
_b.isOpen and(_b.isHost or _b.serverId)do local ac=os.epoch("utc")
if
_b.isHost then local bc={}
for cc,dc in pairs(_b.clients)do local _d=dc.lastPing or dc.connectedAt
if
(ac-_d)> (_b._heartbeatTimeout*1000)then
da.warn("Network: Client "..
cc.." timed out (no ping for "..math.floor((
ac-_d)/1000).."s)")table.insert(bc,cc)else
_b.send(cc,{type="PING",t=ac},_b._protocol)end end;for cc,dc in ipairs(bc)do _b.clients[dc]=nil
_b._emit("network.clientTimeout",dc)end elseif _b.serverId then
local bc=_b._lastPingTime[_b.serverId]
if bc and(ac-bc)> (_b._heartbeatTimeout*1000)then
da.warn(
"Network: Server ".._b.serverId.." timed out")local cc=_b.serverId;_b.serverId=nil
_b._emit("network.serverTimeout",cc)break else
_b.send(_b.serverId,{type="PING",t=ac},_b._protocol)end end;sleep(_b._heartbeatInterval)end;_b._heartbeatThread=nil
da.info("Network: Heartbeat thread stopped")end)end
local function db()if _b._heartbeatThread then local _c=ca("core.thread")
_c.stop(_b._heartbeatThread)_b._heartbeatThread=nil
da.info("Network: Heartbeat stopped")end end
function _b.open(_c)
if _c then
if peripheral.getType(_c)=="modem"then rednet.open(_c)
_b.modemSide=_c;_b.isOpen=true
da.info("Network: Modem opened on side ".._c..
" (ID: "..os.getComputerID()..")")return true end else local ac={peripheral.find("modem")}
if#ac>0 then
for bc,cc in ipairs(ac)do
local dc=peripheral.getName(cc)rednet.open(dc)_b.modemSide=dc end;_b.isOpen=true
da.info("Network: "..#ac..
" modem(s) opened. Local ID: "..os.getComputerID())return true end end;return false end
function _b.close()
if _b.isOpen then db()local _c={peripheral.find("modem")}
for ac,bc in
ipairs(_c)do rednet.close(peripheral.getName(bc))end;_b.isOpen=false;da.info("Network: All modems closed")end end
function _b.disconnect()if not _b.isOpen then return end;local _c=_b._protocol;if _b.isHost then
_b.broadcast({type="SERVER_SHUTDOWN"},_c)elseif _b.serverId then
_b.send(_b.serverId,{type="CLIENT_LEAVE"},_c)end
_b.isHost=false;_b.serverId=nil;_b._protocol=nil;_b._hostname=nil;_b.clients={}
_b._lastPingTime={}_b.close()end
function _b.send(_c,ac,bc)if not _b.isOpen then return false end;local cc=bc or _b._protocol;if not
cc then
da.warn("Network: send() called with no protocol specified and no default set")return false end
rednet.send(_c,ac,cc)return true end
function _b.broadcast(_c,ac)if not _b.isOpen then return false end
local bc=ac or _b._protocol;if not bc then
da.warn("Network: broadcast() called with no protocol specified and no default set")return false end
rednet.broadcast(_c,bc)return true end
function _b.connect(_c,ac,bc,cc)cc=cc or 5
da.info("Network: connect() called — protocol='"..
tostring(_c).."' hostname='"..tostring(ac)..
"' timeout="..tostring(cc))
if not _b.isOpen then
da.info("Network: modem not open, attempting auto-open")local ad=_b.open()
if not ad then local bd="No modem found"
da.warn("Network: connect() failed — "..bd)if bc then bc(false,bd)end;return false,bd end end
if _b._connecting then local ad="Already connecting"
da.warn("Network: connect() rejected — "..ad)if bc then bc(false,ad)end;return false,ad end;_b._connecting=true;_b._connectCallback=bc;_b._protocol=_c
da.info("Network: starting connect thread")local function dc(ad,bd)local cd=_b._connectCallback;_b._connectCallback=nil;_b._connecting=false;if cd then
cd(ad,bd)end end
local _d=ca("core.thread")
_d.start(function()
local ad,bd=pcall(function()
da.info("Network: [thread] looking up '"..tostring(ac)..
"' on protocol '"..tostring(_c).."'")local cd,dd=pcall(rednet.lookup,_c,ac)local __a=cd and dd or nil
da.info(
"Network: [thread] lookup result — ok="..tostring(cd).." id="..tostring(__a))
if not __a then
da.info("Network: [thread] DNS lookup failed, trying broadcast DISCOVER")
rednet.broadcast({type="DISCOVER",hostname=ac},_c)local c_a=os.startTimer(3)
while true do local d_a,_aa,aaa,baa=os.pullEvent()
if
d_a=="rednet_message"then local caa,daa=aaa,baa
if

type(caa)=="table"and caa.type=="DISCOVER_REPLY"and caa.hostname==ac and daa==_c then __a=_aa
da.info("Network: [thread] DISCOVER_REPLY from "..tostring(__a))os.cancelTimer(c_a)break end elseif d_a=="timer"and _aa==c_a then
da.warn("Network: [thread] broadcast discovery timed out")break end end end
if not __a then
local c_a=(not cd)and tostring(dd)or"Server not found"
da.warn("Network: [thread] connect failed — "..c_a)dc(false,c_a)
_b._emit("network.connectionFailed",_c,ac)return end
da.info("Network: [thread] sending CONNECT_REQUEST to server ID "..tostring(__a))
rednet.send(__a,{type="CONNECT_REQUEST"},_c)
da.info("Network: [thread] waiting up to "..cc.."s for CONNECT_ACCEPT")local a_a=os.startTimer(cc)
local b_a="network_connect_"..tostring(__a)
while true do local c_a,d_a=os.pullEvent()
if c_a=="timer"and d_a==a_a then
if _b._connecting then
da.warn("Network: [thread] timed out waiting for CONNECT_ACCEPT")dc(false,"Connection timed out")
_b._emit("network.connectionFailed",_c,ac)end;break elseif c_a==b_a then os.cancelTimer(a_a)
da.info("Network: [thread] connection established")dc(true,__a)break elseif not _b._connecting then os.cancelTimer(a_a)
if
_b.serverId==__a then
da.info("Network: [thread] connection established by processEvent")dc(true,__a)else
da.info("Network: [thread] _connecting cleared externally, exiting wait")end;break end end end)
if not ad then
da.error("Network: [thread] crashed: "..tostring(bd))
dc(false,"Internal error: "..tostring(bd))_b._emit("network.connectionFailed",_c,ac)end end)return true end
function _b.cancelConnect(_c)if not _b._connecting then return end;local ac=_b._connectCallback;_b._connectCallback=
nil;_b._connecting=false;if ac then
ac(false,_c or"Cancelled")end
da.info("Network: Connection cancelled — ".. (_c or"No reason"))end
function _b.host(_c,ac)if not _b.isOpen then
da.warn("Network: Cannot host, modem not open")return false end
rednet.host(_c,ac)_b.isHost=true;_b._protocol=_c;_b._hostname=ac
da.info("Network: Now hosting protocol '".._c.."' as '"..
ac.."'")cb()return true end;function _b.lookup(_c,ac)if not _b.isOpen then return nil end
return rednet.lookup(_c,ac)end
function _b.setHeartbeat(_c,ac)if _c then
_b._heartbeatInterval=_c end;if ac then _b._heartbeatTimeout=ac end
da.info(
"Network: Heartbeat configured — interval="..
_b._heartbeatInterval.."s, timeout=".._b._heartbeatTimeout.."s")end
function _b.processEvent(_c)if _c[1]~="rednet_message"then return end
local ac,bc,cc=_c[2],_c[3],_c[4]if ac==_b.serverId and cc==_b._protocol then
_b._lastPingTime[ac]=os.epoch("utc")end
if type(bc)~="table"then
_b._emit("network.message",ac,bc,cc)
for _d,ad in ipairs(ab)do local bd,cd=pcall(ad,ac,bc,cc)if not bd then
da.error("Network handler failed: "..tostring(cd))end end;return end;local dc=bc.type
if dc=="DISCOVER"and _b.isHost then if bc.hostname==_b._hostname then
_b.send(ac,{type="DISCOVER_REPLY",hostname=_b._hostname},cc)end;return end
if dc=="CONNECT_REQUEST"and _b.isHost then
da.info("Network: CONNECT_REQUEST from ID "..ac)
_b.clients[ac]={id=ac,connectedAt=os.epoch("utc"),lastPing=os.epoch("utc")}_b.send(ac,{type="CONNECT_ACCEPT"},cc)
_b._emit("network.clientConnect",ac)return end
if dc=="CONNECT_ACCEPT"then
da.info("Network: connected to server "..ac)_b.serverId=ac;_b._connecting=false
_b._lastPingTime[ac]=os.epoch("utc")
os.queueEvent("network_connect_"..tostring(ac))_b._emit("network.connected",ac)cb()return end
if dc=="PING"then
if _b.isHost and _b.clients[ac]then
_b.clients[ac].lastPing=os.epoch("utc")elseif ac==_b.serverId then _b._lastPingTime[ac]=os.epoch("utc")end;_b.send(ac,{type="PONG",t=bc.t},cc)return end
if dc=="PONG"then
if _b.isHost and _b.clients[ac]then
_b.clients[ac].lastPing=os.epoch("utc")elseif ac==_b.serverId then _b._lastPingTime[ac]=os.epoch("utc")end;return end;if dc=="CLIENT_LEAVE"and _b.isHost then _b.clients[ac]=nil
_b._emit("network.clientDisconnect",ac)return end;if
dc=="SERVER_SHUTDOWN"and not _b.isHost then _b.serverId=nil;db()
_b._emit("network.serverShutdown",ac)return end
_b._emit("network.message",ac,bc,cc)
for _d,ad in ipairs(ab)do local bd,cd=pcall(ad,ac,bc,cc)if not bd then
da.error("Network handler failed: "..tostring(cd))end end
if dc and bb[dc]then
for _d,ad in ipairs(bb[dc])do local bd,cd=pcall(ad,ac,bc,cc)if not bd then
da.error(
"Network type handler failed: "..tostring(cd))end end end end;return _b
]=]
paths["core.network"] = "core/network"
sources["core.particles"] = [=[
local ba=...local ca=ba("core.math")local da=ba("core.physics")
local _b=ba("core.logger")local ab=ba("core.loader")local bb={}
function bb.createEmitter(cb)
return
{active=cb.active~=false,spawnRate=math.max(0.001,
cb.spawnRate or 10),accumulator=0,angle=cb.angle or 0,spread=cb.spread or 360,speedMin=cb.speedMin or 5,speedMax=
cb.speedMax or 10,lifeMin=cb.lifeMin or 1,lifeMax=cb.lifeMax or 2,sprite=cb.sprite,colors=cb.colors,chars=cb.chars,bgColors=cb.bgColors,z=cb.z or 1,bounce=cb.bounce or
false,gravityScale=cb.gravityScale or 0,drag=cb.drag or 0}end
function bb.load(cb)local db=ab.loadEmitter(cb)if not db then
_b.error("[particles] Failed to load emitter: "..tostring(cb))return nil end
return bb.createEmitter(db)end
function bb.emitterSystem(cb)
return
function(db,_c,ac)
for bc,cc in ipairs(_c)do local dc=ac.emitter[cc]local _d=ac.pos[cc]
if
dc.active and _d then dc.accumulator=dc.accumulator+db;local ad=1 /dc.spawnRate
while
dc.accumulator>=ad do dc.accumulator=dc.accumulator-ad;local bd=cb:spawn()
local cd=math.rad(
dc.angle+ (math.random()-0.5)*dc.spread)
local dd=dc.speedMin+math.random()* (dc.speedMax-dc.speedMin)
local __a=dc.lifeMin+math.random()* (dc.lifeMax-dc.lifeMin)cb:attach(bd,"pos",ca.vec2(_d.x,_d.y))
cb:attach(bd,"velocity",ca.vec2(
math.cos(cd)*dd,math.sin(cd)*dd))cb:attach(bd,"lifetime",__a)
cb:attach(bd,"maxLifetime",__a)cb:attach(bd,"isParticle",true)
cb:attach(bd,"z",dc.z)
if dc.bounce then cb:attach(bd,"particleBounce",true)end;if dc.gravityScale~=0 then
cb:attach(bd,"particleGravity",dc.gravityScale)end;if dc.drag>0 then
cb:attach(bd,"particleDrag",dc.drag)end;if dc.sprite then
cb:attach(bd,"sprite",dc.sprite)end;if dc.colors then
cb:attach(bd,"particleColors",dc.colors)end;if dc.chars then
cb:attach(bd,"particleChars",dc.chars)end;if dc.bgColors then
cb:attach(bd,"particleBgColors",dc.bgColors)end end end end end end
function bb.motionSystem(cb)
return
function(db,_c,ac)
for bc,cc in ipairs(_c)do local dc=ac.pos[cc]local _d=ac.velocity[cc]local ad=ac.particleBounce and
ac.particleBounce[cc]
local bd=ac.particleDrag and ac.particleDrag[cc]if bd then ca.applyDamping(_d,bd,db)end;local cd=ac.particleGravity and
ac.particleGravity[cc]
if cd then _d.y=_d.y+
da.GRAVITY_VECTOR.y*cd*db end
if ad then local dd=dc.x;dc.x=dc.x+_d.x*db
local __a,a_a,b_a=cb:isAreaBlocked(dc.x,dc.y,1,1,cc)if __a and not b_a then dc.x=dd;_d.x=-_d.x*0.5 end
local c_a=dc.y;dc.y=dc.y+_d.y*db
local d_a,_aa,aaa=cb:isAreaBlocked(dc.x,dc.y,1,1,cc)
if d_a then if aaa then dc.y=aaa-1 else dc.y=c_a end;_d.y=-_d.y*0.5 end else dc.x=dc.x+_d.x*db;dc.y=dc.y+_d.y*db end end end end
function bb.updateSystem(cb)
return
function(db,_c,ac)
for bc,cc in ipairs(_c)do local dc=ac.lifetime[cc]
local _d=ac.maxLifetime[cc]
local ad=ac.particleColors and ac.particleColors[cc]local bd=ac.particleChars and ac.particleChars[cc]
local cd=math.max(0,math.min(1,
1 - (dc/ (_d>0 and _d or 1))))
if ad then
local __a=math.max(1,math.min(#ad,math.ceil(cd*#ad)))cb:attach(cc,"colorOverride",ad[__a])end
if bd then
local __a=math.max(1,math.min(#bd,math.ceil(cd*#bd)))cb:attach(cc,"charOverride",bd[__a])end
local dd=ac.particleBgColors and ac.particleBgColors[cc]
if dd then
local __a=math.max(1,math.min(#dd,math.ceil(cd*#dd)))cb:attach(cc,"bgOverride",dd[__a])end end end end
function bb.cleanupSystem(cb)
return function(db,_c,ac)
for bc,cc in ipairs(_c)do ac.lifetime[cc]=ac.lifetime[cc]-db;if
ac.lifetime[cc]<=0 then cb:despawn(cc)end end end end
function bb.registerAll(cb)
cb:addSystem({"emitter","pos"},bb.emitterSystem(cb))
cb:addSystem({"pos","velocity","isParticle"},bb.motionSystem(cb))
cb:addSystem({"lifetime","maxLifetime","isParticle"},bb.updateSystem(cb))
cb:addSystem({"lifetime","isParticle"},bb.cleanupSystem(cb))end;return bb
]=]
paths["core.particles"] = "core/particles"
sources["core.pathfinding"] = [=[
local bd=...local cd=bd("core.math")local dd=bd("core.logger")
local __a=math.floor;local a_a=math.abs;local b_a=math.min;local c_a={}c_a.MAX_ITERATIONS=4000
local function d_a()local cca={}local dca=0
local function _da(cda,dda)dca=
dca+1;cca[dca]={node=cda,priority=dda}local __b=dca
while __b>1 do
local a_b=__a(__b/2)if cca[__b].priority<cca[a_b].priority then
cca[__b],cca[a_b]=cca[a_b],cca[__b]__b=a_b else break end end end
local function ada()if dca==0 then return nil end;local cda=cca[1].node;cca[1]=cca[dca]
cca[dca]=nil;dca=dca-1;local dda=1
while true do local __b,a_b,b_b=dda*2,dda*2 +1,dda
if __b<=dca and cca[__b].priority<
cca[b_b].priority then b_b=__b end;if
a_b<=dca and cca[a_b].priority<cca[b_b].priority then b_b=a_b end;if b_b~=dda then
cca[dda],cca[b_b]=cca[b_b],cca[dda]dda=b_b else break end end;return cda end;local function bda()return dca==0 end;return{push=_da,pop=ada,isEmpty=bda}end;local _aa=10000;local function aaa(cca,dca)return dca*_aa+cca end
local function baa(cca)return cca%_aa end;local function caa(cca)return __a(cca/_aa)end;local daa=1;local _ba=1.414
local aba=_ba-2 *daa
local function bba(cca,dca,_da,ada)local bda=a_a(cca-_da)local cda=a_a(dca-ada)return daa* (bda+cda)+aba*
b_a(bda,cda)end
local cba={{dx=1,dy=0,cost=daa},{dx=-1,dy=0,cost=daa},{dx=0,dy=1,cost=daa},{dx=0,dy=-1,cost=daa},{dx=1,dy=1,cost=_ba},{dx=-1,dy=1,cost=_ba},{dx=1,dy=
-1,cost=_ba},{dx=-1,dy=-1,cost=_ba}}local dba=0
local function _ca(cca,dca,_da,ada,bda,cda,dda)return
cca:isAreaBlocked(dca-dba,_da-dba,ada+dba*2,bda+dba*2,cda,dda)end
local function aca(cca,dca,_da,ada,bda,cda,dda,__b,a_b)return cca:hasLOS(dca,_da,ada,bda,cda,dda,__b,a_b)end
local function bca(cca,dca,_da,ada,bda,cda)if#dca<=2 then return dca end;local dda={dca[1]}local __b=1
while __b<#dca do local a_b=__b+1
for i=#dca,
__b+2,-1 do local b_b,c_b=dca[__b],dca[i]if
aca(cca,b_b.x,b_b.y,c_b.x,c_b.y,_da,ada,bda,cda)then a_b=i;break end end;table.insert(dda,dca[a_b])__b=a_b end;return dda end
function c_a.findPath(cca,dca,_da,ada,bda,cda,dda,__b)if not dca or not _da then
dd.error("[pathfinding] findPath: startPos or endPos is nil")return nil end
ada=ada or{w=1,h=1}local a_b,b_b=ada.w,ada.h;dda=dda~=false
local c_b,d_b=__a(dca.x),__a(dca.y)local _ab,aab=__a(_da.x),__a(_da.y)if c_b==_ab and d_b==aab then return
{cd.vec2(c_b,d_b)}end;local bab=d_a()local cab={}local dab={}local _bb={}
local abb=aaa(c_b,d_b)local bbb=aaa(_ab,aab)cab[abb]=0
bab.push({x=c_b,y=d_b},bba(c_b,d_b,_ab,aab))local cbb=0;local dbb=__b or c_a.MAX_ITERATIONS
while not bab.isEmpty()do
local _cb=bab.pop()local acb,bcb=_cb.x,_cb.y;local ccb=aaa(acb,bcb)
if not _bb[ccb]then _bb[ccb]=true
cbb=cbb+1;if cbb>dbb then
dd.error("[pathfinding] MAX_ITERATIONS ("..
dbb..") exceeded — map may be too large or goal unreachable")return nil end
if
acb==_ab and bcb==aab then local _db={}local adb=ccb;while adb~=nil do
table.insert(_db,cd.vec2(baa(adb),caa(adb)))adb=dab[adb]end;local bdb,cdb=1,#_db;while bdb<cdb do
_db[bdb],_db[cdb]=_db[cdb],_db[bdb]bdb=bdb+1;cdb=cdb-1 end;if dda then return
bca(cca,_db,a_b,b_b,bda,cda)end;return _db end;local dcb=cab[ccb]
for i=1,8 do local _db=cba[i]local adb=acb+_db.dx;local bdb=bcb+_db.dy
local cdb=aaa(adb,bdb)local ddb=(cdb==bbb)
if not _bb[cdb]and(ddb or
not _ca(cca,adb,bdb,a_b,b_b,bda,cda))then local __c=true;if not ddb and
_db.dx~=0 and _db.dy~=0 then
if _ca(cca,adb,bcb,a_b,b_b,bda,cda)or
_ca(cca,acb,bdb,a_b,b_b,bda,cda)then __c=false end end
if __c then local a_c=dcb+
_db.cost;if not cab[cdb]or a_c<cab[cdb]then cab[cdb]=a_c
dab[cdb]=ccb
bab.push({x=adb,y=bdb},a_c+bba(adb,bdb,_ab,aab))end end end end end end end;return c_a
]=]
paths["core.pathfinding"] = "core/pathfinding"
sources["core.physics"] = [=[
local d=...local _a=d("core.math")local aa={}
aa.GRAVITY_VECTOR=_a.vec2(0,50)function aa.gravity()
return _a.vec2(aa.GRAVITY_VECTOR.x,aa.GRAVITY_VECTOR.y)end;function aa.setGravity(ba,ca)
aa.GRAVITY_VECTOR.x=ba;aa.GRAVITY_VECTOR.y=ca end
function aa.createBody(ba)ba=
ba or{}
return
{mass=ba.mass or 1.0,bounciness=ba.bounciness or 0.0,friction=ba.friction or 0.15,gravityScale=ba.gravityScale or 1.0,isKinematic=
ba.isKinematic or false,useGravity=ba.useGravity~=false}end
function aa.resolveBounce(ba,ca,da)da=da or 1.0;local _b=ba:dot(ca)if _b<0 then
ba:add(ca* (- (1 +da)*_b))end;return ba end
function aa.resolveCollision(ba,ca,da,_b,ab)local bb=ba.mass or 1.0;local cb=da.mass or 1.0;if bb<=0 and cb<=0 then
return end
local db=math.min(ba.bounciness or 0,da.bounciness or 0)local _c=ca-_b;local ac=_c:dot(ab)if ac>0 then return end
local bc=bb>0 and(1 /bb)or 0;local cc=cb>0 and(1 /cb)or 0
local dc=- (1 +db)*ac/ (bc+cc)local _d=ab*dc;ca:add(_d*bc)_b:add(_d*-cc)end
function aa.applyImpulse(ba,ca,da)local _b=da or 1.0;if _b<=0 then return end
if
type(ca)=="table"and ca.x then ba:add(ca* (1 /_b))else ba.x=ba.x+ (ca/_b)end end
function aa.aabbOverlap(ba,ca,da,_b,ab,bb,cb,db)return
ba<ab+cb and ba+da>ab and ca<bb+db and ca+_b>bb end
function aa.getAABBOverlap(ba,ca,da,_b,ab,bb,cb,db)
if not aa.aabbOverlap(ba,ca,da,_b,ab,bb,cb,db)then return nil,0 end
local _c=math.min(ba+da,ab+cb)-math.max(ba,ab)
local ac=math.min(ca+_b,bb+db)-math.max(ca,bb)local bc,cc=ba+da*0.5,ca+_b*0.5;local dc,_d=ab+cb*0.5,bb+db*0.5;local ad=math.abs(
bc-dc)/ ( (da+cb)*0.5)local bd=
math.abs(cc-_d)/ ( (_b+db)*0.5)if ad>=bd then
local cd=bc<dc and-1 or 1;return _a.vec2(cd,0),_c else local cd=cc<_d and-1 or 1
return _a.vec2(0,cd),ac end end
function aa.system(ba,ca)ca=math.max(1,math.floor(ca or 1))
return
function(da,_b,ab)
local bb=ab.pos;local cb=ab.vel;local db=ab.body
if not bb or not cb or not db then return end;local _c=aa.gravity()local ac=da/ca
for _=1,ca do
for bc,cc in ipairs(_b)do local dc=bb[cc]local _d=cb[cc]
local ad=db[cc]
if dc and _d and ad and not ad.isKinematic then
if ad.useGravity and
ad.gravityScale~=0 then
_d.x=_d.x+_c.x*ad.gravityScale*ac;_d.y=_d.y+_c.y*ad.gravityScale*ac end
if ad.friction and ad.friction>0 then
local cd=(1 -ad.friction)^ (ac*20)_d.x=_d.x*cd;_d.y=_d.y*cd end;local bd=ab.collider and ab.collider[cc]
if
bd and ba and ba.isAreaBlocked then local cd=dc.x;dc.x=dc.x+_d.x*ac
local dd=ba:isAreaBlocked(dc.x,dc.y,bd.w or 1,bd.h or 1,cc)if dd then dc.x=cd
_d.x=- (_d.x or 0)* (ad.bounciness or 0)end;local __a=dc.y;dc.y=dc.y+_d.y*ac;local a_a,b_a,c_a=ba:isAreaBlocked(dc.x,dc.y,
bd.w or 1,bd.h or 1,cc)
if
a_a then if c_a then dc.y=c_a- (bd.h or 1)else dc.y=__a end;_d.y=-
(_d.y or 0)* (ad.bounciness or 0)end else dc.x=dc.x+_d.x*ac;dc.y=dc.y+_d.y*ac end end end;if ab.onSubStep then ab.onSubStep(_b)end end end end;return aa
]=]
paths["core.physics"] = "core/physics"
sources["core.scene"] = [=[
local bc=...local cc=bc("core.ecs")local dc=bc("core.logger")
local _d=bc("core.loader")local ad=bc("core.math")local bd=bc("core.ui")
local cd=bc("core.error")local dd=bc("core.event")local __a=bc("core.debug")local a_a=nil;local b_a={}
local c_a=getmetatable(cc.new())local d_a=setmetatable({},{__index=c_a})d_a.__index=d_a;function b_a.setBuffer(caa)
a_a=caa end;local _aa=_G and _G.debug
local function aaa(caa)return
(_aa and _aa.traceback)and
_aa.traceback(tostring(caa),2)or tostring(caa)end
local function baa(caa)local daa;if type(caa)~='table'then return caa end;daa={}for _ba,aba in pairs(caa)do
daa[baa(_ba)]=baa(aba)end
setmetatable(daa,baa(getmetatable(caa)))return daa end
function b_a.new()local caa=cc.new()setmetatable(caa,d_a)caa.name=""
caa.memory={}caa.camera=ad.vec2(0,0)caa._lastCam=ad.vec2(0,0)
caa._camera=nil;caa.event=dd.new()caa.ui=bd.new(a_a)caa.tilemap=nil
caa._staticElements={}caa._staticCache={t={},f={},b={}}caa._staticDirty=true
caa._staticSortDirty=false;caa._foregroundElements={}caa._foregroundSortDirty=false
caa._rowsToRestore={}caa._sortedEntities={}caa._zDirty=true;caa._cellSize=10
caa._spatialGrid={}caa._activeDynamicCells={}caa._triggers={}
caa._systems={update={},render={}}caa._hudCallbacks={}caa._nextHudId=0;caa.onUpdate=nil;caa.onDraw=nil;caa.onEvent=
nil;caa.onLoad=nil;caa.onUnload=nil;return caa end
function b_a.newStaticElement(caa,daa,_ba,aba)aba=aba or{}
return
{sprite=caa,spritePath=aba.spritePath or(caa and caa.path),x=daa,y=_ba,z=
aba.z or-100,w=caa and caa.width or
(aba.collider and aba.collider.w or 0),h=caa and caa.height or(
aba.collider and aba.collider.h or 0),collider=aba.collider,layer=aba.layer or 1,oneWay=
aba.oneWay or false}end;function b_a.newTriggerZone(caa,daa,_ba,aba,bba,cba,dba)
return{x=caa,y=daa,w=_ba,h=aba,onEnter=bba,onExit=cba,onStay=dba,entitiesInside={}}end
function b_a.newTilemap(caa,daa,_ba,aba,bba)
return
{sprite=caa,spritePath=
bba or(caa and caa.path),data=daa,solidTiles=_ba or{},tileProperties=aba or{},tileW=caa and caa.width or 1,tileH=caa and
caa.height or 1}end
function d_a:setTilemap(caa,daa,_ba,aba,bba)
self.tilemap={sprite=caa,spritePath=bba,data=daa,solidTiles=_ba or{},tileProperties=aba or{},tileW=caa and caa.width or 1,tileH=
caa and caa.height or 1}self._staticDirty=true end
function d_a:instantiate(caa,daa,_ba)local aba=self:spawn()for bba,cba in pairs(caa)do
self:attach(aba,bba,baa(cba))end;if daa and _ba then
if self:has(aba,"pos")then
self:get(aba,"pos"):set(daa,_ba)else self:attach(aba,"pos",ad.vec2(daa,_ba))end end;return aba end;function d_a:setParent(caa,daa,_ba,aba)
self:attach(caa,"parent",{id=daa,offset=ad.vec2(_ba or 0,aba or 0)})end
function d_a:addStatic(caa,daa,_ba,aba)
aba=aba or{}if not caa and not aba.collider then
dc.warn(string.format("Scene: addStatic at (%.1f, %.1f) with nil sprite and no collider",
daa or 0,_ba or 0))end
local bba={sprite=caa,spritePath=
aba.spritePath or(caa and caa.path),x=daa,y=_ba,z=aba.z or-100,w=caa and caa.width or(aba.collider and
aba.collider.w or 0),h=
caa and caa.height or(aba.collider and aba.collider.h or 0),collider=aba.collider,layer=
aba.layer or 1,oneWay=aba.oneWay or false}table.insert(self._staticElements,bba)
self._staticSortDirty=true;self._staticDirty=true;self:_addToGrid(bba,true)end
function d_a:addForeground(caa,daa,_ba,aba)
table.insert(self._foregroundElements,{sprite=caa,x=daa,y=_ba,z=aba or 100,w=caa.width,h=caa.height})self._foregroundSortDirty=true end
function d_a:_addToGrid(caa,daa,_ba)if caa.collider==false then return end;local aba=caa.collider or
{x=0,y=0,w=caa.w,h=caa.h}local bba=math.floor((caa.x+aba.x)/
self._cellSize)
local cba=math.floor((caa.y+
aba.y)/self._cellSize)
local dba=math.floor((caa.x+aba.x+aba.w-0.001)/self._cellSize)
local _ca=math.floor((caa.y+aba.y+aba.h-0.001)/self._cellSize)
for cx=bba,dba do
for cy=cba,_ca do
self._spatialGrid[cx]=self._spatialGrid[cx]or{}self._spatialGrid[cx][cy]=self._spatialGrid[cx][cy]or
{static={},dynamic={}}
local aca=self._spatialGrid[cx][cy]caa.layer=caa.layer or 1
if daa then
table.insert(aca.static,caa)else if not next(aca.dynamic)then
table.insert(self._activeDynamicCells,aca)end;aca.dynamic[_ba]=caa end end end end
function d_a:_updateDynamicGrid()for i=1,#self._activeDynamicCells do
self._activeDynamicCells[i].dynamic={}end;self._activeDynamicCells={}
local caa=self:select("pos","collider")
for daa,_ba in ipairs(caa)do local aba=self:get(_ba,"pos")
local bba=self:get(_ba,"collider")local cba=self:get(_ba,"layer")or 1
self:_addToGrid({x=aba.x,y=aba.y,w=bba.w,h=bba.h,collider=bba,layer=cba},false,_ba)end end
function d_a:getEntityAt(caa,daa,_ba)local aba=math.floor(caa/self._cellSize)local bba=math.floor(
daa/self._cellSize)
local cba=
self._spatialGrid[aba]and self._spatialGrid[aba][bba]
if cba then
for dba,_ca in pairs(cba.dynamic)do
if dba~=_ba then local aca=_ca.collider;local bca=_ca.x+aca.x;local cca=_ca.y+
aca.y
if
caa>=bca and caa<bca+aca.w and daa>=cca and daa<cca+aca.h then return dba end end end end;return nil end
function d_a:getDistance(caa,daa)local _ba=self:get(caa,"pos")
local aba=self:get(daa,"pos")if not _ba or not aba then return 9999 end;return
ad.dist(_ba.x,_ba.y,aba.x,aba.y)end
function d_a:queryRect(caa,daa,_ba,aba,bba)local cba={}
local dba=math.floor(caa/self._cellSize)local _ca=math.floor(daa/self._cellSize)local aca=math.floor(
(caa+_ba)/self._cellSize)local bca=math.floor(
(daa+aba)/self._cellSize)
for cx=dba,aca do
if
self._spatialGrid[cx]then
for cy=_ca,bca do local cca=self._spatialGrid[cx][cy]
if cca then
for dca,_da in
pairs(cca.dynamic)do
if
not bba or bit.band(_da.layer or 1,bba)>0 then local ada=_da.collider;local bda=_da.x+ada.x;local cda=_da.y+ada.y;if
caa<
bda+ada.w and caa+_ba>bda and daa<cda+ada.h and daa+aba>cda then
table.insert(cba,dca)end end end end end end end;return cba end
function d_a:getUIAt(caa,daa)local _ba,aba=0,0
if __a.designW and __a.designH then local bba,cba=a_a:getSize()_ba=math.floor((
bba-__a.designW)/2)aba=math.floor((cba-
__a.designH)/2)end
for i=#self.ui.sorted,1,-1 do local bba=self.ui.sorted[i]
local cba,dba=self.ui:getAbsolutePos(bba,_ba,aba)
if caa>=cba and caa<cba+bba.w and daa>=dba and daa<
dba+bba.h then return bba.name end end end
function d_a:castRay(caa,daa,_ba,aba,bba,cba,dba)local _ca,aca,bca=ad.normalizeRaw(_ba-caa,aba-daa)if bca==0 then return
false,caa,daa end
local cca=math.min(bca,bba or 100)
for d=0,cca,0.5 do local dca=caa+_ca*d;local _da=daa+aca*d
local ada=math.floor(dca/self._cellSize)local bda=math.floor(_da/self._cellSize)
local cda=
self._spatialGrid[ada]and self._spatialGrid[ada][bda]
if cda then
for dda,__b in pairs(cda.dynamic)do
if dda~=cba and(not dba or
bit.band(__b.layer or 1,dba)>0)then local a_b=__b.collider;local b_b=
(__b.x or 0)+ (a_b.x or 0)
local c_b=(__b.y or 0)+ (a_b.y or 0)if
dca>=b_b and dca<b_b+ (a_b.w or 0)and _da>=c_b and _da<c_b+ (a_b.h or 0)then return true,dca,_da,
dda end end end
for dda,__b in ipairs(cda.static)do
if __b.collider~=false and(not dba or
bit.band(__b.layer or 1,dba)>0)then
local a_b=__b.collider;local b_b=(__b.x or 0)+ (a_b and a_b.x or 0)local c_b=(
__b.y or 0)+ (a_b and a_b.y or 0)local d_b=
a_b and a_b.w or __b.w or 0;local _ab=
a_b and a_b.h or __b.h or 0
if
dca>=b_b and dca<b_b+d_b and _da>=c_b and _da<c_b+_ab then return true,dca,_da,nil end end end end end;return false,caa+_ca*cca,daa+aca*cca end
function d_a:hasLOS(caa,daa,_ba,aba,bba,cba,dba,_ca)bba=bba or 1;cba=cba or 1
local aca,bca=math.floor(caa),math.floor(daa)local cca,dca=math.floor(_ba),math.floor(aba)
local _da=math.abs(cca-aca)local ada=math.abs(dca-bca)local bda=aca<cca and 1 or-1;local cda=bca<
dca and 1 or-1;local dda=_da-ada;local __b,a_b=aca,bca
while __b~=cca or a_b~=
dca do local b_b=2 *dda;local c_b=b_b>-ada;local d_b=b_b<_da;if c_b and d_b then
if self:isAreaBlocked(
__b+bda,a_b,bba,cba,dba,_ca)or
self:isAreaBlocked(__b,a_b+cda,bba,cba,dba,_ca)then return false end end;if c_b then dda=
dda-ada;__b=__b+bda end
if d_b then dda=dda+_da;a_b=a_b+cda end;if
(__b~=cca or a_b~=dca)and self:isAreaBlocked(__b,a_b,bba,cba,dba,_ca)then return false end end;return true end
function d_a:isAreaBlocked(caa,daa,_ba,aba,bba,cba)local dba=nil
if self.tilemap then local dca=self.tilemap;local _da=
math.floor(caa/dca.tileW)+1
local ada=math.floor(daa/dca.tileH)+1
local bda=math.floor((caa+_ba-0.001)/dca.tileW)+1
local cda=math.floor((daa+aba-0.001)/dca.tileH)+1
for ty=ada,cda do
if dca.data[ty]then
for tx=_da,bda do local dda=dca.data[ty][tx]
if dda then
local __b=dca.tileProperties[dda]
if __b and __b.type=="slope"then local a_b=
(caa+_ba/2 - (tx-1)*dca.tileW)/dca.tileW
a_b=ad.clamp(a_b,0,1)local b_b=ad.lerp(__b.hL,__b.hR,a_b)*dca.tileH;local c_b=(
ty-1)*dca.tileH+ (dca.tileH-b_b)if daa+
aba>c_b then dba=c_b end elseif __b and __b.type=="one-way"then local a_b=(ty-1)*
dca.tileH
if bba then local b_b=self:get(bba,"velocity")if
b_b and b_b.y>0 and(daa+aba-b_b.y*0.1)<=a_b then if daa+aba>a_b then
dba=a_b end end end elseif dca.solidTiles[dda]then return true,"tile"end end end end end end;if dba then return true,"tile",dba end
local _ca=math.floor(caa/self._cellSize)local aca=math.floor(daa/self._cellSize)
local bca=math.floor((caa+_ba-
0.001)/self._cellSize)
local cca=math.floor((daa+aba-0.001)/self._cellSize)
for cx=_ca,bca do
if self._spatialGrid[cx]then
for cy=aca,cca do
local dca=self._spatialGrid[cx][cy]
if dca then
for _da,ada in ipairs(dca.static)do
if ada.collider~=false and(not cba or
bit.band(ada.layer or 1,cba)>0)then
local bda=ada.collider;local cda,dda,__b,a_b
if bda then cda=ada.x+ (bda.x or 0)
dda=ada.y+ (bda.y or 0)__b=bda.w or ada.w or 0
a_b=bda.h or ada.h or 0 else cda=ada.x or 0;dda=ada.y or 0;__b=ada.w or 0;a_b=ada.h or 0 end
if
caa<cda+__b and caa+_ba>cda and daa<dda+a_b and daa+aba>dda then
if ada.oneWay then
if bba then
local b_b=self:get(bba,"velocity")if
b_b and b_b.y>=0 and(daa+aba-b_b.y*0.1)<=dda then return true,"static"end end else return true,"static"end end end end
for _da,ada in pairs(dca.dynamic)do
if _da~=bba and(not cba or
bit.band(ada.layer or 1,cba)>0)then local bda=ada.collider;local cda=
(ada.x or 0)+ (bda.x or 0)
local dda=(ada.y or 0)+ (bda.y or 0)if
caa<cda+ (bda.w or 0)and caa+_ba>cda and daa<dda+
(bda.h or 0)and daa+aba>dda then return true,_da end end end end end end end;return false end;function d_a:addTrigger(caa,daa,_ba,aba,bba,cba)
table.insert(self._triggers,{x=caa,y=daa,w=_ba,h=aba,onEnter=bba,onExit=cba,entitiesInside={}})end
function d_a:_updateTriggers()
for caa,daa in
ipairs(self._triggers)do local _ba=self:queryRect(daa.x,daa.y,daa.w,daa.h)
local aba={}for bba,cba in ipairs(_ba)do aba[cba]=true end
for bba in pairs(daa.entitiesInside)do if not
aba[bba]then if daa.onExit then daa.onExit(bba)end;daa.entitiesInside[bba]=
nil end end;for bba,cba in ipairs(_ba)do
if not daa.entitiesInside[cba]then if daa.onEnter then
daa.onEnter(cba)end;daa.entitiesInside[cba]=true end end end end
function d_a:loadUI(caa,daa,_ba)local aba,bba=_d.loadUI(caa)if not aba then
dc.error("Failed to load OUI: "..tostring(bba))return end;for cba,dba in pairs(aba.elements)do
self.ui:add(cba,dba.type,(
daa or 0)+ (dba.x or 0),(_ba or 0)+ (dba.y or 0),dba)end end
function d_a:unloadUI(caa)local daa=_d.loadUI(caa)if daa then for _ba in pairs(daa.elements)do
self.ui:remove(_ba)end end end
function d_a:addUI(caa,daa,_ba,aba,bba)return self.ui:add(caa,daa,_ba,aba,bba)end;function d_a:updateUI(caa,daa)self.ui:update(caa,daa)end
function d_a:bindHUD(caa,daa)self._nextHudId=(
self._nextHudId or 0)+1;local _ba=self._nextHudId
table.insert(self._hudCallbacks,{id=_ba,name=caa,fn=daa})return _ba end
function d_a:unbindHUD(caa)for i=#self._hudCallbacks,1,-1 do
if
self._hudCallbacks[i].id==caa then table.remove(self._hudCallbacks,i)end end end;function d_a:addSystem(caa,daa)
table.insert(self._systems.update,{filter=caa,update=daa})end
function d_a:attach(caa,daa,_ba)
c_a.attach(self,caa,daa,_ba)
if daa=="z"or daa=="sprite"then if daa=="sprite"and _ba==nil then
dc.warn(
"Scene: Sprite component set to nil for entity "..tostring(caa))end;self._zDirty=true end end
function d_a:despawn(caa)local daa=self:get(caa,"pos")
local _ba=self:get(caa,"sprite")
if daa and _ba then local aba,bba=a_a:getSize()local cba,dba=__a.designW,__a.designH
local _ca=
(cba and dba)and math.floor((bba-dba)/2)or 0;local aca=self.camera.y-_ca
local bca=math.floor(daa.y-aca)
for i=0,_ba.height-1 do local cca=bca+i;if cca>=1 and cca<=bba then
self._rowsToRestore[cca]=true end end end;c_a.despawn(self,caa)self._zDirty=true end
function d_a:update(caa)self:_updateDynamicGrid()
local daa=self:select("pos","parent")
for _ba,aba in ipairs(daa)do local bba=self:get(aba,"parent")
local cba=self:get(bba.id,"pos")local dba=self:get(aba,"pos")
if cba and dba then dba:set(cba.x+bba.offset.x,
cba.y+bba.offset.y)end end
for _ba,aba in ipairs(self._systems.update)do
local bba=self:select(table.unpack(aba.filter))
local cba,dba=xpcall(function()aba.update(caa,bba,self._store)end,aaa)if not cba then
local _ca="["..table.concat(aba.filter,", ").."]"
cd.report("System ".._ca..":\n"..dba)return end end;self:_updateTriggers()if self.onUpdate then
local _ba,aba=xpcall(self.onUpdate,aaa,caa)
if not _ba then cd.report("Scene.onUpdate:\n"..aba)return end end
for _ba,aba in
ipairs(self._hudCallbacks)do
local bba,cba=xpcall(function()aba.fn(self,caa)end,aaa)
if not bba then cd.report("HUD callback:\n"..cba)end end end
function d_a:draw()
local caa=self.camera.x~=self._lastCam.x or self.camera.y~=
self._lastCam.y;local daa,_ba=a_a:getSize()local aba,bba=__a.designW,__a.designH;local cba,dba=0,0;if
aba and bba then
cba=math.max(0,math.floor((daa-aba)/2))
dba=math.max(0,math.floor((_ba-bba)/2))end;local _ca,aca=0,0;if self._camera and
self._camera:isShaking()then
_ca,aca=self._camera:getShakeOffset()end
local bca=self.camera.x-cba+_ca;local cca=self.camera.y-dba+aca
if self._staticSortDirty then
table.sort(self._staticElements,function(dca,_da)return
dca.z<_da.z end)self._staticSortDirty=false end
if self._foregroundSortDirty then
table.sort(self._foregroundElements,function(dca,_da)return dca.z<_da.z end)self._foregroundSortDirty=false end
if self._staticDirty or caa or
(self._camera and self._camera:isShaking())then
self:_renderStatic(bca,cca,daa,_ba)else self:_restoreRows()end;self:_renderEntities(bca,cca,daa,_ba)
self:_renderForeground(bca,cca,daa,_ba)if not __a.unsupportedResolution then
self.ui:draw(cba,dba,self._rowsToRestore)end;if self._camera and
self._camera:isFlashing()then local dca=self._camera:getFlashColor()
a_a:drawRect(1,1,daa,_ba," ",dca,dca)end;if __a.enabled then
self:_renderDebug(daa,_ba)end;if self.onDraw then local dca,_da=xpcall(self.onDraw,aaa)
if not
dca then cd.report("Scene.onDraw:\n".._da)end end end
function d_a:_renderStatic(caa,daa,_ba,aba)a_a:clear()
if self.tilemap then local bba=self.tilemap;local cba=math.max(1,
math.floor(caa/bba.tileW)+1)
local dba=math.max(1,math.floor(daa/
bba.tileH)+1)
local _ca=math.floor((caa+_ba)/bba.tileW)+1
local aca=math.floor((daa+aba)/bba.tileH)+1
if bba.layers then
for bca,cca in ipairs(bba.layers)do
for ty=dba,aca do
if cca.data[ty]then
for tx=cba,_ca do
local dca=cca.data[ty][tx]if dca and dca>0 and bba.sprite[dca]then
a_a:drawSprite(bba.sprite[dca],(tx-1)*
bba.tileW,(ty-1)*bba.tileH,caa,daa)end end end end end else
for ty=dba,aca do
if bba.data[ty]then
for tx=cba,_ca do local bca=bba.data[ty][tx]if bca and bca>0 and
bba.sprite[bca]then
a_a:drawSprite(bba.sprite[bca],(tx-1)*bba.tileW,(ty-1)*bba.tileH,caa,daa)end end end end end end
for bba,cba in ipairs(self._staticElements)do local dba=cba.sprite
local _ca=math.floor(cba.x-caa)local aca=math.floor(cba.y-daa)if
dba and dba[1]and
_ca+dba.width>=1 and _ca<=_ba and aca+dba.height>=1 and aca<=aba then
a_a:drawSprite(dba[1],cba.x,cba.y,caa,daa)end end;a_a:copyTo(self._staticCache)self._staticDirty=false
self._rowsToRestore={}
self._lastCam.x,self._lastCam.y=self.camera.x,self.camera.y end
function d_a:_restoreRows()for caa in pairs(self._rowsToRestore)do
a_a:restoreLine(caa,self._staticCache)end;self._rowsToRestore={}end
function d_a:_renderEntities(caa,daa,_ba,aba)
if self._zDirty then
self._sortedEntities=self:select("pos","sprite")
table.sort(self._sortedEntities,function(bba,cba)local dba=self:get(bba,"z")or 0;local _ca=
self:get(cba,"z")or 0;return dba<_ca end)self._zDirty=false end;__a.dynamicCount=#self._sortedEntities
for bba,cba in
ipairs(self._sortedEntities)do local dba=self:get(cba,"pos")local _ca=self:get(cba,"sprite")
local aca=self:get(cba,"animation")local bca=1
if aca and aca.sequences and aca.state then
local dca=aca.sequences[aca.state]bca=dca and dca[aca.currentFrame or 1]or
(aca.currentFrame or 1)elseif aca then
bca=aca.currentFrame or 1 end;local cca=_ca and _ca[bca]
if cca then local dca=math.floor(dba.x-caa)local _da=math.floor(
dba.y-daa)local ada=_ca.width or 0
local bda=_ca.height or 0
if
dca+ada>=1 and dca<=_ba and _da+bda>=1 and _da<=aba then local cda=self:get(cba,"colorOverride")
local dda=self:get(cba,"charOverride")local __b=self:get(cba,"bgOverride")
if cda or dda or __b then
for row=0,bda-1 do local a_b=math.floor(
dba.y-daa)+row;local b_b
if dda then
b_b=string.rep(dda:sub(1,1),ada)elseif cca[1]and cca[1][row+1]then
b_b=table.concat(cca[1][row+1])else b_b=string.rep(" ",ada)end
a_a:drawText(math.floor(dba.x-caa),a_b,b_b,cda or" ",__b or" ")end else a_a:drawSprite(cca,dba.x,dba.y,caa,daa)end
for i=0,bda-1 do local a_b=_da+i;if a_b>=1 and a_b<=aba then
self._rowsToRestore[a_b]=true end end end end end end
function d_a:_renderForeground(caa,daa,_ba,aba)
for bba,cba in ipairs(self._foregroundElements)do local dba=cba.sprite
local _ca=math.floor(cba.x-caa)local aca=math.floor(cba.y-daa)
if
dba and dba[1]and
_ca+dba.width>=1 and _ca<=_ba and aca+dba.height>=1 and aca<=aba then
a_a:drawSprite(dba[1],cba.x,cba.y,caa,daa)
for i=0,dba.height-1 do self._rowsToRestore[aca+i]=true end end end end
function d_a:_renderDebug()if __a.alwaysOnTop then return end
local caa=string.format("FPS: %d | Upd: %dms | Draw: %dms",__a.fps,__a.updateTime,__a.drawTime)
local daa=string.format("Entities: %d (Dyn) | %d (Stat)",__a.dynamicCount,#self._staticElements)a_a:drawText(1,1,caa,"0","f")
a_a:drawText(1,2,daa,"7","f")self._rowsToRestore[1]=true
self._rowsToRestore[2]=true
if __a.showLogs then local _ba=dc.getHistory()
for aba,bba in ipairs(_ba)do
a_a:drawText(1,3 +aba,bba.text,bba.color,"f")self._rowsToRestore[3 +aba]=true end end end;return b_a
]=]
paths["core.scene"] = "core/scene"
sources["core.serialization"] = [=[
local aa=...local ba=aa("core.logger")local ca=aa("core.loader")
local da=aa("core.math")local _b={}
function _b.pack(ab)
local bb={name=ab.name or"Unnamed Scene",camera={x=ab.camera.x,y=ab.camera.y},tilemap=nil,statics={},entities={}}
if ab.tilemap then
bb.tilemap={spritePath=ab.tilemap.spritePath,data=ab.tilemap.data,solidTiles=ab.tilemap.solidTiles,tileProperties=ab.tilemap.tileProperties}end
for cb,db in ipairs(ab._staticElements)do
table.insert(bb.statics,{spritePath=db.spritePath,x=db.x,y=db.y,z=db.z,collider=db.collider,layer=db.layer})end
for cb,db in pairs(ab._entities)do local _c={id=cb,components={}}local ac=ab._tags[cb]
for bc,cc in
pairs(ac)do local dc=ab._store[bc][cb]
if bc=="sprite"then
_c.components[bc]={spritePath=dc.path}elseif da.isVec2(dc)then
_c.components[bc]={__type="vec2",x=dc.x,y=dc.y}elseif type(dc)=="table"then local _d={}for ad,bd in pairs(dc)do
if type(bd)~="function"then _d[ad]=bd end end;_c.components[bc]=_d else
_c.components[bc]=dc end end;table.insert(bb.entities,_c)end;return bb end
function _b.save(ab,bb)local cb=_b.pack(ab)local db=fs.open(bb,"w")if not db then
ba.error(
"Serialization: Could not open file for writing: "..tostring(bb))return false end
local _c,ac=pcall(function()
db.write(textutils.serialize(cb))end)db.close()if not _c then
ba.error("Serialization: Failed to serialize scene: "..tostring(ac))return false end
ba.info("Scene serialized to "..bb)return true end
function _b.apply(ab,bb)local cb={}for _c in pairs(ab._entities)do cb[#cb+1]=_c end;for _c,ac in
ipairs(cb)do ab:despawn(ac)end;ab._staticElements={}
ab._foregroundElements={}ab.tilemap=nil;ab._spatialGrid={}ab._activeDynamicCells={}
ab._staticDirty=true;ab.name=bb.name
ab.camera:set(bb.camera.x,bb.camera.y)
if bb.tilemap and bb.tilemap.spritePath then
local _c=ca.loadSprite(bb.tilemap.spritePath)
ab:setTilemap(_c,bb.tilemap.data,bb.tilemap.solidTiles,bb.tilemap.tileProperties)ab.tilemap.spritePath=bb.tilemap.spritePath end
for _c,ac in ipairs(bb.statics)do local bc=
ac.spritePath and ca.loadSprite(ac.spritePath)or nil
ab:addStatic(bc,ac.x,ac.y,{z=ac.z,collider=ac.collider,layer=ac.layer})
ab._staticElements[#ab._staticElements].spritePath=ac.spritePath end;local db={}
for _c,ac in ipairs(bb.entities)do local bc=ab:spawn()db[ac.id]=bc end
for _c,ac in ipairs(bb.entities)do local bc=db[ac.id]
for cc,dc in pairs(ac.components)do
if cc=="sprite"then
local _d=ca.loadSprite(dc.spritePath)ab:attach(bc,"sprite",_d)elseif
type(dc)=="table"and dc.__type=="vec2"then ab:attach(bc,cc,da.vec2(dc.x,dc.y))elseif cc=="pos"then
ab:attach(bc,"pos",da.vec2(
dc.x or 0,dc.y or 0))elseif cc=="parent"and type(dc)=="table"and dc.id then local _d={id=
db[dc.id]or dc.id}
if dc.offset then _d.offset=da.vec2(dc.offset.x or 0,
dc.offset.y or 0)end;ab:attach(bc,"parent",_d)else ab:attach(bc,cc,dc)end end end end;return _b
]=]
paths["core.serialization"] = "core/serialization"
sources["core.server"] = [=[
local cba=...local dba=cba("core.logger")local _ca=cba("core.network")
local aca=cba("core.buffer")local bca={}bca._emit=function()end;local cca;local dca={}local _da={}local ada={}local bda={}local cda={}
local dda=nil;local __b=nil;local a_b=false;local b_b=nil;local c_b=nil;local d_b=20;local _ab=30;local aab=5;local bab=false
local cab={enabled=false,title="Obsidian Server",maxEntries=200,log={},lines={},lastWidth=0,lastHeight=0,startTime=
nil,dirty=true,buf=nil}
local dab={info={fore="0",prefix="[INFO ] "},warn={fore="1",prefix="[WARN ] "},error={fore="e",prefix="[ERROR] "},success={fore="d",prefix="[OK   ] "},system={fore="b",prefix="[SYS  ] "},debug={fore="7",prefix="[DEBUG] "}}local _bb=0
local function abb()local __c=os.date("*t")return
string.format("%02d:%02d:%02d",__c.hour,__c.min,__c.sec)end
local function bbb(__c,a_c,b_c)if a_c<=0 or#__c<=a_c then return{__c}end;local c_c={}
local d_c=string.rep(" ",b_c)local _ac=__c
while#_ac>a_c do local aac=a_c;for i=a_c,b_c+1,-1 do
if _ac:sub(i,i)==" "then aac=i-1;break end end;c_c[#c_c+1]=_ac:sub(1,aac)local bac=_ac:sub(
aac+1):match("^%s*(.*)")_ac=(#bac>0)and(
d_c..bac)or""end;if#_ac>0 then c_c[#c_c+1]=_ac end;return c_c end
local function cbb(__c)cab.lines={}
for a_c,b_c in ipairs(cab.log)do
local c_c=b_c.ts.."  "..b_c.prefix..b_c.raw;for d_c,_ac in ipairs(bbb(c_c,__c,_bb))do
cab.lines[#cab.lines+1]={text=_ac,fore=b_c.fore}end end;cab.lastWidth=__c end
local function dbb(__c,a_c)a_c=dab[a_c]or dab.info
local b_c={ts=abb(),prefix=a_c.prefix,raw=tostring(__c),fore=a_c.fore}table.insert(cab.log,b_c)
if#cab.log>cab.maxEntries then
table.remove(cab.log,1)if cab.lastWidth>0 then cbb(cab.lastWidth)end else
if
cab.lastWidth>0 then
local c_c=b_c.ts.."  "..b_c.prefix..b_c.raw;for d_c,_ac in ipairs(bbb(c_c,cab.lastWidth,_bb))do
cab.lines[#cab.lines+1]={text=_ac,fore=b_c.fore}end end end;cab.dirty=true end
local function _cb()if not cab.enabled or not cab.dirty then return end
cab.dirty=false;local __c,a_c=term.getSize()if __c==0 or a_c==0 then return end
if
not cab.buf then cab.buf=aca.new(__c,a_c)cab.lastWidth=__c;cab.lastHeight=a_c elseif __c~=
cab.lastWidth or a_c~=cab.lastHeight then
cab.buf:setSize(__c,a_c)cab.lastWidth=__c;cab.lastHeight=a_c end;if __c~=cab.lastWidth then cbb(__c)end;local b_c=cab.buf;local c_c=""
if
cab.startTime then
local bbc=math.floor(os.epoch("utc")/1000 -cab.startTime)local cbc=math.floor(bbc/60)local dbc=bbc%60
c_c=string.format("up %dm%02ds",cbc,dbc)end
local d_c=string.format("ID:%-3d  %s ",os.getComputerID(),c_c)
local _ac=(" "..cab.title..string.rep(" ",__c)):sub(1,
__c-#d_c)..d_c;b_c:drawLine(1,_ac,"f","5")local aac=b_b or"(no protocol)"
local bac=0;for bbc in pairs(dca)do bac=bac+1 end
local cac=string.format(" proto: %-20s  clients: %d",aac,bac)b_c:drawLine(a_c,cac,"0","8")local dac=a_c-2;local _bc=math.max(1,
#cab.lines-dac+1)local abc=2;for i=_bc,math.min(_bc+dac-1,#cab.lines)
do local bbc=cab.lines[i]
b_c:drawLine(abc,bbc.text,bbc.fore,"f")abc=abc+1 end
while
abc<a_c do b_c:drawLine(abc,"","0","f")abc=abc+1 end;b_c:present()end
function bca.showConsole(__c)cab.enabled=true;if __c then cab.title=__c end end
function bca.log(__c,a_c)dbb(tostring(__c),a_c or"info")end
local function acb(__c,a_c)return
{type=__c,data=a_c or{},sender=os.getComputerID(),timestamp=os.epoch("utc")}end;function bca.getClients()local __c={}for a_c in pairs(dca)do __c[#__c+1]=a_c end
return __c end;function bca.clientCount()local __c=0;for a_c in pairs(dca)do
__c=__c+1 end;return __c end;function bca.isConnected(__c)return
dca[__c]~=nil end;function bca.setMeta(__c,a_c,b_c)if dca[__c]then
dca[__c].meta[a_c]=b_c end end
function bca.getMeta(__c,a_c)if dca[__c]then return
dca[__c].meta[a_c]end;return nil end
local function bcb(__c)if not dca[__c]then return end;dca[__c]=nil;cca.sessions[__c]=nil;cca.nonces[__c]=
nil
for a_c,b_c in pairs(_da)do b_c[__c]=nil;local c_c=0
for d_c in pairs(b_c)do c_c=c_c+1 end;if c_c==0 then _da[a_c]=nil end end;if __b then pcall(__b,__c)end
bca._emit("server.clientDisconnect",__c)
dba.info("Server: Client "..__c.." disconnected")
dbb("Client #"..__c.." disconnected","warn")end
function bca.kick(__c,a_c)if not dca[__c]then return end
bca.send(__c,"SERVER_KICK",{reason=a_c or"Kicked by server"})bcb(__c)end
function bca.joinRoom(__c,a_c)if not dca[__c]then return end
if not _da[a_c]then _da[a_c]={}end;_da[a_c][__c]=true end
function bca.leaveRoom(__c,a_c)if _da[a_c]then _da[a_c][__c]=nil end end
function bca.getRoomClients(__c)local a_c={}if _da[__c]then
for b_c in pairs(_da[__c])do a_c[#a_c+1]=b_c end end;return a_c end;function bca.getClientRooms(__c)local a_c={}
for b_c,c_c in pairs(_da)do if c_c[__c]then a_c[#a_c+1]=b_c end end;return a_c end;function bca.send(__c,a_c,b_c)if
not _ca.isOpen then return false end;local c_c=acb(a_c,b_c)
rednet.send(__c,c_c,b_b)return true end
function bca.broadcast(__c,a_c,b_c)if
not _ca.isOpen then return end;local c_c=acb(__c,a_c)for d_c in pairs(dca)do if d_c~=b_c then
rednet.send(d_c,c_c,b_b)end end end
function bca.broadcastRoom(__c,a_c,b_c,c_c)if not _da[__c]then return end;local d_c=acb(a_c,b_c)for _ac in
pairs(_da[__c])do
if _ac~=c_c and dca[_ac]then rednet.send(_ac,d_c,b_b)end end end;function bca.on(__c,a_c)ada[__c]=a_c end
function bca.off(__c)ada[__c]=nil end;function bca.use(__c)bda[#bda+1]=__c end
local function ccb(__c,a_c)local b_c=0
local function c_c()b_c=b_c+1
if b_c<=#bda then
local d_c,_ac=pcall(bda[b_c],__c,a_c,c_c)if not d_c then
dba.error("Server middleware error: "..tostring(_ac))end else local d_c=ada[a_c.type]
if d_c then
local _ac,aac=pcall(d_c,__c,a_c.data or{},a_c)if not _ac then
dba.error("Server handler error ["..
tostring(a_c.type).."]: "..tostring(aac))end end end end;c_c()end;function bca.onConnect(__c)dda=__c end;function bca.onDisconnect(__c)__b=__c end
cca={enabled=false,db=nil,sessions={},nonces={},attempts={},opts={}}
local function dcb(__c)local a_c=5381;for i=1,#__c do
a_c=( (a_c*33)+string.byte(__c,i))%2147483647 end;return tostring(a_c)end;local function _db(__c)local a_c={}
for b_c,c_c in pairs(__c)do if b_c~="passwordHash"then a_c[b_c]=c_c end end;return a_c end
function bca.enableAuth(__c,a_c)
assert(__c,"server.enableAuth: db must be an Obsidian DB collection")a_c=a_c or{}cca.db=__c;cca.opts=a_c;cca.enabled=true
local b_c=a_c.minNameLen or 3;local c_c=a_c.maxNameLen or 16
ada["REGISTER"]=function(d_c,_ac)
local aac=tostring(_ac.name or"")local bac=tostring(_ac.passwordHash or"")
local cac=_ac.class;if#aac<b_c or#aac>c_c then
bca.send(d_c,"REGISTER_FAILED",{message="Name must be "..b_c..
"-"..c_c.." characters."})return end;if
aac:match("[^%w_%-]")then
bca.send(d_c,"REGISTER_FAILED",{message="Name may only contain letters, numbers, - and _"})return end;if
#bac==0 then
bca.send(d_c,"REGISTER_FAILED",{message="No password supplied."})return end;if
cca.db:findOne({name=aac})then
bca.send(d_c,"REGISTER_FAILED",{message="Name already taken."})return end
local dac={cid=d_c,name=aac,passwordHash=bac,class=cac}
if a_c.buildProfile then local _bc=a_c.buildProfile(d_c,_ac)or{}for abc,bbc in
pairs(_bc)do dac[abc]=bbc end end;cca.db:insert(dac)cca.sessions[d_c]=dac
dba.info("Auth: '"..aac..
"' registered (client "..d_c..")")
dbb("Auth: '"..aac.."' registered","success")
bca.send(d_c,"REGISTER_SUCCESS",{profile=_db(dac)})
if a_c.onRegister then pcall(a_c.onRegister,d_c,dac)end end
ada["LOGIN_CHALLENGE_REQUEST"]=function(d_c,_ac)local aac=os.epoch("utc")/1000
local bac=cca.attempts[d_c]
if bac and aac<bac.resetAt then
bca.send(d_c,"LOGIN_FAILED",{message=string.format("Too many failed attempts. Try again in %ds.",math.ceil(
bac.resetAt-aac))})return end;local cac=tostring(_ac.name or"")
math.randomseed(os.epoch("utc")+d_c)
local dac=tostring(math.random(10000000,99999999))..tostring(os.epoch("utc")%
1000000)cca.nonces[d_c]={nonce=dac,name=cac,expireAt=aac+30}
bca.send(d_c,"LOGIN_CHALLENGE",{nonce=dac})end
ada["LOGIN"]=function(d_c,_ac)local aac=os.epoch("utc")/1000
local bac=cca.nonces[d_c]local cac=tostring(_ac.name or"")
local dac=tostring(_ac.response or"")
if not bac or bac.name~=cac or aac>bac.expireAt then cca.nonces[d_c]=
nil
bca.send(d_c,"LOGIN_FAILED",{message="Challenge expired. Please try again."})return end;cca.nonces[d_c]=nil
local _bc=cca.db:findOne({name=cac})
if
not _bc or dcb(_bc.passwordHash..bac.nonce)~=dac then local abc=cca.attempts[d_c]or{count=0,resetAt=0}abc.count=
abc.count+1;if abc.count>=5 then abc.resetAt=aac+60;abc.count=0
dbb("Auth: Client #"..d_c..
" rate-limited","warn")end
cca.attempts[d_c]=abc
bca.send(d_c,"LOGIN_FAILED",{message="Wrong username or password."})
dbb("Auth: Failed login for '"..cac.."'","warn")return end;cca.attempts[d_c]=nil;if _bc.cid~=d_c then
cca.db:update({name=cac},{cid=d_c})_bc.cid=d_c end
cca.sessions[d_c]=_bc
dba.info("Auth: '"..cac.."' logged in (client "..d_c..")")
dbb("Auth: '"..cac.."' logged in","success")
bca.send(d_c,"LOGIN_SUCCESS",{profile=_db(_bc)})if a_c.onLogin then pcall(a_c.onLogin,d_c,_bc)end end
ada["LOGOUT"]=function(d_c)local _ac=cca.sessions[d_c]cca.sessions[d_c]=nil;if _ac then
dba.info(
"Auth: '".._ac.name.."' logged out (client "..d_c..")")
dbb("Auth: '".._ac.name.."' logged out","info")end;if a_c.onLogout then
pcall(a_c.onLogout,d_c,_ac)end end end
bca.auth={isLoggedIn=function(__c)return cca.sessions[__c]~=nil end,getProfile=function(__c)return
cca.sessions[__c]end,logout=function(__c)cca.sessions[__c]=nil end,require=function(__c)if
not cca.sessions[__c]then
bca.send(__c,"AUTH_REQUIRED",{message="Please log in first."})return false end;return true end}function bca.onTick(__c)cda[#cda+1]=__c end;function bca.setTickRate(__c)
d_b=math.max(1,__c)end;function bca.setTimeout(__c)_ab=__c end;function bca.setHeartbeatInterval(__c)
aab=__c end;function bca.enableSequencing()bab=true end
function bca.getPing(__c)
local a_c=dca[__c]return a_c and a_c.ping or nil end
function bca.sendToList(__c,a_c,b_c)if not _ca.isOpen then return end;local c_c=acb(a_c,b_c)
for d_c,_ac in ipairs(__c)do if
dca[_ac]then rednet.send(_ac,c_c,b_b)end end end
function bca.init(__c,a_c,b_c)b_b=__c;if not _ca.open(b_c)then
dba.error("Server: No modem found!")return false end;if not _ca.host(__c,a_c)then
dba.error(
"Server: Failed to host protocol '"..__c.."'")return false end;c_b=a_c
dba.info(string.format("Server: Online | protocol='%s' hostname='%s' id=%d",__c,a_c,os.getComputerID()))return true end
function bca.stop()if not a_b then return end;a_b=false
bca.broadcast("SERVER_SHUTDOWN",{reason="Server shutting down"})local __c={}for a_c in pairs(dca)do __c[#__c+1]=a_c end;for a_c,b_c in ipairs(__c)do dca[b_c]=
nil end;_da={}_ca.close()
dbb("Server stopped.","system")_cb()bca._emit("server.stopped")
dba.info("Server: Stopped")end
local function adb(__c,a_c,b_c)if b_c~=b_b then return end
if type(a_c)~="table"or not a_c.type then return end
if type(a_c)=="table"and a_c.type=="DISCOVER"and
a_c.hostname==c_b then
dba.info("Server: DISCOVER from "..
tostring(__c).." — replying")
rednet.send(__c,{type="DISCOVER_REPLY",hostname=c_b,serverId=os.getComputerID()},b_c)return end
if dca[__c]then dca[__c].lastSeen=os.epoch("utc")/1000 end
if a_c.type=="CONNECT_REQUEST"then
dca[__c]={id=__c,meta={},joinedAt=os.epoch("utc")/1000,lastSeen=
os.epoch("utc")/1000,ping=nil,heartbeatSent=nil,lastSeq=-1}
rednet.send(__c,acb("CONNECT_ACCEPT",{serverId=os.getComputerID(),serverTime=os.epoch("utc")}),b_b)if dda then pcall(dda,__c)end
bca._emit("server.clientConnect",__c)
dba.info("Server: Client "..__c.." connected")
dbb("Client #"..__c.." connected","success")return end;if a_c.type=="CLIENT_LEAVE"then bcb(__c)return end;if
not dca[__c]then return end;if a_c.type=="PING"then local c_c=a_c.t or(type(a_c.data)=="table"and
a_c.data.t)
rednet.send(__c,acb("PONG",{t=c_c}),b_b)return end
if a_c.type==
"PONG"then local c_c=dca[__c]
if c_c and c_c.heartbeatSent then
c_c.ping=math.floor((
os.epoch("utc")-c_c.heartbeatSent))c_c.heartbeatSent=nil end;return end;if bab and a_c.seq then local c_c=dca[__c]if a_c.seq<=c_c.lastSeq then return end
c_c.lastSeq=a_c.seq end;ccb(__c,a_c)end;local bdb=nil;local cdb=0
local function ddb()local __c=os.epoch("utc")/1000;local a_c=__c-cdb
cdb=__c
for b_c,c_c in pairs(dca)do
if _ab>0 and __c-c_c.lastSeen>_ab then dba.warn("Server: Client "..b_c..
" timed out")
dbb(string.format("Client #%d timed out",b_c),"warn")bca.kick(b_c,"Timed out")elseif
aab>0 and not c_c.heartbeatSent and(__c-c_c.lastSeen)>=aab then
c_c.heartbeatSent=os.epoch("utc")
rednet.send(b_c,acb("PING",{t=c_c.heartbeatSent}),b_b)end end
for b_c,c_c in ipairs(cda)do local d_c,_ac=pcall(c_c,a_c)if not d_c then
dba.error("Server tick error: "..tostring(_ac))
dbb("Tick error: "..tostring(_ac),"error")end end;cab.dirty=true;_cb()bdb=os.startTimer(1 /d_b)end
function bca.processEvent(__c)local a_c=__c[1]
if a_c=="rednet_message"then
adb(__c[2],__c[3],__c[4])elseif a_c=="term_resize"then cab.dirty=true elseif a_c=="timer"and __c[2]==bdb then ddb()end end
function bca.start()if not b_b then
dba.error("Server: Call server.init() before server.start()")return false end;a_b=true;cdb=
os.epoch("utc")/1000;cab.startTime=cdb
bdb=os.startTimer(1 /d_b)bca._emit("server.started")
dba.info("Server: Running at "..d_b.." ticks/s")
dbb("Server started on ".. (b_b or"?"),"system")if cab.enabled then local __c,a_c=term.getSize()cbb(__c)cab.lastWidth=__c
cab.lastHeight=a_c end;return true end
function bca.run()if not bca.start()then return end
while a_b do
local __c={os.pullEventRaw()}if __c[1]=="terminate"then
dba.info("Server: Terminate signal received")bca.stop()break end
bca.processEvent(__c)end end;return bca
]=]
paths["core.server"] = "core/server"
sources["core.storage"] = [=[
local c={}local d="saves/"function c.setDir(_a)d=_a end
function c.save(_a,aa)if not fs.exists(d)then
fs.makeDir(d)end;local ba=fs.combine(d,_a..".dat")
local ca=fs.open(ba,"w")
if not ca then return false,"Could not open file for writing: "..ba end
local da,_b=pcall(function()ca.write(textutils.serialize(aa))end)ca.close()return da,_b end
function c.load(_a)local aa=fs.combine(d,_a..".dat")
if not fs.exists(aa)then return nil,
"Save file does not exist: "..aa end;local ba=fs.open(aa,"r")if not ba then
return nil,"Could not open file for reading: "..aa end;local ca=ba.readAll()ba.close()
local da,_b=pcall(textutils.unserialize,ca)if not da then
return nil,"Failed to deserialize save data: "..tostring(_b)end;return _b,nil end
function c.delete(_a)local aa=fs.combine(d,_a..".dat")if fs.exists(aa)then
fs.delete(aa)return true end;return false end
function c.list()if not fs.exists(d)then return{}end;local _a={}for aa,ba in ipairs(fs.list(d))do
if ba:sub(
-4)==".dat"then _a[#_a+1]=ba:sub(1,-5)end end;return _a end;return c
]=]
paths["core.storage"] = "core/storage"
sources["core.thread"] = [=[
local da=...local _b=da("core.logger")local ab={}ab.errorHandler=nil;local bb={}local cb=1;local function db(bc)local cc=
_G and _G.debug
return(cc and cc.traceback)and
cc.traceback(tostring(bc),2)or tostring(bc)end;local _c={}function _c:stop()return
ab.stop(self)end
function _c:isAlive()local bc=
type(self)=="table"and self.id or nil;if not bc then return false end
local cc=bb[bc]
return cc~=nil and coroutine.status(cc.co)~="dead"end
function _c:getStatus()
local bc=type(self)=="table"and self.id or nil;if not bc then return nil end;local cc=bb[bc]
return cc and cc.status or nil end;function _c:yield(bc)return ab.yield(bc)end;local function ac(bc)local cc={id=bc}
setmetatable(cc,{__index=_c})return cc end
function ab.start(bc)
local cc=coroutine.create(function(...)
local ad,bd=xpcall(bc,db,...)
if not ad then if ab.errorHandler then ab.errorHandler(bd)else
_b.error("[Thread] Uncaught error: "..tostring(bd))end end end)local dc=cb;cb=cb+1;local _d=ac(dc)
bb[dc]={id=dc,co=cc,status="running",filter=nil,handle=_d}return _d end
function ab.stop(bc)local cc=bc
if type(bc)=="table"and bc.id then cc=bc.id end;if cc==nil then return false end;if bb[cc]then bb[cc]=nil;return true end;return
false end
function ab.getAll()local bc={}for cc,dc in pairs(bb)do bc[cc]=dc end;return bc end
function ab.count()local bc=0;for cc,dc in pairs(bb)do
if coroutine.status(dc.co)~="dead"then bc=bc+1 end end;return bc end;function ab.reset()bb={}cb=1 end
function ab.yield(bc)return coroutine.yield(bc)end
function ab.update(...)local bc={...}local cc={}for dc,_d in pairs(bb)do cc[dc]=_d end
for dc,_d in pairs(cc)do
if
coroutine.status(_d.co)~="dead"then
if _d.filter==bc[1]or _d.filter==nil then
local ad,bd=coroutine.resume(_d.co,table.unpack(bc))
if not ad then if ab.errorHandler then ab.errorHandler(bd)else
_b.error("[Thread] Error in Thread "..dc..
": "..tostring(bd))end;bb[dc]=nil else
_d.filter=bd end end else bb[dc]=nil end end end;return ab
]=]
paths["core.thread"] = "core/thread"
sources["core.tilemap"] = [=[
local aa=...local ba=aa("core.loader")local ca=aa("core.storage")local da={}
local _b={}
function _b.new(ab)ab=ab or{}
local bb={tileW=ab.tileW or 2,tileH=ab.tileH or 1,_defs={},_layers={},_layerMap={},_sprites={},_scene=nil}setmetatable(bb,{__index=da})return bb end
function da:defineTile(ab,bb)
assert(type(ab)=="number"and ab>0,"tilemap:defineTile id must be a positive number")bb=bb or{}
self._defs[ab]={spritePath=bb.spritePath,solid=bb.solid or false,type=bb.type,hL=bb.hL or 0,hR=bb.hR or 0}end;function da:getTileDef(ab)return self._defs[ab]end
function da:addLayer(ab,bb)
assert(type(ab)==
"string","layer name must be a string")
assert(not self._layerMap[ab],"layer '"..ab.."' already exists")bb=bb or{}
local cb={name=ab,z=bb.z or-100,collision=bb.collision or false,data={}}table.insert(self._layers,cb)
table.sort(self._layers,function(db,_c)
return db.z<_c.z end)self._layerMap[ab]=cb;return cb end
function da:removeLayer(ab)self._layerMap[ab]=nil;for i=#self._layers,1,-1 do
if
self._layers[i].name==ab then table.remove(self._layers,i)return true end end;return false end;function da:getLayer(ab)return self._layerMap[ab]end
function da:setTile(ab,bb,cb,db)
local _c=self._layerMap[ab]
assert(_c,"tilemap:setTile: unknown layer '"..tostring(ab).."'")if not _c.data[cb]then _c.data[cb]={}end;_c.data[cb][bb]=(
db and db>0)and db or nil
self:_markDirty()end
function da:getTile(ab,bb,cb)local db=self._layerMap[ab]if not db then return nil end;return db.data[cb]and
db.data[cb][bb]or nil end
function da:fill(ab,bb,cb,db,_c,ac)local bc=self._layerMap[ab]
assert(bc,"tilemap:fill: unknown layer '"..
tostring(ab).."'")local cc=(bb and bb>0)and bb or nil
if not cb then if cc then
error("tilemap:fill: provide x1,y1,x2,y2 when placing tiles (can't fill unbounded)")end;bc.data={}else for ty=db,ac do if
not bc.data[ty]then bc.data[ty]={}end
for tx=cb,_c do bc.data[ty][tx]=cc end end end;self:_markDirty()end
function da:copyRect(ab,bb,cb,db,_c,ac,bc,cc)local dc=self._layerMap[ab]local _d=self._layerMap[bb]
assert(dc,
"copyRect: unknown source layer '"..tostring(ab).."'")
assert(_d,"copyRect: unknown dest layer '"..tostring(bb).."'")
for oy=0,ac-db do local ad=db+oy;local bd=cc+oy
if not _d.data[bd]then _d.data[bd]={}end
for ox=0,_c-cb do local cd=cb+ox;_d.data[bd][bc+ox]=
dc.data[ad]and dc.data[ad][cd]or nil end end;self:_markDirty()end
function da:worldToTile(ab,bb)return math.floor(ab/self.tileW)+1,
math.floor(bb/self.tileH)+1 end
function da:tileToWorld(ab,bb)return(ab-1)*self.tileW, (bb-1)*self.tileH end
function da:forArea(ab,bb,cb,db,_c)local ac=math.floor(ab/self.tileW)+1;local bc=math.floor(
bb/self.tileH)+1;local cc=
math.floor(cb/self.tileW)+1
local dc=math.floor(db/self.tileH)+1
for _d,ad in ipairs(self._layers)do for ty=bc,dc do
if ad.data[ty]then for tx=ac,cc do local bd=ad.data[ty][tx]if bd then
_c(ad.name,tx,ty,bd)end end end end end end
function da:getNeighbors(ab,bb,cb)local db=self._layerMap[ab]if not db then return{}end
local _c={{0,-1},{0,1},{-1,0},{1,0}}local ac={}for bc,cc in ipairs(_c)do local dc,_d=bb+cc[1],cb+cc[2]local ad=db.data[_d]and
db.data[_d][dc]or nil
table.insert(ac,{tx=dc,ty=_d,tileId=ad})end
return ac end
function da:attach(ab)self._scene=ab
for bb,cb in pairs(self._defs)do
if cb.spritePath and not
self._sprites[cb.spritePath]then
local db=ba.loadSprite(cb.spritePath)if db then self._sprites[cb.spritePath]=db end end end;self:_buildSceneTilemap(ab)end
function da:detach()if self._scene then self._scene.tilemap=nil
self._scene._staticDirty=true;self._scene=nil end end
function da:save(ab)
local bb={tileW=self.tileW,tileH=self.tileH,defs={},layers={}}for cb,db in pairs(self._defs)do
bb.defs[cb]={spritePath=db.spritePath,solid=db.solid,type=db.type,hL=db.hL,hR=db.hR}end;for cb,db in
ipairs(self._layers)do
table.insert(bb.layers,{name=db.name,z=db.z,collision=db.collision,data=db.data})end
ca.save(ab,bb)end
function da:load(ab)local bb=ca.load(ab)if not bb then return nil,
"tilemap: no saved data for key '"..ab.."'"end;self.tileW=
bb.tileW or self.tileW
self.tileH=bb.tileH or self.tileH
for cb,db in pairs(bb.defs or{})do self._defs[tonumber(cb)]=db end;self._layers={}self._layerMap={}
for cb,db in ipairs(bb.layers or{})do local _c={name=db.name,z=db.z,collision=db.collision,data=
db.data or{}}
table.insert(self._layers,_c)self._layerMap[db.name]=_c end
table.sort(self._layers,function(cb,db)return cb.z<db.z end)return self end
function da:_markDirty()if self._scene then self:_buildSceneTilemap(self._scene)
self._scene._staticDirty=true end end
function da:_buildSceneTilemap(ab)local bb={}local cb={}local db={}
for ac,bc in pairs(self._defs)do if bc.spritePath then
local cc=self._sprites[bc.spritePath]if cc then bb[ac]=cc end end;if bc.solid then
cb[ac]=true end;if bc.type then
db[ac]={type=bc.type,hL=bc.hL or 0,hR=bc.hR or 0}end end;local _c={}
for ac,bc in ipairs(self._layers)do if bc.collision then _c=bc.data;break end end
ab.tilemap={layers=self._layers,data=_c,sprite=bb,solidTiles=cb,tileProperties=db,tileW=self.tileW,tileH=self.tileH,_map=self}end;return _b
]=]
paths["core.tilemap"] = "core/tilemap"
sources["core.timer"] = [=[
local _a=...local aa=_a("core.logger")local ba={_active={}}
local function ca()local da={}
local _b={cancel=function(ab)
return ba.cancel(ab)end,pause=function(ab)return ba.pause(ab)end,resume=function(ab)
return ba.resume(ab)end,isActive=function(ab)return ba.isActive(ab)end,getRemaining=function(ab)return
ba.getRemaining(ab)end,getFiredCount=function(ab)return ba.getFiredCount(ab)end}return setmetatable(da,{__index=_b})end
function ba.after(da,_b)if type(da)~="number"or da<0 then
aa.error("Timer: Invalid delay (must be non-negative number)")return ca()end;if type(_b)~=
"function"then
aa.error("Timer: Invalid callback (must be function)")return ca()end;local ab=ca()
table.insert(ba._active,{handle=ab,elapsed=0,interval=da,callback=_b,repeating=false,maxTimes=1,firedCount=0,paused=false})return ab end
function ba.every(da,_b,ab)if type(da)~="number"or da<=0 then
aa.error("Timer: Invalid interval (must be positive number)")return ca()end;if type(_b)~=
"function"then
aa.error("Timer: Invalid callback (must be function)")return ca()end;local bb=ca()
table.insert(ba._active,{handle=bb,elapsed=0,interval=da,callback=_b,repeating=true,maxTimes=
ab or math.huge,firedCount=0,paused=false})return bb end;function ba.nextFrame(da)return ba.after(0,da)end
function ba.cancel(da)for i=#ba._active,1,-1 do
if
ba._active[i].handle==da then table.remove(ba._active,i)return true end end;return false end
function ba.pause(da)for _b,ab in ipairs(ba._active)do
if ab.handle==da then ab.paused=true;return true end end;return false end
function ba.resume(da)for _b,ab in ipairs(ba._active)do
if ab.handle==da then ab.paused=false;return true end end;return false end
function ba.pauseAll()for da,_b in ipairs(ba._active)do _b.paused=true end end
function ba.resumeAll()for da,_b in ipairs(ba._active)do _b.paused=false end end;function ba.cancelAll()ba._active={}end
function ba.isActive(da)for _b,ab in ipairs(ba._active)do if
ab.handle==da then return true end end;return false end;function ba.count()return#ba._active end
function ba.getRemaining(da)
for _b,ab in ipairs(ba._active)do if
ab.handle==da then
return math.max(0,ab.interval-ab.elapsed)end end;return nil end
function ba.getFiredCount(da)for _b,ab in ipairs(ba._active)do
if ab.handle==da then return ab.firedCount end end;return nil end
function ba.update(da)
for i=#ba._active,1,-1 do local _b=ba._active[i]_b.elapsed=_b.elapsed+da
if not
_b.paused then
if _b.elapsed>=_b.interval then
_b.elapsed=_b.elapsed-_b.interval;_b.firedCount=_b.firedCount+1;local ab,bb=pcall(_b.callback)
if not ab then
aa.error(
"Timer: Callback error - "..tostring(bb))table.remove(ba._active,i)elseif
not _b.repeating or(
_b.maxTimes~=math.huge and _b.firedCount>=_b.maxTimes)then table.remove(ba._active,i)end end end end end
function ba.getDebugInfo()local da={}
for _b,ab in ipairs(ba._active)do
table.insert(da,{remaining=ab.interval-ab.elapsed,interval=ab.interval,repeating=ab.repeating,firedCount=ab.firedCount,maxTimes=ab.maxTimes})end;return da end;return ba
]=]
paths["core.timer"] = "core/timer"
sources["core.tween"] = [=[
local ba=...local ca=ba("core.logger")local da={_active={},easing={}}da.easing.linear=function(cb)return
cb end
da.easing.quadIn=function(cb)return cb*cb end
da.easing.quadInOut=function(cb)return
cb<0.5 and 2 *cb*cb or-1 + (4 -2 *cb)*cb end;da.easing.sineIn=function(cb)
return 1 -math.cos((cb*math.pi)/2)end
da.easing.sineOut=function(cb)return math.sin((
cb*math.pi)/2)end
da.easing.sineInOut=function(cb)return
- (math.cos(math.pi*cb)-1)/2 end;da.easing.cubicIn=function(cb)return cb*cb*cb end
da.easing.cubicOut=function(cb)local db=
cb-1;return db*db*db+1 end
da.easing.cubicInOut=function(cb)return cb<0.5 and 4 *cb*cb*cb or
1 - (-2 *cb+2)^3 /2 end;da.easing.expoIn=function(cb)
return cb==0 and 0 or 2 ^ (10 *cb-10)end
da.easing.expoOut=function(cb)return
cb==1 and 1 or 1 -2 ^ (-10 *cb)end
da.easing.expoInOut=function(cb)if cb==0 then return 0 end;if cb==1 then return 1 end;return cb<0.5 and 2 ^
(20 *cb-10)/2 or
(2 -2 ^ (-20 *cb+10))/2 end
da.easing.backIn=function(cb)local db=1.70158;local _c=db+1
return _c*cb*cb*cb-db*cb*cb end
da.easing.backOut=function(cb)local db=1.70158;local _c=db+1;return 1 +_c* (cb-1)^3 +
db* (cb-1)^2 end
da.easing.backInOut=function(cb)local db=1.70158;local _c=db*1.525
return cb<0.5 and(2 *cb)^2 *
( (_c+1)*2 *cb-_c)/2 or
( (2 *cb-2)^2 * ( (_c+1)* (
cb*2 -2)+_c)+2)/2 end
da.easing.elasticIn=function(cb)local db=(2 *math.pi)/3;if cb==0 then return 0 end;if cb==1 then
return 1 end;return- (2 ^ (10 *cb-10))*
math.sin((cb*10 -10.75)*db)end
da.easing.elasticOut=function(cb)local db=(2 *math.pi)/3;if cb==0 then return 0 end;if cb==1 then
return 1 end;return
2 ^ (-10 *cb)*math.sin((cb*10 -0.75)*db)+1 end
da.easing.elasticInOut=function(cb)local db=(2 *math.pi)/4.5;if cb==0 then return 0 end;if
cb==1 then return 1 end;return

cb<0.5 and- (2 ^ (20 *cb-10)*
math.sin((20 *cb-11.125)*db))/2 or
(2 ^ (-20 *cb+10)*math.sin((20 *cb-11.125)*db))/2 +1 end
da.easing.bounceOut=function(cb)local db,_c=7.5625,2.75
if cb<1 /_c then return db*cb*cb elseif cb<2 /_c then
cb=cb-1.5 /_c;return db*cb*cb+0.75 elseif cb<2.5 /_c then cb=cb-2.25 /_c;return
db*cb*cb+0.9375 else cb=cb-2.625 /_c;return db*cb*cb+0.984375 end end;da.easing.bounceIn=function(cb)
return 1 -da.easing.bounceOut(1 -cb)end
da.easing.bounceInOut=function(cb)
return
cb<0.5 and
(1 -da.easing.bounceOut(1 -2 *cb))/2 or
(1 +da.easing.bounceOut(2 *cb-1))/2 end;local function _b(cb)
for db,_c in ipairs(da._active)do if _c.handle==cb then return _c end end;return nil end;local ab={}function ab:pause()return
da.pause(self)end
function ab:resume()return da.resume(self)end;function ab:cancel()return da.cancel(self)end;function ab:complete()return
da.complete(self)end
function ab:isActive()return da.isActive(self)end;function ab:isPaused()return da.isPaused(self)end;function ab:getProgress()return
da.getProgress(self)end
function ab:seek(cb)
if type(cb)~="number"then return false end;local db=_b(self)if not db then return false end
cb=math.max(0,math.min(1,cb))db.elapsed=db.delay+cb*db.duration
local _c=math.max(0,db.elapsed-db.delay)local ac=math.min(1,_c/db.duration)
local bc=db.easing(ac)
for cc,dc in pairs(db.endValues)do if db.startValues[cc]then
db.target[cc]=db.startValues[cc]+ (dc-
db.startValues[cc])*bc end end;return true end
local function bb()local cb={}setmetatable(cb,{__index=ab})return cb end
function da.to(cb,db,_c,ac,bc)if type(cb)~="table"then
ca.error("Tween: Target must be a table")return bb()end;if type(_c)~="table"then
ca.error("Tween: Properties must be a table")return bb()end;local cc=
type(ac)=="table"and ac or{easing=ac,onComplete=bc}
local dc=bb()local _d={}
for bd,cd in pairs(_c)do if type(cb[bd])=="number"then _d[bd]=cb[bd]else
ca.warn("Tween: Property '"..
tostring(bd).."' is not a number, skipping")end end
local ad={handle=dc,target=cb,duration=math.max(0.001,db),elapsed=0,startValues=_d,endValues=_c,easing=cc.easing or da.easing.linear,onComplete=cc.onComplete,delay=cc.delay or 0,loop=
cc.loop or false,pingpong=cc.pingpong or false,paused=false,_isReversing=false}table.insert(da._active,ad)return dc end
function da.from(cb,db,_c,ac)ac=ac or{}local bc={}
for cc,dc in pairs(_c)do bc[cc]=cb[cc]cb[cc]=dc end;return da.to(cb,db,bc,ac)end
function da.pause(cb)for db,_c in ipairs(da._active)do
if _c.handle==cb then _c.paused=true;return true end end;return false end
function da.resume(cb)for db,_c in ipairs(da._active)do
if _c.handle==cb then _c.paused=false;return true end end;return false end
function da.cancel(cb)
for i=#da._active,1,-1 do if da._active[i].handle==cb then
table.remove(da._active,i)return true end end;return false end
function da.stop(cb)local db=0
for i=#da._active,1,-1 do if da._active[i].target==cb then
table.remove(da._active,i)db=db+1 end end;return db end;function da.stopAll()da._active={}end
function da.complete(cb)
for i=#da._active,1,-1 do
local db=da._active[i]
if db.handle==cb then
for ac,bc in pairs(db.endValues)do db.target[ac]=bc end;local _c=db.onComplete;table.remove(da._active,i)if _c then _c()end;return
true end end;return false end
function da.seek(cb,db)local _c=_b(cb)
if not _c or type(db)~="number"then return false end;db=math.max(0,math.min(1,db))
_c.elapsed=_c.delay+db*_c.duration;local ac=math.max(0,_c.elapsed-_c.delay)local bc=math.min(1,ac/
_c.duration)local cc=_c.easing(bc)for dc,_d in
pairs(_c.endValues)do
if _c.startValues[dc]then _c.target[dc]=_c.startValues[dc]+
(_d-_c.startValues[dc])*cc end end;return true end;function da.getTweensForTarget(cb)local db={}for _c,ac in ipairs(da._active)do if ac.target==cb then
table.insert(db,ac.handle)end end
return db end;function da.count()return
#da._active end
function da.isActive(cb)for db,_c in ipairs(da._active)do if
_c.handle==cb then return true end end;return false end;function da.isPaused(cb)
for db,_c in ipairs(da._active)do if _c.handle==cb then return _c.paused end end;return false end
function da.getProgress(cb)for db,_c in
ipairs(da._active)do
if _c.handle==cb then
local ac=math.max(0,_c.elapsed-_c.delay)return math.min(1,ac/_c.duration)end end;return nil end
function da.update(cb)
for i=#da._active,1,-1 do local db=da._active[i]db.elapsed=db.elapsed+cb
if not
db.paused then local _c=db.elapsed-db.delay
if _c>=0 then
local ac=math.min(1,_c/db.duration)local bc=db.easing(ac)
for cc,dc in pairs(db.endValues)do if db.startValues[cc]then
db.target[cc]=
db.startValues[cc]+ (dc-db.startValues[cc])*bc end end
if ac>=1 then
if db.pingpong then
for cc,dc in pairs(db.endValues)do local _d=db.startValues[cc]
db.startValues[cc]=dc;db.endValues[cc]=_d end;db.elapsed=db.delay;db._isReversing=not db._isReversing elseif db.loop then
db.elapsed=db.delay else local cc=db.onComplete;table.remove(da._active,i)if cc then cc()end end end end end end end
function da.getDebugInfo()local cb={}
for db,_c in ipairs(da._active)do
local ac=math.max(0,_c.elapsed-_c.delay)
table.insert(cb,{target=tostring(_c.target),progress=math.min(1,ac/_c.duration),duration=_c.duration,paused=_c.paused,loop=_c.loop,pingpong=_c.pingpong})end;return cb end;return da
]=]
paths["core.tween"] = "core/tween"
sources["core.ui.element"] = [=[
local c={}
c.ELEMENT_FIELDS={x=true,y=true,z=true,w=true,h=true,visible=true,sprite=true,disabled=true,fore=true,back=true,borderColor=true,anchor=true,interactive=true,borderTop=true,borderBottom=true,borderLeft=true,borderRight=true}c.DIRTY_FIELDS={z=true,sprite=true,w=true,h=true}
function c.wrapText(_a,aa)local ba={}
for ca in(
tostring(_a or"").."\n"):gmatch("([^\n]*)\n")do
if#ca==0 then
table.insert(ba,"")elseif aa<=0 or#ca<=aa then table.insert(ba,ca)else local da={}for ab in ca:gmatch("%S+")do
table.insert(da,ab)end;local _b=""for ab,bb in ipairs(da)do
if#_b==0 then _b=bb elseif#_b+1 +#bb<=aa then _b=_b..
" "..bb else table.insert(ba,_b)_b=bb end end;if#_b>0 then
table.insert(ba,_b)end end end;return ba end
local function d(_a)local aa=_a.border~=false
return
_a.borderTop~=nil and _a.borderTop or aa,_a.borderBottom~=nil and _a.borderBottom or aa,
_a.borderLeft~=nil and _a.borderLeft or aa,
_a.borderRight~=nil and _a.borderRight or aa end
function c.make(_a,aa,ba,ca,da)local _b=da or{}local ab,bb,cb,db=d(_b)
local _c={name=_a,type=aa,x=ba,y=ca,w=_b.w or
(_b.text and#_b.text or 0),h=_b.h or 1,z=_b.z or 0,config=_b,visible=(_b.visible~=false)and(_b.hidden~=true),anchor=
_b.anchor or"top-left",interactive=
(
aa~="text"and aa~="rect"and aa~="sprite"and aa~="multiline")or(_b.interactive==true)or(_b.onClick~=nil),sprite=_b.sprite,borderTop=ab,borderBottom=bb,borderLeft=cb,borderRight=db,fore=
_b.fore or"0",back=_b.back or"7",borderColor=_b.borderColor or"8",disabled=_b.disabled==true}
if _b.sprite then _c.w=_b.sprite.width;_c.h=_b.sprite.height end;if aa=="multiline"and not _b.h then
_c.h=#c.wrapText(_b.text or"",_c.w)end;return _c end
function c.makeContainer(_a,aa,ba,ca,da,_b)local ab=_b or{}local bb,cb,db,_c=d(ab)
return
{name=_a,type="container",x=aa,y=ba,w=ca,h=da,z=ab.z or 0,config=ab,visible=(ab.visible~=false)and(
ab.hidden~=true),anchor=ab.anchor or"top-left",interactive=true,fore=ab.fore or"0",back=ab.back or"7",borderColor=
ab.borderColor or"8",borderTop=bb,borderBottom=cb,borderLeft=db,borderRight=_c,disabled=ab.disabled==true,children={},sortedChildren={},childrenDirty=true,scrollOffset=0}end;return c
]=]
paths["core.ui.element"] = "core/ui/element"
sources["core.ui.events"] = [=[
local d={}
local function _a(ba,ca,da)
local _b=math.max(0,math.min(ba.w-1,ca-da))local ab=ba.config.min or 0;local bb=ba.config.max or 100;local cb=
ba.config.step or 1;local db=ab+
(_b/math.max(1,ba.w-1))* (bb-ab)
local _c=math.floor(db/cb+0.5)*cb;return math.max(ab,math.min(bb,_c))end
local function aa(ba,ca,da,_b,ab)
for i=#ba.sorted,1,-1 do local bb=ba.sorted[i]if not bb.visible then goto next end
local cb,db=ba:getAbsolutePos(bb,_b,ab)
if bb.type=="container"then
if ca>=cb and ca<cb+bb.w and da>=db and da<
db+bb.h then
if bb.childrenDirty then bb.sortedChildren={}
for dc,_d in
pairs(bb.children)do table.insert(bb.sortedChildren,_d)end
table.sort(bb.sortedChildren,function(dc,_d)return dc.z<_d.z end)bb.childrenDirty=false end;local _c=cb+ (bb.borderLeft and 1 or 0)local ac=db+ (
bb.borderTop and 1 or 0)
local bc=bb.h-
(bb.borderTop and 1 or 0)- (bb.borderBottom and 1 or 0)local cc=bb.scrollOffset or 0
for j=#bb.sortedChildren,1,-1 do
local dc=bb.sortedChildren[j]
if dc.visible then local _d=_c+dc.x;local ad=ac+dc.y-cc
if
ad+dc.h>ac and ad<ac+bc then
local bd=

(dc.type=="dropdown"and dc.isOpen and dc.config.options)and(dc.h+#dc.config.options)or dc.h;if
ca>=_d and ca<_d+dc.w and da>=ad and da<ad+bd then return dc,_d,ad end end end end;if bb.config.onClick then return bb,cb,db end;return nil,0,0 end else
local _c=

(bb.type=="dropdown"and bb.isOpen and bb.config.options)and(bb.h+#bb.config.options)or bb.h;if
ca>=cb and ca<cb+bb.w and da>=db and da<db+_c then return bb,cb,db end end::next::end;return nil,0,0 end
function d.handle(ba,ca,da,_b,ab)local bb=da[1]
if bb=="mouse_click"or bb=="mouse_drag"then
local cb,db=da[3],da[4]if ba.dirty then ba:_sort()end;local _c,ac,bc=aa(ba,cb,db,_b,ab)
if
bb=="mouse_click"then
ba.focusedElement=(_c and _c.type=="input")and _c or nil
for cc,dc in pairs(ba.elements)do
if dc.type=="dropdown"and dc~=_c then dc.isOpen=false end;if dc.type=="container"then
for _d,ad in pairs(dc.children)do if
ad.type=="dropdown"and ad~=_c then ad.isOpen=false end end end end
if _c and _c.interactive and not _c.disabled then
if _c.type=="checkbox"then _c.config.checked=
not _c.config.checked;if _c.config.onChanged then
_c.config.onChanged(_c.config.checked)end;return true end
if _c.type=="dropdown"then
if _c.isOpen then local cc=db-bc-_c.h
if
cc>=0 and _c.config.options and cc<#_c.config.options then _c.config.selectedIndex=
cc+1;if _c.config.onChanged then
_c.config.onChanged(_c.config.selectedIndex,_c.config.options[_c.config.selectedIndex])end end;_c.isOpen=false else _c.isOpen=true end;return true end
if _c.type=="list"then local cc=db-bc;local dc=(_c.config.scrollOffset or 0)+cc+
1
if _c.config.options and dc>=1 and dc<=#
_c.config.options then
_c.config.selectedIndex=dc;if _c.config.onChanged then
_c.config.onChanged(dc,_c.config.options[dc])end end;return true end
if _c.type=="slider"then local cc=_a(_c,cb,ac)_c.config.value=cc;if
_c.config.onChanged then _c.config.onChanged(cc)end end;ba.pressedElement=_c;ba.pressedAbsX=ac;ba.pressedAbsY=bc;return true end elseif bb=="mouse_drag"then
if
ba.pressedElement and ba.pressedElement.type=="slider"then local cc=ba.pressedElement
local dc=_a(cc,cb,ba.pressedAbsX or 0)cc.config.value=dc;if cc.config.onChanged then
cc.config.onChanged(dc)end;return true end end elseif bb=="mouse_up"then
if ba.pressedElement then local cb=ba.pressedElement
local db,_c=ba.pressedAbsX or 0,ba.pressedAbsY or 0;local ac,bc=da[3],da[4]
if cb.type=="slider"then local cc=_a(cb,ac,db)
cb.config.value=cc
if cb.config.onChanged then cb.config.onChanged(cc)end elseif
ac>=db and ac<db+cb.w and bc>=_c and bc<_c+cb.h then
if cb.config.onClick then cb.config.onClick(da[2])end end;ba.pressedElement=nil;ba.pressedAbsX=nil;ba.pressedAbsY=nil;return true end elseif bb=="char"then
if
ba.focusedElement and ba.focusedElement.type=="input"then local cb=ba.focusedElement
cb.config.text=(cb.config.text or"")..da[2]if cb.config.onChange then
cb.config.onChange(cb.config.text)end;return true end elseif bb=="key"then
if
ba.focusedElement and ba.focusedElement.type=="input"then local cb=ba.focusedElement;local db=da[2]
if db==keys.backspace then cb.config.text=(
cb.config.text or""):sub(1,-2)
if
cb.config.onChange then cb.config.onChange(cb.config.text)end elseif db==keys.enter then ba.focusedElement=nil;if cb.config.onConfirm then
cb.config.onConfirm(cb.config.text)end end;return true end elseif bb=="mouse_scroll"then local cb,db,_c=da[2],da[3],da[4]
if ba.dirty then ba:_sort()end
for i=#ba.sorted,1,-1 do local ac=ba.sorted[i]
if ac.visible and not ac.disabled then
local bc,cc=ba:getAbsolutePos(ac,_b,ab)
if
db>=bc and db<bc+ac.w and _c>=cc and _c<cc+ac.h then
if ac.type=="list"then
local dc=math.max(0,# (ac.config.options or{})-ac.h)
ac.config.scrollOffset=math.max(0,math.min(dc,(ac.config.scrollOffset or 0)+cb))return true elseif ac.type=="slider"then local dc=ac.config.min or 0
local _d=ac.config.max or 100;local ad=ac.config.step or 1
local bd=math.max(dc,math.min(_d,
(ac.config.value or dc)-cb*ad))ac.config.value=bd;if ac.config.onChanged then
ac.config.onChanged(bd)end;return true elseif ac.type=="container"and
ac.config.scrollable~=false then
local dc=ac.h- (ac.borderTop and 1 or 0)- (
ac.borderBottom and 1 or 0)local _d=0
for bd,cd in pairs(ac.children)do local dd=cd.y+cd.h;if dd>_d then _d=dd end end;local ad=math.max(0,_d-dc)
ac.scrollOffset=math.max(0,math.min(ad,ac.scrollOffset+cb))return true end end end end end;return false end;return d
]=]
paths["core.ui.events"] = "core/ui/events"
sources["core.ui"] = [=[
local aa=...local ba=aa("core.ui.element")
local ca=aa("core.ui.render")local da=aa("core.ui.events")local _b={}
function _b.new(ab)
assert(ab,"UI.new: a Buffer instance is required")
local bb={buf=ab,elements={},sorted={},dirty=true,pressedElement=nil,pressedAbsX=nil,pressedAbsY=nil,focusedElement=nil}
function bb:_sort()self.sorted={}for cb,db in pairs(self.elements)do
table.insert(self.sorted,db)end
table.sort(self.sorted,function(cb,db)return cb.z<db.z end)self.dirty=false end
function bb:_insert(cb)self.elements[cb.name]=cb;self.dirty=true;return cb end
function bb:add(cb,db,_c,ac,bc)return self:_insert(ba.make(cb,db,_c,ac,bc))end
function bb:button(cb,db,_c,ac)return self:add(cb,"button",db,_c,ac)end
function bb:text(cb,db,_c,ac)return self:add(cb,"text",db,_c,ac)end
function bb:input(cb,db,_c,ac)return self:add(cb,"input",db,_c,ac)end
function bb:checkbox(cb,db,_c,ac)return self:add(cb,"checkbox",db,_c,ac)end
function bb:dropdown(cb,db,_c,ac)return self:add(cb,"dropdown",db,_c,ac)end
function bb:progress(cb,db,_c,ac)return self:add(cb,"progress",db,_c,ac)end
function bb:slider(cb,db,_c,ac)return self:add(cb,"slider",db,_c,ac)end
function bb:list(cb,db,_c,ac)return self:add(cb,"list",db,_c,ac)end
function bb:rect(cb,db,_c,ac)return self:add(cb,"rect",db,_c,ac)end
function bb:sprite(cb,db,_c,ac)return self:add(cb,"sprite",db,_c,ac)end
function bb:multiline(cb,db,_c,ac)return self:add(cb,"multiline",db,_c,ac)end
function bb:label(cb,db,_c,ac)return self:multiline(cb,db,_c,ac)end;function bb:container(cb,db,_c,ac,bc,cc)
return self:_insert(ba.makeContainer(cb,db,_c,ac,bc,cc))end
function bb:remove(cb)if self.elements[cb]then self.elements[cb]=
nil;self.dirty=true end end
function bb:addToContainer(cb,db,_c,ac,bc,cc)local dc=self.elements[cb]if
not dc or dc.type~="container"then return nil end
local _d=ba.make(db,_c,ac,bc,cc or{})dc.children[db]=_d;dc.childrenDirty=true;return _d end;function bb:removeFromContainer(cb,db)local _c=self.elements[cb]
if
_c and _c.type=="container"then _c.children[db]=nil;_c.childrenDirty=true end end
function bb:update(cb,db)
local _c=self.elements[cb]if not _c then return end;for ac,bc in pairs(db)do
if ba.ELEMENT_FIELDS[ac]then _c[ac]=bc;if
ba.DIRTY_FIELDS[ac]then self.dirty=true end else _c.config[ac]=bc end end;if _c.type==
"text"and db.text then _c.w=#db.text end end
function bb:updateInContainer(cb,db,_c)local ac=self.elements[cb]if
not ac or ac.type~="container"then return end;local bc=ac.children[db]if not bc then return end;for cc,dc in
pairs(_c)do
if ba.ELEMENT_FIELDS[cc]then bc[cc]=dc
if ba.DIRTY_FIELDS[cc]then ac.childrenDirty=true end else bc.config[cc]=dc end end;if
bc.type=="text"and _c.text then bc.w=#_c.text end end
function bb:get(cb)local db=self.elements[cb]if not db then return nil end;local _c=db.type
if _c==
"input"or _c=="button"or _c=="text"then
return db.config.text elseif _c=="checkbox"then return db.config.checked elseif _c=="dropdown"or _c=="list"then
local ac=db.config.selectedIndex;return ac,
ac and db.config.options and db.config.options[ac]elseif _c=="progress"then return db.config.progress elseif _c==
"slider"then
return db.config.value or db.config.min or 0 end;return nil end
function bb:getAbsolutePos(cb,db,_c)local ac,bc=self.buf:getSize()
local cc,dc=cb.x+db,cb.y+_c;local _d=
db+math.floor((ac-db*2)/2)-math.floor(cb.w/2)+cb.x;local ad=
_c+math.floor(
(bc-_c*2)/2)-math.floor(cb.h/2)+cb.y;local bd=(ac-db)-cb.w-
cb.x;local cd=(bc-_c)-cb.h-cb.y
local dd=cb.anchor
if dd=="top-center"then cc=_d elseif dd=="top-right"then cc=bd elseif dd=="center-left"then dc=ad elseif dd=="center"then cc=_d
dc=ad elseif dd=="center-right"then cc=bd;dc=ad elseif dd=="bottom-left"then dc=cd elseif dd=="bottom-center"then cc=_d;dc=cd elseif dd==
"bottom-right"then cc=bd;dc=cd end;return cc,dc end;function bb:handleEvent(cb,db,_c)
return da.handle(self,self.buf,cb,db or 0,_c or 0)end
function bb:draw(cb,db,_c)cb=cb or 0;db=db or 0
_c=_c or{}if self.dirty then self:_sort()end
for ac,bc in ipairs(self.sorted)do
if bc.visible then
local cc,dc=self:getAbsolutePos(bc,cb,db)if bc.type=="container"then
ca.drawContainer(self.buf,bc,cc,dc,self,_c)else
ca.drawEl(self.buf,bc,cc,dc,self.pressedElement,self.focusedElement,_c)end end end;return _c end;return bb end;_b.createContext=_b.new;return _b
]=]
paths["core.ui"] = "core/ui/init"
sources["core.ui.render"] = [=[
local _a=...local aa={}
local function ba(da,_b,ab,bb,cb,db,_c,ac)if db<=bb then return end
local bc=math.max(1,math.floor(bb*bb/db))local cc=db-bb;local dc=math.floor((cb/cc)* (bb-bc))for i=0,bb-1 do local _d=(i>=
dc and i<dc+bc)
da:drawText(_b,ab+i," ","0",_d and ac or _c)end end
local function ca(da,_b,ab,bb,cb,db)if _b.borderTop then
da:drawText(ab,bb,("\131"):rep(_b.w),cb,db)end;if _b.borderBottom then
da:drawText(ab,bb+_b.h-1,("\143"):rep(_b.w),db,cb)end;if _b.borderLeft then for i=0,_b.h-1 do
da:drawText(ab,bb+i,"\149",cb,db)end end;if _b.borderRight then
for i=0,
_b.h-1 do da:drawText(ab+_b.w-1,bb+i,"\149",db,cb)end end;if _b.borderTop and _b.borderLeft then
da:drawText(ab,bb,"\151",cb,db)end
if _b.borderTop and _b.borderRight then da:drawText(ab+
_b.w-1,bb,"\148",db,cb)end;if _b.borderBottom and _b.borderLeft then
da:drawText(ab,bb+_b.h-1,"\138",db,cb)end;if _b.borderBottom and _b.borderRight then
da:drawText(
ab+_b.w-1,bb+_b.h-1,"\133",db,cb)end end
function aa.drawEl(da,_b,ab,bb,cb,db,_c)
if _b.sprite then
local ac=_b.sprite[_b.config.frame or 1]if ac then da:drawSprite(ac,ab,bb,0,0)
for i=0,_b.h-1 do _c[bb+i]=true end end;return end
if _b.type=="text"then
da:drawText(ab,bb,_b.config.text or"",_b.disabled and"8"or _b.fore,_b.back)_c[bb]=true;return end
if _b.type=="multiline"then local ac=_a("core.ui.element")
local bc=ac.wrapText(_b.config.text or"",_b.w)local cc=_b.config.align or"left"
local dc=_b.disabled and"8"or _b.fore;da:drawRect(ab,bb,_b.w,_b.h," ",dc,_b.back)
for _d,ad in ipairs(bc)do local bd=bb+
_d-1;if bd>=bb+_b.h then break end;local cd=ab;if cc=="center"then cd=ab+math.floor((
_b.w-#ad)/2)elseif cc=="right"then cd=
ab+_b.w-#ad end;if#ad>0 then
da:drawText(cd,bd,ad,dc,_b.back)end end;for i=0,_b.h-1 do _c[bb+i]=true end;return end
if

_b.type=="rect"or _b.type=="button"or _b.type=="input"or _b.type=="checkbox"or
_b.type=="dropdown"or _b.type=="progress"then local ac=(cb==_b)local cc=(db==_b)local dc=_b.disabled and"8"or
(ac and _b.borderColor or _b.back)
local _d=
_b.disabled and"7"or(ac and _b.back or _b.fore)local ad=(ac or cc)and _b.fore or _b.borderColor;da:drawRect(ab,bb,_b.w,_b.h,
_b.config.char or" ",_d,dc)
if _b.type==
"progress"then
local bd=math.max(0,math.min(1,_b.config.progress or 0))local cd=_b.config.fillColor or"d"
local dd=math.floor(_b.w*bd)local __a=_b.w*bd-dd;if dd>0 then
da:drawRect(ab,bb,dd,_b.h,_b.config.fillChar or" ",cd,cd)end;if __a>=0.5 and dd<_b.w then
for row=0,_b.h-1 do da:drawText(
ab+dd,bb+row,"\149",cd,_b.back)end end end;ca(da,_b,ab,bb,ad,dc)if _b.type=="checkbox"then local bd=
_b.config.checked and"\7"or" "
da:drawText(ab+math.floor(_b.w/2),
bb+math.floor(_b.h/2),bd,_d,dc)end
if
(_b.type==
"button"or _b.type=="input")and _b.config.text~=nil then local bd=_b.config.text;local cd=bb+math.floor(_b.h/2)
local dd
if _b.type=="input"then dd=ab+1;local __a=cc and
(math.floor(os.clock()*2)%2 ==0)if _b.config.password then
bd=string.rep("*",#bd)end;if __a then bd=bd.."_"end
local a_a=math.max(1,_b.w-2)if#bd>a_a then bd=bd:sub(#bd-a_a+1)end else dd=ab+math.floor((_b.w-#
bd)/2)end;da:drawText(dd,cd,bd,_d,dc)end
if _b.type=="dropdown"then local bd=_b.config.selectedIndex
local cd=tostring(
(
bd and _b.config.options and _b.config.options[bd])or _b.config.text or"")local dd=math.max(1,_b.w-2)
if#cd>dd then cd=cd:sub(1,dd)end
da:drawText(ab+1,bb+math.floor(_b.h/2),cd,_d,dc)
da:drawText(ab+_b.w-1,bb+math.floor(_b.h/2),_b.isOpen and"\30"or"\31",_d,dc)
if _b.isOpen and _b.config.options then
for __a,a_a in ipairs(_b.config.options)do local b_a=
bb+_b.h-1 +__a
local c_a=(__a==bd)and _b.fore or _b.back;local d_a=(__a==bd)and _b.back or _b.fore
da:drawRect(ab,b_a,_b.w,1," ",d_a,c_a)local _aa=tostring(a_a)
if#_aa>_b.w-1 then _aa=_aa:sub(1,_b.w-1)end;da:drawText(ab+1,b_a,_aa,d_a,c_a)_c[b_a]=true end end end;for i=0,_b.h-1 do _c[bb+i]=true end;return end
if _b.type=="list"then local ac=_b.config.options or{}
local bc=_b.config.scrollOffset or 0;local cc=_b.config.selectedIndex
local dc=_b.config.selectedFore or _b.back;local _d=_b.config.selectedBack or _b.fore
local ad=#ac>_b.h;local bd=ad and(_b.w-1)or _b.w
local cd=_b.config.scrollTrack or"8"local dd=_b.config.scrollThumb or _b.fore
da:drawRect(ab,bb,_b.w,_b.h," ",_b.fore,_b.back)
for row=0,_b.h-1 do local __a=bc+row+1;local a_a=ac[__a]
if a_a then local b_a=(__a==cc)
local c_a=b_a and dc or _b.fore;local d_a=b_a and _d or _b.back;local _aa=tostring(a_a)if#_aa>bd then
_aa=_aa:sub(1,bd)end
da:drawRect(ab,bb+row,bd,1," ",c_a,d_a)da:drawText(ab,bb+row,_aa,c_a,d_a)end end
if ad then ba(da,ab+_b.w-1,bb,_b.h,bc,#ac,cd,dd)end;for i=0,_b.h-1 do _c[bb+i]=true end;return end
if _b.type=="slider"then local ac=_b.config.min or 0
local bc=_b.config.max or 100;local cc=_b.config.value or ac
local dc=(bc>ac)and
math.max(0,math.min(1,(cc-ac)/ (bc-ac)))or 0;local _d=math.floor(dc* (_b.w-1))local ad=_b.disabled and"8"or(
_b.config.fillColor or"d")local bd=_b.disabled and
"7"or _b.back
local cd=_b.config.thumbFore or _b.back
local dd=_b.config.thumbBack or(_b.disabled and"8"or _b.fore)local __a=_b.config.thumbChar or"\149"
da:drawRect(ab,bb,_b.w,_b.h," ",_b.fore,bd)
if _d>0 then da:drawRect(ab,bb,_d,_b.h," ",ad,ad)end;da:drawText(ab+_d,bb,__a,cd,dd)
if _b.config.showValue then
local a_a=tostring(math.floor(cc))local b_a=ab+math.floor((_b.w-#a_a)/2)if b_a+#
a_a-1 ~=ab+_d then
da:drawText(b_a,bb,a_a,_b.fore,bd)end end;for i=0,_b.h-1 do _c[bb+i]=true end end end
function aa.drawContainer(da,_b,ab,bb,cb,db)
da:drawRect(ab,bb,_b.w,_b.h," ",_b.fore,_b.back)ca(da,_b,ab,bb,_b.borderColor,_b.back)
if _b.config.title and
_b.borderTop then local dd=" ".._b.config.title.." "local __a=ab+math.floor((
_b.w-#dd)/2)
da:drawText(__a,bb,dd,_b.borderColor,_b.back)end;for i=0,_b.h-1 do db[bb+i]=true end
if _b.childrenDirty then _b.sortedChildren={}
for dd,__a in
pairs(_b.children)do table.insert(_b.sortedChildren,__a)end
table.sort(_b.sortedChildren,function(dd,__a)return dd.z<__a.z end)_b.childrenDirty=false end;local _c=ab+ (_b.borderLeft and 1 or 0)local ac=bb+ (
_b.borderTop and 1 or 0)
local bc=_b.h-
(_b.borderTop and 1 or 0)- (_b.borderBottom and 1 or 0)local cc=_b.w- (_b.borderLeft and 1 or 0)-
(_b.borderRight and 1 or 0)
local dc=_b.scrollOffset or 0;local _d=0
for dd,__a in pairs(_b.children)do local a_a=__a.y+__a.h;if a_a>_d then _d=a_a end end;local ad=_d>bc;local bd=_b.config.scrollTrack or"8"local cd=
_b.config.scrollThumb or _b.fore
for dd,__a in ipairs(_b.sortedChildren)do
if __a.visible then local a_a=ac+
__a.y-dc
if a_a+__a.h>ac and a_a<ac+bc then da:setClip(_c,ac,
_c+cc-1,ac+bc-1)
aa.drawEl(da,__a,_c+__a.x,a_a,cb.pressedElement,cb.focusedElement,db)da:clearClip()end end end;if ad then ba(da,_c+cc-1,ac,bc,dc,_d,bd,cd)end end;return aa
]=]
paths["core.ui.render"] = "core/ui/render"
local loaded = {}
local loading = {}
local function loader(name)
    local cached = loaded[name]
    if cached ~= nil then return cached end
    if loading[name] then
        error("Obsidian: circular require of " .. tostring(name), 0)
    end
    local source = sources[name]
        or error("Obsidian: module not bundled: " .. tostring(name), 0)
    local chunk = assert(load(source,
        "@obsidian/" .. (paths[name] or name) .. ".lua"))
    loading[name] = true
    local result = chunk(loader, name)
    loading[name] = nil
    loaded[name] = result == nil and true or result
    return loaded[name]
end

return loader("engine")