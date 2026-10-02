local local_class = newclass('NightmareFutureCastle3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 퀘스트 id
	self.main_quest_id = 208

	-- 오브젝트를 가져오는 함수
	self.get_small_rock = function(num) return get_field_object('small_rock_' .. num) end

	self.in_soccer_grid = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self:find_and_execute_fo_all(self.get_small_rock, function(small_rock)
		small_rock.Transform.localScale = vector(0.5, 0.5, 0.5)
		small_rock.Hitbox = CS.Oak.Hitbox(vector(0.75, 0, 0.5), vector(1, 1, 1))
	end)
end
--endregion

--region launch
function local_class:need_on_launch()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	return main_quest_progress ~= nil and main_quest_progress.InnerProgress == 4
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(_)
	local sapa_oneline_1 = get_character('sapa_oneline_1')
	--character_util.spine_rotate(sapa_oneline_1, -90, 0)
	--sapa_oneline_1.SpineController:SetAttachment('[base]weapon1', 'empty')
	--sapa_oneline_1.SpineController:SetAttachment('[base]weapon2', 'empty')
end

function local_class:on_camera_grid_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

	local grid_name = e.CameraGrid.name

	if grid_name == 'soccer_grid' and not self.in_soccer_grid then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.soccer_routine, self))
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return end
	if e.FieldObject ~= user_party.Leader then return end
	local zone_name = e.Zone.Name

	if zone_name == 'soccer_out' then
		self.in_soccer_grid = false
	end

	return false
end
--endregion

function local_class:find_and_execute_fo_all(find_fo_func, execute_func)
	local i = 1
	while true do
		local fo = find_fo_func(i)

		if fo == nil then
			break
		end

		execute_func(fo)

		i = i + 1
	end
end

function local_class:soccer_routine()
	self.in_soccer_grid = true
	local merchant = get_character('nightmare_future_china_merchant')
	local female = get_character('nightmare_future_china_female')
	local soccer_ball = get_field_object('soccer_ball')
	local move_passed = 0
	local female_pos = female.Position + vector(-0.5,0,0)
	local merchant_pos = merchant.Position + vector(0.5,0,0)

	merchant.Interactable.Talk = nil
	female.Interactable.Talk = nil

	character_util.set_emotion(merchant, { name = 'mad' })
	character_util.set_emotion(female, { name = 'mad' })

	local ball_move_time = 0.3

	local animation_duration = spine_util.get_animation_duration(female, 'twohand_attack4')

	while self.in_soccer_grid do
		music_player_util.play_sfx({ sfx_name = '01_female_shout_01',
									 parent = female, type_priority = 'event', player_priority = 'npc', max_distance = 10 })

		speech_bubble_util.show_speech_bubble(female, { key = 'nightmare_futurecastle_3_football_6' })
		character_util.set_animation_n_times(female, { name = 'twohand_attack4', count = 1, scale = 2 })

		wait_for_sec(animation_duration * 0.5)

		if not self.in_soccer_grid then break end
		music_player_util.play_sfx({ sfx_name = '02_hit_projectile_01',
									 parent = female, type_priority = 'event', player_priority = 'npc', max_distance = 10 })

		move_passed = 0
		while move_passed <= ball_move_time do
			move_passed = move_passed + unity_class.time.deltaTime
			soccer_ball.Position = unity_class.vector3.Lerp(female_pos, merchant_pos, move_passed / ball_move_time)
			soccer_ball.transform.localRotation = unity_class.quaternion.Euler(0, move_passed / ball_move_time * 360, 0)
			coroutine.yield()
		end
		if not self.in_soccer_grid then break end

		wait_for_sec(0.2)
		if not self.in_soccer_grid then break end

		music_player_util.play_sfx({ sfx_name = '02_boss_sapa_shout_01',
									 parent = merchant, type_priority = 'event', player_priority = 'npc', max_distance = 10 })

		speech_bubble_util.show_speech_bubble(merchant, { key = 'nightmare_futurecastle_3_football_5' })
		character_util.set_animation_n_times_async(merchant,
				{ name = 'jingak', count = 1, scale = 2, sfx = '02_hit_projectile_01' })
		if not self.in_soccer_grid then break end

		move_passed = 0
		while move_passed <= ball_move_time do
			move_passed = move_passed + unity_class.time.deltaTime
			soccer_ball.Position = unity_class.vector3.Lerp(merchant_pos, female_pos, move_passed / ball_move_time)
			soccer_ball.transform.localRotation = unity_class.quaternion.Euler(0, -move_passed / ball_move_time * 360, 0)
			coroutine.yield()
		end
		if not self.in_soccer_grid then break end

		wait_for_sec(0.2)
		coroutine.yield()
	end

	soccer_ball.Position = female_pos
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
