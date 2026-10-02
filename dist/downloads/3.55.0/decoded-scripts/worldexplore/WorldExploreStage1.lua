--- 월드 탐험 게임 컨트롤러
local local_class = newclass("WorldExploreStage1")

function local_class:init(cs_controller, scene)
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.WorldExploreStageEvent), 'on_event')

	self.constants = require('worldexplore/WorldExploreConstants')

	self.num_woods = 40
	self.num_stones = 40
end



function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.WorldExploreStageEvent), 'on_event')
	self.world_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageLoadedEvent) then

	elseif event_type == typeof(CS.Oak.StageStartEvent) then

	elseif event_type == typeof(CS.Oak.WorldExploreStageEvent) then
		if e.Type == self.constants.event_types.start_stage_event_load then
			self:load_npc()
		elseif e.Type == self.constants.event_types.npc_interaction_start then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.npc_interaction, self, e.Unit1, e.Unit2))
		elseif e.Type == self.constants.event_types.stage_launch_ready then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_event, self))
		end
	end
	return false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	unity_object_pool.GetOrCreate("FX_Event_InvaderBeam")
	CS.Oak.CommonScreenplay.PreloadItemGetEvent()
	coroutine.yield(music_player:PreloadMusic('ondemand/worldexplore/audio:bgm_worldexplore_lobby'))
	coroutine.yield(music_player:PreloadMusic('ondemand/worldexplore/audio:bgm_worldexplore_reinforce'))
end

function local_class:load_npc()
	local has, world_controller = stage.WorldStates:TryGetValue("controller")
	self.world_controller = world_controller
	self.world_controller:add_npc("ailie", "ailie", CS.UnityEngine.Vector2Int(2, 0), CS.Oak.Direction.Left, "none", false, "dungeon_ailie_3")
	self.world_controller:finish_stage_event_load()
end

function local_class:npc_interaction(hero_unit, npc_unit)
	self.world_controller:finish_npc_interaction()
end

function local_class:start_event()
	-- 적들 모두 숨긴다.
	local units = stage.Units
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy then
			self.world_controller:hide_unit(units[i])
		end
	end

	local offset, bd = self.world_controller:get_npc_talk_params(false)
	local c = self.world_controller.npc_units[1]

	coroutine.yield(self.world_controller:intro_zoom_and_fade_in(nil))
	music_player_util.play_stage_music({ name = 'ondemand/worldexplore/audio:bgm_worldexplore_lobby', state = 'event', mix = 0 })

	wait_for_sec(0.25)

	character_util.set_emotion(c, { name = "smile", loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_1", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_anim(c, { name = "cast" })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_2", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_anim(c, { name = "bomb_idle" })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_3", skip = true, offset = offset, bubble_direction = bd })
	music_player:PlaySfxOneShot("03_dialogue_evil_01")
	character_util.set_emotion(c, { name = "doyagao", loop = false })
	character_util.set_anim(c, { name = "cast" })
	c.Direction = CS.Oak.Direction.Right
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_3_2", skip = true, offset = offset, bubble_direction = bd })
	c.Direction = CS.Oak.Direction.Left
	character_util.set_anim(c, { name = "bomb_idle" })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_4", skip = true, offset = offset, bubble_direction = bd })

	music_player:PlaySfxOneShot("01_throw_01")
	character_util.set_anim(c, { name = "attack", loop = false, next_anim = "idle" })

	coroutine.yield(self:drop_disc_and_show(user_party[0].Position + vector(2, 0, 0), user_party[0].Position + vector(1, 0, 0)))

	character_util.set_emotion(c, { name = "smile", loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_5", skip = true, offset = offset, bubble_direction = bd })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_5_2", skip = true, offset = offset, bubble_direction = bd })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_6", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_emotion(c, { name = "tired", loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_7", skip = true, offset = offset, bubble_direction = bd })

	wait_for_sec(0.25)
	music_player_util.play_stage_music({ name = 'ondemand/worldexplore/audio:bgm_worldexplore_reinforce', state = 'event', mix = 0 })

	c.Direction = CS.Oak.Direction.Right
	coroutine.yield(self.world_controller:focus_camera_to(vector(6, 0, 0)))

	wait_for_sec(0.5)

	local boss_unit = nil
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy then
			if units[i].Index == self.world_controller.boss_leader_index then
				boss_unit = units[i]
			else
				self.world_controller:reinforce_unit(units[i])
				wait_for_sec(0.2)
			end
		end
	end

	wait_for_sec(0.5)

	coroutine.yield(self.world_controller:focus_camera_to(vector(13, 0, 0)))
	self.world_controller:reinforce_unit(boss_unit)

	wait_for_sec(1.5)

	coroutine.yield(self.world_controller:focus_camera_to(user_party[0].Position))

	c.Direction = CS.Oak.Direction.Left
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_8", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_emotion(c, { name = "smile", loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_9", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_anim(c, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_10", skip = true, offset = offset, bubble_direction = bd })
	music_player:PlaySfxOneShot("03_dialogue_positive_01")
	character_util.set_anim(c, { name = 'victory_extra' })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s1_11", skip = true, offset = offset, bubble_direction = bd })

	music_player:PlaySfxOneShot("01_fade_out_05")
	self.world_controller:destroy_npc("ailie")
	wait_for_sec(1.0)

	music_player_util.play_stage_music({ state = 'muted', mix = 1.0 })
	wait_for_sec(0.1)

	field_ui_manager:Show()
	coroutine.yield(self.world_controller:show_stage_info())
	self.world_controller:finish_start_event()
end

function local_class:drop_disc_and_show(from_pos, to_pos)
	local item_data = game_data_service.GetData('ItemData')
	local item_placeholder = create_item_placeholder({ id = item_data:GetSpec('the_one_disc').Id, not_for_inventory = true })
	CS.Oak.DropItem.Create(from_pos, to_pos, item_placeholder, false, true)

	self.got_disc = false
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_disc_get')

	while not self.got_disc do
		coroutine.yield(nil)
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_disc_get')

	local player = user_party[0]
	local height = 1.2
	local itemSpriteScale = 0.7
	local itemTargetPos = vector(player.Position.x, player.Position.y + height, player.Position.z - 0.1)

	-- 중요 아이템 획득 SFX Play
	music_player:PlaySfxOneShot("01_get_keyitem_01")

	player.LockedDirection = CS.Oak.Direction.Down
	character_util.set_anim(player, { name = "get", loop = false })

	-- 보여줄 아이템 생성
	local  item = CS.Oak.DropItem.Create(player.Position, item_placeholder);
	item.SpriteTransform.localScale = vector(1, 1, 1) * itemSpriteScale;
	item.ShadowTransform.localScale = vector(1, 1, 1) * itemSpriteScale;
	item.State = CS.Oak.DropItem.LootState.DontFindLooter
	item.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 0, 0)
	item:SetSortingLayer(true)

	stage_camera:Shake(0.05, 0.1)

	-- 이펙트 생성
	local hightlightEffect = unity_object_pool.GetOrCreate("FX_highlight_item"):Instantiate(itemTargetPos)

	character_util.set_emotion(player, { name = "smile", loop = false})

	local itemHighlightDuration = 1.5
	local curTime = unity_class.time.time;

	-- 아이템 위로 들어 올림
	while unity_class.time.time - curTime < itemHighlightDuration do
		local curPos = CS.UnityEngine.Vector3.Lerp(player.Position, itemTargetPos, (unity_class.time.time - curTime) / itemHighlightDuration);
		item:SetPosition(curPos)
		coroutine.yield(nil)
	end

	-- Overlay UI
	local waitingForOverlay = true

	local on_ok = function ()
		waitingForOverlay = false
	end

	-- UISceneManager를 통해 아이템을 띄우는 오버레이를 푸쉬한다.
	local overlay_state = CS.UIOverlayState()
	overlay_state.Type = CS.UIOverlayType.Item
	overlay_state.Title = "we_s1_disc_title"
	overlay_state.Text = "we_s1_disc_text"
	overlay_state.Item = item_placeholder
	overlay_state.ItemDesc = "we_s1_disc_desc"
	overlay_state.OkAction = on_ok

	ui_scene_manager:PushOverlay(CS.UIOverlay.Instance, overlay_state)

	while waitingForOverlay do
		coroutine.yield(nil)
	end

	hightlightEffect:Dispose()
	item.ConsumeTarget = nil
	item:ConsumeComplete()

	player.LockedDirection = CS.Oak.Direction.None
	character_util.set_anim(player, { name = "seat", loop = true })
	character_util.remove_emotion(player)
end

function local_class:on_disc_get(e)
	self.got_disc = true
	return false
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
