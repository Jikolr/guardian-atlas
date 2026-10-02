local local_class = newclass("NightmareSnowMountain6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 오브젝트를 가져오는 함수
	self.get_snowball = function() return get_field_object('snowball_1') end
	self.get_reset_switch = function() return get_field_object('reset_switch_1') end

	-- 마커를 가져오는 함수
	self.snowball_reset_marker = function() return field:GetMarker('snowball_reset') end

	-- 이펙트 풀을 가져오는 함수
	self.get_reset_effect = function() return unity_object_pool.GetOrCreate('FX_reset_object') end

	-- 눈공의 원래 비주얼 스케일
	self.snowball_visual_scale = nil

	-- 눈공의 원래 히트박스
	self.snowball_original_hitbox = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')

	local snowball = self.get_snowball()
	self.snowball_visual_scale = snowball.Transform.localScale
	self.snowball_original_hitbox = snowball.Hitbox

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.get_reset_effect()

	yield_return(unity_object_pool, 'WaitAll')
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		return self:on_switch_on_off_event(e)
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	local reset_switch = self.get_reset_switch()

	if e.IsTurningOn then
		if lua_helper.reference_equals(e.SwitchObject, reset_switch) then
			self:reset_snowball()
		end
	end

	return false
end
--endregion

function local_class:reset_snowball()
	local snowball = self.get_snowball()
	local reset_marker = self.snowball_reset_marker()

	--이미 기믹을 사용해서 눈덩이가 Disabled 됐다면 Reset하지 않는다.
	if snowball.ActiveState == CS.Oak.ActiveState.Disabled then
		return
	end

	self.get_reset_effect():Instantiate(snowball.Position)

	snowball.Transform.localScale = self.snowball_visual_scale
	snowball.Hitbox = self.snowball_original_hitbox
	snowball.Position = reset_marker.position

	self.get_reset_effect():Instantiate(snowball.Position)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
