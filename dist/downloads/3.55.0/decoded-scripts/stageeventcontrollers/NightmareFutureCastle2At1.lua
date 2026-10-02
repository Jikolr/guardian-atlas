local local_class = newclass("NightmareFutureCastle2At1Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.saw_idol = false

	self.end_idol_event = false

	--region 라일라 특제 스튜
	-- stew 아이템 id
	self.stew_item_id = 20388
	-- stew 지역 진입 시 재생할 sfx
	self.boiling_sfx = nil

	--endregion

	--region 인형극 하는 아이들
	self.bone_follower_list = {}

	self.puppet_grid = 'puppet_grid'

	self.puppet_zone_sfx_holder  = nil

	self.vampire_idol_zone = 'vampireidol'

	self.get_snowman = function() return get_character('idolparty_snowmna_reporter_b') end
	self.get_gallery = function(num) return get_character('gallery_' .. num) end
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	self.main_quest_id = 217
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if self.main_quest_progress == nil or self.main_quest_progress.InnerProgress < 1 then
		return true
	end
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)

end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_stage_loaded()
	--region 라일라 특제 스튜
	local stew_eater_1 = get_character('stew_steampunk_male_1')
	local stew_eater_2 = get_character('stew_steampunk_male_2')
	local stew_eater_3 = get_character('stew_steampunk_resistance_1')
	local stew_eater_4 = get_character('stew_steampunk_resistance_2')

	-- stew 아이템 배치
	drop_item_util.create_item({
		pos = stew_eater_1.Position + (0.5 * unity_class.vector3.right), itemid = self.stew_item_id,
		notforinven = true, lootstate = 'dontfindlooter'
	})

	drop_item_util.create_item({
		pos = stew_eater_2.Position + (0.5 * unity_class.vector3.right), itemid = self.stew_item_id, notforinven = true,
		lootstate = 'dontfindlooter'
	})

	drop_item_util.create_item({
		pos = stew_eater_3.Position + (0.5 * unity_class.vector3.left), itemid = self.stew_item_id, notforinven = true,
		lootstate = 'dontfindlooter'
	})

	drop_item_util.create_item({
		pos = stew_eater_4.Position + 0.5 * unity_class.vector3.right, itemid = self.stew_item_id, notforinven = true,
		lootstate = 'dontfindlooter'
	})

	local box = get_field_object('princess_box')
	local box_animator = box.transform:GetComponentInChildren(
			typeof(CS.UnityEngine.Animator))
	box_animator:Play('open', -1, 99)
	CS.Oak.AnimatorExtensions.SwitchCullMode(box_animator, box)
	--endregion

	--region 인형극 하는 아이들
	-- 아이들이 피규어 드는 스롯
	local slot_list = {
		2, 2, 1, 1, 1
	}

	-- 피규어 회전 값
	local rotate_list = {
		180, 180, 180, 180, 270
	}

	for i = 1, 5 do
		local kid = get_character('puppetshot_kid_' .. i)

		-- 플레이어의 기사 성별에 따라 기사 피규어 성별 다르게 설정
		local figure = nil
		if i == 1 then
			if user_util.has_knight_male() then
				figure = get_character('kid_1_figure_male_1')
			else
				figure = get_character('kid_1_figure_female_1')
			end
		else
			figure = get_character('kid_1_figure_' .. i)
			character_util.set_anim(figure, { name = 'idle', scale = 0 })
		end

		character_util.set_scale_factor(figure, nil, 0.5)
		character_util.set_active_shadow(figure, false)
		field_ui_manager:RemoveUI(figure, CS.Oak.FieldUiType.CharacterStats)

		self:attach_figure_to_target(kid, figure, slot_list[i], rotate_list[i])
	end

	character_util.add_listener(self.get_snowman(), self.cs_controller)
	--endregion
end

function local_class:on_zone_enter(e)
	if e.FullEnter == false then return end
	if e.FieldObject ~= user_party.Leader then return end
	local zone_name = e.Zone.Name

	if zone_name == 'vampireidol' then
		music_player_util.play_stage_music({name = 'bgm_idol_lyric', state = 'event', mix = 1})
	end

	if zone_name == 'vampireidol' and self.saw_idol == false then
		self.saw_idol = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.idol_event_1, self))
	elseif zone_name == 'laila_stew_zone' then
		if self.boiling_sfx == nil or self.boiling_sfx ~= nil and not self.boiling_sfx.IsUsing then
			self.boiling_sfx = music_player_util.play_sfx(
					{ sfx_name = '01_boiling_01', loop = true, fade_in_time = 1.5, type_priority = 'loop'})
		end
	end
end

function local_class:on_zone_leave(e)
	if e.FullLeave == false then return end
	if e.FieldObject ~= user_party.Leader then return end
	local zone_name = e.Zone.Name

	if zone_name == 'vampireidol' then
		music_player_util.play_stage_music({ state = 'field', mix = 1 })
	end

	if zone_name == 'laila_stew_zone' then
		if self.boiling_sfx ~= nil then
			self.boiling_sfx:FadeOut(1)
		end
	end
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, self.puppet_grid) then
		if self.puppet_zone_sfx_holder == nil then
			self.puppet_zone_sfx_holder = music_player_util.play_sfx({
				sfx_name = '01_crowd_buzz_02', type_priority = 'loop',
				player_priority = 'npc', loop = true,
				parent = get_character('puppetshot_steampunk_male_1')
			})
		end
	end
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, self.puppet_grid) then
		if self.puppet_zone_sfx_holder ~= nil then
			self.puppet_zone_sfx_holder:FadeOut(1)
			self.puppet_zone_sfx_holder = nil
		end
	end
end


function local_class:on_interact_event(e)
	local snowman = self.get_snowman()
	local gallery_7 = self.get_gallery(7)
	local gallery_8 = self.get_gallery(8)

	if lua_helper.reference_equals(e.Target, snowman) then
		music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = snowman, type_priority = 'event' })
		speech_bubble_util.show_speech_bubble(snowman, { key = 'nightmare_futurecastle_2_idolparty_5', skip = false })
		return true
	end

	if self.end_idol_event == false then
		return false
	end

	if lua_helper.reference_equals(e.Target, gallery_7) then
		music_player_util.play_sfx({ sfx_name = '01_clap_01', parent = gallery_7, type_priority = 'event' })
		speech_bubble_util.show_speech_bubble(gallery_7, { key = 'nightmare_futurecastle_2_s2_2', skip = false })
		return true
	end

	if lua_helper.reference_equals(e.Target, gallery_8) then
		music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', parent = gallery_8, type_priority = 'event' })
		speech_bubble_util.show_speech_bubble(gallery_8, { key = 'nightmare_futurecastle_2_s2_6', skip = false })
		return true
	end
	return false
end

function local_class:idol_event_1()
	local gallery = {}
	for i = 1, 8 do
		gallery[i] = get_character('gallery_' .. i)
	end

	local vampireidol = get_character('vampire_idol')

	music_player_util.play_sfx({ sfx_name = '01_crowd_clap_03', parent = vampireidol, type_priority = 'event' })

	local order = { 1, 8, 2, 5, 3, 7 }
	for i = 1, #order do
		local key = 'nightmare_futurecastle_2_s2_' .. i
		speech_bubble_util.show_speech_bubble_async(gallery[order[i]], { key = key })
	end

	character_util.set_anim(vampireidol, {name = 'sing'})
	speech_bubble_util.show_speech_bubble_async(vampireidol, { key = 'nightmare_futurecastle_2_s2_7' })
	--소박하게나마 준비해본 부유성의 콘서트, 즐거우신가요?

	character_util.set_anim_and_emotion(gallery[1], {name = 'success'}, {name = 'awesome'})
	character_util.set_anim_and_emotion(gallery[8], {name = 'success'}, {name = 'awesome'})

	speech_bubble_util.show_speech_bubble(gallery[1], { key = 'nightmare_futurecastle_2_s2_8' })
	--네!

	speech_bubble_util.show_speech_bubble_async(gallery[8], { key = 'nightmare_futurecastle_2_s2_9' })
	--너무 좋아요!

	speech_bubble_util.show_speech_bubble_async(vampireidol, { key = 'nightmare_futurecastle_2_s2_10' })
	--부유성을 지켜준 여러분과 재건에 힘쓰는 여러분 모두가 영웅이에요.

	speech_bubble_util.show_speech_bubble_async(vampireidol, { key = 'nightmare_futurecastle_2_s2_11' })
	--이렇게 여전히 평화를 노래할 수 있게 해줘서…

	character_util.set_emotion(vampireidol, {name = 'smile'})
	speech_bubble_util.show_speech_bubble_async(vampireidol, { key = 'nightmare_futurecastle_2_s2_12' })
	--정말 감사해요, 모두들.

	character_util.set_emotion(princess, {name = 'smile'})
	speech_bubble_util.show_speech_bubble(gallery[2], { key = 'nightmare_futurecastle_2_s2_13',
														skip = true, bubble_type = 'shout' })
	wait_for_sec(0.2)
	speech_bubble_util.show_speech_bubble(gallery[5], { key = 'nightmare_futurecastle_2_s2_13',
														skip = true, bubble_type = 'shout' })
	wait_for_sec(0.1)
	speech_bubble_util.show_speech_bubble_async(gallery[7], { key = 'nightmare_futurecastle_2_s2_13',
															  skip = true, bubble_type = 'shout' })
	--와아아아!

	character_util.remove_emotion(vampireidol)
	character_util.set_anim(vampireidol, {name = 'sing2'})

	for i = 1, #order do
		local key = 'nightmare_futurecastle_2_s2_' .. i
		gallery[order[i]].Interactable.Talk = key
	end

	self.end_idol_event = true

	character_util.add_listener(self.get_gallery(7), self.cs_controller)
	character_util.add_listener(self.get_gallery(8), self.cs_controller)
end

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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	if self.bone_follower_list ~= nil then
		for i = 1, #self.bone_follower_list do
			CS.UnityEngine.GameObject.Destroy(self.bone_follower_list[i])
		end
		self.bone_follower_list = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:attach_figure_to_target(target, figure, slot_index, z_rotation)
	local slot = lua_helper.get_or_default(slot_index, 2)
	local rotate = lua_helper.get_or_default(z_rotation, 0)

	local bone_follower = figure.Transform.gameObject:AddComponent(typeof(CS.Spine.Unity.BoneFollower))
	bone_follower.followBoneRotation = false
	bone_follower.SkeletonRenderer = target.SpineController.SkeletonAnimation
	bone_follower:SetBone('[base]weapon' .. slot .. '_side')

	figure.Transform.localRotation = unity_class.quaternion.Euler(0, 0, rotate)

	table.insert(self.bone_follower_list, bone_follower)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
