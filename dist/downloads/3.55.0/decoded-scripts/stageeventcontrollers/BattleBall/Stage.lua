local local_class = newclass('ShortStoryBattleBallController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.quest_id = 7002001

	self.minigame_audience_list = nil

	self.sfx_routine = setmetatable({
		sfx_list = {
			{ grid_name = 'amb_grid', zone_name = 'amb_sfx_zone',
			  sfx_name = '01_amb_meeting_01', volume = 0.7, priority = 2, zone_bound = nil },
			{ grid_name = 'beach_grid', zone_name = 'crowd_sfx_zone',
			  sfx_name = '01_crowd_beach_01', volume = 0.6, priority = 1, zone_bound = nil },
		},
		playing_sfx = { sfx_holder = nil, priority = 0, zone_name = nil, grid_name = nil },
		loop_grid_name = 'square_grid',
		is_zone_loop = false,
	},{
		__index = {
			grid_change = function(this, grid)
				-- 존 루프 정지
				this.is_zone_loop = false

				if grid.name == this.playing_sfx.grid_name then
					return
				end

				this:fade_out_sfx()

				for i = 1, #this.sfx_list do
					if grid.name == this.sfx_list[i].grid_name then
						this:play_sfx(i)
						return
					end
				end

				if grid.name == this.loop_grid_name then
					start_coroutine(this.zone_routine, this)
				end
			end,
			zone_routine = function(this)
				this.is_zone_loop = true

				while this.is_zone_loop do
					this:zone_leave_check()
					this:zone_enter_check()
					coroutine.yield()
				end
			end,
			zone_enter_check = function(this)
				if this.playing_sfx.sfx_holder ~= nil then
					return
				end

				for i = 1, #this.sfx_list do
					if CS.BoundsExtensions.ContainsXZ(this.sfx_list[i].zone_bound, stage_camera.LookAtPosition) then
						this:play_sfx(i)
						return
					end
				end
			end,
			zone_leave_check = function(this)
				if this.playing_sfx.sfx_holder == nil then
					return
				end

				for i = 1, #this.sfx_list do
					if this.playing_sfx.zone_name == this.sfx_list[i].zone_name and
							not CS.BoundsExtensions.ContainsXZ(this.sfx_list[i].zone_bound, stage_camera.LookAtPosition) then
						this:fade_out_sfx()
						return
					end
				end
			end,
			play_sfx = function(this, index)
				this.playing_sfx.zone_name = this.sfx_list[index].zone_name
				this.playing_sfx.grid_name = this.sfx_list[index].grid_name
				this.playing_sfx.sfx_holder = music_player_util.play_sfx({
					loop = true,
					sfx_name = this.sfx_list[index].sfx_name,
					volume = this.sfx_list[index].volume,
					fade_in_time = 1,
					type_priority = 'event',
					player_priority = 'npc'
				})
			end,
			stop_sfx = function(this)
				if this.playing_sfx.sfx_holder ~= nil then
					music_player_util.stop_sfx(this.playing_sfx.sfx_holder)
					this.playing_sfx.sfx_holder = nil
				end

				this.playing_sfx.priority = 0
				this.playing_sfx.zone_name = nil
				this.playing_sfx.grid_name = nil
				this.is_zone_loop = false
			end,
			fade_out_sfx = function(this)
				if this.playing_sfx.sfx_holder ~= nil then
					music_player_util.fade_out_sfx(this.playing_sfx.sfx_holder, 1)
					this.playing_sfx.sfx_holder = nil
				end

				this.playing_sfx.priority = 0
				this.playing_sfx.zone_name = nil
				this.playing_sfx.grid_name = nil
			end,
			set_zone_bound = function(this)
				for i = 1, #this.sfx_list do
					this.sfx_list[i].zone_bound = field:GetZone(this.sfx_list[i].zone_name).Bounds
				end
			end
		}
	})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent))

	self.sfx_routine:stop_sfx()

	self.sfx_routine = nil
	self.cs_controller = nil
end

function local_class:load_resource()
	local is_create
	is_create, self.place_controller = global_table_util.try_create_character_place_controller()

	self.place_controller:initialize()
end

function local_class:on_event(e)
	return false
end

function local_class:on_watching_camera_grid_changed_event(e)
	if e.CameraGrid ~= nil then
		self.sfx_routine:grid_change(e.CameraGrid)

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
	self.sfx_routine:set_zone_bound()

	message_system:Subscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent), 'on_watching_camera_grid_changed_event')

	local quest_progress = user_progress:GetStartedQuest(self.quest_id)
	stage_start_util.start_function(quest_progress)
end

function local_class:load_audience_list()
	local quest_progress = user_progress:GetStartedQuest(self.quest_id)

	if quest_progress ~= nil then
		if quest_progress.InnerProgress == 2 or quest_progress.InnerProgress == 6 or
				quest_progress.InnerProgress == 9 or
				quest_progress.InnerProgress == 12 or quest_progress.InnerProgress == 14 then
			self.minigame_audience_list = {}
			local group = self.place_controller:get_group('minigame_audience_group_1')
			self.minigame_audience_list['center_left'] = group.dynamic_member_list

			group = self.place_controller:get_group('minigame_audience_group_2')
			self.minigame_audience_list['center_right'] = group.dynamic_member_list

			group = self.place_controller:get_group('minigame_audience_group_3')
			self.minigame_audience_list['outside_left'] = group.dynamic_member_list

			group = self.place_controller:get_group('minigame_audience_group_4')
			self.minigame_audience_list['outside_right'] = group.dynamic_member_list
		end
	end
end

function local_class:set_one_side_audience_alpha_fade(side, value, duration)
	if self.minigame_audience_list == nil then
		self:load_audience_list()
	end

	for _, npc in pairs(self.minigame_audience_list[side]) do
		character_util.spine_set_alpha_fade_v2(npc, value, duration)
	end
end

function local_class:set_one_side_audience_anim(side, anim)
	if self.minigame_audience_list == nil then
		self:load_audience_list()
	end

	for _, npc in pairs(self.minigame_audience_list[side]) do
		scene_util.set_anim(npc, self, { name = anim, one_shot_sfx = false })
	end
end

function local_class:set_one_side_audience_active(side, state)
	if self.minigame_audience_list == nil then
		self:load_audience_list()
	end

	for _, npc in pairs(self.minigame_audience_list[side]) do
		field_object_util.set_active_state(npc, state)
	end
end

return local_class
