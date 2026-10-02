local local_class = newclass('FireWorld4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	self.main_quest_id = 478
	self.quest_progress = nil

	self.fo = {
		door = function()
			return get_field_object('s19_open_door')
		end
	}

	self.get_statue = function()
		return get_character('fw_fire_dragon_king_statue')
	end

	self.smoke_fx = nil
	self.fx = metatable_helper.create_fx_accessor({
		smoke_screen_loop = function()
			return unity_object_pool.GetOrCreate('fx_fw_brimstone_smoke_screen_stage_loop')
		end,
	})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self:dispose_smoke_fx()

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	local statue = self.get_statue()

	field_ui_manager:RemoveUI(statue, CS.Oak.FieldUiType.CharacterStats)
	character_util.spine_scale(statue, vector(3, 3, 3), 0)
	character_util.force_update_spines(statue, 0.1)

	return true
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
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.fx:load_async()

	self:set_plate()
	self:set_door()
	self:set_smoke_fx()

	-- 칼로르 무기 숨김
	local first_bishops = { 'first_bishop', 'first_bishop_young', 'first_bishop_myth' }

	for i = 1, #first_bishops do
		local first_bishop = get_character(first_bishops[i])
		scene_util.hide_weapon(first_bishop)
		message_system:SendSync(first_bishop, CS.Oak.CharacterBehaviourResetEvent.Instance)
	end

	stage_start_util.start_function(self.quest_progress)
end

function local_class:set_plate()
	if self.quest_progress == nil or self.quest_progress.InnerProgress < 17 then
		return
	end

	local plate = get_field_object('s17_plate')

	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
	damage_info.sender = plate
	damage_info.target = plate
	damage_info.damage = 1

	command_util.publish_damage(damage_info)
end

function local_class:set_door()
	if self.quest_progress == nil or self.quest_progress.InnerProgress < 19 then
		return
	end

	animator_util.play(self.fo.door(), 'opened')
end

function local_class:dispose_smoke_fx()
	if self.smoke_fx ~= nil then
		self.smoke_fx:Dispose()
		self.smoke_fx = nil
	end
end

function local_class:set_smoke_fx()
	if self.quest_progress == nil or self.quest_progress.InnerProgress < 13 then
		return
	end

	self:create_smoke_fx()
end

function local_class:create_smoke_fx()
	if self.smoke_fx == nil then
		self.smoke_fx = self.fx.smoke_screen_loop():Instantiate(stage_camera.transform.position + vector(0, 8, -8),
				unity_class.quaternion.identity, stage_camera.transform)
	end
end

return local_class
