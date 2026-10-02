local local_class = newclass('HellForestFieldTintSetting')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--- 데이터 테이블 로드
	local controller_data = get_or_create_global_variable('stageeventcontrollers/HellForest/FieldTintSettingData')
	--- 현재 스테이지에서 적용될 틴트 색상 데이터
	local color_table = controller_data[stage.Name].field_tint_color
	--- 현재 스테이지에서 적용될 틴트 색상
	self.field_tint_color = unity_color({ color_table.r / 255, color_table.g / 255, color_table.b / 255 })
end

function local_class:load_resource()
	-- 로드 완료 이벤트 구독
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:dispose()
	self.cs_controller = nil

	-- 로드 완료 이벤트 해제
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event(e)
	-- 로드되자마자 틴트 적용
	field_util.tint('field_tint_setting_controller', self.field_tint_color, 0)
end

return local_class
