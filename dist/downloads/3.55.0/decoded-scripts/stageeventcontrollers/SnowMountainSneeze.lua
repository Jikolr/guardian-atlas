local local_class = newclass("SnowMountainSneezeController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.fat_elf_name = 'sneeze_desertelf'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent), 'on_event')

	local fat_elf = get_character(self.fat_elf_name)
	fat_elf.Interactable:AddListener(self.cs_controller)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent))

	local fat_elf = get_character(self.fat_elf_name)
	if lua_helper.type_compare(fat_elf.Interactable, CS.Oak.NPCInteractable) then
		fat_elf.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		local fat_elf = get_character(self.fat_elf_name)
		if lua_helper.reference_equals(e.Target, fat_elf) then
			sp_util.play_normal_screenplay(self.talk_fat_elf, self)
			return true
		end
	end

	if event_type == typeof(CS.Oak.TeslaCoilOnOffEvent) then
		if e.IsTurningOn then return false end
		for i = 1, 2 do
			local tesla = get_field_object('sneeze_tesla_' .. i)
			if lua_helper.reference_equals(e.CoilObject, tesla) then
				sp_util.play_normal_screenplay(self.turn_off_fire, self, i)
				return true
			end
		end
	end

	return false
end

-- 돌격대장과 대화
function local_class:talk_fat_elf()
	local fat_elf = get_character(self.fat_elf_name)
	fat_elf.Interactable:RemoveRelatedEvent(self.cs_controller)
	character_util.align_party(fat_elf, 'right', 1, 'linear')

	-- 여기… 너무 춥잖아!
	local string_key = 'snowmountain_1_3_sneeze_1'
	speech_bubble_util.show_speech_bubble_async(fat_elf, { key = string_key, skip = true })

	music_player:PlaySfxOneShot('03_runaway_01')
	character_util.shake(fat_elf, 0.04, 4)
	-- 이렇게 독한 감기는… 쿨쩍… 처음이야!
	string_key = 'snowmountain_1_3_sneeze_2'
	speech_bubble_util.show_speech_bubble_async(fat_elf, { key = string_key, skip = true })

	fat_elf.SpineController:CancelShake()

	local party = {}
	for i = 0, user_party.Count - 1 do
		table.insert(party, user_party[i])
	end

	-- 불 붙은 화로 개수
	local burning_brz_index = 0
	if get_field_object('puzzle_brz2').CombustibleBehaviour.IsBurning then
		burning_brz_index = burning_brz_index + 1
	end

	if get_field_object('puzzle_brz3').CombustibleBehaviour.IsBurning then
		burning_brz_index = burning_brz_index + 1
	end

	if burning_brz_index ~= 2 then
		music_player:PlaySfxOneShot('02_die_fat_ogre_01')
		-- 게다가 뭐야! 불까지 갑자기 꺼져버리고!
		string_key = 'snowmountain_1_3_sneeze_3'
		speech_bubble_util.show_speech_bubble_async(fat_elf, { key = string_key, skip = true })
	end

	local sneeze_ready_sfx = music_player_util.play_sfx({ sfx_name = '01_slowmotion_01' })

	character_util.set_anim(fat_elf, { name = 'sneeze_ready' })
	for i = 0, 2 - burning_brz_index do
		camera_util.resize_to(4 - (i + 1) * 0.5, 0.5)
		wait_for_sec(0.5)
		-- 에엣…
		string_key = 'snowmountain_1_3_sneeze_4'
		speech_bubble_util.show_speech_bubble_async(fat_elf, { key = string_key, skip = true })
	end

	character_util.remove_anim(fat_elf)
	character_util.set_anim(fat_elf, { name = 'sneeze_shoot', loop = false })
	wait_for_sec(0.5)

	sneeze_ready_sfx:Stop()
	music_player:PlaySfxOneShot('01_sneeze_01')
	local slide_sfx = music_player_util.play_sfx({ sfx_name = '01_slide_01', delayed_time = 0.2 })
	-- 취이!!!
	string_key = 'snowmountain_1_3_sneeze_5'
	local string_pos = user_party_leader.Position + vector(-3, 0, -1)
	speech_bubble_util.show_speech_bubble(fat_elf, { key = string_key, bubble_type = 'shout', world_pos = string_pos })

	if burning_brz_index == 0 then
		camera_util.shake(0.2, 0.3)
	end

	character_util.remove_anim(fat_elf)
	camera_util.resize_to_default(0.5)

	-- 화로에 꺼진 불 개수에 따라 다른 연출
	local speed = {19, 14, 11}
	for k, v in pairs(party) do
		coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.is_pushed_action, self, v, speed[burning_brz_index + 1]))
	end

	-- 카메라 이동을 따라서 버블 이동
	local bubble = speech_bubble.instance:Get(fat_elf)
	local end_pos = field:GetMarker('sneeze_jump_pos').position + vector(-5, 0, -1)
	local time_passed = 0
	while time_passed <= self.move_duration do
		bubble.transform.position = unity_class.vector3.Lerp(string_pos, end_pos, time_passed / self.move_duration)
		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield(nil)
	end
	speech_bubble_util.remove_bubble(fat_elf)

	slide_sfx:Stop()

	-- 점프 타일 애니메이션 실행
	local jump_tile = get_field_object('sneeze_jump_tile')
	local jump_tile_animator = jump_tile:GetComponent(typeof(CS.UnityEngine.Animator))
	jump_tile_animator.speed = 1.5
	jump_tile_animator:Play('on')
	wait_for_sec(1.75)

	jump_tile_animator:Play('off')

	fat_elf.Interactable:AddListener(self.cs_controller)
end

-- 재채기에 날아가는 파티
function local_class:is_pushed_action(character, speed)
	-- 빙판길에서 미끄러짐
	local way_points = {}
	table.insert(way_points, user_party_leader.Position)
	table.insert(way_points, field:GetMarker('sneeze_jump_pos').position)

	character_util.set_anim(character, { name = 'embarrassed' })
	character_util.set_emotion(character, { name = 'surprise' })
	character_util.move_waypoint(character, way_points, speed, true )

	local move_info = CS.Oak.WaypointMoveInfo()
	move_info.waypoints = way_points
	move_info.speed = speed
	self.move_duration = move_info:GetDuration(character.Position)
	wait_for_sec(self.move_duration)

	character_util.remove_anim_and_emotion(character)

	-- 점프 타일 밟고 날아감
	local jump_tile = get_field_object('sneeze_jump_tile')
	local jump_info = CS.Oak.JumpInfo()
	jump_info.jumper = character
	jump_info.jumpSource = jump_tile
	jump_info.speed = speed
	local xz_dir = vector_util.get_x0z(field:GetMarker('sneeze_end').position - character.Position).normalized
	jump_info.direction = (xz_dir + 1.5 * unity_class.vector3.up).normalized
	jump_info.jumpStartPos = jump_tile.Position
	jump_info.jumpTimeScale = 1.75
	jump_info.gravity = CS.Oak.Constants.JumpGravity

	local cmd = CS.Oak.JumpCommand.Create(jump_info)
	command_util.execute_cmd(cmd)
end

-- 화로의 불이 꺼짐
function local_class:turn_off_fire(index)
	local brazier = get_field_object('puzzle_brz' .. (index + 1))
	if index == 1 then
		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		camera_util.move(brazier.Position, 0)
		wait_for_sec(1)

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	else
		camera_util.move_async(brazier.Position, 1)
	end

	command_util.execute_extinguish(user_party_leader, brazier)
	wait_for_sec(1)

	local fat_elf = get_character(self.fat_elf_name)
	music_player:PlaySfxOneShot('03_runaway_01')
	character_util.shake(fat_elf, 0.04, 4)
	-- 재채기가 더 심해지고 있어.
	local string_key = 'snowmountain_1_3_sneeze_6'
	speech_bubble_util.show_speech_bubble_async(fat_elf, { key = string_key, skip = true })

	fat_elf.SpineController:CancelShake()

	wait_for_sec(1)

	if index == 1 then
		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		camera_util.move(user_party_leader.Position, 0, { end_target = user_party_leader })

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	else
		camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })
	end

	-- 해당 화로는 다시는 불이 붙으면 되지 않으므로 NonCombustibleBehaviour 로 변경 해준다.
	brazier.CombustibleBehaviour = CS.Oak.NonCombustibleBehaviour.Instance
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
