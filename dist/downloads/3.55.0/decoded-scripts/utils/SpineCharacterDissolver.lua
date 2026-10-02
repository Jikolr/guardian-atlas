---@class SpineCharacterDissolver
local local_class = newclass('SpineCharacterDissolver')

function local_class:init()
	self.main_texture_property_id = CS.UnityEngine.Shader.PropertyToID('_MainTex')
	self.dissolve_progress_property_id = CS.UnityEngine.Shader.PropertyToID('_DissolveProgress')
	self.wave_speed_property_id = CS.UnityEngine.Shader.PropertyToID('_WaveSpeed')
	self.wave_length_property_id = CS.UnityEngine.Shader.PropertyToID('_WaveLength')
	self.wave_amplitude_property_id = CS.UnityEngine.Shader.PropertyToID('_Amplitude')

	self.res_holder = nil

	self.cached_materials = {}
end

function local_class:dispose()
	for _, material in pairs(self.cached_materials) do
		CS.UnityEngine.Object.Destroy(material)
	end

	self.cached_materials = nil

	self.material_container = nil

	if not is_unity_null(self.material_container_obj) then
		CS.UnityEngine.Object.Destroy(self.material_container_obj)
	end

	self.material_container_obj = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end

	self.res_holder = nil
end

function local_class:load_async(asset_path, asset_name)
	if self.res_holder ~= nil then
		return
	end

	self.res_holder = CS.Foundations.ResourceHolder()

	self.material_container_obj = load_util.load_prefab_async(self.res_holder,
			asset_path, asset_name)

	self.material_container = self.material_container_obj:GetComponent(typeof(CS.Oak.MaterialContainer))
end

--- 캐릭터에 Dissolve Material을 세팅한다.
--- Dissolve 사용이 끝난 이후에는 (스테이지 종료 시 등) 반드시 remove_dissolve_material을 사용해 지워줄 것.
---@param need_cache boolean|nil 여러 번 사용하기 위해 캐싱을 할 것인지. 동적 할당된 캐릭터는 사용하지 말 것!!!
function local_class:set_dissolve_material(character, need_cache)
	need_cache = lua_helper.get_or_default(need_cache, true)

	if need_cache then
		if self.cached_materials[character] == nil then
			self.cached_materials[character] = self:create_dissolve_material(character)
		end

		character.SpineController.MaterialOverride = self.cached_materials[character]

		self:set_dissolve_progress(character, 0)
	else
		character.SpineController.MaterialOverride = self:create_dissolve_material(character)
	end
end

function local_class:create_dissolve_material(character)
	local renderer = character.SpineController.SkeletonAnimation:GetComponent(typeof(CS.UnityEngine.MeshRenderer))

	-- 캐릭터의 메인 텍스쳐 가져옴
	local origin_texture = nil

	for i = 1, renderer.materials.Length do
		local material = renderer.materials[i - 1]
		local texture = material:GetTexture(self.main_texture_property_id)

		-- 첫 번째 머터리얼이 아이템인 경우가 있어서 예외 처리
		-- 주체가 텍스쳐기 때문에, 머터리얼 네임으로 검사하지 않고 텍스쳐 네임으로 검사
		-- FIXME : 이렇게 해도 되는걸까...?
		if texture.name ~= 'items' then
			origin_texture = texture

			break
		end
	end

	if origin_texture == nil then
		logger_util.error('Cannot find Spine Character [Name : ' .. character.Name .. '] Material!')

		return nil
	end

	local dissolve_material = CS.UnityEngine.Material(self.material_container.MaterialList[0])

	dissolve_material:SetTexture(self.main_texture_property_id, origin_texture)

	return dissolve_material
end

--- 캐릭터에 붙은 Dissolve Material을 지운다.
function local_class:remove_dissolve_material(character)
	if self.cached_materials[character] == nil then
		local dissolve_material = self:get_dissolve_material(character)

		if dissolve_material == nil then
			return
		end

		character.SpineController.MaterialOverride = nil

		-- 캐싱되어있지 않다면 바로 파괴
		CS.UnityEngine.Object.Destroy(dissolve_material)

		character.SpineController:SetShadowAlpha(1)
	else
		-- 캐싱되어있는 경우에는 비워주기만 함. 파괴는 이 클래스에서 관리해줄 것이기 때문.
		character.SpineController.MaterialOverride = nil

		character.SpineController:SetShadowAlpha(1)
	end
end

function local_class:get_dissolve_material(character)
	--- FIXME : 이렇게 가져오면, Override로 변경되었을 때 체크가 불가능함.
	return character.SpineController.MaterialOverride
end

--- 진행도 세팅. 0부터 1까지 진행되면서 점점 가루가 됨
function local_class:set_dissolve_progress(character, progress)
	local dissolve_material = self:get_dissolve_material(character)

	if dissolve_material == nil then
		return
	end

	dissolve_material:SetFloat(self.dissolve_progress_property_id, progress)

	character.SpineController:SetShadowAlpha(1 - progress)
end

-- 캐릭터가 흔들리는 효과 수치 세팅
function local_class:set_wave_data(character, data)
	local dissolve_material = self:get_dissolve_material(character)

	if dissolve_material == nil then
		return
	end

	local speed = lua_helper.get_value(data, 'speed', 1)
	local length = lua_helper.get_value(data, 'length', 0.3)
	local amplitude = lua_helper.get_value(data, 'amplitude', 0.1)

	dissolve_material:SetFloat(self.wave_speed_property_id, speed)
	dissolve_material:SetFloat(self.wave_length_property_id, length)
	dissolve_material:SetFloat(self.wave_amplitude_property_id, amplitude)
end

return {
	create = function()
		return local_class()
	end
}
