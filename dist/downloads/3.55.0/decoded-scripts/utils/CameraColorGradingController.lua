---@class CameraColorGradingController
local local_class = newclass('CameraColorGradingController')

function local_class:init()
	self.res_holder = nil

	self.color_grader = nil

	self.color_self_default_value = 100
	self.color_other_default_value = 0
	self.origin_prop_values = {}

	self.color_self_prop_names = {
		'RedChannelRed',
		'GreenChannelGreen',
		'BlueChannelBlue',
	}

	self.color_other_prop_names = {
		'RedChannelGreen',
		'RedChannelBlue',
		'GreenChannelRed',
		'GreenChannelBlue',
		'BlueChannelRed',
		'BlueChannelGreen',
	}
end

function local_class:dispose()
	-- 새로 클론했던 녀석이기 때문에, 꼭 파괴해야 함
	if not is_unity_null(self.color_grader) then
		self:detach()

		CS.UnityEngine.Object.Destroy(self.color_grader)
	end

	self.color_grader = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end

	self.res_holder = nil
end

function local_class:load_async(asset_path, asset_name, image_effect_name)
	if self.res_holder ~= nil then
		return
	end

	self.res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder,
			asset_path, asset_name, function(prefab)
				local container = prefab:GetComponent(typeof(CS.Oak.ImageEffectDataContainer))
				local image_effects = container.ImageEffectDataList
				local origin_color_grader = nil

				for i = 1, image_effects.Count do
					local image_effect = image_effects[i - 1]

					if image_effect.Name == image_effect_name then
						origin_color_grader = image_effect
						break
					end
				end

				if is_unity_null(origin_color_grader) then
					-- TODO : 에러로그 출력
					return
				end

				self.color_grader = CS.UnityEngine.Object.Instantiate(origin_color_grader)
			end)

	for _, prop_name in pairs(self.color_self_prop_names) do
		self.origin_prop_values[prop_name] = self.color_grader[prop_name]
	end

	for _, prop_name in pairs(self.color_other_prop_names) do
		self.origin_prop_values[prop_name] = self.color_grader[prop_name]
	end
end

--- 카메라에 ColorGrading 이미지 이펙트 부착
function local_class:attach()
	local stage_camera_effects = stage_camera.ImageEffectController.ImageEffectDataList

	-- 추가한 경우 뒤에서부터 체크하는 것이 빠름
	for i = stage_camera_effects.Count - 1, 0, -1 do
		local image_effect = stage_camera_effects[i]

		if image_effect.Name == self.color_grader.Name then
			--TODO : 중복해서 넣으려고 한다는 에러로그 출력
			return
		end
	end

	stage_camera_effects:Add(self.color_grader)

	self.color_grader.IsActive = true
end

--- 카메라에 붙어있는 ColorGrading 이미지 이펙트 떼줌
--- !!! 중요 !!! 기능 사용이 끝나면 꼭 detach를 호출해줄 것!!
function local_class:detach()
	local stage_camera_effects = stage_camera.ImageEffectController.ImageEffectDataList

	-- 추가한 경우 뒤에서부터 체크하는 것이 빠름
	for i = stage_camera_effects.Count - 1, 0, -1 do
		local image_effect = stage_camera_effects[i]

		if image_effect.Name == self.color_grader.Name then
			stage_camera_effects:RemoveAt(i)

			break
		end
	end
end

---이미지 이펙트의 수준 제어.
---@param progress number 프로그레스가 0이면 화면 효과 없음, 1이면 이미지 이펙트 원본과 같은 값 사용. 0 ~ 1 사잇값
function local_class:set_progress(progress)
	-- 강제로 0~1 사이로 만들어줌
	-- FIXME : 0~1 이외의 값을 사용할 일이 있을까?
	progress = unity_class.mathf.Clamp01(progress)

	for _, prop_name in pairs(self.color_self_prop_names) do
		local cur_value = self.color_self_default_value * (1 - progress) + self.origin_prop_values[prop_name] * progress

		self.color_grader[prop_name] = cur_value
	end

	for _, prop_name in pairs(self.color_other_prop_names) do
		local cur_value = self.color_other_default_value * (1 - progress) + self.origin_prop_values[prop_name] * progress

		self.color_grader[prop_name] = cur_value
	end
end

return {
	create = function()
		return local_class()
	end
}
