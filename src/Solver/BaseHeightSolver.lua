--!strict
local Package = script.Parent.Parent
local Packages = Package.Parent
local _Math = require(Packages.Math)
local _Maid = require(Packages.Maid)

local Types = require(Package.Types)

return function(config: Types.LandmasterConfigData, getTerrainMap: () -> Types.NoiseMap<number>, getRiverMap: () -> Types.NoiseMap<number>)
	local cache = {}

	local map: _Math.NoiseSolver = _Math.Noise.Simplex.new()
	map:SetSeed(config.Seed)
	map:SetFrequency(config.Frequency)
	map:SetAmplitude(1)
	map:SetLacunarity(2)
	map:SetPersistence(0.5)

	for i = 1, 4 do
		local Octave = _Math.Noise.Simplex.new()
		Octave:SetSeed(config.Seed * i)
		map:InsertOctave(Octave)
	end

	return function(alpha: Vector2): number
		if cache[alpha] then return cache[alpha] end

		local baseValue = (map:Get(alpha)^1.5) * 2
		if baseValue ~= baseValue then
			baseValue = 0
		end

		local terrainValue = getTerrainMap()(alpha)

		baseValue = _Math.clamp(baseValue * 0.5 + 0.5 * terrainValue, 0, 1)
		local distFromCenter = (Vector2.new(0.5, 0.5) - alpha).Magnitude
		local linearReduction = _Math.max(1 - (distFromCenter / 0.5), 0)
		local easedReduction =
			_Math.Algebra.ease(linearReduction ^ 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		local easedHeight = easedReduction * baseValue

		local riverValue = getRiverMap()(alpha)

		local final = riverValue * _Math.clamp(easedHeight, 0, 1)
	
		cache[alpha] = final
	
		return final
	end
end