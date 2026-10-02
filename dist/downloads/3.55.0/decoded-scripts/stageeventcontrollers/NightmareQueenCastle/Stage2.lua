local local_class = newclass('NightmareQueenCastle2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.state = {
		hitori = {
			before_start = 1,
			after_start = 2,
		},
	}

	self.current_state = {
		hitori = self.state.hitori.before_start
	}

	self.marker = {
		hitori_pivot = function()
			return field_util.get_marker_pos('android_hitori_pivot')
		end,
	}

	self.fx = metatable_helper.create_fx_accessor({
		dead = function()
			return unity_object_pool.GetOrCreate('FX_dead')
		end,
	})

	self.quest_id = 457

	self.item = metatable_helper.inherit({
		hitori_box = {
			id = 21520,

			item = nil,

			spawn = function(this, pos)
				this.item = quest_drop_item_util.create_item({
					item_id = this.id,
					pos = pos,
					unique_id = 'hitori_mall_box',
					loot_state = quest_drop_item_loot_state.dont_find_looter,
				})

				return this.item
			end,

			dispose = function(this)
				if this.item then
					quest_drop_item_util.dispose_item(this.item)
					this.item = nil
				end
			end,
		},
	}, {
		dispose = function(this)
			for _, item in pairs(this) do
				item:dispose()
			end
		end
	})

	self.script = nil

	---@type CharacterPlaceController 캐릭터 배치 컨트롤러
	self.place_controller = nil

	self.block_event = {
		is_in_zone = false,
		done = false
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.item:dispose()

	self.script:dispose()

	self.script = nil

	self.place_controller = nil

	self.cs_controller = nil
end

function local_class:load_resource()
	self.fx:load_async()

	local script_path = 'Quest/Nightmare/QueenCastle/Common/WeaponNpcBattleLogic'

	self.script = CS.Oak.StageLuaScript.Create(script_path)

	-- 캐릭터 배치 컨트롤러 로드 및 초기화
	--local place_controller = get_or_create_global_table('Quest/Etc/CharacterPlaceController/CharacterPlaceController')
	local is_create, place_controller = global_table_util.try_create('Quest/Etc/CharacterPlaceController/CharacterPlaceController')

	self.place_controller = place_controller

	self.place_controller:initialize()
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if self.current_state.hitori == self.state.hitori.before_start and
			type_util.is_zone_full_enter(e, get_party_leader(), 'android_hitori') then
		self.current_state.hitori = self.state.hitori.after_start

		start_coroutine(self.hitori_event, self)

		return true
	elseif self.quest_progress ~= nil and self.quest_progress.InnerProgress < 3 and not self.quest_progress.IsComplete and
			not self.block_event.done and not self.block_event.is_in_zone and
			type_util.is_zone_full_enter(e, user_party.Leader, 'android_block_zone') then
		self.block_event.is_in_zone = true

		sp_util.start_scene(self.block_zone_event, self):Then(function()
			self.block_event.is_in_zone = false
		end)

		return true
	end

	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine(_)
	self.quest_progress = user_progress:GetStartedQuest(self.quest_id)

	self.script:load()

	self:hitori_setting()

	stage_start_util.start_function(self.quest_progress)
end

function local_class:block_zone_event()
	local leader = user_party.Leader
	music_player_util.change_stage_music_volume('field', 0.6, 1)

	--니프티 (right, idle, idle): 전류의 대책을 먼저 찾아야됩니다.
	music_player_util.play_sfx_one_shot('03_dialogue_worker_03')

	scene_util.show_normal_speech_async(leader, 'nm_qc_sector_th_block_zone', true)

	--니프티 1초간 1칸 좌측 뒷걸음질
	local wp = zone_util.get_return_pos_on_enter('android_block_zone', leader, 'left')
	wp_util.move_async(leader, wp, nil, 1, { run = false, locked_dir = 'right' })

	music_player_util.change_stage_music_volume('field', 1, 1)
end

function local_class:hitori_setting()
	local pivot = self.marker.hitori_pivot()

	self.item.hitori_box:spawn(pivot)
end

function local_class:hitori_event()
	--(1) 안드로이드 1(nightmare_qc_android_worker) (left, idle, idle)
	--(2) 안드로이드 2(nightmare_qc_android_carpenter) (left, idle, idle)
	--(3) 안드로이드 3(nightmare_qc_android_sweeper) (left, idle, idle)
	--(a) 상자 스프라이트 (mall_box)
	local android_worker = get_character('android_hitori_worker')
	local android_carpenter = get_character('android_hitori_carpenter')
	local android_sweeper = get_character('android_hitori_sweeper')
	local hitori = get_character('android_hitori_hitori')

	--FIXME:아이템 관리
	local box = self.item.hitori_box.item
	local pivot = self.marker.hitori_pivot()

	local hitori_shake_key = 'hitori_shake'

	--(a)스프라이트 (shake 0.03) 0.5초
	quest_drop_item_util.shake(box, hitori_shake_key,
			0.03, 0.5)
	wait_for_sec(0.5)
	quest_drop_item_util.cancel_shake(box, hitori_shake_key)

	--대기 0.5초
	wait_for_sec(0.5)

	--(a)스프라이트 (shake 0.03) 0.5초
	quest_drop_item_util.shake(box, hitori_shake_key,
			0.03, 0.5)
	wait_for_sec(0.5)
	quest_drop_item_util.cancel_shake(box, hitori_shake_key)

	--안드로이드 1 (left, idle, release 2회): 상자안에 있는 거 다 압니다. 빨리 나오십시오.
	scene_util.play_normal_speech_action(android_worker, self, 'left',
			{ name = 'release', count = 2 }, nil,
			{ key = 'nm_qc_stage2_hitori_1', skip = false })

	--안드로이드 2 (left, idle, bomb_idle): 아니면 강제로 꺼낼 수 밖에 없습니다.
	scene_util.play_normal_speech_action(android_carpenter, self, 'left',
			'bomb_idle', nil,
			{ key = 'nm_qc_stage2_hitori_2', skip = false })

	--안드로이드 2 (left, idle, gauntlet_kick2)
	scene_util.set_anim(android_carpenter, self, { name = 'gauntlet_kick2', count = 1 })

	--gauntlet_kick2 재생 0.1초 후
	wait_for_sec(0.1)

	--다음 동작 동시에
	--(a) 스프라이트 위치에 fx_dead 출력되면서 (a)스프라이트 사라짐
	self.fx.dead():Instantiate(pivot)
	self.item.hitori_box:dispose()

	--(a) 스프라이트 위치에 (4) 외톨이 안드로이드 (nightmare_qc_android_hitori_blue)(left, damaged, prostrate)
	field_object_util.set_active_state(hitori, active_state_type.enabled)
	scene_util.set_direction(hitori, 'left', false)
	scene_util.set_emotion(hitori, self, 'damaged')
	scene_util.set_anim(hitori, self, 'prostrate')

	--가 회전하며 포물선으로 좌측 0.5칸 위치에 떨어짐
	character_util.spine_rotate(hitori, 360, 0.5)

	character_util.jump(hitori, 1, 0.5)

	wp_util.move_async(hitori, pivot + unity_class.vector3.left * 0.5, nil,
			0.5)

	character_util.cancel_jump(hitori)

	--외톨이 안드로이드 바닥에 도착했을 때 damged_squish +red_pusle
	character_util.spine_damage_squish_default(hitori)
	character_util.spine_damage_red_pulse(hitori)

	wait_for_sec(0.5)

	--안드로이드3(left, idle, bomb_idle): 상자안에는 왜 자꾸 들어가는 겁니까?
	scene_util.play_normal_speech_action(android_sweeper, self, 'left',
			'bomb_idle', nil,
			{ key = 'nm_qc_stage2_hitori_3', skip = false })

	--안드로이드2(left, idle, idle): 무슨 상상력 놀이라도 하는 겁니까?
	scene_util.play_normal_speech_action(android_carpenter, self, 'left',
			nil, nil,
			{ key = 'nm_qc_stage2_hitori_4', skip = false })

	--외톨이 안드로이드 (right, tired, seat): 그… 그게 상자는…!
	scene_util.play_normal_speech_action(hitori, self, 'right',
			'seat', 'scared',
			{ key = 'nm_qc_stage2_hitori_5', skip = false })

	--외톨이 안드로이드 (right, damaged, cast): 우, 우수한 외골격 장치입니다.
	scene_util.play_normal_speech_action(hitori, self, 'right',
			'cast', 'damaged',
			{ key = 'nm_qc_stage2_hitori_6', skip = false })

	--안드로이드2(left, idle, bomb_idle): 그건 도대체 무슨 농담입니까?
	scene_util.play_normal_speech_action(android_carpenter, self, 'left',
			'bomb_idle', nil,
			{ key = 'nm_qc_stage2_hitori_7', skip = false })

	--외톨이 안드로이드 (right, tired, idle)(shake0.03/0.5초): 그게… 상자 틈으로 바람이 들어가면서 마르누이 법칙과 베그누스 효과를….
	field_object_util.shake(hitori, 0.03, 0.5)

	scene_util.play_normal_speech_action(hitori, self, 'right',
			nil, 'scared',
			{ key = 'nm_qc_stage2_hitori_8', skip = false })

	--안드로이드1 (left, idle, idle): 그건 무슨 농담을 하고 있는겁니까?
	scene_util.play_normal_speech_action(android_worker, self, 'left',
			nil, nil,
			{ key = 'nm_qc_stage2_hitori_9', skip = false })

	--다음 동작 동시에
	--안드로이드3 (left, idle, release2회): 당신 방에 있는 상자들은 모두 폐기처분 하겠습니다.
	--외톨이 안드로이드 (right, suprise, idle)(jump 1회)
	character_util.normal_jump(hitori)
	scene_util.set_emotion(hitori, self, 'surprise')

	scene_util.play_normal_speech_action(android_sweeper, self, 'left',
			{ name = 'releas', count = 2 }, nil,
			{ key = 'nm_qc_stage2_hitori_10', skip = false })

	--다음 동작 동시에
	--안드로이드 1, 2, 3 속도 4로 우측 이동 시작 (walk 애니메이션)
	--그리드 밖에서 사라짐
	--외톨이 안드로이드 (right,cry,seat): 안돼!!!
	--해당 애니메이션 상태 고정
	do
		local offset = unity_class.vector3.right * 10

		local move_fos = { android_worker, android_carpenter, android_sweeper }

		for _, fo in pairs(move_fos) do
			wp_util.move_with_end_callback(fo, fo.Position + offset, 4,
					nil, self, nil,
					{
						end_callback = function()
							field_object_util.set_active_state(fo, active_state_type.disabled)
						end
					})
		end

		scene_util.play_normal_speech_action(hitori, self, 'right',
				{ name = 'seat', keep = true },
				{ name = 'cry', keep = true },
				{ key = 'nm_qc_stage2_hitori_11', skip = false })

		wp_util.wait_move_end(self)
	end
end

return local_class
