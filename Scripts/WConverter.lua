--[[

    Xesau_WConverter.lua
    
    Copyright (c) 2018 Xesau 

  ]]--

Xesau_WConverter = class( nil )
Xesau_WConverter.maxParentCount = 10
Xesau_WConverter.maxChildCount = 10000
Xesau_WConverter.connectionInput = sm.interactable.connectionType.power
Xesau_WConverter.connectionOutput = sm.interactable.connectionType.logic
Xesau_WConverter.colorNormal = sm.color.new( 0xe2df2fff )
Xesau_WConverter.colorHighlight = sm.color.new( 0xfffc35ff )
Xesau_WConverter.poseWeightCount = 1

function Xesau_WConverter.server_onCreate( self ) 
    self:server_init()
end
function Xesau_WConverter.server_onRefresh( self )
    self:server_init()
end

function Xesau_WConverter.server_init( self )
        print("CREATE S")
end

function Xesau_WConverter.server_onFixedUpdate( self, dt )
--    local input = self.interactable:getSingleParent()
--    if input and input:getPower() > 0 then
--        if self.interactable:isActive() ~= false then
--            self.interactable:setActive(false)
--        end
--        self.interactable:setPower(0)
--    else
--        if self.interactable:isActive() ~= true then
--            self.interactable:setActive(true)
--        end
--        self.interactable:setPower(input:getPower())
--    end
--    if input then
--        self.interactable:setPower(input:getPower())
--       self.interactable:setActive(true)
--    end
--    print("parents:")
--    parents = self.interactable:getParents()
--    for id, p in pairs(parents) do
--        print(id, p)
--    end
--    print("children:")
--    children = self.interactable:getChildren()
--    for id, c in pairs(children) do
--        print(id, c)
--    end
--

--    print("joints:")
--    joints = self.interactable:getJoints()
--    for id, j in pairs(joints) do
--        print(k,j)
--    end

    --print(self.shape.color)

    self.interactable:setActive(true)


end

function Xesau_WConverter.client_onCreate( self )
    print("CREATE C")
end

function Xesau_WConverter.client_onUpdate( self, dt )
--    local a = self.interactable:isActive()
--    local w = self.interactable:getPoseWeight(0)
--    if a and w == 0 then
--        self.interactable:setPoseWeight(0, 1)
--    elseif a ~= true and w == 1 then
--        self.interactable:setPoseWeight(0, 0)
--    end
    
end