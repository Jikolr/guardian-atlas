local local_class = newclass('MemorialSquirrelGirlMayreelController')

function local_class:init()
	self.controller = nil
	self.custom_state_key = nil

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	--state
	self.states = {
		none = 1,
		mayreel = 2,
		civilian_male_talk = 4,
		show_picture = 5,
	}

	self.current_state = self.states.none

	--npc
	self.character = {
		squirrel_girl = function()
			return get_character('squirrel_girl')
		end,
		mayreel = function()
			return get_character('mayreel')
		end,
		civilian_male = function()
			return get_character('civilian_male')
		end,
		granddaughter = function()
			return get_character('granddaughter')
		end
	}

	-- fo
	self.fo = {
		picture = function()
			return get_field_object('mayreel_picture')
		end
	}

	--marker
	self.marker = {
		mayreel_pos = function(number)
			return field_util.get_marker_pos('event_mayreel_pos_' .. number)
		end,
		granddaughter_pos = function(number)
			return field_util.get_marker_pos('event_granddaughter_pos_' .. number)
		end,
		civilian_male_pos = function()
			return field_util.get_marker_pos('event_civilian_male_pos')
		end
	}

	self.is_stage_exit = false

	self.picture_marker = {
		id = 7200101,
		marker_name = 'mayreel_quest',
		toggle = false,
		fo_name = 'mayreel_picture',
		zone_name = 'mayreel_marker_zone',
		active = false,
		sfx_holder = nil,

		---@type fun(this:self)
		on = function(this)
			if this.toggle then
				return
			end

			local fo = get_field_object(this.fo_name)

			quest_marker_util.add_quest_marker_to_ifo(this.marker_name, this.id, false, fo)
			this.toggle = not this.toggle
		end,

		---@type fun(this:self)
		off = function(this)
			if not this.toggle then
				return
			end

			quest_marker_util.remove(this.marker_name)
			this.toggle = not this.toggle
		end,

		---@type fun(this:self, e:ZoneEnterEvent):boolean, function
		enter_event = function(this, e)
			if this.active and
					type_util.is_zone_full_enter(e, get_party_leader(), this.zone_name) then
				this:on()
				this:sfx_active()

				return true
			end

			return false
		end,

		---@type fun(this:self, e:ZoneLeaveEvent):boolean, function
		leave_event = function(this, e)
			if this.active and
					type_util.is_zone_full_leave(e, get_party_leader(), this.zone_name) then
				this:off()
				this:sfx_dispose()

				return true
			end

			return false
		end,

		---@type fun(this:self, active:boolean)
		set_active = function(this, active)
			this.active = active
		end,

		---@type fun(this:self)
		sfx_active = function(this)
			if this.sfx_holder == nil then
				this.sfx_holder = music_player_util.play_sfx({
					sfx_name = '01_amb_forest_03',
					loop = true,
					type_priority = 'loop',
					play_pos = get_field_object(this.fo_name).Position,
					max_distance = 10
				})
			end
		end,

		---@type fun(this:self)
		sfx_dispose = function(this)
			if this.sfx_holder ~= nil then
				music_player_util.fade_out_sfx(this.sfx_holder, 1)
				this.sfx_holder = nil
			end
		end
	}
end

function local_class:init_controller(controller, custom_state_key)
	self.controller = controller
	self.custom_state_key = custom_state_key

	local custom_state = quest_util.get_custom_state(self.controller.quest_progress, self.custom_state_key)

	if custom_state < 1 then
		self:setting_npc()

		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	else
		self:after_setting_npc()
	end

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	stage.SmokeManager:UnsetCharacterSmoke(self.character.mayreel())

	self.custom_state_key = nil
	self.controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	if self.current_state == self.states.civilian_male_talk and
			type_util.is_interacted_target(e, self.fo.picture()) then
		self.current_state = self.states.show_picture
		--퀘스트 마커 해제
		self.picture_marker:off()
		self.picture_marker:set_active(false)

		sp_util.start_scene(self.show_picture_scene, self)

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.current_state == self.states.none and
			type_util.is_zone_full_enter(e, get_party_leader(), 'mayreel_move_zone') then
		self.current_state = self.states.mayreel
		start_coroutine(self.move_mayreel, self)

		return true
	end

	if self.current_state == self.states.mayreel and
			type_util.is_zone_full_enter(e, get_party_leader(), 'mayreel_hidden_zone') then
		self.current_state = self.states.civilian_male_talk
		sp_util.start_scene(function()
			self:talk_civilian_male()

			--퀘스트 마커 지정
			self.picture_marker:set_active(true)
			self.picture_marker:on()
		end)

		return true
	end

	if self.picture_marker:enter_event(e) then
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.picture_marker:leave_event(e) then
		return true
	end

	return false
end

function local_class:on_stage_end_event(e)
	self.is_stage_exit = true
	stage.SmokeManager:UnsetCharacterSmoke(self.character.mayreel())
	character_util.stop(self.character.mayreel())
	return true
end

function local_class:setting_npc()
	--메이릴 : (left, idle, idle)
	local mayreel = self.character.mayreel()

	character_util.set_position(mayreel, self.marker.mayreel_pos(1))
	character_util.set_direction(mayreel, 'left')

	--화가 : (left, idle, idle)
	local civilian_male = self.character.civilian_male()

	character_util.set_position(civilian_male, self.marker.civilian_male_pos())
	character_util.set_direction(civilian_male, 'left')

	--손녀 (left, tired, question 마지막 프레임) : 저 아저씨 어디서 본 것 같은데?
	local granddaughter = self.character.granddaughter()

	character_util.set_position(granddaughter, self.marker.granddaughter_pos(1))
	character_util.set_direction(granddaughter, 'left')
	scene_util.set_emotion(granddaughter, self, 'tired')
	scene_util.set_anim(granddaughter, self, 'question')
	granddaughter.Interactable.Talk = 'mm_squirrel_girl_event_mayreel_1'
end

function local_class:after_setting_npc()
	--화가 (right, tired, idle): 아저씨는 저 꽃밭에 설 때면 아무 걱정없이 예술하던 시절이 떠오른단다.
	local civilian_male = self.character.civilian_male()

	character_util.set_position(civilian_male, self.marker.civilian_male_pos())
	character_util.set_direction(civilian_male, 'left')
	scene_util.set_emotion(civilian_male, self, 'tired')
	civilian_male.Interactable.Talk = 'mm_squirrel_girl_event_mayreel_7'

	--손녀 (down, love, sing) : 어머, 귀여워라~!
	local granddaughter = self.character.granddaughter()

	character_util.set_position(granddaughter, self.marker.granddaughter_pos(2))
	character_util.set_direction(granddaughter, 'right')
	scene_util.set_emotion(granddaughter, self, 'love')
	scene_util.set_anim(granddaughter, self, 'sing')
	granddaughter.Interactable.Talk = 'mm_squirrel_girl_event_mayreel_11'

	local mayreel = self.character.mayreel()

	character_util.set_position(mayreel, self.marker.mayreel_pos(3))

	start_coroutine(self.mayreel_routine, self)
end

function local_class:move_mayreel()
	local mayreel = self.character.mayreel()

	--메이릴 (right, idle, idle) jump 1회, 끝날 대까지 대기
	character_util.normal_jump_async(mayreel, true)

	--메이릴 (right, idle, idle) 속도 7로 동선 따라 이동
	wp_util.move_async(mayreel, mayreel.Position + vector(1, 0, 0), 7)

	--파란색 브레이커블 위치에서 jump 자세 적용하여 높이 1 점프
	music_player_util.play_sfx_one_shot('01_jump_01')
	character_util.jump(mayreel, 2, 0.5)
	character_util.move_to_async(mayreel, mayreel.Position + vector(3, 0, 0), 0.5)

	wp_util.move_async(mayreel, mayreel.Position + vector(5, 0, 0), 7)

	--메이릴 도착지점에서 left, idle, idle 적용한 원라인 npc로 전환
	character_util.set_position(mayreel, self.marker.mayreel_pos(2))
	character_util.set_direction(mayreel, 'left')

	--메이릴 npc와 상호작용시 아래 나레이션 출력
	--메이릴… 처럼 생겼지만 화가가 기르고 있는 평범한 양이다.
	local narration_interactable = CS.Oak.NarrationInteractable()
	narration_interactable.StringKeys = { 'mm_squirrel_girl_event_mayreel_2' }
	mayreel.Interactable = narration_interactable
end

function local_class:talk_civilian_male()
	local leader = get_party_leader()
	local squirrel_girl = self.character.squirrel_girl()
	local civilian_male = self.character.civilian_male()
	local picture = self.fo.picture()

	music_player_util.play_stage_music({ state = 'muted', mix = 3 })
	self.picture_marker:sfx_active()

	do
		local wp_key = 'leader_wp'

		wp_util.move_with_end_callback(leader, civilian_male.Position + vector(-1, 0, 0),
				nil, 1.5, self, wp_key, { last_direction = 'right' })
		wp_util.move_with_end_callback(squirrel_girl, civilian_male.Position + vector(-1, 0, -1),
				nil, 1.5, self, wp_key, { last_direction = 'right' })

		wp_util.wait_move_end(self, wp_key)
	end

	--화가 (right, idle, idle): 안녕, 미안하지만 오늘 초상화는 마감했어.
	scene_util.play_normal_speech_action(civilian_male, self, 'left',
			nil, nil, 'mm_squirrel_girl_event_mayreel_3')

	--화가 (right, idle, idle): 다음에 찾아오거든 멋진 초상화를 그려줄게.
	scene_util.play_normal_speech_action(civilian_male, self, 'left',
			nil, nil, 'mm_squirrel_girl_event_mayreel_4')

	--화가 (right, tired, question 1회, 마지막 프레임 유지) silence 이모티콘 출력. 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_emoticon_action(civilian_male, self, 'left',
			'question', 'tired', 'silence')

	--화가 (right, idle, idle): … 그렇지, 오른편에 있는 정원에 가보는 게 어때?
	scene_util.play_normal_speech_action(civilian_male, self, 'left',
			nil, nil, 'mm_squirrel_girl_event_mayreel_5')

	--카메라 노란색 마름모 위치로 1.5초간 포커스 옮기기
	camera_util.move_to_target_async(picture, 1.5)

	--카메라 2초 대기
	wait_for_sec(2)

	--카메라 가디언 포커스로 1.5초간 원위치
	camera_util.return_to_leader(1.5)

	--화가 (right, smile, idle): 소중한 추억을 떠올리게 해주는 아름다운 풍경이 있거든.
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(civilian_male, self, 'left',
			nil, 'smile', 'mm_squirrel_girl_event_mayreel_6')

	--화가 (right, tired, idle): 아저씨는 저 꽃밭에 설 때면 아무 걱정없이 예술하던 시절이 떠오른단다.
	scene_util.play_normal_speech_action(civilian_male, self, 'left',
			nil, 'tired', 'mm_squirrel_girl_event_mayreel_7')

	music_player_util.play_stage_music({ state = 'field' })
	civilian_male.Interactable.Talk = 'mm_squirrel_girl_event_mayreel_7'
	picture.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:show_picture_scene()
	local leader = get_party_leader()
	local granddaughter = self.character.granddaughter()
	local mayreel = self.character.mayreel()

	-- 1.5초에 걸쳐 화이트 페이드아웃
	music_player_util.play_sfx_one_shot('01_fade_out_01')
	screen_util.fade_out_async(1.5, unity_class.color.white, 'linear')

	local res_holder = CS.Foundations.ResourceHolder()
	local flower_scene

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			res_holder, 'ondemand/v2_14_bari/theatres_end', 'bari_end_scene', function(prefab)
				flower_scene = CS.UnityEngine.GameObject.Instantiate(prefab)
				flower_scene.transform.localPosition = vector(-300, 0, -300)
				flower_scene:SetActive(false)

				local main_camera = flower_scene.transform:Find('Main Camera')
				main_camera.position = main_camera.position + vector(0, 1, 0)

				local audio_listener = main_camera.gameObject:GetComponent(typeof(CS.UnityEngine.AudioListener))
				audio_listener.enabled = false
			end)

	local asset_bundle_path = 'ondemand/v2_14_bari/theatres_end'
	local info = {
		target_name = 'bg_flower_garden',
		asset_name = 'bg_flower_garden.jpg',
		order = 1,
		need_loading = true
	}

	local asset_bundle
	yield_return_func(CS.Foundations.AssetBundleManager.Instance.LoadAssetBundleAsync,
			CS.Foundations.AssetBundleManager.Instance, asset_bundle_path, function(res)
				asset_bundle = res
			end)

	if info.need_loading then
		local target_obj = flower_scene.transform:Find(info.target_name).gameObject

		yield_return_func(asset_bundle.LoadAssetAsync, asset_bundle, info.asset_name, function(texture_bytes)
			if texture_bytes then
				local texture = CS.UnityEngine.Texture2D(2, 2, CS.UnityEngine.TextureFormat.RGBA32, false)
				texture.wrapMode = CS.UnityEngine.TextureWrapMode.Mirror
				if CS.UnityEngine.ImageConversion.LoadImage(texture, texture_bytes.bytes, true) then
					local rect = CS.UnityEngine.Rect(0, 0, texture.width, texture.height)
					-- 텍스쳐를 스프라이트로 생성
					local sprite = CS.UnityEngine.Sprite.Create(texture,
							rect,
							vector(0.5, 0.5),
							100,
							0,
							CS.UnityEngine.SpriteMeshType.Tight,
							unity_class.vector4.zero,
							false)

					-- 새 오브젝트를 만들어서 SpriteRenderer를 붙여줌
					local sprite_renderer = CS.GameObjectExtensions.GetOrAddComponent(target_obj,
							typeof(CS.UnityEngine.SpriteRenderer))

					if sprite_renderer then
						sprite_renderer.sprite = sprite
						sprite_renderer.sortingOrder = info.order
					end
				end
			end
		end)
	end

	flower_scene:SetActive(true)
	camera_util.move_async(vector(-300, 0, -300), 0)

	music_player_util.play_stage_music({ name = 'ondemand/v2_14_bari/audio:bgm_bari_theme', state = 'event', mix = 2 })
	music_player_util.play_sfx_one_shot('01_fade_out_07')
	screen_util.fade_in_async(1, unity_class.color.white, 'linear')

	--별도의 말풍선 연출 없이 5초간 재생
	wait_for_sec(5)

	music_player_util.change_stage_music_volume('event', 0, 4)
	screen_util.fade_out_async(1.5, unity_class.color.white, 'linear')

	camera_util.return_to_leader(0.5)

	CS.UnityEngine.GameObject.Destroy(flower_scene)
	res_holder:Dispose()

	character_util.set_position(granddaughter, self.marker.granddaughter_pos(2))
	character_util.set_direction(granddaughter, 'right')
	character_util.remove_anim_and_emotion(granddaughter)

	scene_util.set_emotion(leader, self, 'sleep_deep')
	screen_util.fade_in_async(1, unity_class.color.white, 'linear')

	--이후 아래 연출 동시에 진행
	--나레이션 박스 재생
	--가디언 (현재 방향, sleep_deep)
	--소중한 추억의 단편을 엿본 것만 같은 기분이다.
	field_ui_util.show_narration_async({ key = 'mm_squirrel_girl_event_mayreel_8' })

	--컨트롤 돌려준다.
	self.fo.picture().Interactable = CS.Oak.NonInteractable.Instance

	--손녀 (right, idle, idle) : 어디서 봤다 했더니….
	scene_util.play_normal_speech_action(granddaughter, self, 'right',
			nil, nil, 'mm_squirrel_girl_event_mayreel_9')

	--가디언, 크루시엘 (left, idle, idle)
	do
		local group = { leader, self.character.squirrel_girl() }
		scene_util.set_group_direction(group, 'left', false)
		character_util.remove_group_anim_and_emotion(group)
	end

	--다음 연출 동시 재생
	wait_all_lua(
			function()
				party_util.set_direction('left')
				--손녀 (right, smile, idle) : 여기는 제 고향 풍경을 빼다 박았네요.
				scene_util.play_normal_speech_action(granddaughter, self, 'right',
						nil, 'smile', 'mm_squirrel_girl_event_mayreel_10')
			end,
			function()
				--메이릴 좌측 방에서부터 7의 속도 run 애니 적용하여 위와 같은 동선으로 이동
				local mayreel_pos = screen_util.get_left_right_outside_pos('left',
						self.marker.mayreel_pos(3), -1)

				character_util.set_position(mayreel, mayreel_pos)

				wp_util.move_async(mayreel, vector_util.get_xy0(granddaughter.Position, mayreel.Position.z), 7)
			end
	)

	character_util.set_direction(granddaughter, 'down')
	--도착 후 메이릴 (up, jump 1회) rowdy 이모티콘 1회 출력, 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	character_util.normal_jump(mayreel, true)
	scene_util.play_emoticon_action(mayreel, self, { dir = 'up', sfx = false },
			nil, nil, 'rowdy')

	--손녀 (down, love, sing) : 어머, 귀여워라~!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.set_emotion(granddaughter, self, 'love')
	scene_util.set_anim(granddaughter, self, 'sing')
	scene_util.show_normal_speech_async(granddaughter, 'mm_squirrel_girl_event_mayreel_11')

	--이후 메이릴 (smile, run) 위 동선으로 6의 속도로 빙빙 돈다. 끝날때까지 대기없음.
	start_coroutine(self.mayreel_routine, self)

	--메이릴 충돌 처리도 없습니다.
	mayreel.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	mayreel.Interactable = CS.Oak.NonInteractable.Instance

	--컨트롤 돌려준다.
	--이후 그리드 이탈할 때 헬레나 BGM on 상태일 경우 기존 BGM으로 전환
	music_player_util.play_stage_music({ state = 'field', volume = 1 })
	music_player_util.change_stage_music_volume('event', 1, 5)
	character_util.remove_emotion(leader)
	character_util.set_direction(granddaughter, 'right')
	granddaughter.Interactable.Talk = 'mm_squirrel_girl_event_mayreel_11'

	self.picture_marker:sfx_dispose()

	self.controller.stage_event:clear_event(self.custom_state_key, 1)
end

function local_class:mayreel_routine()
	local mayreel = self.character.mayreel()

	local wp = {
		self.marker.mayreel_pos(3),
		self.marker.mayreel_pos(4),
		self.marker.mayreel_pos(5),
		self.marker.mayreel_pos(6),
	}

	mayreel.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	stage.SmokeManager:SetCharacterSmoke(mayreel)
	scene_util.set_emotion(mayreel, self, 'smile')

	while not self.is_stage_exit do
		wp_util.move_async(mayreel, wp, 6, nil, { run = true })
	end

	mayreel.OverrideCrashBehaviour = nil
end

return {
	create = function()
		return local_class()
	end
}
