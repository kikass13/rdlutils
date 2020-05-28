--[[
    rdlCpupler.lua
    Copyright (c) 2018 kikass13 
]]--

-- ###############################################################################################################
-- ###############################################################################################################
BLOCKUNIT = 0.25

function blocks(count)
    return count * 0.25
end
function blocks3d(cx, cy, cz)
    return sm.vec3.new(blocks(cx), blocks(cy), blocks(cz))
end
function vlen(v1, v2)
    return math.sqrt(math.pow(v2.x - v1.x, 2) + math.pow(v2.y - v1.y, 2) + math.pow(v2.z - v1.z, 2))
end
function vmuls(v, scalar)
    return sm.vec3.new(v.x * scalar, v.y * scalar, v.z * scalar)
end
function qtoeuler(q)
    local test = q.x * q.y + q.z * q.w
    if (test > 0.499) then -- // singularity at north pole
        heading = 2 * math.atan2(q.x, q.w)
        attitude = math.pi/2
        bank = 0
        return
    end
    if (test < -0.499) then -- singularity at south pole
        heading = -2 * math.atan2(q.x, q.w)
        attitude = -math.pi/2
        bank = 0
        return
    end
    local sqx = q.x * q.x;
    local sqy = q.y * q.y;
    local sqz = q.z * q.z;
    heading = math.atan2(2 * q.y * q.w - 2 * q.x * q.z, 1 - 2 * sqy - 2 * sqz)
    attitude = math.asin(2 * test)
    bank = math.atan2(2 * q.x * q.w - 2 * q.y * q.z, 1 - 2 * sqx - 2 * sqz)
    return heading, attitude, bank
end

function eulerDeg(x,y,z)
    if(x and y and z) then
        return x*360/math.pi, y*360/math.pi, z*360/math.pi
    end
    return
end
-- ##################################################################################
-- ###############                    I N I T                   #####################
-- ##################################################################################
RDLCoupler = class( nil )
RDLCoupler.maxParentCount = 1
RDLCoupler.maxChildCount = 1
RDLCoupler.connectionInput = sm.interactable.connectionType.logic
RDLCoupler.connectionOutput = sm.interactable.connectionType.logic
RDLCoupler.colorNormal = sm.color.new( 0xe2df2fff )
RDLCoupler.colorHighlight = sm.color.new( 0xfffc35ff )
RDLCoupler.poseWeightCount = 1
-- ##################################################################################
-- ###############               C O N S T A N T S               ####################
-- ##################################################################################
RDLCoupler.DEFAULT_COUPLER_FORCE_STRENGTH = -300
--
RDLCoupler.DEFAULT_COUPLER_AREA_OF_INTEREST_BOX_SIZE_X = 100
RDLCoupler.DEFAULT_COUPLER_AREA_OF_INTEREST_BOX_SIZE_Y = 100
RDLCoupler.DEFAULT_COUPLER_AREA_OF_INTEREST_BOX_SIZE_Z = 100
--
RDLCoupler.PARTICLES_ENABLE = true
RDLCoupler.PARTICLES_BLOCK_DISTANCE = 0.5

-- ##################################################################################
-- ###############                   S E R V E R                #####################
-- ##################################################################################
function RDLCoupler.server_onCreate( self ) 
    self:server_init()
end

function RDLCoupler.server_onRefresh( self )
    self:server_init()
end

function RDLCoupler.server_init( self )
    print("Creating RDLCoupler")
    local size = blocks3d(self.DEFAULT_COUPLER_AREA_OF_INTEREST_BOX_SIZE_X,
                          self.DEFAULT_COUPLER_AREA_OF_INTEREST_BOX_SIZE_Y,
                          self.DEFAULT_COUPLER_AREA_OF_INTEREST_BOX_SIZE_Z )
    local pos = self.shape:getWorldPosition()
    local ori = self.shape:getWorldRotation()
    
    --- calculate the center of our collision area (which is directly behind the coupler)
    --print(self.shape:getYAxis()) -- gives local "forward" axis
    local trans = self.shape:getYAxis() * (-size.y) -- calculate translation of (size.y)>blocks backwards
    local transYCorrection = self.shape:getXAxis() * blocks(-0.5) -- correct the x axis of the block, because each grid block is to far left ?? 
    local transZCorrection = self.shape:getZAxis() * blocks(-0.5) -- correct the z axis of the block, because each grid block is to high ?? 
    local trans  = trans - transYCorrection - transZCorrection
    local globalTransPos = pos - trans

    -- print(pos)
    -- print(globalTransPos)

    -- filter
    --  sm.areaTrigger.filter.dynamicBody   1
    --  sm.areaTrigger.filter.staticBody    2
    --  sm.areaTrigger.filter.character     4
    --  sm.areaTrigger.filter.all           -1
    --self.coupleArea = sm.areaTrigger.createBox( size, pos, ori, 3)

    self.coupled = nil
    
    if self.coupleArea ~= nil then
        sm.areaTrigger.destroy(self.coupleArea) 
    end

    local localTransPos = self.shape:transformPoint(globalTransPos)
    self.coupleArea = sm.areaTrigger.createAttachedBox( self.interactable, size, localTransPos, sm.quat.identity(), -1) 
    self.coupleArea:bindOnEnter("onEnter")
    self.coupleArea:bindOnExit("onExit" )

    -- debug
    -- local woodBlockUuid = sm.uuid.new("df953d9c-234f-4ac2-af5e-f0490b223e71")
    -- sm.shape.createBlock(woodBlockUuid, sm.vec3.new(1,1,1), globalTransPos, self.shape:getWorldRotation(), false, true )
end

function RDLCoupler.server_onFixedUpdate( self, dt )
    -- do logic stuff
    self:doLogicStuff()
    -- do things related to coupling
    self:doCouplingStuff()

    -- DEBUG  LOCAL ROTATION
    if self:isEnabled() == true then
        --objRot =  self.shape:getWorldRotation()
        --print(objRot)
        --sm.effect.playEffect( "Example", self.shape:getWorldPosition(), sm.vec3.zero(), objRot )

        --local worldUp = sm.vec3.new( 0, 0, 1 )
        --local worldRot = sm.vec3.getRotation( worldUp, worldDir )
        --local localRot = self.shape:transformRotation( worldRot )
        --print(localRot)
        --sm.effect.playEffect( "Example", self.shape:getWorldPosition(), sm.vec3.zero(), localRot )
        
        --rotrot = sm.quat.lookRotation( self.shape:getAt(), sm.vec3.new( 0, 0, 1 ) )
        --sm.effect.playEffect( "Example", self.shape:getWorldPosition(), sm.vec3.zero(), rotrot )

    end
end

function RDLCoupler.server_onDestroy(self)
    print("Deleting RDLCoupler")
end
-- ##################################################################################
-- ###############                   C L I E N T                #####################
-- ##################################################################################
function RDLCoupler.client_onCreate( self )
    -- create and initialize effects ?!
    --sm.effect.createEffect( "Example", self.interactable )
end

function RDLCoupler.client_onUpdate( self, dt )
    -- generate some random particles for viz
    if self:isEnabled() == true and self.coupled ~= nil then
        -- find center position between both couplers
        --local centerCouplePosition = self.shape:getWorldPosition() - (self.shape:getWorldPosition() - self.coupled:getWorldPosition())/2
        --sm.particle.createParticle("coupling_connection", centerCouplePosition)
    
        -- create multiple particles between both couplers
        local pos1 = self.shape:getWorldPosition()
        local pos2 = self.coupled:getWorldPosition()
        local r = vlen(pos1, pos2)
        local t = blocks(self.PARTICLES_BLOCK_DISTANCE) --interpolation steps, ~N blocks in rational numbers
        local c = math.floor(r/t) +1 -- the amount particles we want in between (on r vector) couplers
        local dir = pos2 - pos1
        dir = sm.vec3.normalize(dir)
        incr = r/c
        for i=0,c,1 do
            x = pos1.x + incr*i * dir.x -- interpolate direction vector from start to end
            y = pos1.y + incr*i * dir.y
            z = pos1.z + incr*i * dir.z
            local particlePos = sm.vec3.new(x,y,z)
            if self.PARTICLES_ENABLE then
                --sm.particle.createParticle("construct_welding", particlePos)
                sm.particle.createParticle("coupling_connection", particlePos)
            end
        end
    end
end
-- ##################################################################################
-- ###############         A R E A     C O L L I D E R          #####################
-- ##################################################################################
function RDLCoupler.onExit( self, trigger, results )
    if self.coupled ~= nil then 
        -- search for our current coupled shape, 
        -- if it has left our are of influence, we decouple from it
        local partnerFound = self:checkForCoupler(results, self.coupled)
        if partnerFound ~= nil then
            self:decouple()
        end
    end
end

function RDLCoupler.onEnter( self, trigger, results ) 
    -- find out if there is another coupler entity within our area of influence
    -- if so, couple with it (remember the reference)
    if self.coupled == nil then
        local partnerFound = self:checkForCoupler(results)
        if partnerFound ~= nil then
            self:couple(partnerFound)
        end
    end
end
-- ##################################################################################
-- ###############        S E R V E R     M E T H O D S         #####################
-- ##################################################################################
function RDLCoupler.checkForCoupler(self, results, searchForThisSpecificPartner)
    searchForThisSpecificPartner = searchForThisSpecificPartner or nil
    local partnerFound = nil
    for i, object in ipairs( results ) do
        --print(type(object))
        if type(object) == "Body" then
            for j, otherShape in ipairs(object:getShapes()) do
                -- print(otherShape:getId())
                --print(otherShape:getShapeUuid())
                -- print(otherShape:getMaterial())
                if otherShape ~= self.shape and 
                    otherShape:getShapeUuid() == self.shape:getShapeUuid() or
                    otherShape == searchForThisSpecificPartner then
                    partnerFound = otherShape
                    break
                end
            end
        --debug character
        elseif type(object) == "Character" then
            -- print("Hello char!")
        end
    end
    return partnerFound
end

function RDLCoupler.isEnabled(self)
    local enabled = false
    local parent = self.interactable:getSingleParent()
    if parent then  
        enabled = parent:isActive()
    end
    return enabled
end

function RDLCoupler.decouple(self, force)
    local force = force or false
    if self.coupled or force == true then
        print("Decoupling! ...")
        self.coupled = nil 
    end
end

function RDLCoupler.couple(self, partner)
    if self.coupled == nil and partner ~= nil then 
        print(string.format("Coupling! [enabled=%s]", tostring(self:isEnabled() )) )
        -- calculate center position of both partners
        --local couplePosition = self.shape:getWorldPosition() + (self.shape:getWorldPosition() - partnerFound:getWorldPosition())/2
        --local coupleDirection = self.shape:getYAxis() --backwards
        -- create joint for both couplers
        --local woodBlockUuid = sm.uuid.new("260b4597-f1ac-409c-8e6b-90c998c5fe94")
        --self.shape:createJoint(woodBlockUuid, couplePosition, coupleDirection)
        -- remember coupling partner
        self.coupled = partner
    end
end

function RDLCoupler.exertCouplingForce(self)
    local pos1 = self.shape:getWorldPosition()
    local pos2 = self.coupled:getWorldPosition()
    local baseImpulseStrength = self.DEFAULT_COUPLER_FORCE_STRENGTH
    local r = math.max(1,vlen(pos1, pos2))
    local rr = math.max(1,r)
    local impulseStrength = baseImpulseStrength / math.pow (rr, 2)
    local impulseDirection = pos2 - pos1 
    impulseDirection = sm.vec3.normalize(impulseDirection)
    local impulse = vmuls(impulseDirection, impulseStrength)  --uniform strength (sphere)
    -- print(">>>>>>>>>>>>>")
    -- print(pos1)
    -- print(pos2)
    -- print("r:   " .. r)
    -- print("str: " .. impulseStrength)
    -- print(impulseDirection)
    --print(impulse)

    -- beeing pulled
    -- sm.physics.applyImpulse(self.shape, impulse, true, nil ) -- "pulling" impulse (global = false, offset = nil)
    -- pulling other
    sm.physics.applyImpulse(self.coupled, impulse, true, nil ) -- "pulling" impulse (global = false, offset = nil)

    -- create object with all that relevant information and return it
    coupleDataObj = {
        source = self.shape,
        target = self.coupled,
        distance = r,
        direction = impulseDirection, -- direcion vector from source -> target (local)
        strength = impulseStrength,
        impulse = impulse
    }
    return coupleDataObj
end

function RDLCoupler.doLogicStuff(self)
end

function RDLCoupler.doCouplingStuff(self)
    if self:isEnabled() == true and self.coupled ~= nil then
        --self:exertCouplingForce()
        -- try / catch
        status, coupleDataObj = pcall(RDLCoupler.exertCouplingForce, self)
        if not status then
            print("Connection broken ... !")
            -- coupling broken because block does not exist anymore?
            self.decouple(true)
        else
            -- go on ... 
            -- play effect for couple mechanism
            self:doEffectStuff(coupleDataObj)
        end
    end
end

function RDLCoupler.doEffectStuff(self, coupleData)
    if self:isEnabled() == true and self.coupled ~= nil then
        -- tell all the clients to play an effect
        if(coupleData) then

            local a = coupleData.source:getAt()
            local b = coupleData.target:getAt()
            local r = sm.vec3.getRotation(a, b) --rotation between both couplers ?

           -- print(coupleData.source:getWorldRotation())
            print(eulerDeg(qtoeuler(coupleData.source:getWorldRotation()) ))

            --print(eulerDeg(qtoeuler(r)))

            local o = sm.vec3.cross(a, b);
            local qw = math.sqrt(math.pow(a:length(),2) * math.pow(b:length(), 2)) + sm.vec3.dot(a, b)
            local q = sm.quat.new(o.x, o.y, o.z, qw )

            --print(q)
            --print(r)
            --print(rr)
            --print(".")
            --sm.effect.playEffect( "Example", coupleData.source:getWorldPosition(), sm.vec3.new(5,0,0), q )
        end
    end
end
-- ##################################################################################
-- ###############        C L I E N T     M E T H O D S         #####################
-- ##################################################################################

-- ###############################################################################################################
-- ###############################################################################################################


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