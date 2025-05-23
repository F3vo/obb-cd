local _BIG = -1e10
local SKIN_THICKNESS = 1e-5
local SKIP_AXIS_THRESHOLD = 1e-4

local CUBE_CORNER_OFFSET = {
	Vector3.new( 0.5,  0.5,  0.5),
	Vector3.new( 0.5,  0.5, -0.5),
	Vector3.new( 0.5, -0.5,  0.5),
	Vector3.new( 0.5, -0.5, -0.5),
	Vector3.new(-0.5,  0.5,  0.5),
	Vector3.new(-0.5,  0.5, -0.5),
	Vector3.new(-0.5, -0.5,  0.5),
	Vector3.new(-0.5, -0.5, -0.5),
}

local NUM_VERTS_IN_CUBE = 8
local NUM_OBB_OBB_SEPARATING_AXES = 15
local NUM_OBB_OBB_EDGE_SEPARATING_AXES = 9

local function isOOBOOBSeparatedOnAxis(cfA, sA, cfB, sB, axis)
	local minA, maxA = math.huge, -math.huge
	local minB, maxB = math.huge, -math.huge

	for j = 1, NUM_VERTS_IN_CUBE do
		local v0 = cfA * (sA * CUBE_CORNER_OFFSET[j])
		local v1 = cfB * (sB * CUBE_CORNER_OFFSET[j])
		
		local d0 = vector.dot(v0, axis)
		local d1 = vector.dot(v1, axis)
		
		minA = if minA < d0 then minA else d0
		maxA = if maxA > d0 then maxA else d0
		minB = if minB < d1 then minB else d1
		maxB = if maxB > d1 then maxB else d1
	end

	local right = maxB - minA
	local left  = maxA - minB
	
	if left < SKIN_THICKNESS or right < SKIN_THICKNESS then
		return
	elseif right < left then
		return right
	else
		return -left
	end
end

local function resolveOOBOOB(cfA, sA, cfB, sB)
	local axes = table.create(NUM_OBB_OBB_SEPARATING_AXES)
	local numAxes = 6
	
	axes[1]  = cfA.RightVector
	axes[2]  = cfA.UpVector
	axes[3]  = cfA.LookVector
	axes[4]  = cfB.RightVector
	axes[5]  = cfB.UpVector
	axes[6]  = cfB.LookVector
	
	for i = 1, 3 do
		local axisA = axes[i]
		
		for j = 1, 3 do
			local axis = vector.cross(axisA, axes[j])
			
			numAxes += 1
			axes[numAxes] = axis 
		end
	end
	
	local pdist = _BIG
	local pvec = vector.zero
	
	for i = 1, NUM_OBB_OBB_SEPARATING_AXES do
		local axis = axes[i]
		
		if axis:FuzzyEq(vector.zero, SKIP_AXIS_THRESHOLD) then
			continue
		end
		
		local dist = isOOBOOBSeparatedOnAxis(cfA, sA, cfB, sB, axis)
		
		if not dist then
			return vector.zero
		end
		
		if dist > 0 then
			continue
		end
		
		if dist > pdist then
			pvec = axis.Unit
			pdist = dist
		end
	end
	
	return pvec * pdist
end

return resolveOOBOOB
