local local_class = newclass('AfterWorldEvidence')

function local_class:init()
	-- 현재 연결되어있는 루아 클래스
	-- 메인 섹션 13, 14만 사용할 것임
	self.connected_class = nil

	-- 버튼 GameObject
	self.clue_ui_button = nil
	self.clue_ui_button_controller = nil

	-- 팝업창이 열려있는지
	self.clue_ui_popup_on = false

	-- 버튼을 사용할 수 있는지
	self.clue_ui_button_on = false

	--버튼이 강제로 막힌 상태인지
	self.clue_ui_button_blocked = false

	-- 전투 중인지 상태 체크
	self.is_battle = false

	self.resholder = nil
end

function local_class:pre_load_async()
	if self.resholder ~= nil then
		return
	end

	self.resholder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/afterworld/ui', 'EvidencePopup', function(prefab)
				local book_obj = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				local overlay = book_obj:GetComponent(typeof(CS.Oak.UI.IUIOverlay))
				overlay.UISceneManager = stage.UISceneManager
				book_obj:SetActive(false)
			end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/afterworld/ui', 'EvidenceButton', function(prefab)
				self.clue_ui_button = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)

				self.clue_ui_button_controller = self.clue_ui_button:GetComponent(typeof(CS.Oak.UI.EvidenceButtonUI))

				local button = self.clue_ui_button.transform:Find('Contents'):Find('Button')

				local button_component = button:GetComponent(typeof(CS.UIButton))

				button_component.onClick:Clear()
				CS.EventDelegate.Set(button_component.onClick, function()
					self:show_clue_popup()
				end)

				self.clue_ui_button:SetActive(false)
			end)

	self.clue_ui_popup_on = false
	self.clue_ui_button_on = false

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
end

function local_class:dispose()
	self:set_connected_class(nil)

	if self.resholder ~= nil then
		self.resholder:Dispose()
	end
	self.resholder = nil

	--게임 오브젝트들 Destroy
	if is_unity_null(self.clue_ui_button) == false then
		CS.UnityEngine.GameObject.Destroy(self.clue_ui_button)
	end
	self.clue_ui_button = nil

	self.clue_ui_button_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	-- 만약 FieldUI를 꺼둔 상태이면 blocking 될 것이므로 패스 -> 나중에 켜짐
	-- FieldUI를 켜둔 상태이면 사작할 때 켜줄 수 있음
	self:show_clue_button()

	return true
end

function local_class:on_connect()
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')
end

function local_class:on_disconnect()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')
end

function local_class:set_connected_class(target)
	if self.connected_class ~= target then
		-- 해제 했다가 다시 연결하는 경우 구독 요청이 씹힐 수가 있음
		if self.connected_class ~= nil and target ~= nil then
			-- 현재 연결된것도 같이 바꿔줌
			self.connected_class = target
			return
		end

		if self.connected_class ~= nil then
			self:on_disconnect()
		end

		self.connected_class = target

		if target ~= nil then
			self:on_connect()
		end
	end
end

function local_class:show_clue_popup(close_cb, present_cb, open_index)
	if self.connected_class ~= nil and self.connected_class.get_clue_ui_data ~= nil and self.clue_ui_popup_on == false then
		self.clue_ui_popup_on = true

		local data = self.connected_class:get_clue_ui_data()

		local evidence_data = CS.Oak.UI.EvidencePopupState()
		evidence_data.EvidenceList = create_generic_list(CS.Oak.UI.EvidenceItemState)

		for _, info in pairs(data) do
			local clue_data = CS.Oak.UI.EvidenceItemState()

			clue_data.Id = info.id
			clue_data.Portrait = info.sprite
			clue_data.Title = 'agora_inventory_item_' .. info.info_index
			clue_data.DescKey = 'agora_inventory_item_' .. info.info_index .. '_desc_1'
			clue_data.HintKey = 'agora_inventory_item_' .. info.info_index .. '_locked_desc_1'
			clue_data.ButtonState = info.enabled
					and CS.Oak.UI.EvidenceItemState.EvidenceButtonState.Normal
					or CS.Oak.UI.EvidenceItemState.EvidenceButtonState.Disable
			clue_data.CurrentCount = info.cur_count
			clue_data.MaxCount = #data

			evidence_data.EvidenceList:Add(clue_data)
		end

		evidence_data.SelectIndex = open_index or 0

		evidence_data.EnablePresentButton = present_cb ~= nil

		evidence_data.CloseCb = function()
			if close_cb ~= nil then
				close_cb()
			end
			self:on_hide_clue_popup()
		end
		evidence_data.PresentCb = function(result)
			if present_cb ~= nil then
				present_cb(result)
			end
			ui_scene_manager:PopOverlay()
			self:on_hide_clue_popup()
		end

		ui_scene_manager:PushOverlay(CS.Oak.UI.EvidencePopup.Instance, evidence_data)
	end
end

function local_class:on_hide_clue_popup()
	self.clue_ui_popup_on = false
end

function local_class:show_clue_popup_async(open_index)
	if self.clue_ui_popup_on then return end

	self:show_clue_popup(nil, nil, open_index)
	self:wait_until_popup_off()
end

-- 팝업이 닫힐 때까지 기다림
-- sp_util.play_normal_screenplay를 사용하지 않고 컨트롤을 뺏는 연출을 진행할 때는 연출 코루틴 시작 부분에서 이 함수 호출
function local_class:wait_until_popup_off()
	if self.connected_class == nil then
		return
	end

	while self.clue_ui_popup_on do
		coroutine.yield()
	end
end

-- Interact 또는 ZoneEnter 등으로 연출이 진행되는 경우 증거 물품 팝업이 열려있을 수 있음
-- 증거 물품 팝업이 닫힐 때 까지 기다리고 sp_util.play_normal_screenplay를 실행하도록 함
function local_class:play_normal_screenplay(func, ...)
	local args =  {...}
	local routine = function()
		self:wait_until_popup_off()

		field_ui_manager:Hide()
		party_util.stop_and_disable_control()

		local cached_leader = user_party.Leader
		if cached_leader.CharacterStatsBehaviour ~= nil then
			cached_leader.CharacterStatsBehaviour:AddStatsOptionRequest(
					stage.StageGameObject, CS.Oak.CharacterStatsOptions.Invincible)
		end

		yield_return_func(func, table.unpack(args))

		if cached_leader.CharacterStatsBehaviour ~= nil then
			cached_leader.CharacterStatsBehaviour:RemoveStatsOptionRequest(
					stage.StageGameObject, CS.Oak.CharacterStatsOptions.Invincible)
		end

		party_util.reset_controllers()
		field_ui_manager:Show()
	end

	return coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(routine))
end

function local_class:show_clue_button()
	if self.is_battle then
		return
	end

	if self.clue_ui_button_blocked == false and self.connected_class ~= nil then
		if self.clue_ui_button_on == false then
			self.clue_ui_button_on = true
			self.clue_ui_button_controller:UpdateIcon()
			self.clue_ui_button:SetActive(true)
		end
	end
end

function local_class:hide_clue_button()
	if self.clue_ui_button_on then
		self.clue_ui_button_on = false
		self.clue_ui_button:SetActive(false)
	end
end

function local_class:toggle_block_button(is_blocking)
	self.clue_ui_button_blocked = is_blocking
end

--region 예외처리
function local_class:on_field_ui_show_event(e)
	self:show_clue_button()

	return true
end

function local_class:on_field_ui_hide_event(e)
	self:hide_clue_button()

	return true
end

function local_class:on_battle_start_event(e)
	self.is_battle = true

	self:hide_clue_button()

	return true
end

function local_class:on_battle_end_event(e)
	if user_party.Leader.FieldObjectStatsBehaviour.IsDead == true then
		return false
	end

	self.is_battle = false

	self:show_clue_button()

	return true
end

function local_class:on_game_over_event(e)
	self:hide_clue_button()

	return true
end

function local_class:on_field_object_revived_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		self:show_clue_button()
		return true
	end

	return false
end
--endregion

return {
	create = function()
		return local_class();
	end
}
