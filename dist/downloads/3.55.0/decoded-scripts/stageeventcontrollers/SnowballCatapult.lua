local local_class = newclass("SnowballCatapultController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.snowball_name = 'catapult_snowball'
	self.jump_tile_name = 'catapult_jump_tile'
	self.catapult_rock_name = 'catapult_rock'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')

	unity_object_pool.GetOrCreate('fx_monster_snowball_hit')
	unity_object_pool.GetOrCreate('FX_Env_BigRock_lv2_destroy')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		local snowball = get_field_object(self.snowball_name)
		if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, snowball) then return false end

		if e.Zone.Name == 'snowball_catapult_zone' then
			sp_util.play_normal_screenplay(self.flying_snowball, self)
			return true
		end
	end
	return false
end

-- 점프 타일 밟고 날아가는 눈덩이
function local_class:flying_snowball()
	local snowball = get_field_object(self.snowball_name)
	local rock = get_field_object(self.catapult_rock_name)

	-- 날아갈 때 사운드
	music_player:PlaySfxOneShot('03_jumptile_01')
	music_player:PlaySfxOneShot('02_aura_slash_01')
	music_player:PlaySfxOneShot('01_fall_down_01')

	-- 점프 타일 애니메이션 실행
	local jump_tile = get_field_object(self.jump_tile_name)
	local jump_tile_animator = jump_tile:GetComponent(typeof(CS.UnityEngine.Animator))
	jump_tile_animator.speed = 1.5
	jump_tile_animator:Play('on')

	-- 날아가는 눈덩이
	local time_passed = 0
	local duration = 2
	local start_pos = snowball.Position
	local end_pos = rock.Bounds.center
	local height = 5

	-- NOTE: 기믹 구조가 바뀌면 같이 바뀌어야 함 ([gimmick]snowball)
	local snowball_main = snowball.transform:Find('scale/snowball')
	local shadow = snowball.transform:Find('scale/shadow')
	local origin_rot = snowball_main.rotation
	shadow.gameObject:SetActive(false)

	-- 카메라 이동을 실행했는지 체크
	local camera_active = false

	-- 날아가는 동안 사운드
	local blizzard_sound = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true })

	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed > 0.2 and not camera_active then
			camera_active = true
			camera_util.move(rock.Bounds.center, duration - 0.1)
		end

		local progress = unity_class.mathf.Clamp01(time_passed / duration)

		snowball_main.rotation =
			unity_class.quaternion.AngleAxis(-360 * 4 * progress, unity_class.vector3.right) * origin_rot

		local cur_y = unity_class.mathf.Sin(unity_class.mathf.PI * progress) * height

		if cur_y <= 0 then cur_y = 0 end

		snowball.Position = unity_class.vector3.Lerp(start_pos, end_pos, progress) + cur_y * unity_class.vector3.up

		coroutine.yield(nil)
	end

	blizzard_sound:Stop()

	-- 점프 타일 애니메이션 되돌리기
	jump_tile_animator:Play('off')

	-- 바위 파괴
	local destroy_rock_effect_pool = unity_object_pool.GetOrCreate('FX_Env_BigRock_lv2_destroy')
	destroy_rock_effect_pool:Instantiate(rock.Bounds.center)
	rock.ActiveState = active_state('disabled')
	music_player:PlaySfxOneShot('03_rock_break_01')

	-- 눈덩이 터짐
	local snowball_effect_pool = unity_object_pool.GetOrCreate('fx_monster_snowball_hit')
	local snowball_effect = snowball_effect_pool:Instantiate(snowball.Position)
	snowball_effect.transform.localScale = 2.5 * unity_class.vector3.one
	snowball.ActiveState = active_state('disabled')

	wait_for_sec(2)

	screen_util.fade_out_async(1, unity_class.color.black)

	camera_util.resize_to_default(0)
	camera_util.move(user_party_leader.Position, 0, { end_target = user_party_leader })

	wait_for_sec(0.5)
	screen_util.fade_in_async(1, unity_class.color.black)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
