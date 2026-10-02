local local_class = newclass("HighSchool1At3Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.iron_teatan_head = nil
	self.iron_teatan_body = nil

	-- 스타피스 숨김 이펙트 이름
	self.sp_hidden_effect_name = 'FX_starpiece_in_character'

	self.hallway_starpiece_name = 'hallwayA_starpiece'
	self.iron_teatan_starpiece_name = 'iron_teatan_starpiece'

	self:sheldon_event_init()
	self:iron_teatan_starpiece_event_init()
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:need_on_launch()
	local main_quest = user_progress:GetStartedQuest(60001)
	return main_quest ~= nil and main_quest.InnerProgress >= 10 and main_quest.InnerProgress <= 12
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:stage_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GuildCastleSitEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')

	self:agency_iron_teatan_parts_load()

	unity_object_pool.GetOrCreate(self.smoke_effect_name)
	unity_object_pool.GetOrCreate(self.explode_effect_name)

	local starpiece_pool = unity_object_pool.GetOrCreate(self.sp_hidden_effect_name)
	while (starpiece_pool.State ~= CS.Oak.UnityObjectPoolState.Loaded) do
		coroutine.yield(nil)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GuildCastleSitEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self:agency_iron_teatan_parts_dispose()
	self:iron_teatan_starpiece_event_dispose()
	self:sheldon_event_dispose()
	self:hallway_starpiece_dispose()

	self.cs_controller = nil
end


function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:iron_teatan_starpiece_event_setting()
		self:sheldon_event_setting()
		self:hallway_starpiece_setting()
	end

	if event_type == typeof(CS.Oak.InteractEvent) then

		local painful_insider = get_character('painful_insider')
		local nerd_convert_npc = get_character('convert_to_nerd_npc')

		if lua_helper.reference_equals(e.Target, self.iron_teatan_body) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.try_to_open_cockpit_event, self))
		elseif lua_helper.reference_equals(e.Target, painful_insider) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.insider_convert_nerd, self))
		elseif lua_helper.reference_equals(e.Target, nerd_convert_npc) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ask_convert_to_nerd, self))
		end
	end

	-- TODO: 길드성 전용 의자와 똑같은 기능을 보여줘야했기때문에 현재 길드성 전용 의자 비헤비어와 스테이트를 일단 그대로 가져다 쓰고있음.
	-- TODO: 기능상 문제는 없지만 Emoji관련 코드때문에 우려가 되는 부분이 있기때문에 추후 범용적으로 사용할 로컬 스테이트를 만들지 고려가 필요함.
	if event_type == typeof(CS.Oak.GuildCastleSitEvent) then
		if e.IsSittingOn == true then
			self.sitting = false
			local sc = CS.Oak.StateChangeEvent.Create(CS.Oak.CharacterControllerSitState.Create(user_party.Leader, e.Chair, nil))
			message_system:SendSync(user_party.Leader.FieldObjectController, sc)

			-- 쉘든의 의자라면 쉘든 이벤트 진행
			local sheldon_chair = get_field_object('sheldon_chair')
			if (lua_helper.reference_equals(sheldon_chair, e.Chair)) and self.sheldon_current_state == self.sheldon_state.none then
				self.sitting = true
				self.sheldon_routine = coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.sheldon_chair_event, self))
			end
		else
			local is_sitting = user_party.Leader.FieldObjectController.CurrentState ~= nil and
					lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerSitState)
			if is_sitting == true and not self.sitting then
				user_party.Leader.FieldObjectController.CurrentState:FinishSitState()
			end

			local sheldon_chair = get_field_object('sheldon_chair')
			if lua_helper.reference_equals(sheldon_chair, e.Chair) and self.sheldon_current_state == self.sheldon_state.angry and not self.sitting then
				stop_coroutine(self.sheldon_routine)
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sheldon_sit_chair, self))
			end
		end
	end

	if event_type == typeof(CS.Oak.CameraGridEnterEvent) then
		local sheldon = get_character('sheldon')
		if e.CameraGrid:Contains(sheldon.Position) and self.sheldon_current_state ~= self.sheldon_state.explode then
			self:reset_sheldon_event()
		end
	end

	if event_type == typeof(CS.Oak.SwitchOnOffEvent) then
		if not self.appeared_hallway_starpiece and self:check_hallWay_starpiece_condition() == true then
			self.appeared_hallway_starpiece = true
			sp_util.play_normal_screenplay(self.hallway_starpiece_appear_event, self)
		end
	end

	if event_type == typeof(CS.Oak.BattleStartEvent) then
		-- 너드화된 상태에서 전투에 들어가면 너드화를 풀어준다.
		if lua_helper.reference_equals(user_party.Leader, get_character('nerd_leader')) then
			self:restore_origin_party()
		end
	end

	return false
end

-- 복도A 스타피스 이벤트 세팅
function local_class:hallway_starpiece_setting()
	self.appeared_hallway_starpiece = false
	local signBoard = get_field_object('hallwayA_starpiece_signboard')
	local target_pos = signBoard.Position + unity_class.vector3.back * 0.2 + unity_class.vector3.up
	if not stage_progress:HasStarPiece(self.hallway_starpiece_name) then
		self.hallway_hidden_effect = unity_object_pool.GetOrCreate(self.sp_hidden_effect_name):Instantiate(target_pos)
	end
end

function local_class:hallway_starpiece_appear_event()
	local signBoard = get_field_object('hallwayA_starpiece_signboard')
	local star_piece = get_field_object(self.hallway_starpiece_name)

	camera_util.move_async(star_piece.Position, 1)

	self.hallway_hidden_effect:Dispose()
	self.hallway_hidden_effect = nil

	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(signBoard.Position + unity_class.vector3.up, false))
	coroutine.yield(coroutine_class.wait_for_sec(2))

	camera_util.move_async(user_party.Leader.Position, 1, {end_target = user_party.Leader})
end

-- 복도A 스타피스 이벤트 자원 해제
function local_class:hallway_starpiece_dispose()
	if self.hallway_hidden_effect ~= nil then
		self.hallway_hidden_effect:Dispose()
	end

	self.hallway_hidden_effect = nil
end

-- 전시용 아이언 티탄 파츠들 로드
function local_class:agency_iron_teatan_parts_load()
	self.res_holder = CS.Foundations.ResourceHolder()
	self.parts_go = {}
	self.parts_vfo = {}

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder, "theatres/iron_teatans_head", "iron_teatans_head", function(prefab)
		local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
		self.iron_teatan_head = obj:AddComponent(typeof(CS.Oak.IronTeatansHead))
		self.iron_teatan_head.Name = 'iron_teatan_head'
		self.iron_teatan_head.Holdable = CS.Oak.Holdable()
		self.iron_teatan_head.Holdable.BounceSfxHandleName = '01_bounce_iron_02'
		self.iron_teatan_head.FieldObjectBehaviour = CS.Oak.HoldableObjectBehaviour()
		self.iron_teatan_head.CrashBehaviour = CS.Oak.PortableCrashBehaviour()
		self.iron_teatan_head.ActiveState = active_state('enabled')
		self.iron_teatan_head.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1.5, 1, 1.5))
		self.iron_teatan_head.Owner = CS.Oak.Player.Local
		self.iron_teatan_head:Init()
		self.iron_teatan_head.Position = vector(20, 0, 5)
		self.iron_teatan_head:SetRockDestructionMode()
		self.iron_teatan_head.Transform:GetChild('iron_teatans_head').localRotation = unity_class.quaternion.Euler(0, 180, 0)
		message_system:Publish(CS.Oak.AddFieldObjectEvent.Create(self.iron_teatan_head))
		self.parts_go[#self.parts_go + 1] = obj
	end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder, "characters/iron_teatans_arm", "iron_teatans_arm", function(prefab)
		local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
		obj.name = 'iron_teatan_left_arm'
		obj.transform.position = vector(14, 0.4, 10.5)
		local mesh = CS.Utils.FindChildRecursively(obj.transform, 'mesh')
		mesh.transform.rotation = unity_class.quaternion.Euler(0, -90, 0)
		local vfo = CS.Oak.VirtualFieldObject()
		vfo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		vfo.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(4, 1, 1.7))
		vfo.Position = vector_util.get_x0z(obj.transform.position)
		message_system:Publish(CS.Oak.AddFieldObjectEvent.Create(vfo))
		self.parts_vfo[#self.parts_vfo + 1] = vfo
		self.parts_go[#self.parts_go + 1] = obj
	end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder, "characters/iron_teatans_arm", "iron_teatans_arm", function(prefab)
		local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
		obj.name = 'iron_teatan_right_arm'
		obj.transform.position = vector(19, 0.4, 10.7)
		local mesh = CS.Utils.FindChildRecursively(obj.transform, 'mesh')
		mesh.transform.rotation = unity_class.quaternion.Euler(0, 90, 0)
		local vfo = CS.Oak.VirtualFieldObject()
		vfo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		vfo.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(4, 1, 1.7))
		vfo.Position = vector_util.get_x0z(obj.transform.position)
		message_system:Publish(CS.Oak.AddFieldObjectEvent.Create(vfo))
		self.parts_vfo[#self.parts_vfo + 1] = vfo
		self.parts_go[#self.parts_go + 1] = obj
	end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder, "characters/iron_teatans_body", "iron_teatans_body", function(prefab)
		local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
		obj.name = 'iron_teatan_body'
		obj.transform.position = vector(12.5, 0, 5)
		local mesh = CS.Utils.FindChildRecursively(obj.transform, 'mesh')
		mesh.transform.localPosition = vector(-0.9, 1.8, 0)
		mesh.transform.rotation = unity_class.quaternion.Euler(-50, 90, 180)
		local vfo = CS.Oak.VirtualFieldObject()
		vfo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		vfo.Interactable = CS.Oak.PublishInteractable.Create()
		vfo.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(2.25, 1, 2.25))
		vfo.Position = vector(13, 0, 5)
		message_system:Publish(CS.Oak.AddFieldObjectEvent.Create(vfo))
		self.iron_teatan_body = vfo
		self.parts_vfo[#self.parts_vfo + 1] = vfo
		self.parts_go[#self.parts_go + 1] = obj
	end)
end

-- 전시용 아이언 티탄 파츠 자원 해제
function local_class:agency_iron_teatan_parts_dispose()
	for _, vfo in ipairs(self.parts_vfo) do
		vfo:Dispose()
	end

	for _, go in ipairs(self.parts_go) do
		CS.UnityEngine.GameObject.Destroy(go)
	end

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end

	self.res_holder = nil
	self.iron_teatan_head = nil
	self.iron_teatan_body = nil
end

function local_class:iron_teatan_starpiece_event_init()
	self.smoke_effect_name = 'FX_Chapter6_PoisonSmoke'
	self.nerd_gas_duration = 30
	self.explode_effect_name = 'FX_dead'
	self.cockpit_starpiece_effect = nil
end

-- 아이언티탄 몸통 스타피스 이벤트 세팅 함수
function local_class:iron_teatan_starpiece_event_setting()
	if stage_progress:HasStarPiece(self.iron_teatan_starpiece_name) then
		self.iron_teatan_body.Interactable = CS.Oak.NonInteractable.Instance

		local disable_npcs = {
			get_character('painful_insider'),
			get_character('convert_to_nerd_npc')
		}
		for _, npc in ipairs(disable_npcs) do
			npc.ActiveState = active_state('disabled')
		end
	else
		-- 콕핏 부분에 스타피스 이펙트 붙여줌.
		local effect_pool = unity_object_pool.GetOrCreate(self.sp_hidden_effect_name)
		self.cockpit_starpiece_effect = effect_pool:Instantiate(vector(11.8, 2, 4.8))

		local painful_insider = get_character('painful_insider')
		painful_insider.Interactable:AddListener(self.cs_controller)
	end
end

-- 아이언티탄 바디에 상호작용할때마다 불리는 이벤트
function local_class:try_to_open_cockpit_event()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	-- 콕핏에 스타피스가 있다
	field_ui_util.show_narration_async({ key = 'find_cockpit_starpiece'})

	if user_party.Leader.Direction == CS.Oak.Direction.Up or user_party.Leader.Direction == CS.Oak.Direction.Down then
		user_party_leader.Direction = CS.Oak.Direction.Right
	end

	local search_sfx = music_player_util.play_sfx({
		sfx_name = '01_clang_01', loop = true, type_priority = 'loop'
	})

	user_party.Leader:SetAnimation('eat', true)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	search_sfx:FadeOut(0.2)

	user_party.Leader:RemoveAnimation()

	-- 콕핏은 복잡한 자물쇠로 잠겨있다.. OR 복잡한 자물쇠 구조가 어린이 퍼즐처럼 느껴진다!
	local is_nerd = lua_helper.reference_equals(user_party.Leader, get_character('nerd_leader'))
	field_ui_util.show_narration_async({ key = is_nerd == true and "cockpit_can_open" or "cockpit_cannot_open"})

	if is_nerd then
		self.iron_teatan_body.Interactable = CS.Oak.NonInteractable.Instance
		self.cockpit_starpiece_effect:Dispose()
		self.cockpit_starpiece_effect = nil

		local star_piece = get_field_object('iron_teatan_starpiece')
		message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(
				vector(11.8, 0.5, 4.7), false))
		coroutine.yield(coroutine_class.wait_for_sec(2))
	end

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:iron_teatan_starpiece_event_dispose()
	if self.cockpit_starpiece_effect ~= nil then
		self.cockpit_starpiece_effect:Dispose()
	end

	self.cockpit_starpiece_effect = nil
end

function local_class:sheldon_event_init()
	self.sheldon_state = {
		none = 1,
		angry = 2,
		sit = 3,
		explode = 4
	}
	self.sheldon_current_state = self.sheldon_state.none
	self.sheldon_routine = nil
	self.sheldon_origin_pos = nil
	self.sheldon_starpiece_name = 'sheldon_starpiece'
end

function local_class:sheldon_event_setting()
	if stage_progress:HasStarPiece(self.sheldon_starpiece_name) then
		local disable_npcs = {
			get_character('sheldon'),
			get_character('sheldon_audience_1'),
			get_character('sheldon_audience_2'),
			get_character('sheldon_audience_3'),
			get_character('sheldon_audience_4')
		}

		for _, npc in ipairs(disable_npcs) do
			npc.ActiveState = active_state('disabled')
		end

		self.sheldon_current_state = self.sheldon_state.explode
	else
		self.sheldon_origin_pos = get_character('sheldon').Position
	end
end

function local_class:sheldon_event_dispose()
	if self.sheldon_routine ~= nil then
		stop_coroutine(self.sheldon_routine)
	end

	self.sheldon_routine = nil
end

-- 복도의 스타피스 조건이 만족했는지 확인해주는 함수
function local_class:check_hallWay_starpiece_condition()
	local switchs = {
		get_field_object('door1_switch_1'),
		get_field_object('door1_switch_2'),
		get_field_object('door1_switch_3'),
		get_field_object('door1_switch_4')
	}
	local conditions = { true, false, true, true}

	local satisfied = true
	for i, switch in ipairs(switchs) do
		if switch.FieldObjectBehaviour.IsPressed ~= conditions[i] then
			satisfied = false
		end
	end

	return not stage_progress:HasStarPiece(self.hallway_starpiece_name) and satisfied
end

function local_class:reset_sheldon_event()
	self.sheldon_current_state = self.sheldon_state.none

	local sheldon = get_character('sheldon')
	sheldon.Position = self.sheldon_origin_pos
	sheldon.Direction = character_util.get_direction('left')
	sheldon:SetEmotion('idle', true)
	sheldon:SetAnimation('seat', true)
	sheldon.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

	local sheldon_chair = get_field_object('sheldon_chair')
	sheldon_chair.Interactable = CS.Oak.Interactable()
end

function local_class:sheldon_chair_event()
	self.sheldon_current_state = self.sheldon_state.angry

	local sheldon = get_character('sheldon')
	sheldon.Direction = character_util.get_direction('up')
	sheldon.SpineController:SetSortingLayer(nil, 1)

	music_player:PlaySfxOneShot('01_small_jump_01')

	sheldon:RemoveAnimation()
	sheldon:Jump(0.7, 0.25)
	character_util.move_to_async(sheldon, vector_util.get_x0z(sheldon.Position) + unity_class.vector3.forward, 0.25)

	wp_util.move_way_points_async(
			sheldon, { waypoints = vector(35.5, 0, 54), speed = 6, run = true, play_sfx = true })

	self.sitting = false

	-- 너 지금 내 자리에 앉아있어.
	sheldon.Direction = character_util.get_direction('right')
	speech_bubble_util.show_speech_bubble_async(sheldon, {key = 'sheldon_starpiece_1'})

	coroutine.yield(coroutine_class.wait_for_sec(1))


	-- 거긴 내 자리야!!
	sheldon:SetEmotion('attack', true)
	sheldon:SetAnimation('release', true)
	character_util.add_animation_sfx(sheldon, '01_swing_01')
	speech_bubble_util.show_speech_bubble_async(sheldon, {key = 'sheldon_starpiece_2'})
	sheldon:RemoveAnimation()

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 그 자리는 여름에는 동쪽과 서쪽의 창문의 바람이 만나는 훌륭한 자리임과 동시에
	sheldon:SetAnimation('release', true)
	character_util.add_animation_sfx(sheldon, '01_swing_01')
	speech_bubble_util.show_speech_bubble_async(sheldon, {key = 'sheldon_starpiece_2_1'})

	-- 겨울에는 라디에이터와의 거리가 적절해 따뜻하기까지 하지.
	speech_bubble_util.show_speech_bubble_async(sheldon, {key = 'sheldon_starpiece_2_1_1'})

	-- 만약 내 삶을 4차원 좌표계로 표현한다면 그 자리가 바로 (0,0,0,0)이야
	sheldon:SetEmotion('doyagao', true)
	sheldon:SetAnimation('cross_arm', false)
	speech_bubble_util.show_speech_bubble_async(sheldon, {key = 'sheldon_starpiece_2_2'})

	coroutine.yield(coroutine_class.wait_for_sec(1))
	sheldon:RemoveAnimation()

	wp_util.move_way_points_async(sheldon, {waypoints = {vector(34, 0, 54), vector(34, 0, 56), vector(37, 0, 56)},
											speed = 7.5, run = true, play_sfx = true })

	music_player:PlaySfxOneShot('03_dialogue_negative_01')

	-- 거긴 내 자리라니까!!!
	camera_util.shake(0.4, 0.3)
	sheldon.Direction = character_util.get_direction('right')
	sheldon:SetEmotion('mad', true)
	character_util.normal_double_jump(sheldon, true)
	speech_bubble_util.show_speech_bubble_async(sheldon, {key = 'sheldon_starpiece_3', bubble_type = 'shout'})

	-- 으…
	speech_bubble_util.show_speech_bubble(sheldon, {key = 'sheldon_starpiece_3_1'})
	sheldon:SetEmotion('tired', true)
	wp_util.move_way_points_async(sheldon, {waypoints = sheldon.Position + unity_class.vector3.left * 2, speed = 2 })
	coroutine.yield(coroutine_class.wait_for_sec(0.5))
	wp_util.move_way_points_async(sheldon, {waypoints = sheldon.Position + unity_class.vector3.right * 2, speed = 2 })

	-- 으으으…
	speech_bubble_util.show_speech_bubble(sheldon, { key = 'sheldon_starpiece_3_2' })
	wp_util.move_way_points_async(sheldon, {
		waypoints = {vector(39, 0, 56), vector(39, 0, 54), vector(34, 0, 54) },
		speed = 4,
		play_sfx = true
	})
	sheldon:SetAnimation('question', false)
	coroutine.yield(coroutine_class.wait_for_sec(1))
	sheldon:RemoveAnimation()
	wp_util.move_way_points_async(sheldon, { waypoints = vector(36, 0, 54), speed = 4 })

	self.sheldon_current_state = self.sheldon_state.explode

	music_player:PlaySfxOneShot('01_asmodian_attack_01')
	music_player:PlaySfxOneShot('03_runaway_01')

	-- 으아아아아아아!!!!!
	sheldon.Direction = character_util.get_direction('down')
	sheldon:SetEmotion('mad', true)
	character_util.set_anim(sheldon, {name = 'embarrassed', scale = 2})
	speech_bubble_util.show_speech_bubble_async(sheldon, { key = 'sheldon_starpiece_4' })

	music_player:PlaySfxOneShot('02_explosion_01')

	unity_object_pool.GetOrCreate(self.explode_effect_name):Instantiate(vector_util.get_x0z(sheldon.Position, 0.5))
	sheldon:SetAnimation('explosion_dead', false)

	local star_piece = get_field_object('sheldon_starpiece')
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(sheldon.Position))
	coroutine.yield(coroutine_class.wait_for_sec(1))

	local audience_wps = {
		{ vector(33, 0, 54), vector(37, 0, 54) },
		{ vector(37, 0, 57), vector(37, 0, 56) },
		vector(38, 0, 56),
		{ vector(40, 0, 55), vector(39, 0, 55) }
	}

	-- SOUND: 뛰는소리 넣어도될거같기도 하고 안넣어도 될거같기도 하고 애매함.
	local wait_routines = {}
	for i, wp in ipairs(audience_wps) do
		local audience = get_character('sheldon_audience_' .. i)
		audience.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		wait_routines[i] = util.cs_generator(wp_util.move_way_points_async, audience, {waypoints = wp, speed = 4.5})
	end
	coroutine.yield(coroutine_class.wait_all(table.unpack(wait_routines)))

	-- 박수 소리 4초뒤 2초간 페이드아웃됨 (꺼져도 되므로 우선순위 디폴트)
	music_player_util.play_sfx({
		sfx_name = '01_crowd_clap_01', loop = true, fade_in_time = 0.5, fade_out_time = 2, duration = 6
	})

	-- 관중들이 박수를 쳐준다
	for i = 1, 4 do
		local audience = get_character('sheldon_audience_' .. i)
		character_util.look_at(audience, user_party.Leader)
		audience:SetEmotion('smile', true)
		audience:SetAnimation('clap', true)
	end
end

-- 쉘든이 쪼르르 달려가 자기 의자로 앉는 이벤트
function local_class:sheldon_sit_chair()
	self.sheldon_current_state = self.sheldon_state.sit

	local sheldon_chair = get_field_object('sheldon_chair')
	local sheldon = get_character('sheldon')

	sheldon_chair.Interactable = CS.Oak.NonInteractable.Instance

	speech_bubble_util.remove_bubble(sheldon)

	-- 달릴떄 누구와도 안 부딪치게 해준다.
	sheldon.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	sheldon:RemoveEmotion()
	sheldon:RemoveAnimation()

	-- SOUND: 달리는 소리 넣는게 좋을지?..
	-- 쉘든이 현재 위치에서 의자와 제일 가까운 위치로 달려가 앉도록 해주기
	local sitable_points =
	{
		sheldon_chair.Position + unity_class.vector3.back,
		sheldon_chair.Position + unity_class.vector3.right,
		sheldon_chair.Position + unity_class.vector3.forward
	}
	local closest_dist = 999
	local closest_point = nil
	for _, point in ipairs(sitable_points) do
		local dist = (point - sheldon.Position).magnitude

		if dist < closest_dist then
			closest_dist = dist
			closest_point = point
		end
	end
	wp_util.move_way_points_async(sheldon, { waypoints = closest_point, speed = 6.5, run = true })

	-- SOUND: 폴짝! 뛰는 소리 추가
	sheldon.Direction = character_util.get_direction('left')
	coroutine.yield(coroutine_class.wait_all(
			util.cs_generator(character_util.mario_jump_async, sheldon, 'left'),
			util.cs_generator(character_util.move_to_async, sheldon, sheldon_chair.Position + unity_class.vector3.up * 0.5 + unity_class.vector3.back * 0.25, 0.3)
	))

	sheldon:SetAnimation('seat', true)
	sheldon:SetEmotion('smile', true)
end

-- 고통받는 인싸학생이 너드가 되는 이벤트
function local_class:insider_convert_nerd()
	local insider = get_character('painful_insider')
	local convert_to_nerd_npc = get_character('convert_to_nerd_npc')

	field_ui_manager:Hide()
	character_util.align_party(insider, 'right', 1, 'arc')

	-- 아, 아니야.. 나는 너드가 아니야..
	speech_bubble_util.show_speech_bubble_async(insider, {key = 'nerd_gas_event_1', skip = true})

	music_player:PlaySfxOneShot('03_runaway_01')

	-- 누, 누가 도와줘.. 머리속에서.. 머리속에서…
	insider:Shake(0.05, 99)
	speech_bubble_util.show_speech_bubble_async(insider, {key = 'nerd_gas_event_2', skip = true})
	insider:CancelShake()

	local wait = true
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		Text = game_string:GetString("nerd_gas_event_3"), -- 정신 차려!
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end})
	branches:Add({
		Text = game_string:GetString("nerd_gas_event_4"), -- 해독제를 구해줄게
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	user_party_leader:SetEmotion('attack', true)
	user_party_leader:SetAnimation('release', true)
	character_util.add_animation_sfx(user_party_leader, '01_swing_01')
	coroutine.yield(coroutine_class.wait_for_sec(1))
	user_party_leader:RemoveEmotion()
	user_party_leader:RemoveAnimation()

	insider:Shake(0.05, 1)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	character_util.look_at(npc, user_party_leader)

	music_player:PlaySfxOneShot('03_dialogue_negative_01')

	local build_up_sfx = music_player_util.play_sfx({
		sfx_name = '02_laser_build_up_01'
	})

	-- 으....으아아아아!!!
	speech_bubble_util.show_speech_bubble(insider, {key = 'nerd_gas_event_5', bubble_type = 'shout'})

	insider:SetEmotion('damaged', true)
	insider:SetAnimation('embarrassed', true)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	music_player:PlaySfxOneShot('01_throw_01')

	insider.Direction = character_util.get_direction('right')
	insider:SetAnimation('throw', false)
	coroutine.yield(coroutine_class.wait_for_sec(0.25))
	insider:RemoveAnimation()

	build_up_sfx:FadeOut(0.5)
	music_player:PlaySfxOneShot('01_explosion_gas_01')
	music_player:PlaySfxOneShot('01_mad_laugh_01')

	unity_object_pool.GetOrCreate(self.smoke_effect_name):Instantiate(insider.Position)
	--insider.Interactable:RemoveRelatedEvent(self.cs_controller)
	insider.ActiveState = active_state('disabled')
	convert_to_nerd_npc.Direction = character_util.get_direction('right')
	convert_to_nerd_npc.Position = insider.Position
	convert_to_nerd_npc:SetEmotion('doyagao', true)
	convert_to_nerd_npc:SetAnimation('idle', true)
	convert_to_nerd_npc.Interactable:AddListener(self.cs_controller)
	convert_to_nerd_npc.ActiveState = active_state('enabled')

	unity_object_pool.GetOrCreate(self.smoke_effect_name):Instantiate(user_party_leader.Position)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.convert_nerd_party, self))

	coroutine.yield(coroutine_class.wait_for_sec(1))

	party_util.reset_controllers()
	field_ui_manager:Show()
end

-- 너드가 될건지 묻는 이벤트
function local_class:ask_convert_to_nerd()
	local convert_npc = get_character('convert_to_nerd_npc')

	field_ui_manager:Hide()
	character_util.align_party(convert_npc, 'right')

	-- 너드가 되고싶어?
	speech_bubble_util.show_speech_bubble_async(convert_npc, {key = 'choose_convert_to_nerd', skip = true})

	local ok = false
	local wait = true
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		Text = game_string:GetString("bt_yes"), -- 네
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			ok = true
			wait = false
		end})
	branches:Add({
		Text = game_string:GetString("bt_no"), -- 아니오
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if ok then
		-- 이미 너드인 경우에는 너드로 바꿔주지않음.
		if (lua_helper.reference_equals(user_party.Leader, get_character('nerd_leader'))) then
			-- 넌 이미 나와 같은걸?
			speech_bubble_util.show_speech_bubble_async(convert_npc, {key = 'already_nerd_party', skip = true})
		else
			music_player:PlaySfxOneShot('01_explosion_gas_01')

			unity_object_pool.GetOrCreate(self.smoke_effect_name):Instantiate(user_party.Leader.Position)
			self:convert_nerd_party()
		end
	end

	field_ui_manager:Show()
	party_util.reset_controllers()
end

-- 파티를 너드로 바꿔주는 루틴
function local_class:convert_nerd_party()
	local nerd_party =
	{
		get_character('nerd_leader'),
		get_character('nerd_party_1'),
		get_character('nerd_party_2'),
		get_character('nerd_party_3'),
	}

	local marian = get_character('marian')
	local follow_marian = user_party:Contains(marian)

	local pos_array = {}
	local array_count = follow_marian == true and user_party.Count - 1 or user_party.Count
	for i = 1, array_count do
		pos_array[i] = user_party[i - 1].Position
	end

	-- 너드들 파티 이전 위치에 생성
	for i = 1, #pos_array do
		local nerd = nerd_party[i]
		nerd.Position = pos_array[i]
		nerd.ActiveState = active_state('enabled')

		if i == 1 then
			character_util.convert_to_manual_character(nerd)
		else
			character_util.convert_to_party_member(nerd, user_party)
		end
	end

	-- 마리안이 따라오고있었다면 너드화 시켜준다.
	if follow_marian == true then
		local nerd4 = get_character('nerd_party_4')
		nerd4.Position = marian.Position
		character_util.convert_to_party_member(nerd4, user_party)
	end

	-- 타이머 시작
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.nerd_party_timer_process, self))
end

function local_class:nerd_party_timer_process()
	message_system:Publish(CS.Oak.AttackQueueStartEvent.Create(user_party.Leader, self.nerd_gas_duration))

	local time_passed = 0
	while time_passed <= self.nerd_gas_duration do
		local leader_state = user_party.Leader.FieldObjectController.CurrentState
		if leader_state == nil or not lua_helper.type_compare(leader_state, CS.Oak.CharacterControllerScreenplayState) then
			time_passed = time_passed + unity_class.time.deltaTime
		end

		coroutine.yield(nil)
	end

	if lua_helper.reference_equals(user_party.Leader, get_character('nerd_leader')) then
		self:restore_origin_party()
	end
end

-- 너드파티 -> 원래 파티로 복구 시켜주는 루틴
function local_class:restore_origin_party()
	local selected_party = CS.Oak.User.Me.Party
	local is_sitting = user_party.Leader.CharacterBehaviour.CurrentState ~= nil and
			lua_helper.type_compare(user_party.Leader.CharacterBehaviour.CurrentState, CS.Oak.CharacterSitState)
	local is_holding = user_party.Leader.CharacterBehaviour.CurrentActionState ~= nil and
			lua_helper.type_compare(user_party.Leader.CharacterBehaviour.CurrentActionState, CS.Oak.CharacterHoldUpState)
	local follow_marian = user_party:Contains(get_character('nerd_party_4'))
	local current_battle = stage.BattleManager:GetBattleFor(user_party.Leader)

	-- 앉아있는 도중이였다면 쉘든이 자기 자리로 뛰어갈수 있게 이벤트를 날려줌
	-- 그리고 파티 리더가 의자 앞으로 위치하게 함.
	if is_sitting == true then
		local state = user_party.Leader.CharacterBehaviour.CurrentState
		user_party.Leader.Position = state.Chair.Position + unity_class.vector3.back
		message_system:Publish(CS.Oak.GuildCastleSitEvent.Create(-1, false, state.Chair))
	end

	-- 무언가 들고있던 도중이었다면 내려놓게함.
	if is_holding == true then
		character_util.release_hold_object(user_party.Leader,
				user_party.Leader.CharacterBehaviour.CurrentActionState.HoldTarget)
	end

	music_player:PlaySfxOneShot('02_explosion_01')

	local nerd_party_count = follow_marian == true and user_party.Count - 2 or user_party.Count - 1
	for i = 0, nerd_party_count do
		local info = selected_party[i]
		local member_name = CS.Oak.PartyUtil.GeneratePartyName(selected_party, info)
		local origin_member = get_character(member_name)
		local current_member = user_party[i]

		unity_object_pool.GetOrCreate(self.explode_effect_name):Instantiate(current_member.Position)
		current_member.ActiveState = active_state('disabled')
		origin_member.Position = current_member.Position
	end

	party_manager:RestorePlayerParty(false)

	-- 마리안이 따라다녔었다면 뒤에 따라다니게 배치
	if follow_marian == true then
		local nerd4 = get_character('nerd_party_4')
		nerd4.ActiveState = active_state('disabled')

		local marian = get_character('marian')
		marian.Position = nerd4.Position
		marian.ActiveState = active_state('enabled')
		character_util.convert_to_party_member(marian, user_party)
	end

	-- 전투중이였다면 현재 리더에게로 어그로 변경
	local is_in_battle = current_battle ~= nil
	if is_in_battle == true then
		for i = 0, current_battle.Enemies.Count - 1 do
			local monster = current_battle.Enemies[i].Character

			if monster ~= nil and monster.ActiveState == active_state('enabled') then
				command_util.execute_monster_notice(monster, user_party.Leader, 'battle')
			end
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
