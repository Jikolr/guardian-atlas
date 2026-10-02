local local_class = newclass("KamazonLandController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.resource_holder = CS.Foundations.ResourceHolder()

	self.victory_sfx_handle_name = '01_stage_intro_jump_01'
	self.crowd_cheering_sfx_handle_name = '01_crowd_arena_exclamation_03'
	self.defeated_sfx_handle_name = '01_drown_01'
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	unity_object_pool.GetOrCreate('FX_dead')
	CS.Oak.CommonScreenplay.PreloadPvPEntry()

	local load_top_ui = yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.resource_holder,
			'ui/stage/base', 'ColosseumPvpUI', function(prefab)
				local go = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				self.pvp_ui = go:GetComponent(typeof(CS.Oak.ColosseumPvpUI))
				go:SetActive(false)
			end)

	local load_speed_button = yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.resource_holder,
			'ui/stage/base', 'colosseum_speed_button', function(prefab)
				self.speed_button = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.speed_button.transform:SetParent(stage.StageGameObject.transform)
			end)

	coroutine.yield(coroutine_class.wait_all(load_top_ui, load_speed_button))

	music_player:PreloadSfx('01_stage_clear_01')

	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_event')
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.BattleEndEvent) then
		self:battle_end(false)
	elseif event_type == typeof(CS.Oak.GlobalTimerAlarmEvent) then
		if e.TimerId == CS.Oak.GlobalTimerId.AsyncBattleTimer and e.IsComplete then
			self:battle_end(true)
		end
	end

	return true
end

-- 고대쇼핑몰 전투를 종료하는 함수
function local_class:battle_end(is_time_over)
	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	for i = 0, user_party.Count - 1 do
		local character = user_party[i]

		if character.FieldObjectStatsBehaviour.IsDead == false then
			-- 종료시에 아직 살아있는 캐릭터는 행동을 멈추고 걸려있는 모든 디버프를 제거한다.
			buff_manager:CureAllDebuffs(character, character)
			CS.Oak.CharacterControllerScreenplayState.Stop(character)
			-- 게임이 종료되었지만 남아있는 적군의 불렛으로 인한 데미지가 들어 올수 있어 무적으로 만듦
			character.FieldObjectStatsBehaviour:AddCharacterStatsOption(CS.Oak.CharacterStatsOptions.Invincible)
			-- 다시 맞더라도 전투 걸리지 않게 함
			character.FieldObjectController.DontFight = true
		end
	end

	local all_monster_dead = true

	local monsters = CS.Oak.KamazonLandClient.Instance.Monsters

	for i = 0, monsters.Count - 1 do
		local monster = monsters[i]

		if monster.FieldObjectStatsBehaviour.IsDead == false then
			-- 더미는 판정에서 제외
			if not string.match(monster.Name, 'dummy_monster_') then
				all_monster_dead = false
			end

			-- 종료시에 아직 살아있는 캐릭터는 행동을 멈추고 걸려있는 모든 디버프를 제거한다.
			buff_manager:CureAllDebuffs(monster, monster)
			CS.Oak.CharacterControllerScreenplayState.Stop(monster)
			-- 게임이 종료되었지만 남아있는 적군의 불렛으로 인한 데미지가 들어 올수 있어 무적으로 만듦
			monster.FieldObjectStatsBehaviour:AddCharacterStatsOption(CS.Oak.CharacterStatsOptions.Invincible)
			-- 다시 맞더라도 전투 걸리지 않게 함
			monster.FieldObjectController.DontFight = true
		end
	end

	local result

	if all_monster_dead == true then
		-- 일단 적을 모두 죽였으면 승리
		result = CS.Oak.CoopResult.Victory
	elseif is_time_over == true then
		-- 플레이타임 시간초과
		result = CS.Oak.CoopResult.Timeout
	else
		-- 패배
		result = CS.Oak.CoopResult.Defeated
	end

	message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.send_result_routine, self, result))
end

function local_class:send_result_routine(result)
	-- 이미 결과를 보냈다면 리턴
	if self.sent_result ~= nil then
		return
	end

	self.sent_result = true

	-- 배속이 걸려있었다면 해제
	CS.GlobalTimeManager.Instance:Unmod('colosseum_speed')

	coroutine.yield(coroutine_class.wait_for_sec(1))

	local victory_sfx

	-- 이겼을때는 관중 환호 사운드를 재생한다.
	if result == CS.Oak.CoopResult.Victory then

		music_player:PlaySfxOneShot(self.victory_sfx_handle_name)

		local sfx_info = CS.Oak.SfxInfo()
		sfx_info.sfxName = self.crowd_cheering_sfx_handle_name
		sfx_info.loop = false
		sfx_info.typePriority = CS.Oak.SfxTypePriority.UI

		victory_sfx = music_player:PlaySfx(sfx_info)
	end

	if result == CS.Oak.CoopResult.Victory then
		for i = 0, user_party.Count - 1 do
			local character = user_party[i]

			if character.FieldObjectStatsBehaviour.IsDead == false then
				character_util.set_direction(character, 'right')
				character_util.set_anim(character, { name = 'victory_get', loop = false })
			end
		end
	else
		for i = 0, user_party.Count - 1 do
			local character = user_party[i]

			if character.FieldObjectStatsBehaviour.IsDead == false then
				character_util.set_direction(character, 'right')
				character_util.set_anim(character, { name = 'seat', loop = false })
				character_util.set_emotion(character, { name = 'tired', loop = true })
			end
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	if result ~= CS.Oak.CoopResult.Victory then
		music_player:PlaySfxOneShot(self.defeated_sfx_handle_name)
		music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted, 2)
	end

	for i = 0, user_party.Count - 1 do

		local character = user_party[i]

		if character.CharacterInfo ~= nil then
			local id = character.CharacterInfo.Id
			if id > 0 then
				local hpRatio = character.FieldObjectStatsBehaviour.HpRatio
				CS.Oak.KamazonLandClient.Instance:UpdateHpMap(id, hpRatio, result)
			end
		end

		if result == CS.Oak.CoopResult.Victory then
			if character.FieldObjectStatsBehaviour.IsDead == false then
				character_util.set_anim(character, { name = 'victory_extra', loop = true })
			end
		end
	end

	-- 타임아웃일때 살아남은 영웅들 hp 0으로 줄어들게 함
	if result == CS.Oak.CoopResult.Timeout then

		local time_over_ani_time = 1.0

		self.pvp_ui:KamazonLandTimeOver(time_over_ani_time)

		for i = 0, user_party.Count - 1 do

			local character = user_party[i]

			if character.FieldObjectStatsBehaviour.IsDead == false then
				local uiStats = field_ui_manager:GetUIByKey(CS.Oak.FieldUiType.CharacterStats, character)
				uiStats.HPBar:SetValue(0, time_over_ani_time)
				character_util.set_anim(character, { name = 'frustration', loop = false })
			end
		end

		coroutine.yield(coroutine_class.wait_for_sec(time_over_ani_time))
	end

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 관중 환호 사운드가 재생중이라면 1초에 걸쳐서 페이드 아웃
	if victory_sfx ~= nil then
		victory_sfx:FadeOut(1)
	end

	self.speed_button:SetActive(false)
	self.pvp_ui.gameObject:SetActive(false)

	if result == CS.Oak.CoopResult.Victory then
		local stage_clear_ui_finished = false

		stage.FieldUIQuestComplete:PlayStageClear(function(prefab)
			stage_clear_ui_finished = true
		end)

		while stage_clear_ui_finished == false do
			coroutine.yield(nil)
		end

		music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted, 2)

		local loading_mode_enum = screen_util.get_loading_mode(loading_mode)
		local ip = screen_util.get_interpolations(interpolations)

		local routine = wait_all({
			music_player:PlayAndWaitUntilSfxFinish('01_stage_clear_01'),
			CS.Oak.CircularScreenTransition.Instance:FadeOutAsync(0.6, ip, loading_mode_enum)
		})

		coroutine.yield(routine)

		CS.Oak.KamazonLandClient.Instance:EndStage(result, false)

	else
		local victory_or_defeat_state = CS.Oak.UI.VictoryOrDefeatState()
		victory_or_defeat_state.CoopResult = result
		victory_or_defeat_state.PlayTime = CS.System.TimeSpan.FromSeconds(CS.Oak.PartyDamageRecorder.Instance.TotalBattleTime)
		victory_or_defeat_state.DirectExit = true
		victory_or_defeat_state.StageType = stage.Spec.StageType

		ui_scene_manager:PushOverlay(CS.Oak.UI.VictoryOrDefeat.Instance, victory_or_defeat_state)

		coroutine.yield(coroutine_class.wait_for_sec(3))

		screen_util.fade_out_circular_async(0.6, 'linear', 'image')
	end

end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.launch_routine, self))
end

function local_class:launch_routine()
	local available_positions = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }
	local my_formation = CS.Oak.UserKamazonLand.Me.Formation.Positions

	local dummies = {}
	local other_side = {}

	-- 실제 파티원과 더미 구분
	local party_info = CS.Oak.KamazonLandClient.Instance.PartyInfo
	local party_limit = CS.Oak.UserKamazonLandExtensions.GetPartyLimitCount(CS.Oak.UserKamazonLand.Me)
	local party_count = party_info.Count
	if party_limit > 0 then
		party_count = unity_class.mathf.Min(party_count, party_limit)
	end

	for i = 0, user_party.Count - 1 do
		local character = user_party[i]

		local pos_idx = 0
		if i < my_formation.Count and i < party_count then
			-- 파티원 지정된 위치에 배치
			pos_idx = my_formation[i]

			for j = 1, #available_positions do
				if available_positions[j] == pos_idx then
					table.remove(available_positions, j)
					break
				end
			end
		else
			-- 더미는 랜덤위치에 배치
			local r = random_util.get_values_in_array(available_positions)
			pos_idx = r[1]

			if CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(character.FieldObjectStatsBehaviour, typeof(CS.Oak.KamazonSemiSummonableCharacterStatsBehaviour)) then
				-- 반대쪽에 넣는 것
				if character.FieldObjectStatsBehaviour.OptionSpec.SummonOtherSide == true then
					table.insert(other_side, character)
				end

				-- TODO: FIXME: 소환수 옵션 임시 처리
				if character.CharacterInfo ~= nil then
					local character_spec = character.CharacterInfo.CharacterSpec
					if character_spec ~= nil then
						if character_spec.Options.Count > 0 then
							for option_id, v in pairs(character_spec.Options) do
								local option_level = v:GetDecrypted()
								local spec_option = CS.Oak.OptionManager.CreateOption(option_id, option_level)
								character.CharacterInfo.CharacterOptions:Add(spec_option)
							end
							coroutine.yield(character:UpdateAndBattleAndStageOptions())
						end
					end
				end
			end
		end

		local marker = field:GetMarker('my_' .. pos_idx)

		character.Position = marker.position
		character.Direction = marker.direction

		-- 더미는 전투 시작 시 나타나도록 함.
		if string.match(character.Name, 'dummy_member_') then
			character_util.set_active_state(character, 'infield')
			table.insert(dummies, character)
		end
	end

	local monsters = CS.Oak.KamazonLandClient.Instance.Monsters

	local monster_party = CS.Oak.Party.Create('monster', CS.Oak.PartyOwnerFlag.Other)
	CS.Oak.PartyManager.Instance:AddParty(monster_party)

	for i = 0, monsters.Count - 1 do
		local monster = monsters[i]

		monster_party:Add(monster)
		monsters[i].SpineController:AddColor(monster.Name, unity_color({ 0.6, 0.6, 1, 1 }), 0.7, 0)

		-- 더미는 전투 시작 시 나타나도록 함.
		if string.match(monster.Name, 'dummy_monster_') then
			character_util.set_active_state(monster, 'infield')
			table.insert(dummies, monster)
		end
	end

	-- 몬스터 쪽에 소환하는 소환수 위치 설정
	local node = CS.Oak.KamazonLandClient.Instance.CurrentPlayNode
	local battle_monsters = node.BattleMonsters
	local other_positions = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }

	for i = 0, battle_monsters.Count - 1 do
		for j = 1, #other_positions do
			if other_positions[j] == battle_monsters[i].Position then
				table.remove(other_positions, j)
				break
			end
		end
	end

	for i = 1, #other_side do
		local other_idx

		if #other_positions > 0 then
			local temp = random_util.get_values_in_array(other_positions)
			other_idx = temp[1]
		else
			other_idx = random_util.get_random_int(1, 20)
		end

		local marker = field:GetMarker('other_' .. other_idx)

		other_side[i].Position = marker.position
		other_side[i].Direction = CS.Oak.Direction.Right
	end
	other_side = nil

	self.pvp_ui:SetForKamazonLand(user_party, monster_party)

	field_ui_manager:Hide()

	user_party:StopAndDisableControl()

	camera_util.move(vector(0.5, 0, 1), 0)

	if CS.Oak.AspectRatio.Type == CS.Oak.AspectRatioType.Narrow then
		camera_util.resize_to(7, 0)
	else
		camera_util.resize_to(5.5, 0)
	end

	-- 필드 음악을 먼저 켜준다.
	music_player:RemoveStageMusicClip(CS.Oak.StageBgmState.Field)

	-- 콜로세움에서는 팡파레 및 음성 연출 자동으로하지 않도록 막음
	stage.BattleManager.PlayBattleVoiceAndFanfare = false

	-- 페이드 인 연출
	screen_util.fade_in(0, unity_class.color.black, 'linear')
	screen_util.fade_in_circular(1, CS.Oak.Interpolations.EaseInOutSine)

	-- 스테이지 스타트 시점을 앞으로 당긴다. (GlobalModifier 등이 적용 되어 업데이트 되는것이 StageStartEvent 받아서 업데이트 콜백 등록 한 이후 이므로.)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	-- fade in 대기
	coroutine.yield(coroutine_class.wait_for_sec(1))

	self:start_pvp_entry()

	-- 꺼뒀던 더미 캐릭터들 켜기
	local dummy_fx_pool = unity_object_pool.GetOrCreate('FX_dead')
	for i = 1, #dummies do
		character_util.set_active_state(dummies[i], 'enabled')
		dummy_fx_pool:Instantiate(dummies[i].Position, unity_class.quaternion.identity, dummies[i].Transform)
	end
	dummies = nil

	-- 전투 시작시 전투 음악을 켜준다.
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Combat)

	field_ui_manager:Show()

	-- 스테이지 스타트 시점이 빨라져서 마나가 리젠되는 상태. 마나를 명시적으로 0으로 만듬
	for i = 0, user_party.Count - 1 do
		user_party[i].CharacterStatsBehaviour:ResetMana()
	end

	for i = 0, monsters.Count - 1 do
		monsters[i].CharacterStatsBehaviour:ResetMana()
	end

	user_party:ResetControllers()

	-- 실제 조작을 하진 않지만, 파티버프의 적용시점이 StageControlStartEvent 기 때문에 보내준다.
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	-- 전투 시작 시 걸리는 옵션이 걸리기 전에 StageControlStart 에서 이어지는 버프 처리 등이 끝나는걸 보장하기 위해 yield
	coroutine.yield()

	local battle = stage.BattleManager:CreateBattleInstance()
	message_system:Publish(CS.Oak.BattleStartEvent.Create(battle))

	for i = 0, user_party.Count - 1 do
		battle:AddAlly(user_party[i])
	end

	for i = 0, monsters.Count - 1 do
		battle:AddEnemy(monsters[i])
		message_system:Send(monsters[i], CS.Oak.MonsterNoticeEvent.Create(monsters[i], user_party[0], CS.Oak.MonsterNoticeLevel.Battle))
	end

	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer,
			CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer, CS.Oak.Tower1000Constants.Tower1000PlaySec, null, CS.Oak.InGameTimer.TimerType.DeltaTime)))

	if monsters.Count == 0 then
		-- 적이 하나도 없으면 바로 승리 처리 해준다.
		message_system:Publish(CS.Oak.BattleEndEvent.Create(true, battle))
	end
end

function local_class:start_pvp_entry()
	local pool = unity_object_pool.GetOrCreate('pvp_entry')
	local entry_component = pool:Instantiate(field_ui_manager.FieldUICamera.transform.position):GetComponent(typeof(CS.Oak.UIPvPEntry))

	entry_component.transform.parent = stage.UIRoot.transform
	entry_component.transform.localPosition = vector(0, 100,0)
	entry_component.transform.localScale = unity_class.vector3.one

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_pvp_entry_routine, self, entry_component))
end

function local_class:start_pvp_entry_routine(entry_component)
	coroutine.yield(entry_component:ShowStart())
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))

	self.pvp_ui:Dispose()
	self.pvp_ui = nil
	self.speed_button = nil
	self.scene = nil
	self.cs_controller = nil
	self.resource_holder = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
