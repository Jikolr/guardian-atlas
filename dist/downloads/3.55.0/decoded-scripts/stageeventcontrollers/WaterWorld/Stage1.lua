local local_class = newclass('WaterWorld1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 465
	self.quest_progress = nil

	self.s1_tint_key = 's1_night_sky'

	self.fx = setmetatable({
		asteroid = function()
			return unity_object_pool.GetOrCreate('fx_ww_asteroid')
		end,
		plitvis = function()
			return unity_object_pool.GetOrCreate('fx_ww_plitvis')
		end,

	}, {
		__index = {
			create_all = function(this)
				for _, creator in pairs(this) do
					creator()
				end
			end
		}
	})

	self.fx_star_list = {
		asteroid = nil,
		plitvis = nil,
	}

	self.npc = {
		telescope = function()
			return get_character('s1_telescope')
		end,
	}

	self.amb_beach_sfx = nil
	self.can_amb_sfx = true
end

function local_class:dispose()
	self.cs_controller = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self:stop_beach_amb()
	self:dispose_star_effect()
end

function local_class:load_resource()
	self.fx:create_all()
end

function local_class:on_event(e)
	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.npc.telescope()) then
		sp_util.play_normal_screenplay(self.interact_telescope, self)

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.can_amb_sfx and
			type_util.is_zone_full_enter(e, get_party_leader(), 'main_field') then
		self:play_beach_amb()

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.can_amb_sfx and
			type_util.is_zone_full_leave(e, get_party_leader(), 'main_field') then
		self:fade_out_beach_amb()

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
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	--망원경 인터렉트 이벤트 추가
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	local telescope = self.npc.telescope()
	telescope.Interactable = CS.Oak.PublishInteractable.Create()

	self:create_star_effect()

	if self.quest_progress.InnerProgress ~= 0 then
		--1섹션은 중간 부터 직접 호출함. 이외의 섹션 및 상황 에서는 항상 틴트값 유지.
		--self:field_tint()

		--마찬가지로, amb_beach_sfx 도 1섹션에서 직접 실행해줌.
		self.can_amb_sfx = true
		self:play_beach_amb()
	end

	stage_start_util.start_function(self.quest_progress)
end

function local_class:field_tint()
	field_util.tint(self.s1_tint_key, unity_color({ 0.48, 0.48, 0.48, 1 }), 0)
end

function local_class:remove_field_tint()
	field_util.remove_tint(self.s1_tint_key, 0)
end

function local_class:interact_telescope()
	local telescope = self.npc.telescope()
	local blue_moon_pos = field_util.get_marker_pos('s1_blue_moon_pos')
	local camera_pos = blue_moon_pos + vector(0, 0, 5.5)
	--최초 망원경 NPC가 해당 위치에 배치되어 있음.
	--플레이어가 망원경 NPC 인터렉트 시, 하단의 이벤트 진행.

	--1초에 걸쳐 플레이어 ■ 지점으로 up 방향 정렬.
	party_util.align_party(telescope.Position, 'down', 1)

	--1초 동안 화면 일반 페이드 아웃.
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	--틴트 잠깐 제거
	message_system:Publish(CS.Oak.ChangeTilemapVisualEvent.Create('controller_daylight'))

	--이미지와 같이, 서큘러 페이드가 절반만 되어 있는 상태로 변경.
	local ip = screen_util.get_interpolations('linear')
	yield_return(CS.Oak.CircularScreenTransition.Instance, 'FadeInAsync', 0, 0.3, ip)

	--카메라 ● 지점 포커스.
	camera_util.move_async(camera_pos, 0)

	--1초 동안 화면 일반 페이드 인.
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	--대기 3초
	wait_for_sec(3)

	--1초 동안 화면 일반 페이드 아웃.
	screen_util.fade_out_async(1.5, unity_class.color.black)

	--서큘러 페이드 아웃 상태 제거.
	screen_util.fade_out_circular_async(0, 'linear')
	screen_util.fade_in_circular_async(0, 'linear')

	--카메라 플레이어한테로 복귀.
	camera_util.return_to_leader(0)

	--틴트 원복
	message_system:Publish(CS.Oak.ChangeTilemapVisualEvent.Create('controller_night'))

	--1초 동안 화면 일반 페이드 인.
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	--플레이어 컨트롤 풀림.

	--해당 NPC 이벤트는 섹션 & 퀘스트 클리어 이후에도 계속 볼 수 있도록 처리.
end

function local_class:create_star_effect()
	local pivot_pos = field_util.get_marker_pos('s1_blue_moon_pos') + vector(0, 0, 5)

	--망원경 연출 / 1섹션 연출 시 중앙이 기준이 되도록 설정해놓았음.
	local asteroid_pos = pivot_pos + vector(-1, 0, 0)
	local plitvis_pos = pivot_pos + vector(1, 0, 0.5)

	self.fx_star_list.asteroid = self.fx.asteroid():Instantiate(asteroid_pos)
	self.fx_star_list.plitvis = self.fx.plitvis():Instantiate(plitvis_pos)
end

function local_class:dispose_star_effect()
	if self.fx_star_list.asteroid ~= nil then
		self.fx_star_list.asteroid:Dispose()
		self.fx_star_list.asteroid = nil
	end

	if self.fx_star_list.plitvis ~= nil then
		self.fx_star_list.plitvis:Dispose()
		self.fx_star_list.plitvis = nil
	end

	self.fx_star_list = nil
end

function local_class:play_beach_amb(volume, fade_in_time)
	--실내로 들어가면 믹스 디폴트값으로 종료, 다시 필드에 나오면 볼륨 0.2.
	volume = lua_helper.get_or_default(volume, 0.2)
	fade_in_time = lua_helper.get_or_default(fade_in_time, 1)

	if self.amb_beach_sfx == nil then
		self.amb_beach_sfx = music_player_util.play_sfx({
			sfx_name = '01_amb_beach_01', volume = volume, fade_in_time = fade_in_time, loop = true, type_priority = 'loop'
		})
	end
end

function local_class:change_beach_amb(volume, fade_in_time)
	volume = lua_helper.get_or_default(volume, 0.2)
	fade_in_time = lua_helper.get_or_default(fade_in_time, 1)
	if self.amb_beach_sfx ~= nil then
		music_player_util.change_sfx_volume(self.amb_beach_sfx, volume, fade_in_time)
	end
end

function local_class:fade_out_beach_amb(fade_out_time)
	fade_out_time = lua_helper.get_or_default(fade_out_time, 1)
	if self.amb_beach_sfx ~= nil then
		music_player_util.fade_out_sfx(self.amb_beach_sfx, fade_out_time)
		self.amb_beach_sfx = nil
	end
end

function local_class:stop_beach_amb()
	if self.amb_beach_sfx ~= nil then
		music_player_util.stop_sfx(self.amb_beach_sfx)
		self.amb_beach_sfx = nil
	end
end

return local_class
