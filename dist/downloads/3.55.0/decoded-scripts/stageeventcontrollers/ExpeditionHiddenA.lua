local local_class = newclass('ExpeditionHiddenEventA')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	if stage.PlayHiddenEvent == true then
		unity_object_pool.GetOrCreate('FX_slime_buttbounce')
		unity_object_pool.GetOrCreate('fx_expedition_gimmick_hole_light')
	end

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event(e)
	self.hole = get_field_object('event_hidden_hole')
	self.rock = get_field_object('event_hidden_rock')

	-- FIXME: 임시 코드
	self.rock_transform_1 = self.rock.Transform:Find('mesh/stalagmite_1')
	self.rock_transform_2 = self.rock.Transform:Find('mesh/stalagmite_2')
	self.rock_transform_3 = self.rock.Transform:Find('mesh/stalagmite_3')

	self.use_transform_update = is_unity_null(self.rock_transform_1) == false and
			is_unity_null(self.rock_transform_2) == false and
			is_unity_null(self.rock_transform_3) == false

	-- 이미 이벤트 깼다면 바위 숨김
	if stage.HiddenEventCleared == true then
		self.rock.ActiveState = CS.Oak.ActiveState.Disabled
	end

	-- 이벤트 플레이 가능케 함
	if stage.PlayHiddenEvent == true then
		message_system:Subscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent), 'on_monster_spawned_event')
		message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
		self.current_visible = 1

		-- 체력바 세팅
		local ui_dict = field_ui_manager:SetUI(self.rock, CS.Oak.FieldUiType.TimerBar)
		self.hp_bar = ui_dict[CS.Oak.FieldUiType.TimerBar]
		self.hp_bar.BarSprite:SetWidth(100)
		self.hp_bar.BarSprite:SetMinMax(0, 1)
		self.hp_bar.BarSprite:SetValue(1, 0)

		self.hp_bar:SetPosition(self.rock.Position)
		self.hp_bar.gameObject:SetActive(false)
		self.hp_bar_active_checker = false

		-- 바위를 지정된 레이저 몬스터만 때릴 수 있도록 함.
		self.rock.EntityGroup = CS.Oak.EntityGroups.AllyObject
		self.rock.DamagedBehaviour = CS.Oak.RegisterFieldObjectDamagedBehaviour()
		self.rock.FieldObjectStatsBehaviour.FieldObjectSpec = CS.Oak.GameDataService.GetData('FieldObjectSpecs'):GetSpec(200003)
	end

	return true
end

function local_class:on_monster_spawned_event(e)
	-- 스폰 된 몬스터가 히든 관련 몬스터면 등록
	if e.Spec.AffectHiddenObject == true then
		self.rock.DamagedBehaviour:RegisterObject(e.Monster)
	end
end

function local_class:on_damage_event(e)
	if lua_helper.reference_equals(e.Info.target, self.rock) then

		-- 타이머 체력바 갱신
		local ratio = self.rock.FieldObjectStatsBehaviour.HpRatio
		if ratio < 1 then
			self.hp_bar.BarSprite:SetValue(ratio, 0)
			if not self.hp_bar_active_checker then
				self.hp_bar_active_checker = true
				self.hp_bar.gameObject:SetActive(true)
			end

			-- 체력 상태에 따라 모습 변경
			if self.rock.FieldObjectStatsBehaviour.IsDead == true then
				self:update_rock_visible(3)
			elseif ratio <= 0.5 then
				self:update_rock_visible(2)
			else
				self:update_rock_visible(1)
			end

			return true
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.rock) then
		self:update_rock_visible(3)
		field_ui_manager:RemoveUI(self.rock, CS.Oak.FieldUiType.TimerBar)
		-- 이벤트 클리어 처리
		stage:ClearHiddenEvent()

		return true
	end

	return false
end

function local_class:update_rock_visible(show_target)
	if self.current_visible == show_target then
	elseif show_target == 1 then
		if self.use_transform_update then
			self.rock_transform_1.gameObject:SetActive(true)
			self.rock_transform_2.gameObject:SetActive(false)
			self.rock_transform_3.gameObject:SetActive(false)
		end
	elseif show_target == 2 then
		if self.use_transform_update then
			self.rock_transform_1.gameObject:SetActive(false)
			self.rock_transform_2.gameObject:SetActive(true)
			self.rock_transform_3.gameObject:SetActive(false)
		end

		-- 반파 이펙트
		unity_object_pool.GetOrCreate('FX_slime_buttbounce'):Instantiate(self.rock.Position)
	elseif show_target == 3 then
		if self.use_transform_update then
			self.rock_transform_1.gameObject:SetActive(false)
			self.rock_transform_2.gameObject:SetActive(false)
			self.rock_transform_3.gameObject:SetActive(true)
		else
			-- 단계별 트랜스폼 없는 경우엔 이때 꺼준다.
			self.rock.ActiveState = CS.Oak.ActiveState.Disabled
		end

		-- 완파 이펙트
		unity_object_pool.GetOrCreate('fx_expedition_gimmick_hole_light'):Instantiate(self.hole.Position)
	end

	self.current_visible = show_target
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
