local local_class = newclass('SubStageDreamVillageCyborgFighterController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 447

	self.shelf = {
		prefix = 'record_house_shelf_',
		speech_prefix = 'dv_sub_cyborg_fighter_narration_',

		sp_counts = { 2, 2, 2, 2 },

		get = function(this, idx)
			return get_field_object(this.prefix .. idx)
		end,

		try_event = function(this, fo)
			for idx = 1, #this.sp_counts do
				if fo == this:get(idx) then
					sp_util.start_scene(function()
						for jdx = 1, this.sp_counts[idx] do
							field_ui_util.show_narration_async({ key = this.speech_prefix .. idx .. '_' .. jdx })
						end
					end)

					return true
				end
			end

			return false
		end,
	}

	self.amb_sfx = {
		handler = nil,

		---@type fun(this:self, sfx_name:string, volume:number,mix:number):AudioSourceHolder
		play = function(this, sfx_name, volume, mix)
			if this.handler == nil then
				this.handler = music_player_util.play_sfx({
					sfx_name = sfx_name, volume = volume, fade_in_time = mix, loop = true, type_priority = 'event'
				})
			end

			return this.handler
		end,

		---@type fun(this:self, volume:number,mix:number)
		change_volume = function(this, volume, mix)
			if this.handler == nil then
				return
			end

			music_player_util.change_sfx_volume(this.handler, volume, mix)
		end,

		---@type fun(this:self, fade_time:number)
		stop = function(this, fade_time)
			if this.handler == nil then
				return
			end

			if type_util.is_number(fade_time) then
				music_player_util.fade_out_sfx(this.handler, fade_time)
			else
				music_player_util.stop_sfx(this.handler)
			end

			this.handler = nil
		end,
	}
end

function local_class:dispose()
	self.cs_controller = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent))
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent),
			'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent),
			'on_teleport_party_fadeout_finish_event')
end

function local_class:on_event(e)
	return self:on_interact_event(e)
end

function local_class:on_interact_event(e)
	if self.shelf:try_event(e.Target) then

		return true
	end

	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	self.exit_handle_name = e.ExitHandleName

	--bgm
	if self.exit_handle_name == 'master_house_stair_down' then
		music_player_util.play_stage_music({ state = 'muted' })

		return true
	elseif self.exit_handle_name == 'master_house_stair_up' then
		self.amb_sfx:stop(1)

		return true
	elseif self.exit_handle_name == 'tunnel_inner_exit' then
		music_player_util.play_stage_music({ state = 'muted' })

		return true
	elseif self.exit_handle_name == 'tunnel_outer_exit' then
		self.amb_sfx:stop(1)

		return true
	elseif self.exit_handle_name == 'tunnel_stair_inner_exit' then
		music_player_util.play_stage_music({ state = 'muted' })

		return true
	elseif self.exit_handle_name == 'tunnel_stair_outer_exit' then
		self.amb_sfx:stop(1)

		return true
	end

	return false
end

function local_class:on_teleport_party_fadeout_finish_event(_)
	--bgm
	if self.exit_handle_name == 'master_house_stair_down' then
		self.amb_sfx:play('01_amb_cave_01', 1, 1)

		return true
	elseif self.exit_handle_name == 'master_house_stair_up' then
		music_player_util.play_stage_music({ state = 'field', volume = 1, mix = 1 })

		return true
	elseif self.exit_handle_name == 'tunnel_inner_exit' then
		self.amb_sfx:play('01_amb_cave_01', 1, 1)

		return true
	elseif self.exit_handle_name == 'tunnel_outer_exit' then
		music_player_util.play_stage_music({ state = 'field', volume = 1, mix = 1 })

		return true
	elseif self.exit_handle_name == 'tunnel_stair_inner_exit' then
		self.amb_sfx:play('01_amb_cave_01', 1, 1)

		return true
	elseif self.exit_handle_name == 'tunnel_stair_outer_exit' then
		music_player_util.play_stage_music({ state = 'field', volume = 1, mix = 1 })

		return true
	end

	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s1_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s2_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s3_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s4_start_pos'), true, false)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

return local_class
