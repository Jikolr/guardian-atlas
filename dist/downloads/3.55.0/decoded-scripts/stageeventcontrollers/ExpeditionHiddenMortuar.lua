local local_class = newclass('ExpeditionHiddenMortuar')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.stage_data = require('stageeventcontrollers/ExpeditionHiddenMortuarData.lua')
	self.current_stage_info = nil
end

function local_class:load_resource()
	if stage.PlayHiddenEvent == true then
		unity_object_pool.GetOrCreate('fx_expedition_collapsed_wall_s4')
		unity_object_pool.GetOrCreate('fx_expedition_gimmick_hole_light')
	end

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event(e)
	self.current_stage_info = self.stage_data[stage.Name]
	self.gimmick_max_hp = 1
	self.charge_hit_distance = 5

	if self.current_stage_info ~= nil then
		self.gimmick_max_hp = self.current_stage_info.gimmick_hp
		self.charge_hit_distance = self.current_stage_info.charge_hit_distance
	end

	self.wall = get_field_object('exp_collapsed_wall')

	--클리어 했다면 오프를 꺼준다.
	self.wall_off = self.wall.Transform:Find('off')

	-- 이미 이벤트 깼다면 벽을 숨긴다.
	if stage.HiddenEventCleared == true then
		if self.wall_off ~= nil then
			self.wall_off.gameObject:SetActive(false)
		end
	end

	-- 이벤트 플레이 가능케 함
	if stage.PlayHiddenEvent == true then
		message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
		self.current_visible = 1

		-- 체력바 세팅
		local ui_dict = field_ui_manager:SetUI(self.wall, CS.Oak.FieldUiType.TimerBar)
		self.hp_bar = ui_dict[CS.Oak.FieldUiType.TimerBar]
		self.hp_bar.BarSprite:SetWidth(100)
		self.hp_bar.BarSprite:SetMinMax(0, self.gimmick_max_hp)
		self.hp_bar.BarSprite:SetValue(self.gimmick_max_hp, 0)

		self.hp_bar:SetPosition(self.wall.Position)
		self.hp_bar.gameObject:SetActive(false)
		self.hp_bar_active_checker = false

		self.current_wall_hp = self.gimmick_max_hp
	end

	return true
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'inquisitor_rush_damaged' then
		-- 보스의 돌진 데미지 이벤트를 받았다면 벽위치기준으로 일정범위 안에 있다면 데미지를 준다.
		local pos = vector(tonumber(e:GetParamAt(1)), tonumber(e:GetParamAt(2)), tonumber(e:GetParamAt(3)))
		--실제 벽모양에 따라 어떤방식으로 거리를 체크할 것인지 수정이 필요할것 같다.
		local dist = (self.wall.Position - pos).magnitude

		if math.abs(dist) < self.charge_hit_distance then
			--TODO: 벽 흔들리는 애니 출력 필요
			self.current_wall_hp = self.current_wall_hp - 1

			if self.current_wall_hp > 0 then
				self.hp_bar.BarSprite:SetValue(self.current_wall_hp, 0)
				if not self.hp_bar_active_checker then
					self.hp_bar_active_checker = true
					self.hp_bar.gameObject:SetActive(true)
				end

			else
				--벽파괴 이팩트
				unity_object_pool.GetOrCreate('fx_expedition_collapsed_wall_s4'):Instantiate(self.wall.Position)
				self.wall_off.gameObject:SetActive(false)
				self.hp_bar.gameObject:SetActive(false)
				stage:ClearHiddenEvent()

				return true
			end
		end
	end

	return true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
