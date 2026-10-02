local local_class = newclass("Halloween")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.halloween_loop_quest_id = 7000104

	-- 아이템 스펙 이름
	self.item_spec_name = 'candy'

	self.get_knight = function()
		if not is_unity_null(CS.Oak.User.Me:GetCharacter(2, true)) then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end
	self.get_princess = function() return get_character('princess') end
	self.get_pumpkin_kid = function() return get_character('pumpkin_kid') end
	self.get_shyapira = function() return get_character('bystander_3_1') end
	self.get_ishya = function() return get_character('bystander_3_2') end
	self.get_gamble_kid = function() return get_character('gamble_kid') end
	self.get_card = function(num) return get_character('card_' .. num) end

	-- 오브젝트를 가져오는 함수
	self.get_house_door = function(num) return get_field_object('house_' .. num .. '_in') end

	self.cached_colors = {}

	self.room_grid_names = {'ShellGameRoom', 'BasketCatchGameRoom', 'RedGreenGameRoom'}

	self.candy_list = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_cam_grid_enter')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	local start_marker = field:GetMarker('default_start')
	local knight = self.get_knight()
	knight.Position = start_marker.position
	knight.Direction = start_marker.direction

	local pumpkin_kid = self.get_pumpkin_kid()
	character_util.set_anim(pumpkin_kid, { name = '[skin]pumpkin', upper = true })

	for i = 1, 2 do
		local card = self.get_card(i)
		card:SetGiantFactor('mini', 0.5)
		field_ui_manager:RemoveUI(card, CS.Oak.FieldUiType.CharacterStats)
	end

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = true
	character_util.convert_to_manual_character(knight, param)

	local halloween_loop_quest = user_progress:GetStartedQuest(self.halloween_loop_quest_id)
	if halloween_loop_quest ~= nil and halloween_loop_quest.IsComplete then
		party_util.add_member(pumpkin_kid)
		pumpkin_kid.Direction = CS.Oak.Direction.Right
	elseif halloween_loop_quest ~= nil and halloween_loop_quest.InnerProgress < 1 then
		party_util.add_member(self.get_princess())
	end

	-- 퀘스트를 클리어 했을 때(섹션 2 이상일 떄) 외에는 4번째 집 문이 열리지 않게
	if halloween_loop_quest ~= nil and halloween_loop_quest.InnerProgress ~= 1 and not halloween_loop_quest.IsComplete then
		local house_door = self.get_house_door(4)
		house_door.Interactable = CS.Oak.PublishInteractable.Create()
	end

	local princess = self.get_princess()
	local start_marker = field:GetMarker('default_start')
	user_party.Leader.Position = start_marker.position

	if quest_util.get_custom_state(halloween_loop_quest, 'is_loop') <= 0 then
		user_party.Leader.Direction = character_util.get_direction('left')
		character_util.look_at(princess, user_party.Leader)
	end

	music_player_util.play_stage_music({ state = 'field' })

	if halloween_loop_quest ~= nil and (halloween_loop_quest.InnerProgress >= 1 or halloween_loop_quest.IsComplete) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(stage_launch_util.default_launch_with_marker_name, 'default_start'))
	elseif quest_util.get_custom_state(halloween_loop_quest, 'is_loop') > 0 then
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular_async(1, CS.Oak.Interpolations.Linear)

		party_util.reset_controllers()
		field_ui_manager:Show()

		-- is_loop가 0인경우에는 할로윈 루프 이벤트에서 인트로 처리
	elseif quest_util.get_custom_state(halloween_loop_quest, 'is_loop') <= 0 then
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular_async(1, CS.Oak.Interpolations.Linear)
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(stage_launch_util.default_launch_with_marker_name, 'default_start'))
	end

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)

	return false
end

function local_class:on_stage_loaded_event(_)
	local layer = stage.StageGameObject.transform:Find(stage.Name .. '/light_objects/')
	if is_unity_null(layer) then return end

	local renderers = layer:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))

	for i = 0, renderers.Length - 1 do
		local renderer = renderers[i]

		local color
		if renderer.sharedMaterial:HasProperty("_Color") then
			color = renderer.sharedMaterial:GetColor("_Color")
		elseif renderer.sharedMaterial:HasProperty("_TintColor") then
			color = renderer.sharedMaterial:GetColor("_TintColor")
		else
			CS.UnityEngine.Debug.LogError('can not found light color')
		end
		table.insert(self.cached_colors, color)
	end

	-- 마지막 루프가 아닐 때, 길거리의 npc들 세팅
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.group_3_patrol, self))

	-- 도박 꼬마 근처에 캔디를 쌓아놓는다.
	local gamble_kid = self.get_gamble_kid()
	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(self.item_spec_name).Id

	self.candy_list = {}

	local candy_position_list = {
		vector(-0.3, 0, 0.5),
		vector(0.25, 0, 0.37),
		vector(0.55, 0, 0.2),
		vector(0.4, 0, -0.3),
		vector(0.1, 0, 0.45)
	}
	for i = 1, #candy_position_list do
		local candy = drop_item_util.create_item({ pos = gamble_kid.Position + candy_position_list[i], itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' })
		table.insert(self.candy_list, candy)
	end

	return false
end

function local_class:on_cam_grid_enter(e)
	if type_util.is_player_enter_to_cam_grid(e, self.room_grid_names) then
		self:restore_light_objs_color()
	end

	return false
end

-- 마지막 루프인지 아닌지, 조건 체크
function local_class:is_final_loop(quest_progress)
	return quest_progress ~= nil and quest_util.get_custom_state(quest_progress, 'loop_count') == 3 and quest_progress.InnerProgress < 1 and not quest_progress.IsComplete
end

--- 불빛이 있는 물체들을 원래 색깔로 돌려줌.
function local_class:restore_light_objs_color()
	local layer = stage.StageGameObject.transform:Find(stage.Name .. '/light_objects/')
	if is_unity_null(layer) then return end

	local renderers = layer:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))

	for i = 0, renderers.Length - 1 do
		local renderer = renderers[i]
		renderer.sharedMaterial = CS.UnityEngine.Material(renderer.sharedMaterial)

		if renderer.sharedMaterial:HasProperty("_Color") then
			renderer.sharedMaterial:SetColor("_Color", self.cached_colors[i + 1])
		elseif renderer.sharedMaterial:HasProperty("_TintColor") then
			renderer.sharedMaterial:SetColor("_TintColor", self.cached_colors[i + 1])
		end
	end
end

-- 그룹3 샤피라와 아이샤 패트롤 대화
function local_class:group_3_patrol()
	local shyapira = self.get_shyapira()
	local ishya = self.get_ishya()
	local progress = 0
	local waiting_for_interact = function()
		while lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) do
			coroutine.yield()
		end
	end

	while true do
		-- 리더가 CharacterControllerScreenplayState 상태로 이벤트 연출을 보고 있는 중이라면, 끝날 때 까지 기다린다.
		waiting_for_interact()

		if progress == 0 then
			character_util.move_waypoint(shyapira, shyapira.Position + vector(3, 0, 0), 2, false)
			character_util.move_waypoint_async(ishya, ishya.Position + vector(3, 0, 0), 2, false)
		elseif progress == 1 then
			-- 화, 황녀님… 전 호위 자격으로 따라다니는 겁니다만, 꼭 이런 차림일 필요가…
			character_util.look_at(ishya, shyapira)
			speech_bubble_util.show_speech_bubble_async(shyapira, { key = 'halloween_bystander_3_1' })
		elseif progress == 2 then
			-- 샤피라, 백성들과 교류하는 것도 중요한 일이야. 업무의 일부라고 생각하도록.
			speech_bubble_util.show_speech_bubble_async(ishya, { key = 'halloween_bystander_3_2' })
		elseif progress == 3 then
			character_util.move_waypoint(shyapira, shyapira.Position + vector(4, 0, 0), 2, false)
			character_util.move_waypoint_async(ishya, ishya.Position + vector(4, 0, 0), 2, false)
		elseif progress == 4 then
			-- 확실히, 이 날을 기다려온 사람들이 많은 것 같군.
			character_util.set_anim(ishya, { name = 'question', loop = false })
			speech_bubble_util.show_speech_bubble_async(ishya, { key = 'halloween_bystander_3_3' })
		elseif progress == 5 then
			character_util.remove_anim(ishya)
			character_util.move_waypoint_async(ishya, shyapira.Position + vector(-1, 0, 0), 2, false)
		elseif progress == 6 then
			character_util.move_waypoint(shyapira, vector(23, 0, -1), 2, false)
			character_util.move_waypoint_async(ishya, vector(22, 0, -1), 2, false)
		elseif progress == 7 then
			-- 황녀님, 역시 이런 차림으로는 호위가…
			speech_bubble_util.show_speech_bubble_async(shyapira, { key = 'halloween_bystander_3_4' })
		elseif progress == 8 then
			character_util.move_waypoint_async(ishya, vector(24, 0, -1), 2, false)
		elseif progress == 9 then
			-- 이제 그만. 그 이야기는 더 듣지 않겠다.
			character_util.look_at(shyapira, ishya)
			speech_bubble_util.show_speech_bubble_async(ishya, { key = 'halloween_bystander_3_5' })
			wait_for_sec(2)
		end

		progress = (progress + 1) % 10
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	if self.candy_list ~= nil then
		for i = 1, #self.candy_list do
			self.candy_list[i]:ConsumeComplete()
		end
		self.candy_list = nil
	end

	self.cached_colors = nil
	self.room_grid_names = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
