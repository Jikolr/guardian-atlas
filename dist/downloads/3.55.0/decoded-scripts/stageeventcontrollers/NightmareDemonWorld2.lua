local local_class = newclass('NightmareDemonWorld2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- 아이템 스펙 이름
	self.item_spec_name_list = {
		'merch_erina_pillow_normal',
		'demonworld_sushi',
		'liquor_bottle'
	}

	-- 아이템 인터렉트 시 불릴 함수 명
	self.item_interact_call_func_list = {
		'interact_erina_pillow',
		'interact_oodevil_sushi',
		'interact_liquor_bottle'
	}

	-- 아이템 크기
	self.item_scale_list = {
		0.5574,
		0.929,
		0.929
	}

	-- 캐릭터를 가져오는 함수
	self.get_convenience_store_seller = function() return get_character('convenience_store_seller') end

	-- 오브젝트를 가져오는 함수
	self.get_convenience_store_item = function(num) return get_field_object('convenience_store_item_' .. num) end

	-- 마커를 가져오는 함수
	self.get_convenience_store_item_marker = function(num) return field:GetMarker('convenience_store_item_marker_' .. num) end

	self.item_list = nil

	--region 피자가게 후일담
	-- 피자집 환영 맨트 날리는 이벤트 존 이름
	self.pizza_store_greeting_zone_name = 'pizza_store_greeting_zone'

	-- 피자집 카매라 그리드 이름
	self.pizza_store_grid_name = 'pizza_store_grid'

	-- 피자집 의자 마커 얻기
	self.get_pizza_store_chair_marker = function() return field:GetMarker('pizza_store_chair_marker') end

	-- 피자집 피자 날라가는 도착지점 마커 얻기
	self.get_pizza_store_pizza_marker = function() return field:GetMarker('pizza_store_pizza_marker')  end

	-- 피자집 알바생
	self.pizza_store_seller = nil

	-- 피자집 카운터
	self.pizza_store_counter = nil

	-- 피자 슬라이스 아이템 id
	self.mall_pizza_id = 20464

	-- 피자집 이벤트 진행도
	self.pizza_store_progress = {
		none = 1,
		greeted = 2
	}

	-- 피자집 이벤트 현재 진행도
	self.pizza_store_cur_progrees = self.pizza_store_progress.none
	--endregion
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	if self.item_list then
		for i = 1, #self.item_list do
			self.item_list[i]:ConsumeComplete()
			self.item_list[i] = nil
		end

		self.item_list = nil
	end

	--region 피자집 관련
	character_util.remove_relate_event(self.pizza_store_seller, self)
	--endregion

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')

	local seller = self.get_convenience_store_seller()
	seller.Hitbox = CS.Oak.Hitbox(vector(3, 1, 3))
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.pizza_store_counter) then
		sp_util.play_normal_screenplay(self.pizza_store_event, self)
	else
		for i = 1, #self.item_interact_call_func_list do
			local func_name = self.item_interact_call_func_list[i]
			local convenience_store_item = self.get_convenience_store_item(i)

			if lua_helper.reference_equals(e.Target, convenience_store_item) then
				sp_util.play_normal_screenplay(self[func_name], self, convenience_store_item)
				return true
			end
		end
	end

	return false
end

function local_class:on_stage_start_event(e)
	local item_data = game_data_service.GetData('ItemData')
	self.item_list = {}

	for i = 1, #self.item_spec_name_list do
		local item_spec_name = self.item_spec_name_list[i]
		local marker = self.get_convenience_store_item_marker(i)
		local field_object = self.get_convenience_store_item(i)
		local scale = self.item_scale_list[i]

		local item_id = item_data:GetSpec(item_spec_name).Id
		local item = drop_item_util.create_item({ pos = marker.position + vector(0.1, 0.35, -0.3), itemid = item_id, notforinven = true, lootstate = 'dontfindlooter', sprscale = scale, skip_text = true })

		field_object.Position = vector_util.get_x0z(marker.position)
		item.ShadowTransform.gameObject:SetActive(false)
		table.insert(self.item_list, item)
	end

	--region 피자집 관련
	self.pizza_store_seller = get_character('pizza_store_seller')
	character_util.add_listener(self.pizza_store_seller, self)

	self.pizza_store_counter = get_field_object('oni_girl_pizza_counter_1')
	--endregion

	return true
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.pizza_store_greeting_zone_name) and
			self.pizza_store_cur_progrees == self.pizza_store_progress.none then
		return self:pizza_store_greeting_event()
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, self.pizza_store_grid_name) then
		self:enter_pizza_store()
		return true
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

-- 에리나 베개 인터렉트
function local_class:interact_erina_pillow(convenience_store_item)
	-- 파티, 아이템 좌측으로 정렬.
	party_util.align_to_target(convenience_store_item, 'left', 1, 'arc')

	-- 내레이션 박스 출력
	-- 세븐 투엘브 한정 콜라보 상품, 에리나 베개
	field_ui_util.show_narration_async({ key = 'nightmare_demonworld_convenience_store_3' })

	-- 리리스 (smile, idle) : 요즘 편의점에선 별걸 다 파네!?
	character_util.set_emotion(user_party.Leader, { name = 'smile' })
	character_util.normal_jump(user_party.Leader, '01_player_jump_01')
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_demonworld_convenience_store_4', skip = true })

	-- 리리스 (smile, idle) : 대체 이게 언제적 사진이야!
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_demonworld_convenience_store_5', skip = true })

	-- 리리스 (tired, cross_arm) 0.5초 정도 유지, emoticon_bubble_silence
	character_util.set_emotion(user_party.Leader, { name = 'tired' })
	character_util.set_anim(user_party.Leader, { name = 'cross_arm' })
	wait_for_sec(0.5)

	character_util.show_emoticon_async(user_party.Leader, nil, 'silence')

	-- 리리스 (tired, cross_arm) : 할망구도 이랬던 시절이 있었는데… 세월이 야속하긴 하네…
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_demonworld_convenience_store_6', skip = true })

	character_util.remove_anim_and_emotion(user_party.Leader)

	-- 이벤트 종료.
end

-- 대악마뱃살 초밥 도시락 인터렉트
function local_class:interact_oodevil_sushi(convenience_store_item)
	-- 파티, 아이템 좌측으로 정렬.
	party_util.align_to_target(convenience_store_item, 'left', 1, 'arc')

	-- 나레이션 박스 출력
	-- 대악마뱃살 초밥 도시락
	field_ui_util.show_narration_async({ key = 'nightmare_demonworld_convenience_store_7' })

	-- 리리스 (tired, question) : 요즘은 이런 고급 초밥도 편의점에서 팔다니. 신기하네…
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_emotion(user_party.Leader, { name = 'tired' })
	character_util.set_anim(user_party.Leader, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_demonworld_convenience_store_8', skip = true })

	character_util.remove_anim_and_emotion(user_party.Leader)

	-- 이벤트 종료.
end

-- 양주 인터렉트
function local_class:interact_liquor_bottle(convenience_store_item)
	-- 파티, 아이템 좌측으로 정렬.
	party_util.align_to_target(convenience_store_item, 'left', 1, 'arc')

	-- 내레이션 박스 출력
	-- 존 다니엘 위스키
	field_ui_util.show_narration_async({ key = 'nightmare_demonworld_convenience_store_9' })

	-- 리리스 (idle, idle) : 이 술이랑 민트 초코 콜라랑 섞어먹는게 유행이라던데…
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_demonworld_convenience_store_10', skip = true })

	-- 리리스 (tired, question) : 참, 요즘 젊은 녀석들은 이해가 안간다니깐…
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.set_emotion(user_party.Leader, { name = 'tired' })
	character_util.set_anim(user_party.Leader, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_demonworld_convenience_store_11', skip = true })

	character_util.remove_anim_and_emotion(user_party.Leader)

	-- 이벤트 종료.
end

--region 피자집 이벤트 관련 함수
function local_class:enter_pizza_store()
	music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
end

function local_class:pizza_store_event()
	local chair_pos = self.get_pizza_store_chair_marker().position
	local pizza_pos = self.get_pizza_store_pizza_marker().position
	local seller = self.pizza_store_seller
	local leader = user_party.Leader

	self.pizza_store_counter.Interactable = CS.Oak.NonInteractable.Instance

	character_util.move_to_async(leader, vector(chair_pos.x + 0.75, 0, chair_pos.z), nil, 1, true, true)
	music_player_util.play_sfx_one_shot('01_jump_01')
	character_util.jump_move(leader, chair_pos, 2, 0.8, true, 'right')
	music_player_util.play_sfx_one_shot('01_hit_npc_01')
	character_util.set_anim(leader, { name = 'cross_arm', loop = true, upper = true })
	character_util.set_anim(leader, { name = 'seat', loop = true })
	character_util.set_emotion(leader, { name = 'tired' })
	wait_for_sec(1)

	-- 흠… 보자…
	speech_bubble_util.show_speech_bubble_async(leader, { key = 'nightmare_demonworld_pizza_2', skip = true })

	-- 딥 프라이 페퍼로니 피자
	-- 청키 포테이토 피자
	-- 골드 스위트 피자
	local pizza_types = {
		'nightmare_demonworld_pizza_3',
		'nightmare_demonworld_pizza_4',
		'nightmare_demonworld_pizza_5'
	}

	local result = choose_util.play_choose_event({
		{ pizza_types[1], 'normal'},
		{ pizza_types[2], 'normal'},
		{ pizza_types[3], 'normal'}
	})
	local pizza_text = game_string:GetStringWithReservedKeywords(pizza_types[result])

	-- {0} 하나 주세요.
	character_util.remove_anim(leader, true)
	speech_bubble_util.show_speech_bubble_async(leader, { key = game_string:Format('nightmare_demonworld_pizza_6', pizza_text), skip = true })

	-- 홀, 하프, 슬라이스 어떤 걸로 드릴까요?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_emotion(seller, { name = 'smile' })
	character_util.nod_twice(seller)
	speech_bubble_util.show_speech_bubble_async(seller, { key = 'nightmare_demonworld_pizza_7', skip = true })

	-- 슬라이스로도 파나요?
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.set_emotion(leader, { name= 'surprise'})
	speech_bubble_util.show_speech_bubble_async(leader, { key = 'nightmare_demonworld_pizza_8', skip = true })

	-- 네, 혼자 식사하는 마족들을 위해 이번 시즌부터 판매하고 있습니다!
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.set_anim(seller, { name = 'cast2', loop = true })
	speech_bubble_util.show_speech_bubble_async(seller, { key = 'nightmare_demonworld_pizza_9', skip = true})

	-- 정말 좋은 생각이네요. 슬라이스로 하나 주세요.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_emotion(leader, { name = 'smile' })
	character_util.set_animation_n_times_async(leader, { name = 'nod', count = 2, upper = true })
	speech_bubble_util.show_speech_bubble_async(leader, { key = 'nightmare_demonworld_pizza_10', skip = true})

	-- 네!
	character_util.remove_anim(seller)
	character_util.nod_twice(seller)
	speech_bubble_util.show_speech_bubble_async(seller, { key = 'nightmare_demonworld_pizza_11', skip = true})

	character_util.set_animation_n_times(seller, { name = 'release', count = 1, sfx = '01_swing_01', keep_anim = false })
	wait_for_sec(0.27)
	music_player_util.play_sfx_one_shot('01_throw_01')

	-- 피자 아이템 초기 설정
	local pizza_item = drop_item_util.create_item({
		pos = seller.Position + vector(0, 0.25, 0),
		itemid = self.mall_pizza_id,
		notforinven = true, lootstate = 'dontfindlooter'
	})

	local scale_mult = 0.6
	local start_scale = unity_class.vector3.one * scale_mult
	pizza_item.SpriteTransform.localScale = start_scale
	pizza_item.ShadowTransform.localScale = start_scale

	-- 피자 테이블 위로 던지기
	local time_passed = 0
	local start_pos = pizza_item.Position
	local throw_duration = 0.5

	while time_passed <= throw_duration do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(time_passed / throw_duration)
		local cur_pos = unity_class.vector3.Lerp(start_pos, pizza_pos, progress)
		local cur_y = unity_class.mathf.Sin(unity_class.mathf.PI * progress) * 0.6
		pizza_item.Position = cur_pos + vector(0, cur_y, 0)

		local cur_rot_z = unity_class.mathf.Lerp(0, 360 * 3, progress)
		pizza_item.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 0, cur_rot_z)
		coroutine.yield(nil)
	end

	wait_for_sec(0.4)

	-- 피자 점점 작아지는 연출
	local pizza_disappear_time = 2
	local eat_start_time = unity_class.time.time
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '01_eat_01', loop = true })
	character_util.remove_anim(leader, true)
	character_util.set_anim(leader, { name = 'eat', loop = true})
	while true do
		local progress = (unity_class.time.time - eat_start_time) / pizza_disappear_time
		if progress >= scale_mult then
			pizza_item:ConsumeComplete()
			pizza_item = nil
			break
		end

		local cur_scale = unity_class.vector3.one * (scale_mult - progress)
		pizza_item.SpriteTransform.localScale = cur_scale
		pizza_item.ShadowTransform.localScale = cur_scale
		coroutine.yield(nil)
	end
	eat_sfx:Stop()
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.set_anim(leader, { name = 'seat', loop = true })
	character_util.set_emotion(leader, { name = 'blush' })
	coroutine.yield(nil)

	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.shake(leader, 0.03, 1)
	wait_for_sec(1)

	-- 따뜻하고 맛있어…
	speech_bubble_util.show_speech_bubble_async(leader, { key = 'nightmare_demonworld_pizza_14', skip = true })

	-- 조각 단위로 파는 데도 이렇게 따뜻하고 맛있다니…
	character_util.set_emotion(leader, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(leader, { key = 'nightmare_demonworld_pizza_12', skip = true })

	-- 마마존스… 오픈한지 얼마 안 됐지만 무섭게 성장하겠어.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_animation_n_times_async(leader, { name = 'nod', count = 2, upper = true })
	speech_bubble_util.show_speech_bubble_async(leader, { key = 'nightmare_demonworld_pizza_13', skip = true })

	music_player_util.play_sfx_one_shot('01_jump_01')
	character_util.remove_anim(leader, true)
	character_util.remove_anim_and_emotion(leader)
	character_util.jump_move(leader, vector(chair_pos.x + 1, 0, chair_pos.z), 3, 0.8, true)
	music_player_util.play_sfx_one_shot('01_land_01')
end

function local_class:pizza_store_greeting_event()
	if self.pizza_store_seller ~= nil then
		self.pizza_store_cur_progrees = self.pizza_store_progress.greeted
		speech_bubble_util.show_speech_bubble(self.pizza_store_seller, { key = 'nightmare_demonworld_pizza_1', skip = false })
		return true
	end

	return false
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
