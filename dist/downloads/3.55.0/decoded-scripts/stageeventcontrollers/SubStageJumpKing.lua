local local_class = newclass('SubStageJumpKingController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 메인 퀘스트 id
	self.main_quest_id = 366

	-- scene_util 버전
	self.scene_version = scene_util.default_version

	-- 까마귀 이벤트 내 스테이트 Enum
	self.crow_event_state = {
		none = 1,
		after_interact_ring_box = 2,
		get_ring = 3,
		done = 4
	}

	self.current_crow_event_state = self.crow_event_state.none

	-- 레이네
	self.get_reine = function()
		return get_character('reine')
	end

	-- 헬라
	self.get_hela = function()
		return get_character('hela')
	end

	-- 까마귀
	self.get_crow = function()
		return get_character('sub_crow')
	end

	-- 골드링 획득 오브젝트
	self.get_ring_box = function()
		return get_field_object('sub_crow_interact')
	end

	self.star_piece_name = 'crow_star_piece'
	self.gold_ring_id = 21092
	self.wait_before_get_ring = false
	self.is_jump_reset = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	if self.jump_king_gimmick == nil then
		self.jump_king_gimmick = get_or_create_global_table('Quest/Main/CivilWar/JumpKing/Gimmick/JumpKingGimmickController')
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	local reine = self.get_reine()

	if not star_piece_util.has_star_piece(self.star_piece_name) or
			not self.current_crow_event_state == self.crow_event_state.done then
		if self.current_crow_event_state == self.crow_event_state.get_ring
				and type_util.is_zone_full_enter(e, reine, 'sub_crow_zone') then
			self.current_crow_event_state = self.crow_event_state.done
			start_coroutine(self.crow_zone_enter_event, self, true)

			return true
		elseif self.current_crow_event_state ~= self.crow_event_state.get_ring
				and self.current_crow_event_state ~= self.crow_event_state.done
				and type_util.is_zone_full_enter(e, reine, 'sub_crow_zone') then
			start_coroutine(self.crow_zone_enter_event, self, false)

			return true
		end
	end

	return false
end

function local_class:on_interact_event(e)
	local ring_box = self.get_ring_box()

	if self.current_crow_event_state == self.crow_event_state.after_interact_ring_box and
			lua_helper.reference_equals(e.Target, ring_box) then
		self.current_crow_event_state = self.crow_event_state.get_ring
		sp_util.start_scene(self.interact_ring_box_event, self)

		return true
	end

	return false
end

function local_class:on_item_get_event(e)
	if self.wait_before_get_ring and
			lua_helper.reference_equals(e.Getter, get_party_leader()) and e.Item.ItemId == self.gold_ring_id then
		self.wait_before_get_ring = false
		return true
	end

	return false
end
--endregion

function local_class:launch_routine()
	if not star_piece_util.has_star_piece(self.star_piece_name) then
		self.current_crow_event_state = self.crow_event_state.after_interact_ring_box
	end

	if not star_piece_util.has_star_piece(self.star_piece_name) or
			not self.current_crow_event_state == self.crow_event_state.done then
		self:crow_event_pre_setting()
	end

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if main_quest_progress == nil or main_quest_progress.IsComplete then
		start_coroutine(function()
			self.jump_king_gimmick:load_async()
		end)
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s1_soldier_pos_6'),
				true, true)
	elseif main_quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, true)
	elseif main_quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, true)
	elseif main_quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s2_hela_hide_pos_2')
				+ vector(-0.5, 0, 0), true, true)
	elseif main_quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s4_start_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 4 then
		start_coroutine(function()
			self.jump_king_gimmick:load_async()
		end)
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s4_quest_marker_pos_2'),
				true, true)
	elseif main_quest_progress.InnerProgress == 5 then
		start_coroutine(function()
			self.jump_king_gimmick:load_async()
		end)
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s3_hela_pos_7'),
				true, true)
	end
end

function local_class:crow_event_pre_setting()
	--까마귀(left,idle,land_idle)
	local crow = self.get_crow()
	crow.Position = field_util.get_marker_pos('sub_crow_pos_1')
	scene_util.set_direction_by_args(crow, { dir = 'left', sfx = false })
	scene_util.set_anim(crow, self, { name = 'land_idle' })

	local ring_box = self.get_ring_box()
	ring_box.Interactable = CS.Oak.PublishInteractable.Create()
	ring_box.Hitbox = CS.Oak.Hitbox(vector(0.5, 0.5, 0.2), vector(1, 1, 3))

	self.gold_ring = drop_item_util.create_item({
		pos = ring_box.Position + vector(0, 1.5, 0),
		itemid = self.gold_ring_id,
		notforinven = true,
		lootstate = 'dontfindlooter',
	})
end

function local_class:interact_ring_box_event()
	local reine = self.get_reine()
	local ring_box = self.get_ring_box()
	--안쪽에 있는 빨간색 표시한 오브젝트를 인터랙트 하면
	--레이네(right,idle,eat)
	local eat_loop_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01',
		parent = reine,
		loop = true,
		type_priority = 'loop',
		player_priority = 'npc'
	})
	scene_util.set_anim(reine, self, { name = 'eat' })

	wait_for_sec(0.5)

	--금반지 스프라이트 (shake0.03/0.5초) 후 레이네에게 해당 스프라이트가 날아오고 획득된다.
	wait_for_sec(0.7)

	music_player_util.play_sfx_one_shot('03_treasure_item_popup_01')

	local ring_item_key = 'ring_item_key'
	drop_item_util.shake(self.gold_ring, ring_item_key, 0.03, 0.5)

	wait_for_sec(0.5)

	self.gold_ring.ConsumeTarget = reine
	self.gold_ring:Fly()

	while self.wait_before_get_ring do
		coroutine.yield()
	end

	ring_box.Interactable = CS.Oak.NonInteractable.Instance

	character_util.remove_anim_and_emotion(reine)
	music_player_util.stop_sfx(eat_loop_sfx)

	--금반지(gold_ring_accessory)
end

function local_class:crow_zone_enter_event(get_ring)
	self.jump_king_gimmick:jump_end_wait(function()
		self.is_jump_reset = true
	end)

	if self.is_jump_reset then
		self.is_jump_reset = false
		if self.current_crow_event_state == self.crow_event_state.done then
			self.current_crow_event_state = self.crow_event_state.get_ring
		end
		
		return
	end

	local crow = self.get_crow()
	local reine = self.get_reine()
	local hela = self.get_hela()

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	--녹색존 진입시
	if get_ring then
		--골드링이 있을 경우
		--까마귀 (left,idle,walk)로 레이네 우측으로 
		--레이네 (right,idle,idle) 상태
		character_util.remove_anim_and_emotion(reine)
		scene_util.set_direction_by_args(reine, { dir = 'right', sfx = false })

		scene_util.set_anim(crow, self, { name = 'walk' })

		music_player_util.play_sfx_one_shot('01_crow_02')
		local wp = reine.Position + vector(1, 0, 0)
		wp_util.move_async(crow, wp, nil, 1, { run = false, last_direction = 'left' })

		character_util.remove_anim(crow)

		wait_all({
			util.cs_generator(function()
				--까마귀 0.5칸 좌측 이동 후 (left,idle,attack) 사용
				scene_util.set_anim(crow, self, { name = 'attack' })

				local wp = crow.Position + vector(-0.5, 0, 0)
				wp_util.move_async(crow, wp, nil, 1, { run = false, last_direction = 'left' })
				character_util.remove_anim_and_emotion(crow)
			end),
			util.cs_generator(function()
				--attack 할 때 레이네 (right,surprise,embarrassed) 0.5초
				scene_util.set_emotion(reine, self, 'surprise')
				scene_util.set_anim(reine, self, { name = 'embarrassed' })
				wait_for_sec(0.5)

				scene_util.set_emotion(reine, self, 'tired')
				character_util.remove_anim(reine)

				--금반지 스프라이트가 레이네 0.5칸 우측에 떨어지고 까마귀에게 습득됨
				music_player_util.play_sfx_one_shot('01_throw_01')
				local item_target_pos = reine.Position + vector(0.5, 0, 0)
				local gold_ring = drop_item_util.create_item({
					pos = reine.Position,
					target = item_target_pos,
					itemid = self.gold_ring_id,
					notforinven = true,
					lootstate = 'dontfindlooter',
				})

				wait_for_sec(0.7)

				gold_ring.ConsumeTarget = crow
				gold_ring:Fly()

				while self.wait_before_get_ring do
					coroutine.yield()
				end
			end)
		})

		--까마귀(left, smile, idle)+(happy)이모티콘 버블
		--이 때 레이네(right,tired,idle)
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		scene_util.play_emoticon_action(crow, self,
				'left',
				nil,
				{ name = 'smile' },
				'happy')

		--까마귀 y축 4칸 올라가면서 우측으로 속도 8로 이동 그리드밖에서 까마귀 사라짐
		music_player_util.play_sfx_one_shot('01_crow_01')
		local crow_wp = screen_util.get_left_right_outside_pos('right', crow.Position, 1.5) + vector(0, 4, 0)
		wp_util.move_async(crow, crow_wp, 8, nil, { run = true, end_callback = function()
			crow.Position = vector(999, 0, 999)
			character_util.set_active_state(crow, 'disabled')
		end })

		--녹색존에서 쫓아내는 이벤트 제거됨
	else
		--골드링이 없을 경우
		--까마귀 (left,mad,idle) 상태로 일어남
		scene_util.set_emotion(crow, self, 'mad')
		character_util.remove_anim(crow)
		scene_util.set_anim(crow, self, { name = 'surprise' })

		--레이네 친구 (right,scared,idle)(jump1회)
		scene_util.set_direction_by_args(hela, { dir = 'right', sfx = false })
		scene_util.set_direction_by_args(reine, { dir = 'right', sfx = false })

		scene_util.set_emotion(hela, self, 'scared')
		scene_util.set_emotion(reine, self, 'scared')

		character_util.normal_jump(reine)
		character_util.normal_jump_async(hela)

		--까마귀 (left,mad,attack)하면서 지정된 위치까지 이동 이동시간 (2초)
		scene_util.set_anim(crow, self, { name = 'attack' })

		--레이네 친구 (right,damaged,embarrassed)상태로 지정한 위치까지 뒷걸음질로 이동한다. 이동시간 (2초)
		scene_util.set_direction_by_args(hela, { dir = 'right', sfx = false })
		scene_util.set_direction_by_args(reine, { dir = 'right', sfx = false })

		scene_util.set_emotion(reine, self, 'damaged')
		scene_util.set_anim(reine, self, { name = 'embarrassed' })

		scene_util.set_emotion(hela, self, 'damaged')
		scene_util.set_anim(hela, self, { name = 'embarrassed' })

		local wp_key = 'wp_key'
		local duration = 1

		local reine_wp = field_util.get_marker_pos('sub_crow_reine_pos_1')
		local hela_wp = field_util.get_marker_pos('sub_crow_reine_pos_1') + vector(-0.7, 0, 0)

		if reine.Position.x < hela.Position.x then
			hela_wp = field_util.get_marker_pos('sub_crow_reine_pos_1')
			reine_wp = field_util.get_marker_pos('sub_crow_reine_pos_1') + vector(-0.7, 0, 0)
		end

		wp_util.move_with_end_callback(reine,
				reine_wp, nil, duration, self, wp_key,
				{ run = false, locked_dir = 'right', y_mode = 'floor' })

		wp_util.move_with_end_callback(hela,
				hela_wp, nil, duration, self, wp_key,
				{ run = false, locked_dir = 'right', y_mode = 'floor' })

		music_player_util.play_sfx_one_shot('01_crow_02')
		local crow_wp = field_util.get_marker_pos('sub_crow_pos_2')
		wp_util.move_with_end_callback(crow,
				crow_wp, nil, duration, self, wp_key,
				{ run = false })

		wp_util.wait_move_end(self, wp_key)

		character_util.remove_anim(crow)

		local wp = field_util.get_marker_pos('sub_crow_pos_1')
		wp_util.move(crow, wp, nil, 0.7,
				{ run = false, last_direction = 'left', end_callback = function()
					character_util.remove_emotion(crow)
					scene_util.set_anim(crow, self, { name = 'land_idle' })
				end })
	end

	character_util.remove_anim_and_emotion(hela)
	character_util.remove_anim_and_emotion(reine)
	music_player_util.change_stage_music_volume('field', 1, 1)

	field_ui_manager:Show()
	party_util.reset_controllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
