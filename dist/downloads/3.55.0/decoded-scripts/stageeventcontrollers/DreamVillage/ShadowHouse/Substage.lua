local local_class = newclass('DreamVillageShadowHouseController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 442

	self.get_bookcase = function(number)
		return get_field_object('s' .. number .. '_bookcase')
	end

	self.get_s2_center_pos = function()
		return field_util.get_marker_pos('s2_center_pos_3')
	end

	self.get_s3_center_pos = function()
		return field_util.get_marker_pos('s3_center_pos_3')
	end

	--region Fx
	self.fx = {
		twinkle = function()
			return unity_object_pool.GetOrCreate('FX_Object_Twinkle')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}
	self.fx_list = {}
	self.bookcase_list = {}
	--endregion Fx

	self.sp_controller = nil
end

function local_class:dispose()
	if self.sp_controller then
		self.sp_controller:dispose()
		self.sp_controller = nil
	end

	self.cs_controller = nil

	self:fx_dispose_all()

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	self.fx:load_all()
end

function local_class:on_event(e)
	return false
end

function local_class:on_interact_event(e)
	local s2_bookcase = self.get_bookcase(2)
	local s3_bookcase = self.get_bookcase(3)
	local s4_bookcase = get_field_object('s4_book')

	local time_conversion = get_stage_event_controller('TimeConversionManager')

	if lua_helper.reference_equals(e.Target, s2_bookcase) then
		--2섹션 책장 나레이션 파트
		if time_conversion.time_zone.daylight == time_conversion.current_time_zone then
			if self.fx_list['s2'] then
				self.fx_list['s2']:Dispose()
				self.fx_list['s2'] = nil
			end

			self.sp_controller:try_start_scene(function()
				--나레이션 박스 내용 - 대감의 일기
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_narration_1' })

				--혼례를 올린 뒤 매일매일 행복한 나날이 이어지고 있다. 아내는 내가 작은 꽃 한송이를 가져다줘도 세상을 다 가진듯 환히 웃어준다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s2_39' })

				--서민과 결혼했다는 이유만으로 가문에서는 여전히 그녀를 보는 시선이 곱지 않다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s2_40' })

				--나만 믿고 저택에 들어와 사는 그녀를 평생 지켜주기로 맹세했다. 아내가 상처받을 일이 없었으면 좋겠다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s2_41' })
			end)
		else
			--밤에 책장 오브젝트 인터랙트 시 나레이션 박스 출력
			--어두워서 읽을 수 없다
			self.sp_controller:try_start_scene(function()
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s2_41_1' })
			end)
		end
	elseif lua_helper.reference_equals(e.Target, s3_bookcase) then
		--3섹션 책장 나레이션 파트
		if time_conversion.time_zone.daylight == time_conversion.current_time_zone then
			if self.fx_list['s3'] then
				self.fx_list['s3']:Dispose()
				self.fx_list['s3'] = nil
			end

			self.sp_controller:try_start_scene(function()
				--나레이션 박스 내용 - 대감의 일기
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_narration_1' })

				--최근 창고에 있던 재산을 일부 풀어 마을의 궁핍한 이들을 돕고자 하였으나, 일전에 하인에게 맡겼을 때 보석을 들고 도망친 적이 있어 곤란했다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s3_27' })

				--그런 내 고민을 알게된 아내가 자신이 자진해서 일을 맡겠다고 하여, 앞으론 그녀가 창고를 관리하게 되었다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s3_28' })

				--아내는 자신의 일이 생겨 기쁜지 특유의 종종 걸음으로 밤낮없이 창고를 오간다. 심성이 고운 사람에게 일을 맡겨 안심이다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s3_29' })
			end)
		else
			self.sp_controller:try_start_scene(function()
				--밤에 책장 오브젝트 인터랙트 시 나레이션 박스 출력
				--어두워서 읽을 수 없다
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s3_30' })
			end)
		end
	elseif lua_helper.reference_equals(e.Target, s4_bookcase) then
		--4섹션 책장 나레이션 파트
		if time_conversion.time_zone.daylight == time_conversion.current_time_zone then
			if self.fx_list['s4'] then
				self.fx_list['s4']:Dispose()
				self.fx_list['s4'] = nil
			end

			self.sp_controller:try_start_scene(function()
				--나레이션 박스 내용 - 대감의 일기
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_narration_1' })

				--하인들이 근래 아내가 재산을 빼돌리고 있다고 말하기에 놀라 확인했더니 장부의 일부가 거짓으로 기록되어 있었다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_narration_2' })

				--사실 확인을 위해 아내에게 처음으로 화를내며 따져물었더니 오해라며 슬퍼했다. 그녀의 슬픈 표정을 애써 외면했다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_narration_3' })

				--아내에게서 나는 익숙한 아네모네 향기가 혼례날을 떠올리게 만든다. 나만큼은 아내를 믿고 싶다는 생각이 든다.
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_narration_4' })
			end)
		else
			self.sp_controller:try_start_scene(function()
				--밤에 책장 오브젝트 인터랙트 시 나레이션 박스 출력
				--어두워서 읽을 수 없다
				field_ui_util.show_narration_async({ key = 'dv_sub_shadow_house_s3_30' })
			end)
		end
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

	-- 나레이션 박스 시작 위치 설정(invisible_wall)
	do
		self.bookcase_list = {
			s2 = {
				target = self.get_bookcase(2),
				pos = self.get_s2_center_pos() + vector(5, 0, 3.5),
				fx_pos = self.get_s2_center_pos() + vector(5, 2, 2.5)
			},
			s3 = {
				target = self.get_bookcase(3),
				pos = self.get_s3_center_pos() + vector(4.5, 0, -3),
				fx_pos = self.get_s3_center_pos() + vector(4.5, 2, -3.5)
			},
			s4 = {
				target = get_field_object('s4_book'),
				pos = field_util.get_marker_pos('s4_book_pos'),
				fx_pos = field_util.get_marker_pos('s4_book_pos') + vector(0, 2, -1.5)
			}
		}

		for name, target_data in pairs(self.bookcase_list) do
			self.fx_list[name] = nil

			target_data.target.Interactable = CS.Oak.PublishInteractable.Create()
			target_data.target.Position = target_data.pos
		end

		local created, dv_sp_manager = global_table_util.try_create_dream_village_screenplay_manager()
		self.sp_controller = dv_sp_manager:get_sp_controller(self.cs_controller)
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s1_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s2_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s3_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s4_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s5_start_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end

	if quest_progress.InnerProgress > 2 then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('s3_door_puzzle'))
	end
end

function local_class:fx_dispose_all()
	if self.fx_list then
		for _, target in pairs(self.fx_list) do
			if target then
				target:Dispose()
				target = nil
			end
		end

		self.fx_list = nil
	end
end

return local_class
