local local_class = newclass('NightmareQueenCastle6Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.script = nil

	self.main_quest_id = 456

	self.late_update_handler = metatable_helper.inherit({
		priority = CS.Oak.UpdatePriorities.StageEvent,
		callback_name = 'late_update_frame',
	}, {
		add = function(this, updater)
			update_util.add_late_update(updater, this.priority, this.callback_name)
		end,

		remove = function(this, updater)
			update_util.remove_late_update(updater, this.priority, this.callback_name)
		end,
	})

	self.electric_magnet = {
		magnet_active = false,
		is_detected = false,
		detected_scene = false,
		count = 2,
		radius = 4 * 4,
		reset_pos = vector(-36.5, 0, 17),
		get = function(this, number)
			return get_field_object('electric_magnet_' .. number)
		end,
		foreach = function(this, func)
			for i = 1, this.count do
				func(i, this:get(i))
			end
		end,
		data = {},
		set_data = function(this)
			if #this.data == this.count then
				return
			end

			for i = 1, this.count do
				table.insert(this.data, {
					-- 기본 세팅이 모두 테슬라 연결 되어 있는 상태
					turning_on = true,
				})
			end

			this.magnet_active = true
		end,
		is_in_circle = function(this, magnet)
			local leader_pos = user_party.Leader.Bounds.center
			local sqr_dist = vector_util.sqr_xz_distance(leader_pos, magnet.Bounds.center)

			if sqr_dist < this.radius then
				return true
			end

			return false
		end,
	}

	self.party = {
		get_character('twins_android'),
		get_character('twins_android_b')
	}

	self.fx = metatable_helper.create_fx_accessor({
		magnetic_fx = function()
			return unity_object_pool.GetOrCreate('fx_gimmick_char_magnetic_fx')
		end,
	})

	self.npc = {
		--1~3
		android_remains = function(idx)
			return get_character('android_remains_' .. idx)
		end
	}
	self.android_remains_num = 3
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.late_update_handler:remove(self)

	self.script:dispose()

	self.script = nil

	self.cs_controller = nil
end

function local_class:load_resource()
	local script_path = 'Quest/Nightmare/QueenCastle/Common/WeaponNpcBattleLogic'

	self.script = CS.Oak.StageLuaScript.Create(script_path)

	self.electric_magnet:set_data()
	self.fx:create_all()

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent), 'on_tesla_on_off_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	self.late_update_handler:add(self)
end

function local_class:on_tesla_on_off_event(e)
	self.electric_magnet:foreach(function(index, magnet)
		if lua_helper.reference_equals(e.CoilObject, magnet) then
			self.electric_magnet.data[index].turning_on = true

			if not e.IsTurningOn then
				self.electric_magnet.data[index].turning_on = false
			end
		end
	end)
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.script:load()

	stage_start_util.start_function(quest_progress)

	self:set_tesla_after_clear(quest_progress)

	self:set_android_remains_hitbox()
end

function local_class:late_update_frame(dt)
	self.electric_magnet:foreach(function(index, magnet)
		if self.electric_magnet.data[index].turning_on then
			self.electric_magnet.is_detected = self.electric_magnet:is_in_circle(magnet)

			if self.electric_magnet.is_detected and not self.electric_magnet.detected_scene then
				self.electric_magnet.detected_scene = true

				sp_util.start_scene(self.magnet_detected_scene, self, magnet):Then(function()
					self.electric_magnet.detected_scene = false
				end)
			end
		end
	end)
end

function local_class:set_tesla_after_clear(quest_progress)
	if quest_progress ~= nil and quest_progress.IsComplete then
		local tesla = get_field_object('s6_power_source_2')

		message_system:Publish(CS.Oak.PowerSourceTurnOffEvent.Create(tesla))
	end
end

function local_class:magnet_detected_scene(magnet)
	--플레이어 (니프티) 및 파티원 (시프티) (damaged) 표정 (embarrssed) 애니메이션 으로 변경
	--플레이어 (니프티) 및 파티원 (시프티) 전자석의 자력으로 끌려간다.
	--기존 플레이어가 자석을 들고 전자석에 끌리는 기믹 연출과 동일한 연출

	local magnetic_fx_list = {}

	music_player_util.play_sfx_one_shot('03_runaway_01')

	music_player_util.play_sfx_one_shot('02_spark_01', 0.5)

	for i = 1, #self.party do
		local fo = self.party[i]

		scene_util.set_emotion(fo, self, 'damaged')
		scene_util.set_anim(fo, self, { name = 'embarrassed', one_shot_sfx = false })

		local magnetic_fx = self.fx:magnetic_fx():Instantiate(fo.Bounds.center, unity_class.quaternion.identity, fo.Transform)
		table.insert(magnetic_fx_list, magnetic_fx)
	end

	music_player_util.play_sfx_one_shot('01_magnetic_01')

	local dur = 1

	coroutine_util.while_each_frame(dur, function(dt)
		for i = 1, #self.party do
			local fo = self.party[i]
			local fo_center = fo.Bounds.center
			local magnet_center = magnet.Bounds.center

			-- 기존 자석 기믹과 유사한 임의의 수치
			local speed = 15

			-- IMagnetizable 에서 가져온 값
			local remove_reserved_stay_time = 0.5

			local progress = unity_class.mathf.Clamp01(
					CS.Oak.Interpolations.EaseOutExpo(dt, 0, 1, remove_reserved_stay_time))

			local dir_vector = vector_util.normalized(magnet_center - fo_center)

			-- x축 z축 이동을 각각 적용해 대각선으로 이동 못하는 경우에는 한 방향으로라도 이동 가능하도록
			if dir_vector.x ~= 0 then
				local dir_vector_x = unity_class.vector3.right

				if dir_vector.x < 0 then
					dir_vector_x = unity_class.vector3.left
				end

				local x_speed = math.abs(dir_vector.x / speed * progress)

				CS.Oak.MoveOneFrameStageLogic.ExecuteMove(fo, dir_vector_x, x_speed)
			end

			if dir_vector.z ~= 0 then
				local dir_vector_z = unity_class.vector3.forward

				if dir_vector.z < 0 then
					dir_vector_z = unity_class.vector3.back
				end

				local z_speed = math.abs(dir_vector.z / speed * progress)

				CS.Oak.MoveOneFrameStageLogic.ExecuteMove(fo, dir_vector_z, z_speed)
			end
		end
	end)

	local fade_dur = 0.8

	music_player_util.play_sfx_one_shot('01_drown_01')

	screen_util.fade_out_circular_async(fade_dur, 'linear')

	party_util.position_party(self.electric_magnet.reset_pos, 'left', 'linear')

	camera_util.return_to_leader(0.001)

	for i = 1, #self.party do
		local fo = self.party[i]
		character_util.remove_anim_and_emotion(fo)

		magnetic_fx_list[i]:Dispose()
	end

	magnetic_fx_list = nil

	wait_for_sec(1)

	screen_util.fade_in_circular_async(fade_dur, 'linear')
end

function local_class:set_android_remains_hitbox()
	for idx = 1, self.android_remains_num do
		local npc = self.npc.android_remains(idx)
		npc.Hitbox = CS.Oak.Hitbox( vector(0.4,0,0.5), vector(2.2, 0.75, 1.1))
	end
end

return local_class
