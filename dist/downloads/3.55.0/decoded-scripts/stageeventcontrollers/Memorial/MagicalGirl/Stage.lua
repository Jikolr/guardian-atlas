local local_class = newclass('MemorialMagicalGirlController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 7200103

	self.group_controller = nil

	-- 특정 섹션 환경음 제어용
	self.stage_amb_sfx = metatable_helper.inherit({
		playing_sfx = {
			sfx = nil,
			sfx_name = nil
		},
		use_sfx = false,
		sfx_info = {
			{
				zone = 'campus_square',
				sfx_name = '01_amb_highschool_01',
				volume = 0.4
			},
			{
				zone = 'classroom_area_1',
				sfx_name = '01_crowd_buzz_01',
				volume = 0.4,
			},
			{
				zone = 'classroom_area_2',
				sfx_name = '01_crowd_buzz_02',
				volume = 0.4,
			}
		}
	}, {
		zone_enter_event = function(this, e)
			if not this.use_sfx then
				return
			end

			for i, sfx_info in ipairs(this.sfx_info) do
				if this.playing_sfx.sfx_name ~= sfx_info.sfx_name and
						type_util.is_zone_full_enter(e, get_party_leader(), sfx_info.zone) then
					this:fade_out_sfx(2)
					this:play_sfx(sfx_info.sfx_name, sfx_info.volume)
					return
				end
			end
		end,
		play_sfx = function(this, sfx_name, volume, fade_in_time)
			if this.playing_sfx.sfx ~= nil then
				return
			end

			local sfx_volume = lua_helper.get_or_default(volume, 0.4)
			local sfx_fade_in_time = lua_helper.get_or_default(fade_in_time, 1)

			this.playing_sfx.sfx_name = sfx_name
			this.playing_sfx.sfx = music_player_util.play_sfx({
				sfx_name = sfx_name, volume = sfx_volume, fade_in_time = sfx_fade_in_time, loop = true })
		end,
		fade_out_sfx = function(this, duration)
			if this.playing_sfx.sfx == nil then
				return
			end

			music_player_util.fade_out_sfx(this.playing_sfx.sfx, duration)
			this.playing_sfx.sfx = nil
			this.playing_sfx.sfx_name = nil
		end,
		change_sfx_volume = function(this, volume, duration)
			if this.playing_sfx.sfx == nil then
				return
			end

			music_player_util.change_sfx_volume(this.playing_sfx.sfx, volume, duration)
		end,
		dispose_sfx = function(this)
			if this.playing_sfx.sfx == nil then
				return
			end

			music_player_util.stop_sfx(this.playing_sfx.sfx)
			this.playing_sfx.sfx = nil
			this.playing_sfx.sfx_name = nil
		end
	})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.stage_amb_sfx:dispose_sfx()

	self:dispose_group_controller()
	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	self.group_controller = get_or_create_global_table('Quest/Memorial/MagicalGirl/Common/MGEventGroupManager')
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	self.stage_amb_sfx:zone_enter_event(e)

	return false
end

function local_class:on_stage_end_event(_)
	self:dispose_group_controller()
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

	if quest_progress ~= nil and quest_progress.InnerProgress == 1 then
		self.stage_amb_sfx.use_sfx = true
	elseif quest_progress ~= nil and quest_progress.InnerProgress == 5 then
		self.stage_amb_sfx.use_sfx = true
	elseif quest_progress ~= nil and quest_progress.InnerProgress == 6 then
		self.stage_amb_sfx.use_sfx = true
	end

	stage_start_util.start_function(quest_progress)
end

function local_class:dispose_group_controller()
	if self.group_controller ~= nil then
		self.group_controller:dispose()
		self.group_controller = nil
	end
end

return local_class
