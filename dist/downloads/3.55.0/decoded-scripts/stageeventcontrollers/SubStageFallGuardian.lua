local local_class = newclass('SubStageFallGuardianController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 2섹션쪽 기사 가져오는 용도
	self.get_fg_knight = function()
		return user_util.get_knight_character('fg_knight_female', 'fg_knight_male')
	end

	self.get_maiden = function()
		return get_character('qc_maiden')
	end

	-- 필드 오브젝트
	self.get_paper_drop_item = function()
		return get_field_object('letter_drop_item')
	end

	self.get_starpiece = function()
		return get_field_object('fg_starpiece')
	end

	self.get_brazier_starpiece = function()
		return get_field_object('soccer_ball_star_piece')
	end

	self.get_brazier = function(index)
		return get_field_object('timer_brazier_'..index)
	end

	self.get_knight_start_pos = function()
		return field_util.get_marker_pos('knight_start_pos_1')
	end

	self.scene_version = scene_util.default_version

	-- 마커
	self.get_flower_pos = function()
		return field_util.get_marker_pos('flower_pos_1')
	end

	self.get_flower_drop_item_pos = function()
		return field_util.get_marker_pos('s2_flower_drop_item_pos_1')
	end

	self.get_paper_pos = function()
		return field_util.get_marker_pos('s2_clearevent_letter_pos_1')
	end

	-- 이펙트
	self.get_star_piece_fx = function()
		return unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	end

	self.get_camera_pos = function(num)
		return field_util.get_marker_pos('s1_camera_pos_' .. num)
	end

	-- 꽃
	self.flower = nil

	-- 필드오브젝트 꽃
	self.fo_flower = nil

	-- 꽃 애니메이션
	self.flower_animator = nil

	-- 리소스 홀더
	self.res_holder = nil

	self.starpiece_flag = true

	self.qc_paper_item = nil
	self.qc_paper_id = 20897

	self.flower_bloom_custom_event = 'flower_bloom'

	self.character_tint_key_list = {
		veiled = 'veiled'
	}

	-- 스타피스 관련
	self.brazier_on_count = 0
	self.max_brazier_num = 2
	self.is_brazier_event_finished = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BrazierOnOffEvent))

	-- 꽃 오브젝트 dispose
	if self.starpiece_effect ~= nil then
		self.starpiece_effect:Dispose()
		self.starpiece_effect = nil
	end

	if self.qc_paper_item ~= nil then
		self.qc_paper_item:ConsumeComplete()
		self.qc_paper_item = nil
	end

	if self.flower ~= nil then
		CS.UnityEngine.Object.Destroy(self.flower)
	end

	self.flower = nil
	self.flower_animator = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 꽃 오브젝트 생성
	self.get_star_piece_fx()

	self.res_holder = CS.Foundations.ResourceHolder()
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, "theatres/maiden_flower", "flower", function(prefab)
				local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
				local t =  obj.transform
				t.position = self.get_flower_pos()
				t.rotation = unity_class.quaternion.Euler(0, 0, 0)
				t.localScale = vector(1.5, 1.5, 1.5)
				self.flower = obj
				self.flower_animator = t:GetChild(0):GetComponent(typeof(CS.UnityEngine.Animator))
				local tile = CS.Oak.VirtualFieldObject()
				tile.Position = t.position
				tile.Hitbox = CS.Oak.Hitbox(vector(3, 1.5, 3))
				tile.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
				tile.ActiveState = CS.Oak.ActiveState.InField
				message_system:Send(field, CS.Oak.AddFieldObjectEvent.Create(tile))
			end)

	yield_return(unity_object_pool, 'WaitAll')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	-- camera_util.move(self.get_camera_pos(1), 0)
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.BrazierOnOffEvent), 'on_brazier_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	music_player_util.change_stage_music_volume('field', 0.5)

	local main_quest_id = 339
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	--local maiden = self.get_maiden()
	--character_util.add_color(maiden, self.character_tint_key_list.veiled, unity_class.color.black, 1, 0)

	-- 퀘스트가 클리어 상태가 아니라면 스타피스 셋팅
	self.quest_is_complete = quest_progress.IsComplete
	if not self.quest_is_complete then
		-- 미리 편지 아이템 생성해두기.
		self.qc_paper_item = drop_item_util.create_item({
			pos = self.get_paper_pos() + vector(1, 0, 0),
			target = self.get_paper_pos(),
			itemid = self.qc_paper_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
			sprscale = 1 })

		local paper_pos = self.get_paper_pos()
		self.get_paper_drop_item().Position = paper_pos
		self.starpiece_effect = self.get_star_piece_fx():Instantiate(paper_pos)
	else
		self.qc_paper_item = drop_item_util.create_item({
			pos = self.get_paper_pos() + vector(1, 0, 0),
			target = self.get_paper_pos(),
			itemid = self.qc_paper_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
			sprscale = 1 })
		local paper_pos = self.get_paper_pos()
		self.get_paper_drop_item().Position = paper_pos
	end

	if not quest_progress.IsComplete then
		-- 2섹션인지 검사
		if quest_progress.InnerProgress == 1 then
			-- 2섹션 전용 기사 가져오기
			local fg_knight = self.get_fg_knight()
			--fg_knight.Position = self.get_knight_start_pos()
			character_util.set_direction(fg_knight, 'up')
			character_util.remove_anim_and_emotion(fg_knight)

			screen_util.fade_in_async(0, unity_class.color.black,'linear')
			screen_util.fade_in_circular(1,'linear')
			music_player:PlayStageIntroMusic()
			music_player_util.play_stage_music({ state = 'field' })
		elseif quest_progress.InnerProgress == 0 then
		else
			local fg_knight = self.get_fg_knight()
			fg_knight.Position = self.get_knight_start_pos()

			screen_util.fade_in_async(0, unity_class.color.black,'linear')
			screen_util.fade_in_circular(1,'linear')
			music_player:PlayStageIntroMusic()
			music_player_util.play_stage_music({ state = 'field' })
		end
	else
		--local fg_knight = self.get_fg_knight()
		--fg_knight.Position = self.get_knight_start_pos()
		--
		--screen_util.fade_in_async(0, unity_class.color.black,'linear')
		--screen_util.fade_in_circular(1,'linear')
		--
		--coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(fg_knight.Position + vector(0, 0, 0.5),
		--		fg_knight.Direction, game_string:GetString(stage.Name)))
		--
		--manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(get_party_leader(), false)
		--manual_touch_state:DisableControls(CS.Oak.DisabledControls.Attack | CS.Oak.DisabledControls.Super)
		--
		--state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
		--message_system:SendSync(leader.FieldObjectController, state_change_event)
		--
		--coroutine.yield(nil)
		--
		--field_ui_manager:RemoveUI(leader, CS.Oak.FieldUiType.SkillButton
		--		| CS.Oak.FieldUiType.ClassButton | CS.Oak.FieldUiType.RoleButton | CS.Oak.FieldUiType.ModeChangeButton
		--		| CS.Oak.FieldUiType.TeamCombinationButton | CS.Oak.FieldUiType.PartyState)

		-- 2섹션 전용 기사 가져오기
		local fg_knight = self.get_fg_knight()
		--fg_knight.Position = self.get_knight_start_pos()
		character_util.set_direction(fg_knight, 'up')
		character_util.remove_anim_and_emotion(fg_knight)

		screen_util.fade_in_async(0, unity_class.color.black,'linear')
		screen_util.fade_in_circular(1,'linear')
		music_player:PlayStageIntroMusic()
		music_player_util.play_stage_music({ state = 'field' })
	end

	-- 스타피스 처리
	if star_piece_util.has_star_piece('soccer_ball_star_piece') then
		self.is_brazier_event_finished = true
	else
	end

	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.flower_bloom_custom_event then
			self:bloom()
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_paper_drop_item()) then
		start_coroutine(self.interact_paper, self)
		return true
	end
end

function local_class:on_brazier_on_off_event(e)
	if not self.is_brazier_event_finished then
		for i = 1, 2 do
			if lua_helper.reference_equals(self.get_brazier(i), e.BrazierObject) then
				if e.IsTurningOn then
					self.brazier_on_count = self.brazier_on_count + 1

					if self.brazier_on_count == self.max_brazier_num then
						self.is_brazier_event_finished = true

						star_piece_util.appear(self.get_brazier_starpiece(), self.get_brazier_starpiece().Position)

						return true
					end
				else
					self.brazier_on_count = self.brazier_on_count - 1
				end
			end
		end
	end

	return false
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

function local_class:bloom()
	self.flower_animator:Play('bloom', -1)
end

function local_class:interact_paper()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	-- 편지 상호작용 시 이벤트
	-- 나레이션 박스 : 반가워요, 클론 대전의 우승자 분.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_13' })
	-- 나레이션 박스 : 이 편지를 읽고 있을 쯤엔 이미 모든 준비가 완료된 뒤겠죠.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_14' })
	-- 나레이션 박스 : 제 창조자께서는 헤븐홀드가 마계에 도착한 뒤, 제게 명령을 내리셨답니다.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_15' })
	-- 나레이션 박스 : '가장 우수한 라보스들을 선별하여, 곧 벌어질 전쟁에 참여해라.' 라구요.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_16' })
	-- 나레이션 박스 : 저는 그 분의 명령을 받들어 모습을 숨긴 뒤, 제 유능한 클론들을 만들어오고 있었습니다.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_17' })
	-- 나레이션 박스 : 이제 모든 준비가 완료되었고, 저는 이 곳을 떠나게 될 거에요.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_18' })
	-- 나레이션 박스 : 직접 만나서 인사를 드리고 싶었는데, 그러지 못해 참 아쉽네요.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_19' })
	-- 나레이션 박스 : 그럼…조만간 다시 뵙도록 해요.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_20' })
	-- 나레이션 : 캔터베리의 가디언, (플레이어 이름)에게.
	field_ui_util.show_narration_async({ key = 'qc_fall_guardian_s2_21' })
	-- 최초 1회, 편지의 FX_starpiece_in_character 이펙트가 사라지고 스타피스가 편지에서 튀어나와 클리어 깃발 아래에 떨어짐
	if self.starpiece_flag and not self.quest_is_complete then
		star_piece_util.appear(self.get_starpiece(), self.get_paper_drop_item().Position)
	end

	if self.starpiece_effect ~= nil then
		self.starpiece_effect:Dispose()
		self.starpiece_effect = nil
	end
	-- 컨트롤 복구
	-- 편지 상호작용은 스타피스 나온 뒤에도 계속해서 가능
	self.starpiece_flag = false

	party_util.reset_controllers()
	field_ui_manager:Show()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
