local local_class = newclass('MemorialThiefController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	self.main_quest_id = 7200105

	self.quest_progress = nil

	self.vent_zone_name = 'vent_field'

	self.vent_info = {
		zone_name = 'vent_field',
		is_in_zone = false,

		buff_name = 'speed_cap_memorial_thief_persistent',

		activate = function(this)
			local leader = get_party_leader()
			--해당 존을 이동하는 캐릭터는 walk4legs 를 실행합니다.
			scene_util.set_anim(leader,self,'walk4legs')

			--해당 존을 이동하는 캐릭터는 달리기를 사용할 수 없습니다.
			stage.SmokeManager:UnsetCharacterSmoke(leader)

			--해당 존을 이동하는 캐릭터는 이동속도가 3으로 고정됩니다.
			this:add_buff(leader)
		end,
		deactivate = function(this)
			local leader = get_party_leader()
			character_util.remove_anim_and_emotion(leader)
			stage.SmokeManager:SetCharacterSmoke(leader)
			this:remove_buff(leader)
		end,
		add_buff = function(this, fo)
			buff_manager:AddBuff(fo, CS.Oak.EquipmentSlot.None, fo, this.buff_name, 0, false, false)
		end,
		remove_buff = function(this, fo)
			buff_manager:RemoveBuff(fo, CS.Oak.EquipmentSlot.None, fo, this.buff_name)
		end
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	self.quest_progress = nil
	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

function local_class:on_event(e)
	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	stage_start_util.start_function(self.quest_progress)
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), self.vent_info.zone_name) then
		self.vent_info:activate()
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), self.vent_info.zone_name) then
		self.vent_info:deactivate()
		return true
	end

	return false
end

function local_class:set_broken_window()
	local broken_count = 3

	for index = 1, broken_count do
		local broken_window = get_field_object('s8_broken_window_' .. index)

		animator_util.play(broken_window, 'start')
	end
end

return local_class
