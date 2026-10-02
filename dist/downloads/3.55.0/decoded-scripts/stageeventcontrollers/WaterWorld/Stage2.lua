local local_class = newclass('WaterWorld2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 465
	self.quest_progress = nil

	self.obj_list = {
		data = {},

		---@param this self
		---@param key string
		---@param fo IFieldObject
		add = function(this, key, fo)
			if this.data[key] == nil then
				this.data[key] = fo
			end
		end,

		---@param this self
		---@param key string
		get = function(this, key)
			return this.data[key]
		end,

		---@param this self
		---@param key string
		dispose = function(this, key)
			if this.data[key] ~= nil then
				this.data[key]:Dispose()
				this.data[key] = nil
			end
		end,

		---@param this self
		dispose_all = function(this)
			for key, _ in pairs(this.data) do
				this:dispose(key)
			end
		end,
	}

	self.group_controller = nil

	self.amb_sfx = {
		handler = nil,

		---@param this self
		play_eat_music = function(this, play_pos, volume, fade_in_time)
			if this.handler ~= nil then
				return
			end

			volume = lua_helper.get_or_default(volume, 0.5)
			fade_in_time = lua_helper.get_or_default(fade_in_time, nil)

			this.handler = music_player_util.play_sfx({
				sfx_name = '03_equipping_01',
				loop = true,
				play_pos = play_pos,
				type_priority = 'loop',
				volume = volume,
				fade_in_time = fade_in_time
			})
		end,

		---@param this self
		---@param fade_out_time number
		fade_out = function(this, fade_out_time)
			fade_out_time = lua_helper.get_or_default(fade_out_time, 2)

			if this.handler == nil then
				return
			end

			music_player_util.fade_out_sfx(this.handler, fade_out_time)
			this.handler = nil
		end,

		---@param this self
		stop = function(this)
			if this.handler == nil then
				return
			end

			music_player_util.stop_sfx(this.handler)
			this.handler = nil
		end
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))

	self.group_controller = nil
	self.cs_controller = nil
	self.amb_sfx:stop()
end

function local_class:load_resource()
	local is_create
	is_create, self.group_controller = global_table_util.try_create('Quest/Main/WaterWorld/Common/WWNpcPoolingGroupManager')

	if is_create then
		self.group_controller:initialize()
	end
end

function local_class:on_event(e)
	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id and
			e.PrevProgress == 5 and
			e.CurrentProgress == 6 then

		for i = 1, 6 do
			self.obj_list:dispose('money_s5_' .. i)
		end

		self.amb_sfx:stop()

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

	self:pre_setting(quest_progress)

	stage_start_util.start_function(quest_progress)
end

function local_class:pre_setting(quest_progress)
	--1번 npc 아이템
	do
		local money_offset = {
			vector(-1.4, 0, 0),
			vector(-1, 0, 0.2),
			vector(-1, 0, -0.2),
		}

		for i = 1, #money_offset do
			local item = quest_drop_item_util.create_item({
				pos = vector(-3.3, 0, -149.5) + money_offset[i],
				item_id = 21590,
				scale = 0.7,
				loot_state = quest_drop_item_loot_state.dont_find_looter,
				show_on_character = false,
			})

			self.obj_list:add('money_' .. i, item)
		end
	end

	--11번 npc 아이템
	do
		local item = quest_drop_item_util.create_item({
			pos = vector(4, 0, -130) + vector(0, 0, -0.4),
			item_id = 21591,
			scale = 0.7,
			loot_state = quest_drop_item_loot_state.dont_find_looter,
			show_on_character = false,
		})

		self.obj_list:add('soju', item)
	end

	--5섹션부터 돈 뭉치 생성
	do
		local center_pos = field_util.get_marker_pos('s4_boss_center_pos')
		local money_offset = {
			vector(-2.5, 0, 0.5),
			vector(-3, 0, 0),
			vector(-2.5, 0, -0.5),
			vector(-0.5, 0, -2),
			vector(0, 0, -1.5),
			vector(0.5, 0, -2),
		}

		if quest_progress.InnerProgress > 3 and quest_progress.InnerProgress < 6 then
			for i = 1, #money_offset do
				local item = quest_drop_item_util.create_item({
					pos = center_pos + money_offset[i],
					item_id = 21590,
					scale = 0.7,
					loot_state = quest_drop_item_loot_state.dont_find_looter,
					show_on_character = false,
				})

				self.obj_list:add('money_s5_' .. i, item)
			end

			message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')

			self.amb_sfx:play_eat_music(center_pos)
		end
	end
end

return local_class
