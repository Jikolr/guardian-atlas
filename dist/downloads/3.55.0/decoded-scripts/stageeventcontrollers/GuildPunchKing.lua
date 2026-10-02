local local_class = newclass("GuildPunchKing")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.resource_holder = CS.Foundations.ResourceHolder()

	-- 보스 HP 스텝 텍스트 탄막 개수(한 단계당)
	self.text_cloud_step_code_num = 5

	self.font_sizes = { 32, 34, 38, 41, 43, 45 }
	self.font_colors = {
		CS.UnityEngine.Color32(255, 255, 255, 255),
		CS.UnityEngine.Color32(255, 255, 255, 255),
		CS.UnityEngine.Color32(255, 255, 255, 255),
		CS.UnityEngine.Color32(0, 255, 255, 255),
		CS.UnityEngine.Color32(0, 255, 0, 255),
		CS.UnityEngine.Color32(139, 0, 255, 255),
	}

	-- 현재 관중 에니 스피드
	self.curr_crowd_ani_spd = 1.0
	-- 특정 단계 도달 시 관중 에니에 더해질 스피드
	self.crowd_ani_spd_add = 0.2
	self.crowd_ani_rand_per = 0.2
	self.crowd_ani_list = { 'clap', 'dance', 'success' }
	self.crowd_ani_change_time = 10

	-- Buff
	self.buff_name = 'buff_punchking_boss_attack_up';

	self.data = CS.Oak.GameDataService.GetData('GuildPunchKingData')

	self.time_passed = 0
end

function local_class:load_resource()
	self.on_guild_punch_king_hp_change_event_func = function(e)
		self:on_guild_punch_king_hp_change_event(e)	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.GuildPunchKingHpChangeEvent), self.on_guild_punch_king_hp_change_event_func)

	self.on_custom_stage_event_func = function(e)
		self:on_custom_stage_event(e) end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)

	local frame_rate = CS.UnityEngine.Application.targetFrameRate
	if frame_rate > 60 then
		CS.UnityEngine.Application.targetFrameRate = 60
	end

	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	unity_object_pool.GetOrCreate('FX_dead')
	unity_object_pool.GetOrCreate('messy_text')
	CS.Oak.CommonScreenplay.PreloadPvPEntry()

	local load_top_ui = yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.resource_holder,
			'ondemand/guildpunchking/ui', 'GuildPunchKingHpUI', function(prefab)
				local go = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				self.pvp_ui = go:GetComponent(typeof(CS.Oak.GuildPunchKingHpUI))
				go:SetActive(false)
			end)

	local load_speed_button = yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.resource_holder,
			'ondemand/guildpunchking/ui', 'GuildPunchKingSpeedButton', function(prefab)
				self.speed_button = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.speed_button.transform:SetParent(stage.StageGameObject.transform)
			end)

	coroutine_manager:StartCoroutine(stage.StageGameObject, CS.Oak.UI.UIGameOverTitle.Create(stage.UIRoot.gameObject.transform, nil))

	coroutine.yield(coroutine_class.wait_all(load_top_ui, load_speed_button))

	music_player:PreloadSfx('01_stage_clear_01')
end

function local_class:need_on_launch()
	return true
end

function local_class:use_late_update_frame()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.launch_routine, self))
end

function local_class:launch_routine()
	field_ui_manager:Hide()

	user_party:StopAndDisableControl()

	-- 입장 연출부터 동일한 BGM을 재생할 것이기 때문에, Notice 이벤트를 날려도 BGM이 재시작 되지 않도록 CombatState로 미리 재생시킨다.
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Combat)

	-- 콜로세움에서는 Bgm을 직접 처리하기에 배틀 후에 필드로 돌아가는 일이 없도록 세팅되어있을 수 있는 필드 Bgm을 비운다.
	music_player:RemoveStageMusicClip(CS.Oak.StageBgmState.Field)

	-- 콜로세움에서는 팡파레 및 음성 연출 자동으로하지 않도록 막음
	stage.BattleManager.PlayBattleVoiceAndFanfare = false

	-- 스테이지 스타트 시점을 앞으로 당긴다. (GlobalModifier 등이 적용 되어 업데이트 되는것이 StageStartEvent 받아서 업데이트 콜백 등록 한 이후 이므로.)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	-- 카메라 고정
	camera_util.move(vector(-0.5, 0, 4))
	camera_util.resize_to(6, 0)

	for i = 0, user_party.Count - 1 do
		local character = user_party[i]
		local marker = field:GetMarker('default_start_' .. i + 1)
		character.Position = marker.position
		character.Direction = marker.direction
	end

	self:set_crowd_anim()

	stage.FieldUIManager:RemoveUI(stage.Boss, CS.Oak.FieldUiType.CharacterStats)

	-- 페이드 인 연출
	screen_util.fade_in(0, unity_class.color.black, 'linear')
	screen_util.fade_in_circular(1, CS.Oak.Interpolations.EaseInOutSine)

	-- 페이드 인 대기
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 카운트 연출
	coroutine.yield(yield_return_func(self.start_pvp_entry))

	--- 스테이지 스타트 시점이 빨라져서 마나가 리젠되는 상태. 마나를 명시적으로 0으로 만듬
	for index = 0, user_party.Count - 1 do
		user_party[index].CharacterStatsBehaviour:ResetMana()
	end

	field_ui_manager:Show()

	user_party:ResetControllers()

	-- 콜로세움에서 실제 조작을 하진 않지만, 파티버프의 적용시점이 StageControlStartEvent 기 때문에 보내준다.
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	-- 전투 시작 시 걸리는 옵션이 걸리기 전에 StageControlStart 에서 이어지는 버프 처리 등이 끝나는걸 보장하기 위해 yield
	coroutine.yield()

	local battle = stage.BattleManager:CreateBattleInstance()
	message_system:Publish(CS.Oak.BattleStartEvent.Create(battle))

	for i = 0, user_party.Count - 1 do
		battle:AddAlly(user_party[i])
	end

	local boss = stage.Boss
	self.pvp_ui:Set(CS.Oak.User.Me.Name, user_party, boss)
	battle:AddEnemy(boss)

	message_system:Send(boss, CS.Oak.MonsterNoticeEvent.Create(boss, user_party[0], CS.Oak.MonsterNoticeLevel.Battle))
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer,
			CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer, self.data.Constants.PlayTime, nil, CS.Oak.InGameTimer.TimerType.DeltaTime)))

	-- 라바트랩은 컬리전엔터가 발생하지 않으면(안 움직이면) 데미지 입히는게 작동하지 않는다 강제로 스타트 시키자
	for _, v in pairs(user_party) do
		local fo = field:GetClosestFieldObjectByLineSegment(v.Bounds, CS.Oak.EntityGroups.Neutral, vector(0, -1, 0), false, false)
		if fo ~= nil then
			message_system:Send(fo, CS.Oak.LavaTrapStepOnEvent.Create(v))
		end
	end

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'guild_punchking_stage_start' }))
end

function local_class:late_update_frame(dt)
	self.time_passed = self.time_passed + dt

	if self.time_passed >= self.crowd_ani_change_time then
		self:set_crowd_anim()
		self.time_passed = 0
	end
end

function local_class:start_pvp_entry()
	local pool = unity_object_pool.GetOrCreate('pvp_entry')
	local entry_component = pool:Instantiate(field_ui_manager.FieldUICamera.transform.position):GetComponent(typeof(CS.Oak.UIPvPEntry))

	entry_component.transform.parent = stage.UIRoot.transform
	entry_component.transform.localPosition = vector(0, 100,0)
	entry_component.transform.localScale = unity_class.vector3.one

	local entryState = CS.Oak.UIPvPEntry.State()
	entryState.startTime = CS.GameTime.ServerTime
	coroutine.yield(entry_component:Show(entryState))
end

function local_class:word_cloud_preset(codes)
	for i = codes.Count, 1, -1 do
		local rand_i = random_util.get_random_int(0, codes.Count - 1)

		-- 말구름 각각의 y 위치를 일정 간격 이상으로 설정하는 로직
		--local cur_y_middle = -0.1 + code_interval_large * rand_i
		local cur_y_min = -0.6
		local cur_y_max = 0.85

		-- 말구름 폰트 사이즈 랜덤으로 설정
		local font_idx = math.floor((i - 1) / self.text_cloud_step_code_num + 1)
		local font_size = self.font_sizes[font_idx]
		local font_color = self.font_colors[font_idx]
		local text_speed = unity_class.random.Range(0.45, 0.55)
		local text_life_time = 10.0
		local text = codes[rand_i]
		codes:RemoveAt(rand_i)

		-- 말구름 시작 위치 y값 랜덤으로 설정
		local cur_x  = unity_class.random.Range(1.5, 2.5)
		local cur_y = unity_class.random.Range(cur_y_min, cur_y_max)

		coroutine_manager:StartCoroutine(stage.StageGameObject, CS.MessyText.SetMessyText(game_string:GetString(text),
				vector(cur_x, cur_y), 0, 9999, font_size, 0, vector(-1, 0), text_speed, text_life_time, font_color))
	end
end

function local_class:show_text_cloud(hp_step)
	local msg_rules = self.data.Constants.CrowdComment
	if msg_rules == nil then
		return
	end

	local text_step = nil

	for _, v in pairs(msg_rules) do
		if v.Round == hp_step then
			text_step = v.TextStep
		end
	end

	if text_step == nil then
		return
	end

	local shuffle_comments = CS.Oak.GuildPunchKingClient.Instance:ShuffleComment()
	local comments = shuffle_comments:GetRange(0, text_step * self.text_cloud_step_code_num);
	self:word_cloud_preset(comments)
end

function local_class:check_buff(hp_step)
	local buff_lv = self.data:GetBuffLevel(stage.MonsterId, hp_step - 1)
	if buff_lv > 0 then
		buff_manager:AddBuff(stage.Boss, CS.Oak.EquipmentSlot.None, stage.Boss, self.buff_name, buff_lv, false, false)
	end
end

function local_class:change_crowd_animation_speed(hp_step)
	local crowd_applause = self.data.Constants.CrowdApplause
	if crowd_applause == nil then
		return
	end

	local new_speed = self.curr_crowd_ani_spd
	for _, v in pairs(crowd_applause) do
		if v == hp_step then
			new_speed = new_speed + self.crowd_ani_spd_add
		end
	end

	if self.curr_crowd_ani_spd == new_speed then
		return
	end

	self.curr_crowd_ani_spd = new_speed
	self.time_passed = 0
	self:set_crowd_anim()
end

function local_class:set_crowd_anim()
	local members = stage.GuildMembers
	if members == nil then
		return
	end

	for _, v in pairs(members) do
		local rand_anim_key_idx = random_util.get_random_int(1, #self.crowd_ani_list)
		local rand_anim_key = self.crowd_ani_list[rand_anim_key_idx]

		local spd = self.curr_crowd_ani_spd
		local rand_anim_per = self.crowd_ani_rand_per
		local rand_anim_spd = unity_class.random.Range(spd - spd * rand_anim_per, spd + spd * rand_anim_per)

		local req = CS.Oak.AnimationRequest(rand_anim_key, CS.Oak.AnimationPriorities.Custom, true, rand_anim_spd)
		v:SetAnimation(req)
		v:SetEmotion('smile', true)
	end
end

function local_class:on_guild_punch_king_hp_change_event(e)
	local hp_step = e.HpStep

	-- 텍스트 탄막
	self:show_text_cloud(hp_step)
	self:change_crowd_animation_speed(hp_step)
	self:check_buff(hp_step)

	return true
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'guild_punchking_stage_end' then
		message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer))
	end
end

function local_class:dispose()

	-- FIX: 프레임 복구 - 도중에 옵션창에서 변경 된 경우 등에 대비해 설정값 읽어서 되돌림
	-- Low = 1, Mid, High
	local frame_option = CS.UnityEngine.PlayerPrefs.GetInt('FrameRateOption', 2)
	if frame_option == 1 then
		CS.UnityEngine.Application.targetFrameRate = 30
	elseif frame_option == 3 then
		CS.UnityEngine.Application.targetFrameRate = CS.Oak.UI.OptionsFrameRate.MaximumFps
	else
		CS.UnityEngine.Application.targetFrameRate = 60
	end

	self.pvp_ui:Dispose()
	self.pvp_ui = nil
	self.speed_button = nil
	self.scene = nil
	self.cs_controller = nil
	self.resource_holder = nil

	if self.on_guild_punch_king_hp_change_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.GuildPunchKingHpChangeEvent), self.on_guild_punch_king_hp_change_event_func)
		self.on_guild_punch_king_hp_change_event_func = nil
	end

	if self.on_custom_stage_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)
		self.on_custom_stage_event_func = nil
	end

	CS.MessyText.DisposeAll()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
