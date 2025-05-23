local BIG = 1e10
local N_BIG = -BIG
local SKIN_THICKNESS = 1e-2

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

local NUM_CUBE_VERTS = 8
local NUM_OBB_OBB_SEPARATING_AXES = 15
local NUM_OBB_UNIQUE_EDGES = 3

local function resolveOBBOBBOnAxis(cframeA, sizeA, cframeB, sizeB, axis)
	local minA, maxA = math.huge, -math.huge
	local minB, maxB = math.huge, -math.huge

	for i = 1, NUM_CUBE_VERTS do
		local vertA = cframeA * (sizeA * CUBE_CORNER_OFFSET[i])
		local vertB = cframeB * (sizeB * CUBE_CORNER_OFFSET[i])
		
		local distA = vector.dot(vertA, axis)
		local distB = vector.dot(vertB, axis)
		
		minA = if minA < distA then minA else distA
		maxA = if maxA > distA then maxA else distA
		minB = if minB < distB then minB else distB
		maxB = if maxB > distB then maxB else distB
	end

	local right = maxB - minA
	local left  = maxA - minB
	
	if left < 0 or right < 0 then
		return
	elseif right < left then
		return right
	else
		return -left
	end
end

local function resolveOOBOOB(cframeA, sizeA, cframeB, sizeB)
	local axes = table.create(NUM_OBB_OBB_SEPARATING_AXES)
	local numAxes = 6
	
	axes[1] = cframeA.RightVector
	axes[2] = cframeA.UpVector
	axes[3] = cframeA.LookVector
	axes[4] = cframeB.RightVector
	axes[5] = cframeB.UpVector
	axes[6] = cframeB.LookVector
	
	for i = 1, NUM_OBB_UNIQUE_EDGES do
		local edgeA = axes[i]
		
		for j = NUM_OBB_UNIQUE_EDGES, 2 * NUM_OBB_UNIQUE_EDGES do
			local edgeB = axes[j]
			
			if edgeA:FuzzyEq(edgeB, SKIN_THICKNESS) then
				numAxes += 1
				axes[numAxes] = vector.cross(edgeA, edgeB) 
			end
		end
	end
	
	local penetration = N_BIG
	local mtv = vector.zero
	
	for i = 1, numAxes do
		local axis = axes[i]
		
		local dist = resolveOBBOBBOnAxis(cframeA, sizeA, cframeB, sizeB, axis)
		
		if not dist then
			return vector.zero
		end
		
		if dist > 0 then
			continue
		end
		
		if dist > penetration then
			mtv = axis
			penetration = dist
		end
	end
	
	return mtv * penetration
end

return resolveOOBOOB
