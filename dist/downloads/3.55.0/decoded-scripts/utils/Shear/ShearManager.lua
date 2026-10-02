---@class ShearManager
local local_class = newclass('ShearManager')

function local_class:init()
	local all_constants = require('utils/Shear/ShearManagerConstants')

	local constants = all_constants[stage.Name]
	local shear_controller_name = lua_helper.get_value(constants, 'shear_controller_name', 'shear')
	local off_zone_names = lua_helper.get_value(constants, 'off_zones', nil)

	self.shear_controller = {
		handle_name = shear_controller_name,
		component = nil,
		default_value = nil,

		get_component = function(this)
			if this.component == nil then
				local fo = get_field_object(this.handle_name)

				this.component = fo:GetComponent(typeof(CS.Oak.ShearController))
			end

			return this.component
		end,

		off = function(this)
			this:save_default_value()

			this:get_component().Shear = 0
		end,

		on = function(this)
			this:get_component().Shear = this.default_value
		end,

		save_default_value = function(this)
			if this.default_value ~= nil then
				return
			end

			this.default_value = this:get_component().Shear
		end,

		dispose = function(this)
			this.component = nil
		end
	}

	-- 요청자 목록
	self.off_requesters = create_lua_hashset()

	-- 시어를 꺼줄 존 이름들
	self.off_zones = nil

	if off_zone_names ~= nil and table_util.get_size(off_zone_names) > 0 then
		self.off_zones = create_lua_hashset(table.unpack(off_zone_names))

		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	end
end

function local_class:dispose()
	if self.off_zones ~= nil then
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

		self.off_zones:clear()
	end

	self.off_zones = nil

	if self.shear_controller ~= nil then
		self.shear_controller:dispose()
	end

	self.shear_controller = nil
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, get_party_leader()) and
			self.off_zones:contains(e.Zone.Name) then
		self:request_off(e.Zone.Name)

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, get_party_leader()) and
			self.off_zones:contains(e.Zone.Name) then
		self:request_on(e.Zone.Name)

		return true
	end

	return false
end

--- On 요쳥
function local_class:request_on(request_key)
	-- Remove에 성공했고, 요청자가 남아있지 않다면 다시 On
	if self.off_requesters:remove(request_key) and #self.off_requesters == 0 then
		self.shear_controller:on()
	end
end

--- Off 요청
function local_class:request_off(request_key)
	-- Add에 성공했고, 이 요청만 가지고 있다면 첫 요청이므로 Off
	if #self.off_requesters == 0 and self.off_requesters:add(request_key) then
		self.shear_controller:off()
	end
end

return {
	create = function()
		return local_class()
	end
}
