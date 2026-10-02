local local_class = newclass("ColosseumController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.resource_holder = CS.Foundations.ResourceHolder()

	self.end_sfx_handle_name = '01_stage_intro_jump_01'
	self.victory_sfx_handle_name = '01_crowd_arena_exclamation_03'
	self.defeated_sfx_handle_name = '01_drown_01'
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	CS.Oak.CommonScreenplay.PreloadPvPEntry()

	local load_top_ui = yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.resource_holder,
			'ui/stage/base', 'ColosseumPvpUI', function (prefab)
				local go = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				self.pvp_ui = go:GetComponent(typeof(CS.Oak.ColosseumPvpUI))
				go:SetActive(false)
			end	)

	local load_speed_button = yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.resource_holder,
			'ui/stage/base', 'colosseum_speed_button', function (prefab)
				local go = CS.UnityEngine.GameObject.Instantiate(prefab)
				go.transform:SetParent(stage.StageGameObject.transform)
			end	)

	coroutine.yield(coroutine_class.wait_all(load_top_ui, load_speed_button))

	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_event')
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.BattleEndEvent) then
		self:colosseum_end()
	elseif event_type == typeof(CS.Oak.GlobalTimerAlarmEvent) then
		if e.TimerId == CS.Oak.GlobalTimerId.AsyncBattleTimer and e.IsComplete then
			self:colosseum_end()
		end
	end

	return true
end

-- 콜로세움을 종료하는 함수
function local_class:colosseum_end()
	local my_total_map_hp = 0
	local my_total_hp = 0

	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	for i = 0, user_party.Count - 1 do
		local character = user_party[i]

		my_total_map_hp = my_total_map_hp + character.CharacterStatsBehaviour.MaxHP
		my_total_hp = my_total_hp + character.CharacterStatsBehaviour.HP

		if character.FieldObjectStatsBehaviour.IsDead == false then
			-- 종료시에 아직 살아있는 캐릭터는 행동을 멈추고 걸려있는 모든 디버프를 제거한다.
			buff_manager:CureAllDebuffs(character, character)
			CS.Oak.CharacterControllerScreenplayState.Stop(character)
		end
	end

	local other_total_map_hp = 0
	local other_total_hp = 0

	for i = 0, other_party.Count - 1 do
		local character = other_party[i]

		other_total_map_hp = other_total_map_hp + character.CharacterStatsBehaviour.MaxHP
		other_total_hp = other_total_hp + character.CharacterStatsBehaviour.HP

		if character.FieldObjectStatsBehaviour.IsDead == false then
			-- 종료시에 아직 살아있는 캐릭터는 행동을 멈추고 걸려있는 모든 디버프를 제거한다.
			buff_manager:CureAllDebuffs(character, character)
			CS.Oak.CharacterControllerScreenplayState.Stop(character)
		end
	end

	message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer))

	local result

	if my_total_hp / my_total_map_hp > other_total_hp / other_total_map_hp then
		-- 내가 남은 hp 비율이 높으면 나의 승리
		result = CS.Oak.CoopResult.Victory
	else
		-- 아니라면 나의 패배(적의 승리)
		result = CS.Oak.CoopResult.Defeated
	end

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

	music_player:PlaySfxOneShot(self.end_sfx_handle_name)

	local victory_sfx
	local victory_party

	-- 이겼을때는 관중 환호 사운드를 재생한다.
	if result == CS.Oak.CoopResult.Victory then
		local sfx_info = CS.Oak.SfxInfo()
		sfx_info.sfxName = self.victory_sfx_handle_name
		sfx_info.loop = false
		sfx_info.typePriority = CS.Oak.SfxTypePriority.UI

		victory_sfx = music_player:PlaySfx(sfx_info)

		victory_party = user_party
	else
		victory_party = other_party
	end

	for i = 0, user_party.Count - 1 do
		local character = user_party[i]

		if character.FieldObjectStatsBehaviour.IsDead == false then
			character_util.set_direction(character, 'right')

			if result == CS.Oak.CoopResult.Victory then
				character_util.set_anim(character, {name = 'victory_get', loop = false})
			else
				character_util.set_anim(character, {name = 'seat', loop = false})
				character_util.set_emotion(character, {name = "tired", loop = false})
			end
		end
	end

	for i = 0, other_party.Count - 1 do
		local character = other_party[i]

		if character.FieldObjectStatsBehaviour.IsDead == false then
			character_util.set_direction(character, 'left')

			if result == CS.Oak.CoopResult.Defeated then
				character_util.set_anim(character, {name = 'victory_get', loop = false})
			else
				character_util.set_anim(character, {name = 'seat', loop = false})
				character_util.set_emotion(character, {name = "tired", loop = false})
			end
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	if result == CS.Oak.CoopResult.Defeated then
		music_player:PlaySfxOneShot(self.defeated_sfx_handle_name)
	end

	for i = 0, victory_party.Count - 1 do
		local character = victory_party[i]

		if character.FieldObjectStatsBehaviour.IsDead == false then
			character_util.set_anim(character, {name = 'victory_extra', loop = true})
		end
	end

	--for i = 0, other_party.Count - 1 do
	--	local character = other_party[i]
	--
	--	if character.FieldObjectStatsBehaviour.IsDead == false then
	--		 character_util.set_anim(character, {name = 'victory_extra', loop = true})
	--	end
	--end

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 관중 환호 사운드가 재생중이라면 1초에 걸쳐서 페이드 아웃
	if victory_sfx ~= nil then
		victory_sfx:FadeOut(1)
	end

	self.pvp_ui.gameObject:SetActive(false)

	CS.Oak.ColosseumClient.Instance:SendColosseumEnd(result, user_party, other_party)
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.launch_routine, self))
end

function local_class:launch_routine()
	local opponent = CS.Oak.ColosseumClient.Instance.CurrentOpponent

	local my_formation = CS.Oak.UserColosseumExtension.GetFormation(CS.Oak.UserColosseum.Me).Positions
	local other_formation = opponent.Formation.Positions

	for i = 0, user_party.Count - 1 do
		local character = user_party[i]
		local pos_idx = my_formation[i]

		local marker = field:GetMarker('my_' .. pos_idx)

		character.Position = marker.position
		character.Direction = marker.direction
	end

	for i = 0, other_party.Count - 1 do
		local character = other_party[i]
		local pos_idx = other_formation[i]

		local marker = field:GetMarker('other_' .. pos_idx)

		character.Position = marker.position
		character.Direction = marker.direction

		character.SpineController:AddColor(character.Name, unity_color({0.6, 0.6, 1, 1}), 0.7, 0)

		--- 소환수 매니저
		local manger = stage.SummonableManager

		--- 소환수 리스트를 받아옴
		local summonable_list = manger:GetSummonables(character)

		--- 소환수 리스트가 있다면
		if summonable_list then
			for _, value in pairs(summonable_list) do
				local entity = CS.Oak.LuaBattleExtensions.GetCharacterByEntityId(value)

				entity.SpineController:AddColor(entity.Name, unity_color({0.6, 0.6, 1, 1}), 0.7, 0)
			end
		end
	end

    if CS.Oak.ColosseumClient.IsAnonymousRanker(opponent) then
        local leader = CS.GameStrings.Instance:GetString(other_party.Leader.CharacterInfo.CharacterSpec.CharacterName)
        self.pvp_ui:Set(CS.Oak.User.Me.Name, user_party, leader, other_party)
    else
        self.pvp_ui:Set(CS.Oak.User.Me.Name, user_party, opponent.User.Name, other_party)
    end

	field_ui_manager:Hide()

	user_party:StopAndDisableControl()
	other_party:StopAndDisableControl()

	camera_util.move(vector(0.5, 0, 1), 0)

	if CS.Oak.AspectRatio.Type == CS.Oak.AspectRatioType.Narrow then
		camera_util.resize_to(7, 0)
	else
		camera_util.resize_to(5.5, 0)
	end

	-- 입장 연출부터 동일한 BGM을 재생할 것이기 때문에, Notice 이벤트를 날려도 BGM이 재시작 되지 않도록 CombatState로 미리 재생시킨다.
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Combat)

	-- 콜로세움에서는 Bgm을 직접 처리하기에 배틀 후에 필드로 돌아가는 일이 없도록 세팅되어있을 수 있는 필드 Bgm을 비운다.
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

	-- 카운트 연출
	coroutine.yield(yield_return_func(self.start_pvp_entry))

	--- 스테이지 스타트 시점이 빨라져서 마나가 리젠되는 상태. 마나를 명시적으로 0으로 만듬
	for index = 0, user_party.Count - 1 do
		user_party[index].CharacterStatsBehaviour:ResetMana()
	end

	--- 스테이지 스타트 시점이 빨라져서 마나가 리젠되는 상태. 마나를 명시적으로 0으로 만듬
	for index = 0, other_party.Count - 1 do
		other_party[index].CharacterStatsBehaviour:ResetMana()
	end

	field_ui_manager:Show()

	user_party:ResetControllers()
	other_party:ResetControllers()

	-- 콜로세움에서 실제 조작을 하진 않지만, 파티버프의 적용시점이 StageControlStartEvent 기 때문에 보내준다.
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	-- 전투 시작 시 걸리는 옵션이 걸리기 전에 StageControlStart 에서 이어지는 버프 처리 등이 끝나는걸 보장하기 위해 yield
	coroutine.yield()

	local battle = stage.BattleManager:CreateBattleInstance()
	message_system:Publish(CS.Oak.BattleStartEvent.Create(battle))

	for i = 0, user_party.Count - 1 do
		battle:AddAlly(user_party[i])
	end

	for i = 0, other_party.Count - 1 do
		battle:AddEnemy(other_party[i])
	end

	-- PvP에서 플레이어가 배틀 가능(아군 적군 셋팅 완료) 하다고 보는 시점에 이벤트
	message_system:PublishSync(CS.Oak.PvPControlStartEvent.Create())

	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer,
			CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.AsyncBattleTimer, CS.Oak.ColosseumConstants.ColosseumPlaySec, null, CS.Oak.InGameTimer.TimerType.DeltaTime)))
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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))

	self.pvp_ui:Dispose()
	self.scene = nil
	self.cs_controller = nil
	self.resource_holder = nil
	self.pvp_ui = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
