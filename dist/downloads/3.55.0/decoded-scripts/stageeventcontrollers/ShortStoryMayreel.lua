local local_class = newclass('ShortStoryMayreel')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_mayreel = function() return get_character('mayreel') end
	self.get_mayreel_human = function() return get_character('mayreel_human') end

	self.get_snow_effect = function() return unity_object_pool.GetOrCreate('fx_xm_stage_snow_camera_fx') end

	self.snow_effect = nil

	self.main_quest_id = 7001001

	self.tint_key = 'shortstory_mayreel'

	self.tint_color = CS.UnityEngine.Color(0.3333, 0.3333, 0.5333, 0.8)

	self.bomb_tint_color = CS.UnityEngine.Color(0.168, 0.168, 0.266, 0.8)

	self.enter_factory = false

	self.factory_zone = 'factory_zone'
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.get_snow_effect()
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.factory_zone) and not self.enter_factory then
		self:enter_factory_setting()
		return true
	end
	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, self.factory_zone) and self.enter_factory then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.leave_factory_setting, self))
		return true
	end
	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'snow_effect_off' then
		self:snow_effect_off()
	end

	if e:GetParamAt(0) == 'snow_effect_on' then
		self:snow_effect_on()
	end
end

function local_class:on_stage_loaded_event(_)
	return false
end

-- 사전 세팅
function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	--- 폭탄 메터리얼 색 처리용 핵코드
	xlua.private_accessible(typeof(CS.Oak.BombFieldObjectBehaviour))

	self:snow_effect_on()

	local tint = (main_quest_progress == nil or main_quest_progress.InnerProgress == 0)
			and CS.UnityEngine.Color(0.7, 0.7, 0.9, 0.8) or self.tint_color
	self:set_night_tint(tint)

	if main_quest_progress == nil or main_quest_progress.InnerProgress == 0 then
		tint = CS.UnityEngine.Color(0.7, 0.7, 0.9, 0.8)
		self:mayreel_start_setting(false, field:GetMarker('s1_start').position, 'up',
				false, false, false)
	elseif main_quest_progress.IsComplete then
		local clear_start_pos = field:GetMarker('carol_snowman_pos').position + vector(0, 0, -1)
		self:mayreel_start_setting(true, clear_start_pos, 'right', true)
	elseif main_quest_progress.InnerProgress == 1 then
		self:mayreel_start_setting(false, field:GetMarker('default_start').position, 'right',
				false, false, false)
	elseif main_quest_progress.InnerProgress == 2 then
		self:mayreel_start_setting(false, field:GetMarker('s3_start').position, 'right',
				false, false, false)
	elseif main_quest_progress.InnerProgress >= 3 and main_quest_progress.InnerProgress < 5 then
		self:mayreel_start_setting(true, field:GetMarker('s3_start').position, 'right', true, true)
	elseif main_quest_progress.InnerProgress >= 5 and main_quest_progress.InnerProgress <= 7 then
		self:mayreel_start_setting(true, field:GetMarker('s5_8_start').position, 'right', true)
	elseif main_quest_progress.InnerProgress == 8 then
		self:mayreel_start_setting(true, field:GetMarker('s9_mayreel').position, 'left', false, false, false)
	else
		-- 따로 설정하지 않은 섹션이면 기본 시작 위치에서 메이릴 인간 모습으로 시작
		self:mayreel_start_setting(true, field:GetMarker('default_start').position, 'right', true)
	end
end

-- 메이릴 시작 세팅
function local_class:mayreel_start_setting(is_human, start_pos, dir, directional_stage_entry, with_cap, stage_music)
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	local mayreel = is_human and self.get_mayreel_human() or self.get_mayreel()
	local with_captain = lua_helper.get_or_default(with_cap, false)
	local play_stage_music = lua_helper.get_or_default(stage_music, true)

	--- playerable 메이릴 npc spec id
	local mayreel_human_id = 303711
	--- 더미 characterinfo 생성
	local mayreel_human_character_info = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
		user_party_leader.CharacterInfo.User, mayreel_human_id
	)
	--- 메이릴을 가져옴
	local mayreel_human = self.get_mayreel_human()
	--- 무기 비주얼 오버라이드 정보를 적용 시키기 위해 위해 홀더를 세팅
	mayreel_human.Weapon1.Holder = mayreel_human_character_info
	--- 홀더를 위에서 넣어줘서 어태치먼트 갱신
	mayreel_human:RefreshWeaponAttachments()

	character_util.convert_to_manual_character(mayreel, param)

	mayreel.Position = start_pos
	character_util.set_direction(mayreel, dir)

	field_ui_manager:SetUI(mayreel, CS.Oak.FieldUiType.TopHpBar)

	if with_captain then
		character_util.convert_to_party_member(get_character('captain_rabbit'), user_party, true)
	end

	if directional_stage_entry then
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(mayreel.Position,
				mayreel.Direction, game_string:GetString(stage.Name)))

		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	end

	if play_stage_music then
		music_player_util.play_stage_music({state = 'field'})
	end

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:enter_factory_setting()
	self.enter_factory = true
	self:snow_effect_off()
	field:RemoveTint(self.tint_key, 0)
end

function local_class:leave_factory_setting()
	self.enter_factory = false
	self:snow_effect_on()
	coroutine.yield(nil)
	self:set_night_tint(self.tint_color)
end

function local_class:set_night_tint(tint)
	field:Tint(self.tint_key, tint, 0)
	message_system:Publish(CS.Oak.ChangeColorEvent.Create(tint))
end

function local_class:snow_effect_on()
	if self.snow_effect == nil then
		self.snow_effect = self.get_snow_effect():Instantiate(stage_camera.Transform.position,
				unity_class.quaternion.Euler(45, 0, 0), stage_camera.Transform)
	end
end

function local_class:snow_effect_off()
	if self.snow_effect ~= nil then
		self.snow_effect:Dispose()
		self.snow_effect = nil
	end
end


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	field:RemoveTint(self.tint_key, 0)

	self:snow_effect_off()

	self.tint_color = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
