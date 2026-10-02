local local_class = newclass('SubStageCamillaController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	--기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 공주 가져오기
	-- TODO 공주 없이 진행할 확률 높아 지워야 함
	self.get_princess = function()
		return get_character('princess')
	end

	-- 빔다운 이펙트
	--self.get_fx_beam = function()
	--	return unity_object_pool.GetOrCreate('FX_Event_InvaderBeam')
	--end

	-- effect
	-- 마법진
	self.get_fx_magic_circle = function()
		return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')
	end

	-- markers
	self.get_magic_circle_passage = function()
		return field:GetMarker('magic_circle_passage_pos')
	end

	self.get_magic_circle_passage_out = function()
		return field:GetMarker('magic_circle_passage_out_pos')
	end

	-- zone names
	self.magic_circle_passage_zone = 'magic_circle_passage_zone'

	self.is_warp_magiccircle = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	self.get_fx_magic_circle()

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	local effect_pos = self.get_magic_circle_passage().position
	self.magic_circle_passage_effect_1 = self.get_fx_magic_circle():Instantiate(effect_pos)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_interact_event(e)

end

function local_class:on_zone_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if not self.is_warp_magiccircle then
			if e.Zone.Name == self.magic_circle_passage_zone then
				self.is_warp_magiccircle = true
				sp_util.play_normal_screenplay(self.enter_magiccircle_event, self, e.Zone.Name)
			end
		end
	end
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:pre_setting()

	quest_util.load_pool_resource('FX_Event_InvaderBeam')
	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')

			character_util.set_active_state(leader, 'disabled')

			wait_for_sec(1.0)

			--빔다운 효과로 1프레임 튀는 것 방지하기 위해 카메라 고정.
			camera_util.move_async(vector(-0.5,0,2),0)

			character_util.set_active_state(leader, 'enabled')

			--가디언이 인베이더 빔다운(FX_Event_InvaderBeam)과 함께 등장한다.
			--표정이 먼저 등장하지 않도록 일부러 async로 안함.
			screen_util.invader_transfer(leader.Position ,
					CS.Oak.Direction.Right, leader, { duration = 0.2})
			wait_for_sec(0.2)

			character_util.set_emotion(leader, { name = 'surprise' })
			wait_for_sec(1.0)

			music_player_util.play_sfx_one_shot('01_swing_01')
			character_util.set_direction(leader, 'left')
			wait_for_sec(1.0)

			music_player_util.play_sfx_one_shot('01_swing_01')
			character_util.set_direction(leader, 'right')
			wait_for_sec(1.0)

			character_util.remove_anim_and_emotion(leader)

			CS.Oak.CommonScreenplay.ShowStageTitle(game_string:GetString(stage.Name), 1.5)
			music_player:PlaySfxOneShot('01_stage_intro_jump_01')
			character_util.set_direction(leader, 'right')
			character_util.set_anim(leader, { name = 'victory_get', loop = false })
			if play_stage_music then
				music_player_util.play_stage_music({ state = 'field' })
			end
			wait_for_sec(1.7)



			character_util.remove_anim_and_emotion(leader)

			party_util.stop_and_disable_control()
			--narr : 텔레포트 장치를 통해 혼자 이동했다.
			field_ui_util.show_narration_async({ key = 'qs_camilla_stage_narration' })
			camera_util.return_to_leader(0.1)
			party_util.reset_controllers()

			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		else
			if play_stage_music then
				music_player_util.play_stage_music({ state = 'field' })
			end
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end
	-- 꼬마 공주 없이 진행
	change_leader_character()
	coroutine.yield(nil)
	start_stage_event('up', field:GetMarker('default_start').position, true, true)
end

--region Magic Circle
-- 마법진 진입 이벤트
function local_class:enter_magiccircle_event(zone_name)
	local center = field:GetZone(zone_name).Bounds.center

	local out_marker_pos = self.get_magic_circle_passage_out().position

	self.is_warp_magiccircle = true

	local diff_1 = user_party.Leader.Position - center

	character_util.spine_set_alpha_fade(user_party.Leader, 0, 0.5)

	wait_for_sec(0.2)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party.Leader, out_marker_pos)

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party.Leader, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.is_warp_magiccircle = false
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
