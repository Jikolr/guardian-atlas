local local_class = newclass("FutureCastle1At1Controller")

local EventProgress = {
	idle = 0,
	shelter = 1,
}

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.event_progress = EventProgress.idle

	-- 카메라
	self.heavenhold_camera = nil

	-- 부유성 배경
	self.heavenhold_background = nil

	-- Inn Object 리스트
	self.inn_obj_list = nil

	-- 리소스 홀더
	self.resholder = CS.Foundations.ResourceHolder()

	self.rain_screen_effect = nil
	self.rain_ground_effect = nil

	self.rain_sfx = nil

	-- 지하 대피소 입장 플래그
	self.is_enter_shelter = false

	-- 기타 상수
	self.inn_obj_num = 7
	self.shelter_refugee_num = 4
	self.champ_num = 6
	self.china_champ_num = 4

	-- 캐릭터 이름
	self.shelter_refugee_name = 'shelter_refugee_2_'
	self.princess_name = 'princess'
	self.champ_name = 'champ_'
	self.champ_china_male_name = 'champ_china_male'
	self.champ_china_female_name = 'champ_china_female'
	self.camera_name = 'heavenhold_camera'

	-- 필드오브젝트 이름
	self.grave_name = 'kid_grave'

	-- 필드 이벤트 존 이름
	self.shelter_zone_name = 'shelter'
	self.shelter_event_zone_name = 'shelter_cold_room'

	-- 틴트 키
	self.tint_key = 'futurecastle_1_1'

	-- 커스텀 이벤트 이름
	self.activate_rain_custom_event = 'activate_rain'
	self.deactivate_rain_custom_event = 'deactivate_rain'

	-- 오브젝트 풀 이름
	self.heavenhold_obj_preset = 'heavenholdObject'
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate(self.heavenhold_obj_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.heavenhold_camera = get_character(self.camera_name)

	local main_quest_id = 151
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest ~= nil and main_quest.InnerProgress ~= 0 then
		self.heavenhold_camera.Interactable = CS.Oak.PublishInteractable.Create()
	end

	-- 이펙트 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'effects/stage/weather', 'fx_env_rain_screen_fx', function(prefab)
				self.rain_screen_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.rain_screen_effect.transform:SetParent(stage_camera.Transform.parent)
				self.rain_screen_effect.transform.localPosition = unity_class.vector3.zero
			end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_3_futurecastle/effects/futurecastle', 'fx_futurecastle_rain_ripple_1_1', function(prefab)
				self.rain_ground_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.rain_ground_effect.transform.localPosition = unity_class.vector3.zero
			end)

	self.rain_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_rain_loop_01', loop = true, fade_in_time = 2, type_priority = 'event', player_priority = 'npc' })

	if main_quest == nil or main_quest.InnerProgress == 0 then
		self:deactivate_rain_effect_and_sound()
	end

	-- 모든 파티원들을 파티에서 제외시키고, 비활성화 함.
	for i = user_party.Count - 1, 1, -1 do
		local party = user_party[i]

		character_util.convert_to_npc(party)
		character_util.set_active_state(party, 'disabled')
	end
end

function local_class:need_on_launch()
	local main_quest_id = 151
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return main_quest ~= nil and not main_quest.IsComplete and main_quest.InnerProgress == 0
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)

		-- 꺼지지 않는 불들 처리하는 코드
		if string.match(e.Zone.Name, 'eternal_fire') then
			CS.Oak.ICombustibleBehaviourExtensions.DefaultBurn(nil, user_party.Leader, e.FieldObject)
		end
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	field:Tint('stage_start', unity_class.color.white, 0)
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.shelter_zone_name
		or zone_name == 'android_teslacoil_zone' then
		if not self.is_enter_shelter then
			self.is_enter_shelter = true

			self:enter_shelter_event()
		end
	end
end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == self.shelter_zone_name
		or zone_name == 'android_teslacoil_zone' then
		if self.is_enter_shelter then
			self.is_enter_shelter = false

			self:leave_shelter_event()
		end
	end
end

function local_class:on_interact_event(e)
	local grave = get_field_object(self.grave_name)

	if lua_helper.reference_equals(e.Target, grave) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_with_grave, self))
	elseif lua_helper.reference_equals(e.Target, self.heavenhold_camera) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_with_camera, self))
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.deactivate_rain_custom_event then
			self:deactivate_rain_effect_and_sound()
		elseif e.Params[0] == self.activate_rain_custom_event then
			self:activate_rain_effect_and_sound()
		end
	end
end

-- 지하 대피소로 들어가면 나오는 이벤트
function local_class:enter_shelter_event()
	-- 배경 제거
	message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 0), 0))

	self:deactivate_rain_effect_and_sound()

	-- 화면 틴트
	field:Tint(self.tint_key, unity_color({0.5, 0.5, 0.5, 1}), 0)
end

-- 지하 대피소를 벗어나면 나오는 이벤트
function local_class:leave_shelter_event()
	-- 배경 켜기
	message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(255, 255, 255, 255), 0))

	self:activate_rain_effect_and_sound()

	-- 틴트 복구
	field:RemoveTint(self.tint_key, 0)
end

-- 소년의 무덤에 Interact하면 나오는 이벤트
function local_class:interact_with_grave()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	stage.FieldUINarrationBox:Show()

	yield_return(stage.FieldUINarrationBox, "SetNarration",
			game_string:GetString('futurecastle_1_1_john_grave'), 0, 1.0)
	yield_return(stage.FieldUINarrationBox, "HideAnimation")

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 부유성 카메라에 Interact하면 나오는 이벤트
function local_class:interact_with_camera()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()
	user_party.Leader.CharacterStatsBehaviour.Immortal = true

	music_player_util.play_sfx_one_shot('01_button_select_item_01')

	local user_pos = user_party_leader.Position
	local user_dir = user_party_leader.Direction

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	-- 부유성 연출 NPC 설정
	local char_spec = CS.Oak.CharacterSpecId
	local has_china_boy = CS.Oak.User.Me:GetCharacter(char_spec.ChinaHeroBoy, true) ~= nil

	self.heavenhold_char_list = create_generic_list(CS.Oak.Character)

	self.heavenhold_char_list:Add(user_party_leader)

	local princess = get_character(self.princess_name)
	self.heavenhold_char_list:Add(princess)

	for i = 1, self.champ_num do
		if i ~= self.china_champ_num then
			self.heavenhold_char_list:Add(get_character(self.champ_name..i))
		else
			if has_china_boy then
				self.heavenhold_char_list:Add(get_character(self.champ_china_male_name))
			else
				self.heavenhold_char_list:Add(get_character(self.champ_china_female_name))
			end
		end
	end

	-- 비 내리는 이펙트, 사운드 제거
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.deactivate_rain_custom_event }))

	-- 부유성 전경 이펙트 로드

	if self.heavenhold_background == nil then
		yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
				self.resholder, 'theatres/heavenhold_theatre', 'heavenhold_theatre', function(prefab)
					self.heavenhold_background = CS.UnityEngine.GameObject.Instantiate(prefab)
					self.heavenhold_background.transform.localPosition = vector(-100, 0, 0)
					self.heavenhold_background.transform.localScale = vector(2, 2, 2)

					-- 배경이 캐릭터 뒤로 가도록 레이어 설정
					CS.Utils.ChangeLayersRecursively(self.heavenhold_background.transform, "Default")

					-- 카메라는 Stage것을 사용할 것이므로 비활성화
					self.heavenhold_background.transform:GetChild(0):GetChild(0).gameObject:SetActive(false)

					local theatre_component = self.heavenhold_background:GetComponentInChildren(typeof(CS.Oak.HeavenholdTheatre))

					theatre_component.fakeObj:SetActive(false)
				end)

		self.inn_obj_list = create_generic_list(CS.Oak.SortingLayer)

		local inn_obj_pos_list = create_generic_list(unity_class.vector3)
		inn_obj_pos_list:Add(vector(-105.6, 0, -8.5))
		inn_obj_pos_list:Add(vector(-111, 0, -9.7))
		inn_obj_pos_list:Add(vector(-113, 0, -8.7))
		inn_obj_pos_list:Add(vector(-110.2, 0, -7))
		inn_obj_pos_list:Add(vector(-108.1, 0, -6))
		inn_obj_pos_list:Add(vector(-102.7, 0, -6.1))
		inn_obj_pos_list:Add(vector(-100.6, 0, -7.1))
		inn_obj_pos_list:Add(vector(-98.5, 0, -8.1))

		inn_obj_pos_list:Add(vector(-104.3, 0, -12.4))
		inn_obj_pos_list:Add(vector(-103.7, 0, -12.1))
		inn_obj_pos_list:Add(vector(-103.1, 0, -11.8))
		inn_obj_pos_list:Add(vector(-108, 0, -11.8))
		inn_obj_pos_list:Add(vector(-107.4, 0, -12.1))
		inn_obj_pos_list:Add(vector(-100.5, 0, -10))
		inn_obj_pos_list:Add(vector(-108.7, 0, -8.5))
		inn_obj_pos_list:Add(vector(-107.6, 0, -10.7))
		inn_obj_pos_list:Add(vector(-104, 0, -10.9))
		inn_obj_pos_list:Add(vector(-106.4, 0, -11.8))
		inn_obj_pos_list:Add(vector(-108.8, 0, -11.3))
		inn_obj_pos_list:Add(vector(-102, 0, -11.1))
		inn_obj_pos_list:Add(vector(-102.1, 0, -8.5))

		local inn_obj_name_list = create_generic_list(CS.System.String)
		inn_obj_name_list:Add('building_landmark_inn_lv1')
		inn_obj_name_list:Add('building_drink_brewery_lv1')
		inn_obj_name_list:Add('building_drink_cafe_lv1')
		inn_obj_name_list:Add('building_entertainment_circus_lv1')
		inn_obj_name_list:Add('building_entertainment_figureshop_lv1')
		inn_obj_name_list:Add('building_food_bakery_lv1')
		inn_obj_name_list:Add('building_food_burgerhouse_lv1')
		inn_obj_name_list:Add('building_food_cakeshop_lv1')

		inn_obj_name_list:Add('obstacle_bush_1')
		inn_obj_name_list:Add('obstacle_bush_1')
		inn_obj_name_list:Add('obstacle_bush_1')
		inn_obj_name_list:Add('obstacle_bush_1')
		inn_obj_name_list:Add('obstacle_bush_1')
		inn_obj_name_list:Add('obstacle_rock_1')
		inn_obj_name_list:Add('obstacle_rock_1')
		inn_obj_name_list:Add('obstacle_smalllawn2')
		inn_obj_name_list:Add('obstacle_smalllawn2')
		inn_obj_name_list:Add('obstacle_smalllawn2')
		inn_obj_name_list:Add('obstacle_smalllawn_2')
		inn_obj_name_list:Add('obstacle_smalllawn_2')
		inn_obj_name_list:Add('obstacle_tree_1')

		yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
				self.resholder, 'theatres/heavenhold_theatre', 'theatre_take_picture', function(prefab)
					self.theatre_take_picture = CS.UnityEngine.GameObject.Instantiate(prefab)
					self.theatre_take_picture.transform.localPosition = self.heavenhold_background.transform.localPosition
					self.theatre_take_picture.transform.localScale = vector(2, 2, 2)


					-- 배경이 캐릭터 뒤로 가도록 레이어 설정
					CS.Utils.ChangeLayersRecursively(self.theatre_take_picture.transform, "Default")

					local children = self.theatre_take_picture.transform:GetComponentsInChildren(typeof(CS.Oak.SortingLayer))

					for i = 0, children.Length - 1 do
						local child = children[i]

						self.inn_obj_list:Add(child)
					end

					-- SortingLayer 가 없는 bird(새) 이미지는 따로 묻히지 않게 SortingOrder를 건물 배경보다 높게 설정.
					local root = self.theatre_take_picture.transform:GetChild(0)
					local custom_sprite_list = root:GetChild(0):GetComponentsInChildren(typeof(CS.CustomSprite))
					for i = 0, custom_sprite_list.Length - 1 do
						local custom_sprite = custom_sprite_list[i]
						custom_sprite.SortingOrder = 11
						custom_sprite:Rebuild()
					end
				end)
	else
		self.heavenhold_background:SetActive(true)
	end

	camera_util.move_async(vector(-105.6, 0, -9.5), 0)
	camera_util.resize_to(3, 0)

	-- 부유성 연출 NPC 설정
	local heavenhold_char_pos_list = create_generic_list(unity_class.vector3)
	heavenhold_char_pos_list:Add(vector(-105.6, 0, -10))
	heavenhold_char_pos_list:Add(vector(-104.9, 0, -10))
	heavenhold_char_pos_list:Add(vector(-106.5, 0, -10))
	heavenhold_char_pos_list:Add(vector(-104.2, 0, -10))
	heavenhold_char_pos_list:Add(vector(-107.5, 0, -10))
	heavenhold_char_pos_list:Add(vector(-108.3, 0, -10))
	heavenhold_char_pos_list:Add(vector(-103.2, 0, -10))
	heavenhold_char_pos_list:Add(vector(-102.2, 0, -10))

	for i = 0, self.heavenhold_char_list.Count - 1 do
		field_ui_manager:RemoveUI(self.heavenhold_char_list[i], CS.Oak.FieldUiType.CharacterStats)
		self.heavenhold_char_list[i].SpineController:SetSortingLayer("Default", 1)
		self.heavenhold_char_list[i]:HideWeapon(true)

		character_util.set_position(self.heavenhold_char_list[i], heavenhold_char_pos_list[i])
		character_util.set_direction(self.heavenhold_char_list[i], 'down')
		character_util.set_anim(self.heavenhold_char_list[i], { name = 'idle', loop = false })
		character_util.set_emotion(self.heavenhold_char_list[i], { name = 'smile' })

		if i ~= 0 then
			self.heavenhold_char_list[i].CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		end
	end

	self.heavenhold_camera.SpineController:SetSortingLayer("Default", 1)
	character_util.set_position(self.heavenhold_camera, vector(-105.6, 0, -12.5))
	character_util.set_direction(self.heavenhold_camera, 'up')
	character_util.set_anim(self.heavenhold_camera, { name = 'idle', loop = false })

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	wait_for_sec(2.5)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	camera_util.move_async(vector(-104, 0, -7.5), 0)
	camera_util.resize_to(3, 0)

	-- 공주 사진 추가
	for i = 0, self.heavenhold_char_list.Count - 1 do
		if i == 1 then
			character_util.set_position(self.heavenhold_char_list[i], vector(-104, 0, -7.5))
			character_util.set_direction(self.heavenhold_char_list[i], 'left')
			character_util.set_anim(self.heavenhold_char_list[i], { name = 'eat', loop = false })
			character_util.remove_emotion(self.heavenhold_char_list[i])
		elseif i == 2 then
			character_util.set_position(self.heavenhold_char_list[i], vector(-102, 0, -8.5))
			character_util.set_direction(self.heavenhold_char_list[i], 'right')
			character_util.set_anim(self.heavenhold_char_list[i], { name = 'walk', loop = false })
			character_util.remove_emotion(self.heavenhold_char_list[i])
		elseif i == 3 then
			character_util.set_position(self.heavenhold_char_list[i], vector(-103, 0, -9.5))
			character_util.set_direction(self.heavenhold_char_list[i], 'left')
			character_util.set_anim(self.heavenhold_char_list[i], { name = 'walk', loop = false })
			character_util.remove_emotion(self.heavenhold_char_list[i])
		elseif i == 6 then
			character_util.set_position(self.heavenhold_char_list[i], vector(-106.5, 0, -10))
			character_util.set_direction(self.heavenhold_char_list[i], 'right')
			character_util.set_anim(self.heavenhold_char_list[i], { name = 'walk', loop = false })
			character_util.remove_emotion(self.heavenhold_char_list[i])
		elseif i == 7 then
			character_util.set_position(self.heavenhold_char_list[i], vector(-107.5, 0, -8))
			character_util.set_direction(self.heavenhold_char_list[i], 'left')
			character_util.set_anim(self.heavenhold_char_list[i], { name = 'walk', loop = false })
			character_util.remove_emotion(self.heavenhold_char_list[i])
		else
			character_util.set_position(self.heavenhold_char_list[i], vector(999, 0, 999))
		end
	end

	self.heavenhold_char_list[0].SpineController:SetSortingLayer("Default", 0)

	self.heavenhold_camera.SpineController:SetSortingLayer("Default", 0)
	character_util.set_position(self.heavenhold_camera, vector(96, 0, -36))
	character_util.set_direction(self.heavenhold_camera, 'right')
	character_util.remove_anim(self.heavenhold_camera)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	wait_for_sec(2.5)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	-- 비 내리는 이펙트, 사운드 제거
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.activate_rain_custom_event }))

	-- 부유성 전경 화면 종료
	self.heavenhold_background:SetActive(false)

	stage_camera:SetTarget(user_party_leader)
	camera_util.resize_to_default(0)

	user_party_leader:HideWeapon(false)
	character_util.set_position(user_party_leader, user_pos)
	character_util.set_direction(user_party_leader, user_dir)
	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	user_party.Leader.CharacterStatsBehaviour.Immortal = false
	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 비 이펙트, 사운드 제거
function local_class:deactivate_rain_effect_and_sound()
	-- 이펙트 비활성화
	self.rain_screen_effect:SetActive(false)
	self.rain_ground_effect:SetActive(false)

	-- 사운드 페이드 아웃
	self.rain_sfx:Stop()
end

-- 비 이펙트, 사운드 활성화
function local_class:activate_rain_effect_and_sound()
	-- 이펙트 활성화
	self.rain_screen_effect:SetActive(true)
	self.rain_ground_effect:SetActive(true)

	-- 사운드 재생
	self.rain_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_rain_loop_01', loop = true, fade_in_time = 2, type_priority = 'event', player_priority = 'npc' })
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if self.rain_screen_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.rain_screen_effect)
		self.rain_screen_effect = nil
	end

	if self.rain_ground_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.rain_ground_effect)
		self.rain_ground_effect = nil
	end

	if self.heavenhold_background ~= nil then
		CS.UnityEngine.Object.Destroy(self.heavenhold_background)
		self.heavenhold_background = nil
	end

	if self.inn_obj_list ~= nil then
		self.inn_obj_list = nil
	end

	if self.rain_sfx ~= nil then
		self.rain_sfx:Stop()
		self.rain_sfx = nil
	end

	if self.resholder ~= nil then
		self.resholder:Dispose()
	end

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
