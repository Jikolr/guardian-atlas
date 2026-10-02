local local_class = newclass('NightmareQueenCastleObeliskController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.is_clear_quest = false

	self.obelisk_info = {
		-- 마리안 (번개)
		{ quest_id = 457, gimmick = function()
			return get_field_object('obelisk_lightning')
		end },
		-- 마빈 (바람)
		{ quest_id = 458, gimmick = function()
			return get_field_object('obelisk_wind')
		end },
		-- 크레이그 (불)
		{ quest_id = 459, gimmick = function()
			return get_field_object('obelisk_fire')
		end },
		-- 코코 (물)
		{ quest_id = 460, gimmick = function()
			return get_field_object('obelisk_water')
		end },
	}
end

function local_class:dispose()

	self.cs_controller = nil
end

function local_class:load_resource()
	self:setting_obelisk()
end

function local_class:on_event(e)
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
end

function local_class:check_quest(id)
	local quest_progress = user_progress:GetStartedQuest(id)

	return quest_progress ~= nil and quest_progress.IsComplete
end

function local_class:check_clear()
	local check_count = 0

	for i = 1, #self.obelisk_info do
		if self:check_quest(self.obelisk_info[i].quest_id) then
			check_count = check_count + 1
		end
	end

	return check_count == #self.obelisk_info, check_count
end

function local_class:setting_obelisk()
	for i = 1, #self.obelisk_info do
		if not self:check_quest(self.obelisk_info[i].quest_id) then
			animator_util.play(self.obelisk_info[i].gimmick(), 'idle')
		end
	end
end

function local_class:set_obelisk_anim(quest_id, anim)
	for i = 1, #self.obelisk_info do
		if self.obelisk_info[i].quest_id == quest_id then
			animator_util.play(self.obelisk_info[i].gimmick(), anim)
		end
	end
end

function local_class:set_obelisk_anim_async(quest_id, anim, length)
	for i = 1, #self.obelisk_info do
		if self.obelisk_info[i].quest_id == quest_id then
			animator_util.play_async(self.obelisk_info[i].gimmick(), anim, length)
			return
		end
	end
end

return local_class
