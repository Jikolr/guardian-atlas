local local_class = newclass("GuildArcadeMiniGameController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 미니게임
	self.mini_game = nil

	-- 게임 이름
	self.game_name = nil

	self.game_constants_key = nil

	-- 점수판 ui용
	self.res_holder = nil
	self.ui_prefab = nil
	self.arcade_ui = nil

	-- 타이틀 ui용
	self.title_prefab = nil

	self.camera_effect_prefab = nil

	-- game over ui
	self.game_over_ui_prefab = nil
	self.game_over_ui = nil

	-- 일시 정지 처리용
	self.pause_check_list = nil

	-- 최종 점수
	self.last_score = 0

	-- 스테이지 정보
	self.stage_info = {
		{ stage_name = 'guild_arcade_basket_game', game_name = 'BasketGame', game_constants_key = 'arcade_basket_game' },
		{ stage_name = 'guild_arcade_snake_game', game_name = 'SnakeGame', game_constants_key = 'arcade_snake_game' },
		{ stage_name = 'guild_arcade_energyball_shooting', game_name = 'EnergyballShootingMiniGame', game_constants_key = 'arcade_shooting_game' },
		{ stage_name = 'guild_arcade_racing_game', game_name = 'RacingGame', game_constants_key = 'arcade_racing_game' },
		{ stage_name = 'guild_arcade_climbing_game', game_name = 'ClimbingGame', game_constants_key = 'arcade_climbing_game' },
		{ stage_name = 'guild_arcade_tiger_jump_game', game_name = 'TigerJumpGame', game_constants_key = 'arcade_tiger_jump_game' },
		{ stage_name = 'guild_arcade_tetris_game', game_name = 'TetrisGame', game_constants_key = 'arcade_tetris_game' },
	}
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- Subscribe
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.MiniGameScoreChangeEvent), 'on_mini_game_score_change_event')
	message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_mini_game_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseStartEvent), 'on_pause_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseEndEvent), 'on_pause_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.UI.UiSceneChangeEvent), 'on_ui_scene_change_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.res_holder = CS.Foundations.ResourceHolder()

	-- 점수판 ui 프리팹 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/arcade/ui', 'GuildArcadeButtonUI', function(prefab)
				self.ui_prefab = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				self.arcade_ui = self.ui_prefab.transform:GetComponent(typeof(CS.Oak.UI.GuildArcadeButtonUI))
			end)

	-- 초기 점수 0점 갱신
	self.arcade_ui:SetScore(0)

	-- 타이틀 출력 ui 프리팹 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/arcade/ui', 'ReadyStartTitle', function(prefab)
				self.title_prefab = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
			end)

	-- 카메라 이펙트 로드
	-- 현재 오브젝트 풀 시트가 저장이 안되서 임시로 리소스 홀더로 함, 수정 필요
		yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
				self.res_holder, 'ondemand/arcade/effects', 'fx_guildarcade_camera_effect', function(prefab)
					self.camera_effect_prefab = CS.NGUITools.AddChild(stage_camera.Transform, prefab)
					self.camera_effect_prefab.transform.position = vector(999,0,999)

					if not CS.Oak.GuildArcadeStage.crtEffectEnabled then
						self.camera_effect_prefab.gameObject:SetActive(false)
					end
				end)
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	-- 미니 게임 종료
	if self.mini_game then
		mini_game_manager:DisposeMiniGame(self.game_name)
		self.mini_game = nil
	end

	-- Unsubscribe
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameScoreChangeEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.UI.UiSceneChangeEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.pause_check_list = nil

	-- 프리팹 제거
	self.arcade_ui = nil
	self.game_over_ui = nil

	if not is_unity_null(self.ui_prefab) then
		CS.UnityEngine.Object.Destroy(self.ui_prefab)
	end
	self.ui_prefab = nil

	if not is_unity_null(self.title_prefab) then
		CS.UnityEngine.Object.Destroy(self.title_prefab)
	end
	self.title_prefab = nil

	if not is_unity_null(self.camera_effect_prefab) then
		CS.UnityEngine.Object.Destroy(self.camera_effect_prefab)
	end
	self.camera_effect_prefab = nil

	if not is_unity_null(self.game_over_ui_prefab) then
		CS.UnityEngine.Object.Destroy(self.game_over_ui_prefab)
	end
	self.game_over_ui_prefab = nil

	-- 리소스 홀더 정리
	if self.res_holder ~= nil then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mini_game_start, self))
	return true
end

function local_class:on_mini_game_score_change_event(e)
	if e.Name == self.game_name then
		self.arcade_ui:SetScore(e.Score)
		self.last_score = e.Score
		return true
	end

	return false
end

function local_class:on_mini_game_end_event(e)
	if e.Name == self.game_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mini_game_end, self, e.Name, e.Success))
		return true
	end
	return false
end

function local_class:on_pause_start_event(e)
	self:pause_start()
	return true
end

function local_class:on_pause_end_event(e)
	self:pause_end()
	return true
end

function local_class:on_ui_scene_change_event(e)
	if not lua_helper.reference_equals(ui_scene_manager.CurrentScene, CS.Oak.UI.GuildArcadeMainScene.Instance) then
		return true;
	end

	self.camera_effect_prefab.gameObject:SetActive(false)

	return false
end

function local_class:on_custom_stage_event(e)
	local param = e:GetParamAt(0)

	if param ~= nil and param == 'crt_effect_on' then
		self.camera_effect_prefab.gameObject:SetActive(true)

	elseif param ~= nil and param == 'crt_effect_off' then
		self.camera_effect_prefab.gameObject:SetActive(false)
	end

	return false
end
--endregion

--- 미니 게임 시작 함수
function local_class:mini_game_start()
	-- 미니 게임 로드
	for i = 1, #self.stage_info do
		if stage.Name == self.stage_info[i].stage_name then
			self.game_name = self.stage_info[i].game_name
			self.game_constants_key = self.stage_info[i].game_constants_key

			if self.mini_game == nil then
				self.mini_game = mini_game_manager:GetOrCreate(self.game_name)
			end

			local is_mini_game_load_complete = false
			mini_game_manager:LoadResource(self.game_name, self.game_constants_key, function()
				is_mini_game_load_complete = true
			end)

			while not is_mini_game_load_complete do
				coroutine.yield()
			end

			break
		end
	end

	screen_util.fade_in_circular_async(0, 'linear')

	-- ready start 음 예외 처리
	local ready_sfx = '01_arcade_ready_01'
	local start_sfx = '01_arcade_start_01'

	if stage.Name == 'guild_arcade_tetris_game' then
		ready_sfx = '01_arcade_expedition_01'
		start_sfx = nil
	end
	-- ready, start 타이틀 출력
	wait_for_sec(0.5)

	self.title_prefab.transform.localPosition = vector(0, 150,0)
	self.title_prefab.transform.localScale = unity_class.vector3.one * 8.5

	local ready_title = self.title_prefab.transform:Find('Ready')
	local start_title = self.title_prefab.transform:Find('Start')
	local start_sprite = start_title:GetComponent(typeof(CS.UISprite))

	if ready_sfx ~= nil then
		music_player_util.play_sfx_one_shot(ready_sfx)
	end
	ready_title.gameObject:SetActive(true)
	wait_for_sec(1)

	ready_title.gameObject:SetActive(false)
	wait_for_sec(0.2)

	if start_sfx ~= nil then
		music_player_util.play_sfx_one_shot(start_sfx)
	end
	start_title.gameObject:SetActive(true)
	-- 깜빡임 연출
	local blink_cnt = 1
	local max_cnt = 6
	while blink_cnt <= max_cnt do
		start_sprite.color = unity_class.color(1, 1, 1, blink_cnt % 2)
		blink_cnt = blink_cnt + 1
		wait_for_sec(0.25)
	end

	start_title.gameObject:SetActive(false)
	wait_for_sec(0.5)

	mini_game_manager:StartMiniGame(self.game_name)
end

--- 미니 게임 종료 함수
function local_class:mini_game_end(game_name, is_success)
	wait_for_sec(2)

	-- 클리어, 게임오버를 가르는 게임인지 확인
	local is_check_clear = false
	if game_name == 'RacingGame' then
		is_check_clear = true
	end

	-- 게임 오버 UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/arcade/ui', 'GuildArcadeGameOverUI', function(prefab)
				self.game_over_ui_prefab = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				self.game_over_ui = self.game_over_ui_prefab.transform:GetComponent(typeof(CS.Oak.UI.GuildArcadeGameOverUI))
			end)

	if is_check_clear == true and is_success == true then
		self.game_over_ui:SetUI(self.last_score, true)
	else
		self.game_over_ui:SetUI(self.last_score)
	end

end

--- 일시 정지 시작 처리 함수
function local_class:pause_start()
	self.title_prefab.gameObject:SetActive(false)
end

--- 일시 정지 종료 처리 함수
function local_class:pause_end()
	self.title_prefab.gameObject:SetActive(true)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
