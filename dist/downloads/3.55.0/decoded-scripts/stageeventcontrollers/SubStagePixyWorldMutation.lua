local local_class = newclass('SubStagePixyWorldMutation')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 417

	-- field objects
	self.field_objects = {
		stick = function()
			return get_field_object('stick')
		end,
		knife_sword = function()
			return get_field_object('knife_sword')
		end,
		cardboard_box = function()
			return get_field_object('cardboard_box')
		end,
	}

	-- items
	self.items = {
		data = nil,
		add_item = function(this, item_id, pos, scale)
			if this.data == nil then
				this.data = {}
			end

			local item = quest_drop_item_util.create_item({
				pos = pos,
				item_id = item_id,
				spr_scale = scale,
				loot_state = quest_drop_item_loot_state.dont_find_looter,
			})

			table.insert(this.data, item)
		end,
		dispose_all = function(this)
			if this.data ~= nil then
				for i = 1, #this.data do
					quest_drop_item_util.dispose_item(this.data[i])
					this.data[i] = nil
				end

				this.data = nil
			end
		end
	}
end

function local_class:dispose()
	self.items:dispose_all()

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return true
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:set_item()

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:set_item()
	local stick = self.field_objects.stick()
	local knife_sword = self.field_objects.knife_sword()
	local cardboard_box = self.field_objects.cardboard_box()

	local stick_id = 21270
	local knife_sword_id = 21269
	local cardboard_box_id = 21268

	self.items:add_item(stick_id, stick.Position, 1)
	self.items:add_item(knife_sword_id, knife_sword.Position, 1)
	self.items:add_item(cardboard_box_id, cardboard_box.Position, 1)
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
