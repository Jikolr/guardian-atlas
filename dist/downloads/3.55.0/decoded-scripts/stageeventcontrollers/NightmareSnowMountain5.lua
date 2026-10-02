local local_class = newclass("NightmareSnowMountain5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 매드 팬더 후일담 관련
	self.get_madpanda_leaflet = function() return get_field_object('madpanda_leaflet') end
	self.madpanda_string_default_key = 'nightmare_snowmountain_5_madpanda_'
	self.paper_piece_id = 20022
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event()
	-- paper_piece 세팅
	local mad = self.get_madpanda_leaflet()
	self.paper_piece_object = drop_item_util.create_item({ pos = mad.Position + vector(0, 1, 0), itemid = self.paper_piece_id,
	                                                       lootstate = 'dontfindlooter', notforinven = true, skip_text = true })
	return true
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	if self.paper_piece_object ~= nil then
		self.paper_piece_object:ConsumeComplete()
		self.paper_piece_object = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local madpanda_leaflet = self.get_madpanda_leaflet()

	if lua_helper.reference_equals(e.Target, madpanda_leaflet) then
		-- 매드팬더 출장 회복 서비스 전단지 확인
		sp_util.play_normal_screenplay(self.read_madpanda_leaflet, self)
		return true
	end

	return false
end

-- 매드팬더 출장 회복 서비스 전단지 내용
function local_class:read_madpanda_leaflet()
	-- 1. 고객님이 불러주시면 어디든 찾아가는 매드 팬더 출장 회복 서비스!
	-- 2. 다른 조건 없이, 어디든 200골드로 모십니다!
	-- 3. ※ 산간 등 도서지역 출장 시, 출장비 5000만 골드. ※ / ※ 재수 없는 캔터베리 가디언과 연관된 놈들은 절대 사절. ※
	for i = 1, 3 do
		field_ui_util.show_narration_async({ key = self.madpanda_string_default_key .. i })
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}