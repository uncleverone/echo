local _PACKAGE, common_local = (...):match("^(.+)%.[^%.]+"), common
if not (type(common) == 'table' and common.class and common.instance) then
    assert(common_class ~= false, 'No class commons specification available.')
    require(_PACKAGE .. '.class')
    common_local, common = common, common_local
end
local vector  = require(_PACKAGE .. '.vector-light')

----------------------------
-- Private helper functions
--

local function sign( x )
    if     x > 0 then return 1
    elseif x < 0 then return -1 
    end

    return 0
end

-- create vertex list of coordinate pairs
local function toVertexList(vertices, x,y, ...)
    if not (x and y) then return vertices end -- no more arguments

    vertices[#vertices + 1] = {x = x, y = y}   -- set vertex
    return toVertexList(vertices, ...)         -- recurse
end

-- returns true if three vertices lie on a line
local function areCollinear(p, q, r, eps)
    return math.abs(vector.det(q.x-p.x, q.y-p.y,  r.x-p.x,r.y-p.y)) <= (eps or 1e-32)
end
-- remove vertices that lie on a line
local function removeCollinear(vertices)
    local ret = {}
    local i,k = #vertices - 1, #vertices
    for l=1,#vertices do
        if not areCollinear(vertices[i], vertices[k], vertices[l]) then
            ret[#ret+1] = vertices[k]
        end
        i,k = k,l
    end
    return ret
end

-- get index of rightmost vertex (for testing orientation)
local function getIndexOfleftmost(vertices)
    local idx = 1
    for i = 2,#vertices do
        if vertices[i].x < vertices[idx].x then
            idx = i
        end
    end
    return idx
end

-- returns true if three points make a counter clockwise turn
local function ccw(p, q, r)
    return vector.det(q.x-p.x, q.y-p.y,  r.x-p.x, r.y-p.y) >= 0
end

-- test wether a and b lie on the same side of the line c->d
local function onSameSide(a,b, c,d)
    local px, py = d.x-c.x, d.y-c.y
    local l = vector.det(px,py,  a.x-c.x, a.y-c.y)
    local m = vector.det(px,py,  b.x-c.x, b.y-c.y)
    return l*m >= 0
end

local function pointInTriangle(p, a,b,c)
    return onSameSide(p,a, b,c) and onSameSide(p,b, a,c) and onSameSide(p,c, a,b)
end

-- test whether any point in vertices (but pqr) lies in the triangle pqr
-- note: vertices is *set*, not a list!
local function anyPointInTriangle(vertices, p,q,r)
    for v in pairs(vertices) do
        if v ~= p and v ~= q and v ~= r and pointInTriangle(v, p,q,r) then
            return true
        end
    end
    return false
end

-- test is the triangle pqr is an "ear" of the polygon
-- note: vertices is *set*, not a list!
local function isEar(p,q,r, vertices)
    return ccw(p,q,r) and not anyPointInTriangle(vertices, p,q,r)
end

local function segmentsInterset(a,b, p,q)
    return not (onSameSide(a,b, p,q) or onSameSide(p,q, a,b))
end

-- returns starting/ending indices of shared edge, i.e. if p and q share the
-- edge with indices p1,p2 of p and q1,q2 of q, the return value is p1,q2
local function getSharedEdge(p,q)
    local pindex = setmetatable({}, {__index = function(t,k)
        local s = {}
        t[k] = s
        return s
    end})

    -- record indices of vertices in p by their coordinates
    for i = 1,#p do
        pindex[p[i].x][p[i].y] = i
    end

    -- iterate over all edges in q. if both endpoints of that
    -- edge are in p as well, return the indices of the starting
    -- vertex
    local i,k = #q,1
    for k = 1,#q do
        local v,w = q[i], q[k]
        if pindex[v.x][v.y] and pindex[w.x][w.y] then
            return pindex[w.x][w.y], k
        end
        i = k
    end
end

-----------------
-- Polyline class
--
local Polyline = {}
function Polyline:init(...)
    local vertices = toVertexList({}, ...)
    assert(#vertices >= 2, "Need at least 2 non collinear points to build polyline (got "..#vertices..")")

    -- assert polyline is not self-intersecting
    -- outer: only need to check segments #vert;1, 1;2, ..., #vert-3;#vert-2
    -- inner: only need to check unconnected segments
    local q,p = vertices[#vertices]
    for i = 1,#vertices-2 do
        p, q = q, vertices[i]
        for k = i+1,#vertices-1 do
            local a,b = vertices[k], vertices[k+1]
            assert(not segmentsInterset(p,q, a,b), 'Polyline may not intersect itself')
        end
    end

    self.vertices = vertices
    -- make vertices immutable
    setmetatable(self.vertices, {__newindex = function() error("Thou shall not change a polyline's vertices!") end})

    -- compute centroid
    local cx, cy = 0, 0
    for i,v in ipairs(self.vertices) do
        cx = cx + v.x
        cy = cy + v.y
    end
    self.centroid = { x = cx / #vertices,  y =cy / #vertices}

    -- get outcircle
    self._radius = 0
    for i = 1,#vertices do
        self._radius = math.max(self._radius,
            vector.dist(vertices[i].x,vertices[i].y, self.centroid.x,self.centroid.y))
    end
end
local newPolyline


-- return vertices as x1,y1,x2,y2, ..., xn,yn
function Polyline:unpack()
    local v = {}
    for i = 1,#self.vertices do
        v[2*i-1] = self.vertices[i].x
        v[2*i]   = self.vertices[i].y
    end
    return unpack(v)
end

-- deep copy of the polyline
function Polyline:clone()
    return Polyline( self:unpack() )
end

-- get bounding box
function Polyline:bbox()
    local ulx,uly = self.vertices[1].x, self.vertices[1].y
    local lrx,lry = ulx,uly
    for i=2,#self.vertices do
        local p = self.vertices[i]
        if ulx > p.x then ulx = p.x end
        if uly > p.y then uly = p.y end

        if lrx < p.x then lrx = p.x end
        if lry < p.y then lry = p.y end
    end

    return ulx,uly, lrx,lry
end

function Polyline:move(dx, dy)
    if not dy then
        dx, dy = dx:unpack()
    end
    for i,v in ipairs(self.vertices) do
        v.x = v.x + dx
        v.y = v.y + dy
    end
    self.centroid.x = self.centroid.x + dx
    self.centroid.y = self.centroid.y + dy
end

function Polyline:rotate(angle, cx, cy)
    if not (cx and cy) then
        cx,cy = self.centroid.x, self.centroid.y
    end
    for i,v in ipairs(self.vertices) do
        -- v = (v - center):rotate(angle) + center
        v.x,v.y = vector.add(cx,cy, vector.rotate(angle, v.x-cx, v.y-cy))
    end
    local v = self.centroid
    v.x,v.y = vector.add(cx,cy, vector.rotate(angle, v.x-cx, v.y-cy))
end

function Polyline:scale(s, cx,cy)
    if not (cx and cy) then
        cx,cy = self.centroid.x, self.centroid.y
    end
    for i,v in ipairs(self.vertices) do
        -- v = (v - center) * s + center
        v.x,v.y = vector.add(cx,cy, vector.mul(s, v.x-cx, v.y-cy))
    end
    self._radius = self._radius * s
end

function Polyline:contains(x,y)
    local epsilon = 1e-9
    
    local in_polyline = false

    for i=1,#self.vertices - 1 do
        if areCollinear(self.vertices[i], {x=x,y=y}, self.vertices[i+1]) then
            if (self.vertices[i].x <= x and x <= self.vertices[i+1].x) or  (self.vertices[i+1].x <= x and x <= self.vertices[i].x) then
                return true
            end
        end
    end

    return in_polyline
end

function Polyline:intersectionsWithRay(x,y, dx,dy)
    local nx,ny = vector.perpendicular(dx,dy)
    local wx,xy,det

    local ts = {} -- ray parameters of each intersection
    local q1,q2 = nil, self.vertices[#self.vertices]
    for i = 1, #self.vertices do
        q1,q2 = q2,self.vertices[i]
        wx,wy = q2.x - q1.x, q2.y - q1.y
        det = vector.det(dx,dy, wx,wy)

        if det ~= 0 then
            -- there is an intersection point. check if it lies on both
            -- the ray and the segment.
            local rx,ry = q2.x - x, q2.y - y
            local l = vector.det(rx,ry, wx,wy) / det
            local m = vector.det(dx,dy, rx,ry) / det
            if m >= 0 and m <= 1 then
                -- we cannot jump out early here (i.e. when l > tmin) because
                -- the polyline might be concave
                ts[#ts+1] = l
            end
        else
            -- lines parralel or incident. get distance of line to
            -- anchor point. if they are incident, check if an endpoint
            -- lies on the ray
            local dist = vector.dot(q1.x-x,q1.y-y, nx,ny)
            if dist == 0 then
                local l = vector.dot(dx,dy, q1.x-x,q1.y-y)
                local m = vector.dot(dx,dy, q2.x-x,q2.y-y)
                if l >= m then
                    ts[#ts+1] = l
                else
                    ts[#ts+1] = m
                end
            end
        end
    end

    return ts
end

function Polyline:intersectsRay(x,y, dx,dy)
    local tmin = math.huge
    for _, t in ipairs(self:intersectionsWithRay(x,y,dx,dy)) do
        tmin = math.min(tmin, t)
    end
    return tmin ~= math.huge, tmin
end

function Polyline:intersectsSegment(p,q)
    local segment_length = vector.len(q.x - p.x, q.y - p.y)
    local tmin = math.huge
    for _, t in ipairs(self:intersectionsWithRay(p.x,p.y,vector.normalize(q.x - p.x, q.y - p.y))) do
        tmin = sign(t) * math.min(tmin, math.abs(t))
    end
    return tmin ~= math.huge and tmin >= 0, tmin
end

Polyline = common_local.class('Polyline', Polyline)
newPolyline = function(...) return common_local.instance(Polyline, ...) end
return Polyline