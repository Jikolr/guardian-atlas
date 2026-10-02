---@class IBackgroundFadeController
---@field load_async fun(self:self, asset_path:string, asset_name:string):string
---@field set_background_active fun(self:self, enabled : boolean):boolean
---@field set_background_color fun(self:self, r : number, g : number, b : number):number
---@field set_background_alpha fun(self:self, target_alpha : number):number
---@field set_background_scale fun(self:self, target_scale : number):number
---@field set_background_sorting_order fun(self:self, layer_name : string, sorting_order : number):string, number
---@field set_background_position fun(self:self, position : Vector3):Vector3

-- 백그라운드 오브젝트가 원하는 색상으로 정확히 보이기 위해선 stage camera 에 Image Effect Controller 를 끄고,
-- 해당 위치에 light 를 조절하거나, background 의 소팅 레이어를 light 위로 (Top Effects 및 order) 조절할 필요가 있다.

---@class BackgroundFadeController : IBackgroundFadeController
local local_class = newclass('BackgroundFadeController')

function local_class:init()
	self.res_holder = nil
	self.background = nil
	self.background_renderer = nil
end

function local_class:dispose()
	self:dispose_loaded()
end

-- 백그라운드 오브젝트를 로드 함
---@param asset_path string 프리팹 경로
---@param asset_name string 프리팹 이름
function local_class:load_async(asset_path, asset_name)
	asset_path = lua_helper.get_or_default(asset_path, 'ondemand/v2_22_lilithtower/theatres/ending')
	asset_name = lua_helper.get_or_default(asset_name, 'white_tint_background')

	if self.background == nil then
		self.res_holder = CS.Foundations.ResourceHolder()

		self.background = load_util.load_prefab_async(self.res_holder, asset_path, asset_name)
		self.background_renderer = self.background:GetComponent(typeof(CS.UnityEngine.SpriteRenderer))
	end

	self:set_background_reset()
end

-- 백그라운드 오브젝트를 dispose 해줌
function local_class:dispose_loaded()
	self.background_renderer = nil

	if not is_unity_null(self.background) then
		CS.UnityEngine.Object.Destroy(self.background)
	end

	self.background = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end

	self.res_holder = nil
end

-- 백그라운드 오브젝트를 활성화 시킴
---@param enabled boolean 활성화 여부
function local_class:set_background_active(enabled)
	self.background:SetActive(enabled)

	if enabled then
		local look_at_position = stage_camera.LookAtPosition
		local y_offset = 10
		local background_position = vector(look_at_position.x, y_offset, look_at_position.z - y_offset)
		self:set_background_position(background_position)

		self:set_background_scale(40)
		self:set_background_sorting_order('Under Effects', -100)
	end
end

-- 백그라운드 오브젝트의 컬러 수치 조절
---@param r number unity color 의 r 값
---@param g number unity color 의 g 값
---@param b number unity color 의 b 값
function local_class:set_background_color(r, g, b)
	local alpha = self.background_renderer.color.a
	local target_color = unity_color({ r, g, b, alpha })

	self.background_renderer.color = target_color
end

-- 백그라운드 오브젝트의 투명도 수치 조절
---@param target_alpha number unity color 의 alpha 값
function local_class:set_background_alpha(target_alpha)
	local color = self.background_renderer.color
	color.a = target_alpha

	self.background_renderer.color = color
end

-- 백그라운드 오브젝트의 크기 조절
---@param target_alpha number 백그라운드 의 scale 값
function local_class:set_background_scale(target_scale)
	self.background.transform.localScale = unity_class.vector3.one * target_scale
end

-- 백그라운드 오브젝트의 sorting_order 조절
---@param layer_name string 소팅 레이어 네임
---@param sorting_order number 소팅 오더 값
function local_class:set_background_sorting_order(layer_name, sorting_order)
	self.background_renderer.sortingLayerName = layer_name
	self.background_renderer.sortingOrder = sorting_order
end

-- 백그라운드 오브젝트의 위치 조절
---@param position Vector3 위치 값
function local_class:set_background_position(position)
	self.background.transform.position = position
end

-- 백그라운드 오브젝트의 초기 세팅 으로 리셋
function local_class:set_background_reset()
	self:set_background_color(1, 1, 1)
	self:set_background_alpha(0)
	self:set_background_active(false)
end

return {
	create = function()
		return local_class()
	end
}
