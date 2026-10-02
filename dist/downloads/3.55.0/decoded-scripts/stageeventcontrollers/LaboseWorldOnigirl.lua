local local_class = newclass('LaboseWorldOnigirlController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.quest_id = 395

	self.scene_version = scene_util.default_version

	self.util = nil

	-- character
	self.characters = {
		civilian_male = function()
			return get_character('demon_civilian_male')
		end,
		civilian_female = function()
			return get_character('demon_civilian_female')
		end,
		punk_male = function()
			return get_character('demon_punk_male')
		end,
		punk_female = function()
			return get_character('demon_punk_female')
		end,
		police_male = function()
			return get_character('demon_police_male')
		end,
		oldwoman = function()
			return get_character('demon_oldwoman')
		end,
		homeless_male = function()
			return get_character('demon_homeless_male')
		end,
		business_female = function()
			return get_character('demon_business_female')
		end,
		street_sweeper = function()
			return get_character('demon_street_sweeper')
		end,
		kid_girl = function()
			return get_character('demon_kid_girl')
		end,
		kid_boy = function()
			return get_character('demon_kid_boy')
		end,
		oldman = function()
			return get_character('demon_oldman')
		end,
		carpenter = function()
			return get_character('demon_carpenter')
		end
	}

	-- marker
	self.markers = {
		police_pos = function()
			return field_util.get_marker_pos('police_pos')
		end,
		rooftop_pos = function(number)
			return field_util.get_marker_pos('civilian_pos_' .. number)
		end
	}

	self.zones = {
		rooftop = 'rooftop_zone',
		floor = 'floor_zone'
	}

	self.rooftop_check = false

	-- fx
	self.labose_fxs = nil
	self.labose_zone_count = 4
	self.labose_zone_pre_fix = 'labose_fx_zone_'

	self.fx = {
		virus_fog_weak = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_strong_down')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	if self.labose_fxs ~= nil then
		for _, fx in pairs(self.labose_fxs) do
			fx:Dispose()
			fx = nil
		end
	end

	self.labose_fxs = nil

	self.util = nil
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.labose_fxs = {}

	self.fx:load_all()

	self.util = get_or_create_global_table('Quest/Main/LaboseWorld/Common/Util')

	yield_return(unity_object_pool, 'WaitAll')

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	start_coroutine(self.launch_routine, self)
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if not self.rooftop_check and type_util.is_zone_full_enter(e, get_party_leader(), self.zones.rooftop) then
		self.rooftop_check = true
		start_coroutine(function()
			wait_for_sec(0.1)

			stage_camera.ImageEffectController.enabled = false

			local in_roof_top = field:IsOnUpperFloor(user_party.Leader.Position)

			if in_roof_top then
				self.util:change_rooftop_effect_state(false)
			end
		end)

		return true

	elseif self.rooftop_check and type_util.is_zone_full_enter(e, get_party_leader(), self.zones.floor) then
		self.rooftop_check = false
		stage_camera.ImageEffectController.enabled = true

		return true
	end

	return false
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
	local quest_progress = user_progress:GetStartedQuest(self.quest_id)

	for i = 1, self.labose_zone_count do
		self:add_labose_zone(i)
	end

	if quest_progress == nil or quest_progress.IsComplete then
			stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s1_camera_pos_5'),
					true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 1 then
		self:rooftop_setting()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s1_camera_pos_5'),
				true, true)
	elseif quest_progress.InnerProgress == 2 then
		self:rooftop_setting()
		self:safe_oldman_setting()
		self:safe_carpenter_setting()
		self:safe_kid_boy_setting()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, false)
	else
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:rooftop_setting()
	local police_male = self.characters.police_male()
	character_util.set_position(police_male, self.markers.police_pos())
	scene_util.set_direction(police_male, 'down', false)
	scene_util.set_emotion(police_male, self, 'tired')
	scene_util.set_anim(police_male, self, { name = 'idle', one_shot_sfx = false })
	police_male.Interactable.Talk = 'lw_sub_lana_oneline_1'

	local civilian_male = self.characters.civilian_male()
	character_util.set_position(civilian_male, self.markers.rooftop_pos(1))
	scene_util.set_direction(civilian_male, 'right', false)
	scene_util.set_emotion(civilian_male, self, 'tired')
	scene_util.set_anim(civilian_male, self, { name = 'seat', one_shot_sfx = false })
	civilian_male.Interactable.Talk = 'lw_sub_lana_oneline_2'

	local street_sweeper = self.characters.street_sweeper()
	character_util.set_position(street_sweeper, self.markers.rooftop_pos(2))
	scene_util.set_direction(street_sweeper, 'right', false)
	scene_util.set_emotion(street_sweeper, self, 'tired')
	scene_util.set_anim(street_sweeper, self, { name = 'idle', one_shot_sfx = false })
	street_sweeper.Interactable.Talk = 'lw_sub_lana_oneline_3'

	local kid_girl = self.characters.kid_girl()
	character_util.set_position(kid_girl, self.markers.rooftop_pos(3))
	scene_util.set_direction(kid_girl, 'right', false)
	scene_util.set_emotion(kid_girl, self, 'cry')
	scene_util.set_anim(kid_girl, self, { name = 'idle', one_shot_sfx = false })
	kid_girl.Interactable.Talk = 'lw_sub_lana_oneline_4'

	local business_female = self.characters.business_female()
	character_util.set_position(business_female, self.markers.rooftop_pos(4))
	scene_util.set_direction(business_female, 'left', false)
	scene_util.set_emotion(business_female, self, 'tired')
	scene_util.set_anim(business_female, self, { name = 'idle', one_shot_sfx = false })
	business_female.Interactable.Talk = 'lw_sub_lana_oneline_5'

	local civilian_female = self.characters.civilian_female()
	character_util.set_position(civilian_female, self.markers.rooftop_pos(5))
	scene_util.set_direction(civilian_female, 'left', false)
	scene_util.set_emotion(civilian_female, self, 'tired')
	scene_util.set_anim(civilian_female, self, { name = 'seat', one_shot_sfx = false })
	civilian_female.Interactable.Talk = 'lw_sub_lana_oneline_6'

	local punk_female = self.characters.punk_female()
	character_util.set_position(punk_female, self.markers.rooftop_pos(6))
	scene_util.set_direction(punk_female, 'right', false)
	scene_util.set_emotion(punk_female, self, 'tired')
	scene_util.set_anim(punk_female, self, { name = 'cast', one_shot_sfx = false })
	punk_female.Interactable.Talk = 'lw_sub_lana_oneline_7'

	local punk_male = self.characters.punk_male()
	character_util.set_position(punk_male, self.markers.rooftop_pos(7))
	scene_util.set_direction(punk_male, 'left', false)
	scene_util.set_emotion(punk_male, self, 'tired')
	scene_util.set_anim(punk_male, self, { name = 'idle', one_shot_sfx = false })
	punk_male.Interactable.Talk = 'lw_sub_lana_oneline_8'

	local oldwoman = self.characters.oldwoman()
	character_util.set_position(oldwoman, self.markers.rooftop_pos(8))
	scene_util.set_direction(oldwoman, 'right', false)
	scene_util.set_emotion(oldwoman, self, 'tired')
	scene_util.set_anim(oldwoman, self, { name = 'idle', one_shot_sfx = false })
	oldwoman.Interactable.Talk = 'lw_sub_lana_oneline_9'

	local homeless_male = self.characters.homeless_male()
	character_util.set_position(homeless_male, self.markers.rooftop_pos(9))
	scene_util.set_direction(homeless_male, 'left', false)
	scene_util.set_emotion(homeless_male, self, 'tired')
	scene_util.set_anim(homeless_male, self, { name = 'idle', one_shot_sfx = false })
	homeless_male.Interactable.Talk = 'lw_sub_lana_oneline_10'
end

function local_class:safe_oldman_setting()
	local oldwoman = self.characters.oldwoman()
	local oldman = self.characters.oldman()

	--시민1 (right, smile, idle) : 난 괜찮소, 할멈! 무사해서 다행이오.
	character_util.set_position(oldman, oldwoman.Position + vector(-1, 0, 0))
	scene_util.set_direction(oldman, 'right', false)
	scene_util.set_emotion(oldman, self, 'smile')
	scene_util.set_anim(oldman, self, { name = 'idle', one_shot_sfx = false })
	oldman.Interactable.Talk = 'lw_sub_lana_oneline_11'

	--시민8 (left, smile, idle) : 영감…! 무사했구려! 다친덴 없수?
	scene_util.set_direction(oldwoman, 'left', false)
	scene_util.set_emotion(oldwoman, self, 'smile')
	scene_util.set_anim(oldwoman, self, { name = 'idle', one_shot_sfx = false })
	oldwoman.Interactable.Talk = 'lw_sub_lana_oneline_12'
end

function local_class:safe_carpenter_setting()
	local street_sweeper = self.characters.street_sweeper()
	local carpenter = self.characters.carpenter()

	--마계 인부2 (left, tired, cast) : 죄송합니다, 반장님…! 작업에 열중하다보니 정신이 없어서…
	character_util.set_position(carpenter, street_sweeper.Position + vector(1, 0, 0))
	scene_util.set_direction(carpenter, 'left', false)
	scene_util.set_emotion(carpenter, self, 'tired')
	scene_util.set_anim(carpenter, self, { name = 'cast', one_shot_sfx = false })
	carpenter.Interactable.Talk = 'lw_sub_lana_oneline_13'

	--마계 인부1 (right, attack, cross_arm) : 막내, 이 멍청아! 긴급 상황이면 매뉴얼대로 우선 대피해야할 거 아냐!
	scene_util.set_direction(street_sweeper, 'right', false)
	scene_util.set_emotion(street_sweeper, self, 'attack')
	scene_util.set_anim(street_sweeper, self, { name = 'cross_arm', one_shot_sfx = false })
	street_sweeper.Interactable.Talk = 'lw_sub_lana_oneline_14'
end

function local_class:safe_kid_boy_setting()
	local police_male = self.characters.police_male()
	local kid_boy = self.characters.kid_boy()
	local civilian_female = self.characters.civilian_female()

	character_util.set_position(police_male, field_util.get_marker_pos('s1_police_pos_3'))
	scene_util.set_direction(police_male, 'down', false)

	--시민3 (right, cry, idle) : 엄마아아!! 나 무서웠어!
	character_util.set_position(kid_boy, civilian_female.Position + vector(-0.5, 0, 0))
	scene_util.set_direction(kid_boy, 'right', false)
	scene_util.set_emotion(kid_boy, self, 'cry')
	scene_util.set_anim(kid_boy, self, { name = 'idle', one_shot_sfx = false })
	kid_boy.Interactable.Talk = 'lw_sub_lana_oneline_15'

	--시민5 (left, cry, push) : 우리 아가!! 무사해서 정말 다행이야…!
	scene_util.set_direction(civilian_female, 'left', false)
	scene_util.set_emotion(civilian_female, self, 'cry')
	scene_util.set_anim(civilian_female, self, { name = 'push', one_shot_sfx = false })
	civilian_female.Interactable.Talk = 'lw_sub_lana_oneline_16'
end

--- 라보스 안개 영역 추가 함수
function local_class:add_labose_zone(zone_index)
	local zone_name = self.labose_zone_pre_fix .. zone_index
	local xz_adder = 0.5
	local zone = field_util.get_zone(zone_name)

	if zone == nil then
		logger_util.error('has no [' .. zone_name .. '] zone')
	else
		local min_x = zone.Bounds.min.x + xz_adder
		local min_z = zone.Bounds.min.z + xz_adder
		local max_x = zone.Bounds.max.x - xz_adder
		local max_z = zone.Bounds.max.z - xz_adder

		local start_pos = vector(min_x, 0, min_z)
		local end_pos = vector(max_x, 0, max_z)
		local cur_pos

		for x = math.floor(start_pos.x), math.floor(end_pos.x) do
			for z = math.floor(start_pos.z), math.floor(end_pos.z) do
				cur_pos = vector(x, 0, z)

				local fx = self.fx.virus_fog_weak():Instantiate(cur_pos)

				table.insert(self.labose_fxs, fx)
			end
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
