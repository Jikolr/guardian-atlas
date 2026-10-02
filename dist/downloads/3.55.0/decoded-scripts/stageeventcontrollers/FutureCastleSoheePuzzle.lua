local local_class = newclass('FutureCastleSoheePuzzleController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()

	if not is_unity_null(self.journal) then
		self.journal:ConsumeComplete()
		self.journal = nil
	end

	if not is_unity_null(self.journal_interactable) then
		self.journal_interactable.Interactable = CS.Oak.NonInteractable.Instance
		self.journal_interactable = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	local journal = self.journal_interactable

	if lua_helper.reference_equals(journal, e.Target) then
		sp_util.play_normal_screenplay(self.read_journal, self)
		return true
	end
	return false
end

function local_class:on_stage_start_event(e)
	self.journal_interactable = get_field_object('sohee_journal_interactable')


	-- 20022 : paper_piece
	---[[
	self.journal = drop_item_util.create_item(
			{ pos = self.journal_interactable.Position + 0.5 * unity_class.vector3.up, itemid = 20022, lootstate = 'dontfindlooter'
			, notforinven = true, skip_text = true })
	self.journal_interactable = get_field_object('sohee_journal_interactable')
	--]]
	self.journal_interactable.Interactable = CS.Oak.PublishInteractable.Create()
end

-- 소희의 일지 읽기
function local_class:read_journal()
	-- 버스터 터렛이 정상적으로 작동하는 걸 확인했다. 얼마나 잘 작동하는지는, 통구이가 된 인베이더 놈들한테 물어보면 됨. 아, 맞다. 통구이가 되면 말을 못 하지?
	field_ui_util.show_narration_async( { key = 'futurecastle_sohee_puzzle_1' })

	-- 터렛에 충격이 가해지면 전원 공급이 불안정해질 때가 있는데… 마리안 말대로 내부 공급 방식으로 설계했어야 하나? 하하하, 나도 참 농담이 늘었다
	field_ui_util.show_narration_async( { key = 'futurecastle_sohee_puzzle_2' })

	-- 아이언 자이언트와의 도킹 포트 제작 중. 도킹 후 하중은 어떻게 지탱하지? 또 에너지 역류 현상을 방지하려면? 힘들어. 토 나와. 머리 아파. 재수 없는 놈, 일을 하다 말고 도망치는 게 어디 있어? 과학자 망신은 다 시키지.
	field_ui_util.show_narration_async( { key = 'futurecastle_sohee_puzzle_3' })

	-- 나흘 내리 밤 새서 도킹 포트 완성. 마리안이 봤음 뭐라고 했을까. 거지 같다고? 조잡하다고? 생각만 해도 재수 없네… 어떻게 지내고 있나…
	field_ui_util.show_narration_async( { key = 'futurecastle_sohee_puzzle_4' })
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
