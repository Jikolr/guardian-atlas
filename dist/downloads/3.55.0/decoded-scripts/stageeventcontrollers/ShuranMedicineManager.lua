local local_class = newclass('ShuranMedicineManagerController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	--region Character
	self.get_rabbit = function()
		return get_character('spirit_rabbit')
	end
	self.get_jungpa_master = function()
		return get_character('jungpa_master')
	end
	self.get_medicine_interact_bear = function(idx)
		return get_character('bear_' .. idx)
	end
	self.get_pot = function()
		return get_character('gimmik_leg_pot')
	end
	--endregion Character

	--region Object
	self.get_medicine_jump_interact_object = function(type, idx)
		return get_field_object('medicine_interact_' .. type .. '_' .. idx)
	end
	self.get_medicine_diamond_interact_object = function(type, group_number, idx)
		return get_field_object('medicine_interact_' .. type .. '_' .. group_number .. '_' .. idx)
	end
	self.get_medicine_break_interact_object = function(type, group_number, idx)
		return get_field_object('medicine_interact_' .. type .. '_' .. group_number .. '_' .. idx)
	end
	--endregion Object

	--region Marker
	self.get_diamond_interact_pos = function(number, idx)
		return field_util.get_marker_pos('medicine_diamond_interact_object_pos_' .. number .. '_' .. idx)
	end
	--endregion Marker

	--region Fx
	self.fx = {
		obj_smoke = function()
			return unity_object_pool.GetOrCreate('fx_obj_smoke')
		end,
		buff_loop = function()
			return unity_object_pool.GetOrCreate('fx_sr_medicine_diamond_loop')
		end,
		break_leaf = function()
			return unity_object_pool.GetOrCreate('fx_sr_break_leaf')
		end,
		dead = function()
			return unity_object_pool.GetOrCreate('FX_dead')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}
	--endregion Fx

	--region Sprite
	self.sprite = {
		sprite_info = {
			insam = 21100,
			seoryeon = 21101,
			seokgok = 21102,
			bock = 21103
		},
		sprite_table = {},
		create = function(this, name, pos, item_id, scale, showoncharacter)
			scale = lua_helper.get_or_default(scale, 1)
			showoncharacter = lua_helper.get_or_default(showoncharacter, false)

			local item = drop_item_util.create_item(
					{ pos = pos, itemid = item_id, notforinven = true, showoncharacter = showoncharacter,
					  lootstate = 'dontfindlooter', sprscale = scale })

			this.sprite_table[name] = item

			return item
		end,
		dispose = function(this, name)
			this.sprite_table[name]:ConsumeComplete()
		end,
		dispose_all = function(this)
			if this.sprite_table then
				for name, value in pairs(this.sprite_table) do
					if name then
						this:dispose(name)
					end
				end
			end
			this.sprite_table = nil
		end
	}
	--endregion Sprite

	--region Etc
	self.craft_key = 'medicine_flag'

	--조합 매니저
	self.medicine_manager = {
		current_state = 0,
		state = {
			-- 아무것도 없는 상태, 1개의 약초를 얻은상태, 비약을 가지고 있는 상태
			default = 0,
			get = 1,
			composition = 2,
		},
		herb_type_table = {
			insam = { name = 'insam', idx = 1 },
			seoryeon = { name = 'seoryeon', idx = 2 },
			seokgok = { name = 'seokgok', idx = 3 },
			bock = { name = 'bock', idx = 4 },
		},
		medicine_table = {
			--천보환 (sr_ui_medicine_jump)
			medicine_jump = {
				name = 'jump',
				key = 'sr_medicine',
				idx = 1,
				bit = (1 << 1)
						| (1 << 2)
			},
			--금강단(sr_ui_medicine_diamond)
			medicine_diamond = {
				name = 'diamond',
				key = 'sr_medicine',
				idx = 2,
				bit = (1 << 1)
						| (1 << 4)
			},
			--몽유환(sr_ui_medicine_sleepwalk)
			medicine_sleepwalk = {
				name = 'sleepwalk',
				key = 'sr_medicine',
				idx = 3,
				bit = (1 << 2)
						| (1 << 3)
			},
			--외강산(sr_ui_medicine_break)
			medicine_break = {
				name = 'break',
				key = 'sr_medicine',
				idx = 4,
				bit = (1 << 3)
						| (1 << 4)
			},
		},
		herb_bit = 0,
		add = function(this, value)
			this.herb_bit = value
		end,
		get_bit = function(this, name)
			if name == this.herb_type_table['insam'].name then
				return 1 << this.herb_type_table['insam'].idx

			elseif name == this.herb_type_table['seoryeon'].name then
				return 1 << this.herb_type_table['seoryeon'].idx

			elseif name == this.herb_type_table['seokgok'].name then
				return 1 << this.herb_type_table['seokgok'].idx

			elseif name == this.herb_type_table['bock'].name then
				return 1 << this.herb_type_table['bock'].idx
			end
		end,
		bit_clear = function(this)
			this.herb_bit = 0
		end,
		check_herb = function(this, sub_herb_bit)
			return ((this.herb_bit == sub_herb_bit) and true or false)
		end,
		check_medicine = function(this, medicine_bit)
			return ((this.herb_bit == medicine_bit) and true or false)
		end,
		composition = function(this, sub_herb_bit)
			this.herb_bit = this.herb_bit | sub_herb_bit

			return this:composition_check()
		end,
		composition_check = function(this)
			--현재 가지고 있는 비약을 체크하는 함수 (더해진 비트 값으로 계산)
			if this.herb_bit == this.medicine_table.medicine_jump.bit then
				return { true, this.medicine_table.medicine_jump }
			elseif this.herb_bit == this.medicine_table.medicine_diamond.bit then
				return { true, this.medicine_table.medicine_diamond }
			elseif this.herb_bit == this.medicine_table.medicine_sleepwalk.bit then
				return { true, this.medicine_table.medicine_sleepwalk }
			elseif this.herb_bit == this.medicine_table.medicine_break.bit then
				return { true, this.medicine_table.medicine_break }
			end

			return { false, nil }
		end,
		medicine_name_check = function(this, name)
			--인터렉팅으로 들어온 값(string:비약 명)이 비약과 같은지 체크하는 함수
			for _, value in pairs(this.herb_type_table) do
				if name == value.name then
					return true
				end
			end

			return false
		end
	}

	--Jump관련 상수
	self.jump_constants = {
		angle_y_0 = {
			--리더가 보는 방향
			--오른쪽
			target_direction = vector(1, 0, 0),
			jump_distance = vector(6, 0, 0),
			align_position = {
				move_start = {
					{ pos = vector(-1, 0, 0), dir = 'left' },
					{ pos = vector(-2, 0, 0), dir = 'right' },
					{ pos = vector(-2, 0, -1), dir = 'right' }
				},
				move_end = {
					{ pos = vector(0, 0, 0), dir = 'right' },
					{ pos = vector(1, 0, 0), dir = 'right' },
					{ pos = vector(1, 0, -1), dir = 'right' }
				}
			},
			eat_position = vector(0.5, 0, 0),
			rabbit_head_position = {
				vector(1.2, 0.75, 0),
				vector(0.8, 0.75, 1)
			}
		},
		angle_y_90 = {
			--왼쪽
			target_direction = vector(-1, 0, 0),
			jump_distance = vector(-6, 0, 0),
			align_position = {
				move_start = {
					{ pos = vector(1, 0, 0), dir = 'right' },
					{ pos = vector(2, 0, 0), dir = 'left' },
					{ pos = vector(2, 0, -1), dir = 'left' }
				},
				move_end = {
					{ pos = vector(0, 0, 0), dir = 'left' },
					{ pos = vector(-1, 0, 0), dir = 'left' },
					{ pos = vector(-1, 0, -1), dir = 'left' }
				}
			},
			eat_position = vector(-0.5, 0, 0),
			rabbit_head_position = {
				vector(-1.2, 0.75, 0),
				vector(-0.8, 0.75, 1)
			}
		},
		angle_y_180 = {
			--위쪽
			target_direction = vector(0, 0, 1),
			jump_distance = vector(0, 0, 4.5),
			align_position = {
				move_start = {
					{ pos = vector(0, 0, -1), dir = 'down' },
					{ pos = vector(-0.5, 0, -2), dir = 'right' },
					{ pos = vector(0.5, 0, -2), dir = 'left' },
				},
				move_end = {
					{ pos = vector(0, 0, 0), dir = 'right' },
					{ pos = vector(-0.5, 0, 1), dir = 'right' },
					{ pos = vector(0.5, 0, 1), dir = 'right' },
				}
			},
			eat_position = vector(0, 0, 0.5),
			rabbit_head_position = {
				vector(0.5, 0.75, 1.1),
				vector(-0.5, 0.75, 0.8)
			}
		},
		angle_y_270 = {
			--아래쪽
			target_direction = vector(0, 0, -1),
			jump_distance = vector(0, 0, -4.5),
			align_position = {
				move_start = {
					{ pos = vector(0, 0, 1), dir = 'up' },
					{ pos = vector(-0.5, 0, 2), dir = 'right' },
					{ pos = vector(0.5, 0, 2), dir = 'left' },
				},
				move_end = {
					{ pos = vector(0, 0, 0), dir = 'down' },
					{ pos = vector(-0.5, 0, -1), dir = 'right' },
					{ pos = vector(0.5, 0, -1), dir = 'left' },
				}
			},
			eat_position = vector(0, 0, -0.5),
			rabbit_head_position = {
				vector(0.5, 0.75, -1.1),
				vector(-0.5, 0.75, -0.8)
			}
		}
	}

	--기믹별 상호작용 개수
	self.gimmick_interact_count = {
		jump = 5,
		diamond = {
			group_max_count = 3,
			group_member_max_count = 2
		},
		sleepwalk = 5,
		break_1 = {
			group_max_count = 5,
			group_member_max_count = 3
		}
	}
	self.align_table = {
		bear_1 = {
			wp_state = 1,
			hit_box = { pivot = vector(0.5, 0, 0.25), scale = vector(2, 1, 2) },
			start_info = { pos = nil, dir = nil },
			end_info = { pos = vector(2, 0, 0), dir = nil },
			align_info = {
				add_pos = 0,
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'down', left = 'down', up = 'down', down = 'down' },
				second = { right = 'down', left = 'down', up = 'down', down = 'down' },
			},
			sleep_sfx = nil
		},
		bear_2 = {
			wp_state = 1,
			hit_box = { pivot = vector(0.5, 0, 0.25), scale = vector(2, 1, 2) },
			start_info = { pos = nil, dir = nil },
			end_info = { pos = vector(2, 0, 0), dir = nil },
			align_info = {
				add_pos = 0,
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'down', left = 'down', up = 'down', down = 'down' },
				second = { right = 'down', left = 'down', up = 'down', down = 'down' },
			},
			sleep_sfx = nil
		},
		bear_3 = {
			wp_state = 1,
			hit_box = { pivot = vector(0.5, 0, 0.25), scale = vector(2, 1, 2) },
			start_info = { pos = nil, dir = 'left' },
			end_info = { pos = vector(0, 0, 2), dir = 'left' },
			align_info = {
				add_pos = 0.5,
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'left', left = 'left', up = 'left', down = 'left' },
				second = { right = 'left', left = 'left', up = 'left', down = 'left' },
			},
			sleep_sfx = nil
		},
		bear_4 = {
			wp_state = 1,
			hit_box = { pivot = vector(0.5, 0, 0.25), scale = vector(2, 1, 2) },
			start_info = { pos = nil, dir = nil },
			end_info = { pos = vector(-2, 0, 0), dir = nil },
			align_info = {
				add_pos = 0,
				back_add_pos = 1,
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'up', left = 'up', up = 'up', down = 'up' },
				second = { right = 'up', left = 'up', up = 'up', down = 'up' },
			},
			sleep_sfx = nil
		},
		bear_5 = {
			wp_state = 1,
			hit_box = { pivot = vector(0.5, 0, 0.25), scale = vector(2, 1, 2) },
			start_info = { pos = nil, dir = nil },
			end_info = { pos = vector(2, 0, 0), dir = nil },
			align_info = {
				add_pos = 0,
				back_add_pos = 1,
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'up', left = 'down', up = 'down', down = 'up' },
				second = { right = 'down', left = 'down', up = 'down', down = 'down' },
			},
			sleep_sfx = nil
		},
		rock_1 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				add_pos = vector(0, 0, 2.5),
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'up', left = 'up', up = 'up', down = 'up' },
			}
		},
		rock_2 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				add_pos = vector(2.5, 0, 0),
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'right', left = 'right', up = 'right', down = 'right' },
			}
		},
		rock_3 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				add_pos = vector(-2.5, 0, 0),
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'left', left = 'left', up = 'left', down = 'left' },
			}
		},
		rock_4 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				add_pos = vector(-2.5, 0, 0),
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'left', left = 'left', up = 'left', down = 'left' },
			}
		},
		rock_5 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				add_pos = vector(0, 0, -2.5),
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'down', left = 'down', up = 'down', down = 'down' },
			}
		},
		diamond_1 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				--add_pos = vector(3, 0, 0.5),
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'up', left = 'up', up = 'up', down = 'up' },
				second = { right = 'down', left = 'down', up = 'down', down = 'down' },
			}
		},
		diamond_2 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				--add_pos = vector(3, 0, 0.5),
				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'left', left = 'left', up = 'left', down = 'left' },
				second = { right = 'right', left = 'right', up = 'right', down = 'right' },
			}
		},
		diamond_3 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				--add_pos = vector(3, 0, 0.5),

				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'left', left = 'left', up = 'left', down = 'left' },
				second = { right = 'right', left = 'right', up = 'right', down = 'right' },
			}
		},
		diamond_4 = {
			wp_state = 1,
			align_info = {
				-- 리더가 정렬할 때 추가로 들어가는 값
				--add_pos = vector(3, 0, 0.5),

				-- 리더가 바라보는 방향 = align할 방향
				first = { right = 'left', left = 'left', up = 'left', down = 'left' },
				second = { right = 'right', left = 'right', up = 'right', down = 'right' },
			}
		}
	}

	--hit 오브젝트 캐싱용 (가시덩쿨)
	self.hit_targets = create_generic_hashset(CS.Oak.IFieldObject)

	self.pot_wait_pos = vector(700, 0, 700)
	--endregion Etc

	--버전
	self.scene_version = scene_util.default_version
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	self.hit_targets:Clear()
	self.hit_targets = nil

	self.cs_controller = nil
	self.scene = nil
end

--region load_resourceT
function local_class:load_resource()
	---@type ShuranUtil
	self.sr_util = get_or_create_global_table('Quest/ShortStory/Shuran/Common/Util')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')

	self.fx:load_all()
	self:pre_setting()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()


	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	start_coroutine(self.grid_enter_bear_sfx_setting, self, e)

	return false
end

function local_class:on_stage_loaded_event(_)
end

function local_class:on_custom_stage_event(e)
	--composition상태가 아닐때만
	if e:GetParamAt(0) == 'interacting' and
			self.medicine_manager:medicine_name_check(e:GetParamAt(2)) then
		--sp_util 사용 시 장착시킨 비약을 기본 값(empty)상태로 변경되어 exit_scene의 인자(show_weapon)를 false로 설정하여 사용해야함
		start_coroutine(self.medicine_action_routine, self, e)
	elseif not (self.medicine_manager.current_state == self.medicine_manager.state.composition) and
			e:GetParamAt(0) == 'custom_interacting' and
			self.medicine_manager:medicine_name_check(e:GetParamAt(1)) then
		start_coroutine(self.medicine_composition_routine, self, e:GetParamAt(1))
	elseif e:GetParamAt(0) == 'custom_clear' then
		start_coroutine(self.medicine_clear, self)
	end
end

function local_class:on_interact_event(e)
	--조합 상태가 아닐 땐 바로 도망
	if self.medicine_manager.current_state ~= self.medicine_manager.state.composition then
		return
	end

	--천보환
	for idx = 1, self.gimmick_interact_count.jump do
		if lua_helper.reference_equals(e.Target,
				self.get_medicine_jump_interact_object(self.medicine_manager.medicine_table.medicine_jump.name, idx)) then
			self.sr_util:start_scene(self.jump_interact_event, self, e.Target)

			return true
		end
	end

	--금강단
	for group_idx = 1, self.gimmick_interact_count.diamond.group_max_count do
		for member_idx = 1, self.gimmick_interact_count.diamond.group_member_max_count do
			if lua_helper.reference_equals(e.Target,
					self.get_medicine_diamond_interact_object(self.medicine_manager.medicine_table.medicine_diamond.name, group_idx, member_idx)) then
				self.sr_util:start_scene(self.diamond_interact_event, self, group_idx, member_idx)

				return true
			end

		end
	end

	--몽유환
	for idx = 1, self.gimmick_interact_count.sleepwalk do
		if lua_helper.reference_equals(e.Target,
				self.get_medicine_interact_bear(idx)) then
			self.sr_util:start_scene(self.sleepwalk_interact_event, self, idx)

			return true
		end
	end

	--외강산
	for group_idx = 1, self.gimmick_interact_count.break_1.group_max_count do
		for member_idx = 1, self.gimmick_interact_count.break_1.group_member_max_count - 1 do
			if lua_helper.reference_equals(e.Target,
					self.get_medicine_break_interact_object(self.medicine_manager.medicine_table.medicine_break.name, group_idx, member_idx)) then
				self.sr_util:start_scene(self.break_interact_event, self, group_idx)

				return true
			end
		end
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
--region composition_medicine
--약초 조합
function local_class:medicine_action_routine(e)
	local shuran = get_party_leader()
	local herb_name = e:GetParamAt(2)

	--똑같은 약초 2개 조합 시 실패 판정 아래와 같이 출력
	--(tired, idle) 이미 가지고 있는 약초야.
	--이후 기존에 있는 약초 1개 소지한 채로 컨트롤 해제
	--참이면 같은게 존재
	if self.medicine_manager:check_herb(self.medicine_manager:get_bit(herb_name)) then
		coroutine.yield()

		sp_util.enter_scene({ hide_weapon = false })

		scene_util.play_normal_speech_action(shuran, self,
				nil,
				nil,
				'tired',
				'short_story_sr_gimmick_1')

		sp_util.exit_scene({ show_weapon = false }, get_party_leader())

		return
	end

	if (self.medicine_manager.current_state == self.medicine_manager.state.composition) then
		self:medicine_clear()
	end

	local item = e.Sender
	local herb_name = e:GetParamAt(2)

	local drop_item = self.sprite:create(item.Name, item.Position, self.sprite.sprite_info[herb_name], 1, true)

	drop_item.ConsumeTarget = get_party_leader()
	--drop_item.ShowFloatingText = false
	drop_item:Fly()
	drop_item = nil
	self.sprite.sprite_table[herb_name] = nil

	self:medicine_composition_routine(herb_name)

	--세발솥 연출
	local pot_scene = function(dir, callback)
		local pot = self.get_pot()
		local pot_start_pos = shuran.Bounds.center
		local pos = shuran.Position
				+ vector((direction_util.to_vector3_ver2(dir).x * 0.25), 0, -0.1)

		character_util.set_active_state(pot, 'enabled')

		--시작 크기 0.5
		pot.transform.localScale = unity_class.vector3.one * 0.5
		pot.SpineController.ShadowTransform.localScale = unity_class.vector3.one * 0.5

		character_util.set_position(pot, pot_start_pos)

		scene_util.set_anim(shuran, self, 'idle')

		scene_util.set_direction(shuran, dir, false)

		local pot_move_duration = 0.2

		wait_all({
			util.cs_generator(coroutine_util.while_from_to_each_frame, pot_move_duration, 0.5, 1, function(progress, cur_value)
				local scale = unity_class.vector3.one * cur_value

				pot.transform.localScale = scale
			end),
			util.cs_generator(wp_util.move_async, pot, pos, nil, pot_move_duration, { locked_dir = 'right' }),
		})

		character_util.remove_anim(shuran)

		wait_for_sec(0.2)

		--sr_three_leg_pot가 1스케일이 되면 fire 애니메이션 재생
		local boiling_sfx = music_player_util.play_sfx({
			sfx_name = '01_boiling_02',
			volume = 0.5,
			loop = true,
			type_priority = 'event',
			player_priority = 'npc' })

		music_player_util.play_sfx_one_shot('01_interact_noodlehouse_01')
		scene_util.set_emotion(shuran, self, 'smile')
		scene_util.set_anim(pot, self, 'fire')

		character_util.spine_set_attachment(shuran, '[base]weapon1', 'sr_pat_fan')

		scene_util.set_anim_async(shuran, self, { name = 'unique/boiling_pot', count = 1.5, scale = 1.5 })
		boiling_sfx:Stop()

		if callback then
			callback()
		end

		--sr_three_leg_pot가 fx_dead와 함께 사라지면서
		music_player_util.play_sfx_one_shot('02_explosion_01', 0.5)
		self.fx.dead():Instantiate(pot.Position)

		character_util.spine_set_attachment(shuran, '[base]weapon1', 'empty')

		character_util.remove_anim(pot)

		character_util.set_position(pot, self.pot_wait_pos)
		character_util.set_active_state(pot, 'disabled')
	end

	local str_dir

	if shuran.Position.x < item.Bounds.center.x then
		str_dir = 'right'
	else
		str_dir = 'left'
	end

	--1번째 아이템일 경우
	if self.medicine_manager.current_state == self.medicine_manager.state.get then
		--scene_util.play_wait_action(shuran, self,
		--		'down',
		--		'get',
		--		'smile',
		--		1)

	elseif self.medicine_manager.current_state == self.medicine_manager.state.composition then
		--조합에 성공했을 경우
		sp_util.enter_scene({ hide_weapon = false })
		music_player_util.play_sfx_one_shot('01_interact_pancakehouse_01')

		wait_for_sec(0.2)

		character_util.remove_anim_and_emotion(shuran)

		--애니메이션이 삭제가 안되는 이슈가 있어서 스테이트 변경
		local req = CS.Oak.AnimationRequest('idle', CS.Oak.AnimationPriorities.Default, true)
		local state = CS.Oak.CharacterMarionetteState.Create(shuran, req)
		local state_change_event = CS.Oak.StateChangeEvent.Create(state)

		state.CurrentAction = CS.Oak.FieldObjectAction.None
		message_system:SendSync(shuran.FieldObjectBehaviour, state_change_event)

		coroutine.yield(nil)

		--pot 연출
		pot_scene(str_dir)

		--sr_three_leg_pot가 fx_dead와 함께 사라지면서 손에 sr_medicine 든 채로 victory_get 후 아래 staff 상태로 변경
		self:set_medicine_attachment(shuran, true)

		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		scene_util.set_anim_async(shuran, self, { name = 'victory_get', loop = false, keep_anim = true })

		wait_for_sec(0.5)

		character_util.remove_anim_and_emotion(shuran)

		sp_util.exit_scene({ show_weapon = false }, get_party_leader())
	else
		sp_util.enter_scene({ hide_weapon = false })
		music_player_util.play_sfx_one_shot('01_interact_pancakehouse_01')

		wait_for_sec(0.2)

		character_util.remove_anim_and_emotion(shuran)

		--애니메이션이 삭제가 안되는 이슈가 있어서 스테이트 변경
		local req = CS.Oak.AnimationRequest('idle', CS.Oak.AnimationPriorities.Default, true)
		local state = CS.Oak.CharacterMarionetteState.Create(shuran, req)
		local state_change_event = CS.Oak.StateChangeEvent.Create(state)

		state.CurrentAction = CS.Oak.FieldObjectAction.None
		message_system:SendSync(shuran.FieldObjectBehaviour, state_change_event)

		coroutine.yield(nil)

		--pot 연출
		pot_scene(str_dir)

		--sr_three_leg_pot가 fx_dead와 함께 사라지면서 윈링(damaged,cast)(jump1회)1초 후 컨트롤 복귀
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		music_player_util.play_sfx_one_shot('01_small_jump_01')
		character_util.normal_jump(shuran)
		scene_util.play_wait_action(shuran, self,
				nil,
				'cast',
				'damaged',
				1)

		sp_util.exit_scene({ show_weapon = false }, get_party_leader())
	end
end

function local_class:medicine_composition_routine(herb_name)
	--약초 조합 시작
	--#2
	--저장된 약초가 존재하는가?
	--#8
	--최초로 습득한 약초인가?
	--상태가 default이거나 비트가 0일 때
	if self.medicine_manager.current_state == self.medicine_manager.state.default
			and self.medicine_manager.herb_bit == 0 then
		--첫번째 약초 획득
		self.medicine_manager:add(self.medicine_manager:get_bit(herb_name))

		--조합식 출력 (비약 조합식, 조합식은 ui 컨트롤러에서)
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'ui_on', self.medicine_manager.herb_type_table[herb_name].name }))

		--스테이트 get으로 변환
		self.medicine_manager.current_state = self.medicine_manager.state.get

		return
	end

	--#3
	--조합 시작
	--#4
	--정확한 방법으로 조합하였는가?
	local result = self.medicine_manager:composition(self.medicine_manager:get_bit(herb_name))

	if not result[1] then
		--실패
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'ui_off' }))

		--실패 모션과 bit초기화 및 ui 제거
		self.medicine_manager:bit_clear()
		self.medicine_manager.current_state = self.medicine_manager.state.default

		return
	end

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil,
			{ self.craft_key, result[2].idx }))

	coroutine.yield(nil)

	--#5
	--저장된 약초 소멸 후 만들어진 비약 저장
	--성공 모션과 함께 비약 ui 출력 (변경)
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'change_ui', result[2].name }))

	--비약 인터렉트 활성화
	self:all_setting_interact_object(true)

	--성공
	self.medicine_manager.current_state = self.medicine_manager.state.composition
end
--endregion composition_medicine

--region interact_event
--천보환 (sr_ui_medicine_jump)
function local_class:jump_interact_event(target_fo)
	if not self:is_medicine_same_check_event(self.medicine_manager.medicine_table.medicine_jump.bit) then
		return
	end

	local rabbit = self.get_rabbit()
	local shuran = get_party_leader()

	local party_table = self:get_party_member()

	local jump_data = self.jump_constants['angle_y_' .. tostring(math.floor(target_fo.transform.eulerAngles.y))]

	local align_speed = 2
	--local head_jump_move_speed = 2

	local party_align_key = 'party_align_key'
	--각 방향으로 파티가 정렬된다.
	--1. (윈링)(right,idle,idle) 2. (원걸)(right,idle,idle)  3. (토끼)(left,idle,idle)  (해당 npc들의 바라보는 방향은 interact한 오브젝트에따라 달라진다)
	--2. (원걸) 은 단편집 클리어 후 파티에 포함되지 않는다.
	for idx = 1, #party_table do
		if not party_table[idx] then
			break
		end

		local target_pos = target_fo.Position + jump_data.align_position.move_start[idx].pos

		wp_util.move_with_end_callback(party_table[idx], target_pos, align_speed,
				nil, self, party_align_key, { run = true, last_direction = jump_data.align_position.move_start[idx].dir })
	end

	wp_util.wait_move_end(self, party_align_key)

	wait_for_sec(0.5)

	--(1)이 (3)방향으로 속도 1 (walk) 0.5칸 이동 후 (eat) 1초간 재생
	--현 방향 고정 및 저장 (위 아래를 바로보고 있을 경우 변경되기 때문에) (토끼 점프전 방향 전환 값으로 사용)
	--위 아래일 경우 사이드로 변경
	local eat_start_position = target_fo.Position +
			jump_data.align_position.move_start[2].pos + jump_data.eat_position

	self:target_move_eat(eat_start_position, shuran, true, function(_)
		--(eat)재생 시작할 때 토끼 (shake0.03 / 0.5초)
		scene_util.shake(rabbit, 0.03, 0.5, false)

		--초기화 (웨펀 사라지는 부분)
		self:medicine_clear()
	end)

	--이후 토끼 몸집이 커지는 연출, 슈란과 원걸은 (surprise) 모션 출력
	local party_emo_anim_table = {
		{ emo = 'smile', anim = 'seat' },
		{ emo = 'damaged', anim = 'seat' }
	}

	for idx = 2, #party_table do
		character_util.remove_anim_and_emotion(party_table[idx])

		scene_util.set_emotion(party_table[idx], self, party_emo_anim_table[idx - 1].emo)
	end

	local swell_duration = spine_util.get_animation_duration(rabbit, 'swell')
	local rabbit_from_scale = unity_class.vector3.one
	local rabbit_to_scale = unity_class.vector3.one * 1.2

	--토끼 (swell) 애니메이션 재생
	music_player_util.play_sfx_one_shot('01_fat_gnome_03')
	scene_util.set_anim(rabbit, self, { name = 'swell', loop = false })

	coroutine_util.while_from_to_each_frame(swell_duration, rabbit_from_scale, rabbit_to_scale, function(progress, cur_y)
		rabbit.transform.localScale = cur_y
	end)

	scene_util.set_direction(rabbit, shuran.Direction, false)

	--토끼 위 아래로 점프
	local jump_move_routine = function(target, start_pos, target_pos, jump_duration, height)
		start_coroutine(function()
			coroutine_util.while_each_frame(jump_duration, function(progress)
				local lerp_pos = unity_class.vector3.Lerp(start_pos, target_pos, progress)
				local cur_y = unity_class.mathf.Sin(unity_class.mathf.PI * progress) * height + lerp_pos.y
				local cur_pos = vector_util.get_x0z(lerp_pos, cur_y)

				character_util.set_position(target, cur_pos, true)
			end)

			self.success_count = self.success_count + 1
		end)
	end

	self.success_count = 0
	local head_jump_height = 0.75

	local head_jump_duration = 0.5
	for idx = 2, #party_table do
		-- 토끼위로 올라간다
		local start_pos = party_table[idx].Position
		local target_pos = party_table[idx].Position + jump_data.rabbit_head_position[idx - 1]
		--local head_jump_duration = (target_pos - party_table[idx].Position):GetX0z().magnitude / head_jump_move_speed

		scene_util.set_anim(party_table[idx], self, 'get')

		music_player_util.play_sfx_one_shot('01_jump_01')
		jump_move_routine(party_table[idx], start_pos, target_pos, head_jump_duration, head_jump_height)
	end

	while self.success_count ~= #party_table - 1 do
		coroutine.yield(nil)
	end

	--해당 이벤트 부터 1(smile) 원걸(surprise) 표정 / 둘다 (seat) 애니메이션 고정
	for idx = 2, #party_table do
		character_util.remove_anim(party_table[idx])

		scene_util.set_anim(party_table[idx], self, party_emo_anim_table[idx - 1].anim)
	end

	wait_for_sec(0.5)

	--첫 점프
	scene_util.set_anim(rabbit, self, 'swell_jump')

	self.success_count = 0

	local jump_duration = 0.5
	local jump_height = 2

	--토끼 점프시작할때 방향 변경
	music_player_util.play_sfx_one_shot('01_player_jump_01')
	for idx = 1, #party_table do
		local target_pos = party_table[idx].Position + jump_data.jump_distance
		local start_pos = party_table[idx].Position

		scene_util.set_direction(party_table[idx], shuran.Direction, false)

		jump_move_routine(party_table[idx], start_pos, target_pos, jump_duration, jump_height)
	end

	while self.success_count ~= #party_table do
		coroutine.yield(nil)
	end

	--A 위치 도착했다면 화면 (shake 0.1 / 0.3초)
	music_player_util.play_sfx_one_shot('03_mech_stomp_01')
	camera_util.shake(0.1, 0.3)
	wait_for_sec(0.2)

	--2번째 점프
	self.success_count = 0

	music_player_util.play_sfx_one_shot('01_player_jump_01')
	for idx = 1, #party_table do
		local target_pos = party_table[idx].Position + jump_data.jump_distance
		local start_pos = party_table[idx].Position

		jump_move_routine(party_table[idx], start_pos, target_pos, jump_duration, jump_height)
	end

	while self.success_count ~= #party_table do
		coroutine.yield(nil)
	end

	--반대편 위치에 도착했다면 화면 (shake 0.1 / 0.3초)
	music_player_util.play_sfx_one_shot('03_mech_stomp_01')
	camera_util.shake(0.1, 0.3)

	--동시에 (1) (2) 동시에 표시된 위치까지 0.5초간 마리오 점프로 정렬
	--동시에 토끼 (swell_out)
	local swell_out_duration = spine_util.get_animation_duration(rabbit, 'swell_out')

	music_player_util.play_sfx_one_shot('01_fall_down_02')
	scene_util.set_anim(rabbit, self, { name = 'swell_out', count = 1 })

	local head_get_off_height = 0.75
	self.success_count = 0

	music_player_util.play_sfx({ sfx_name = '01_jump_01' })
	for idx = 2, #party_table do
		local start_pos = party_table[idx].Position
		local target_pos = party_table[1].Position + (jump_data.align_position.move_end[idx].pos)
		--local head_jump_duration = (target_pos - start_pos):GetX0z().magnitude / head_jump_move_speed

		scene_util.set_anim(party_table[idx], self, 'get')

		jump_move_routine(party_table[idx], start_pos, target_pos, head_jump_duration, head_get_off_height)
	end

	coroutine_util.while_from_to_each_frame(swell_out_duration, rabbit_to_scale, rabbit_from_scale, function(progress, cur_y)
		rabbit.transform.localScale = cur_y
	end)

	while self.success_count ~= #party_table - 1 do
		coroutine.yield(nil)
	end
	music_player_util.play_sfx_one_shot('01_land_01')

	for idx = 1, #party_table do
		character_util.remove_anim_and_emotion(party_table[idx])
	end
end

--몽유환(sr_ui_medicine_sleepwalk)
function local_class:sleepwalk_interact_event(idx)
	if not self:is_medicine_same_check_event(self.medicine_manager.medicine_table.medicine_sleepwalk.bit) then
		return
	end

	local bear = self.get_medicine_interact_bear(idx)
	local bear_table = self.align_table['bear_' .. idx]
	local shuran = get_party_leader()

	local bear_move_speed = 1

	--정렬
	self:align_party(bear.Position, shuran, bear_table)

	--리더 1 (윈링) 속도 1 (walk)로 0.5칸 우측 이동 후 (eat) 1초 후
	self:target_move_eat(bear.Position, shuran, true, function()
		--초기화 (웨펀 사라지는 부분)
		self:medicine_clear()
	end)

	--표정 변경
	scene_util.set_emotion(bear, self, 'damaged')

	--곰(shake0.03/0.5초)
	scene_util.shake(bear, 0.03, 0.5)

	wait_for_sec(0.5)

	--scene_util.set_direction(bear, 'down', false)
	scene_util.set_emotion(bear, self, 'sleep')

	music_player_util.play_sfx_one_shot('01_roar_02')
	music_player_util.play_sfx_one_shot('01_bubble_pop_01')

	if bear_table.sleep_sfx then
		bear_table.sleep_sfx.Volume = 0
	end

	character_util.remove_anim(bear)

	wait_for_sec(0.5)

	--곰 이동
	--곰 속도 1 로 애니메이션 (sleep_walk) 표정 (sleep) 우측 2칸 이동 후 다시 애니메이션 (sleep) 표정 (deep_sleep)
	local move_one_frame_routine = function(mover, dir_vector, move_dis, speed)
		local move_one_frame_stage_logic = CS.Oak.MoveOneFrameStageLogic

		scene_util.set_anim(mover, self, 'sleep_walk')
		scene_util.set_emotion(mover, self, 'sleep')

		local time_passed = 0
		local dur = move_dis / speed

		while time_passed < dur do
			time_passed = time_passed + unity_class.time.deltaTime
			move_one_frame_stage_logic.ExecuteMove(mover, dir_vector, speed * unity_class.time.deltaTime)

			coroutine.yield()
		end

		character_util.remove_anim(mover)
	end

	if bear_table.wp_state == 1 then
		local look_dir = vector_util.to_direction(bear_table.end_info.pos - bear_table.start_info.pos)
		local look_dir_vec = direction_util.to_vector3_ver2(look_dir)

		scene_util.set_direction(bear, look_dir, false)

		move_one_frame_routine(bear, look_dir_vec, 2, bear_move_speed)

		if bear_table.end_info.dir then
			scene_util.set_direction(bear, bear_table.end_info.dir, false)
		end

		bear_table.wp_state = 2
	elseif bear_table.wp_state == 2 then
		local look_dir = vector_util.to_direction(bear_table.start_info.pos - bear_table.end_info.pos)
		local look_dir_vec = direction_util.to_vector3_ver2(look_dir)

		scene_util.set_direction(bear, look_dir, false)

		move_one_frame_routine(bear, look_dir_vec, 2, bear_move_speed)

		if bear_table.start_info.dir then
			scene_util.set_direction(bear, bear_table.start_info.dir, false)
		end

		bear_table.wp_state = 1
	end

	wait_for_sec(0.2)

	bear_table.sleep_sfx.Volume = 0.5

	music_player_util.play_sfx_one_shot('01_hit_npc_01')
	scene_util.set_anim(bear, self, 'block_sleep')
	scene_util.set_emotion(bear, self, 'deep_sleep')
end

--금강단(sr_ui_medicine_diamond)
function local_class:diamond_interact_event(group_idx, member_idx)
	if not self:is_medicine_same_check_event(self.medicine_manager.medicine_table.medicine_diamond.bit) then
		return
	end

	local shuran = get_party_leader()
	local party_table = self:get_party_member(true)

	--인터렉트한 idx가 1일경우 2번 위치로 이동
	local target_idx = (member_idx ~= 1) and 1 or 2

	local diamond_name = self.medicine_manager.medicine_table.medicine_diamond.name
	local align_pos = self.get_medicine_diamond_interact_object(diamond_name, group_idx, member_idx).Position
	local target_pos = self.get_medicine_diamond_interact_object(diamond_name, group_idx, target_idx).Position

	local add_interval = user_party.Count
	local move_distance_vector = (target_pos - align_pos).normalized * ((target_pos - align_pos).magnitude + add_interval)

	local party_diamond_key = 'party_diamond_key'

	local move_duration = 1.5

	local diamond_table = self.align_table['diamond_' .. group_idx]

	--정렬
	diamond_table.wp_state = member_idx
	self:align_party(align_pos, shuran, diamond_table)

	local shuran_dir = shuran.Direction
	local side_dir = direction_util.to_str(direction_util.to_side_dir(shuran_dir))

	--초기화 (웨펀 사라지는 부분)
	self:medicine_clear()

	--이펙트 저장 테이블 (연출 끝나고 제거를 위함)
	local fx_table = {}

	start_coroutine(function(_)
		for idx = 1, #party_table do
			if not party_table[idx] then
				break
			end

			wait_for_sec(0.5)

			music_player_util.play_sfx_one_shot('02_magic_heal_01')
			table.insert(fx_table, self.fx.buff_loop():Instantiate(party_table[idx].Position, unity_class.quaternion.identity, party_table[idx].Transform))
		end
	end)

	--eat
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01' })

	scene_util.play_wait_action(shuran, self,
			side_dir,
			'eat',
			nil,
			1.5)

	eat_sfx:Stop()

	scene_util.set_direction(shuran, shuran_dir, false)

	wait_for_sec(0.5)

	local dash_sfx = music_player_util.play_sfx({ sfx_name = '01_dash_01', parent = shuran,
												  type_priority = 'gimmick', player_priority = 'object' })

	for idx = 1, #party_table do
		if not party_table[idx] then
			break
		end

		wp_util.move_with_end_callback(party_table[idx], party_table[idx].Position + move_distance_vector, nil,
				move_duration, self, party_diamond_key, { run = true })
	end

	local move_vector = direction_util.to_vector3_ver2(shuran.Direction) * 9

	local obj_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(shuran.Bounds, move_vector)
	local thorns_count = obj_list.Count / 2

	start_coroutine(function()
		local idx = 0

		while idx < obj_list.Count - 1 do
			local obj_1 = obj_list[idx]
			local obj_2 = obj_list[idx + 1]

			if obj_1.Name == '[gimmick]thorns' then
				field_object_util.shake(obj_1, 0.1, 0.2)
				field_object_util.shake(obj_2, 0.1, 0.2)

				music_player_util.play_sfx_one_shot('02_break_leaf_01')

				self.fx.break_leaf():Instantiate(obj_1.Position)
				self.fx.break_leaf():Instantiate(obj_2.Position)

				-- 이동 시간 / 덩쿨의 개수 만큼 쉰다다
				wait_for_sec(move_duration / thorns_count)

				idx = idx + 2
			else
				idx = idx + 1
			end
		end
	end)

	wp_util.wait_move_end(self, party_diamond_key)

	dash_sfx:Stop()

	for idx = 1, #party_table do
		if not party_table[idx] then
			break
		end

		fx_table[idx]:Dispose()
	end
end

--외강산(sr_ui_medicine_break)
function local_class:break_interact_event(group_idx)
	if not self:is_medicine_same_check_event(self.medicine_manager.medicine_table.medicine_break.bit) then
		return
	end

	local shuran = get_party_leader()

	local rock_table = self.align_table['rock_' .. group_idx]

	--바위에 비약을 던지고 모션으로 공격 시 바위가 파괴됨
	local first_bomb_rock_table = {}
	local second_bomb_rock

	local break_name = self.medicine_manager.medicine_table.medicine_break.name
	local group_count = self.gimmick_interact_count.break_1.group_member_max_count

	for idx = 1, group_count - 1 do
		table.insert(first_bomb_rock_table, self.get_medicine_break_interact_object(break_name, group_idx, idx))
	end

	second_bomb_rock = self.get_medicine_break_interact_object(break_name, group_idx, group_count)

	--정렬
	self:align_party(vector_util.get_x0z(second_bomb_rock.Bounds.center), shuran, rock_table)

	local shuran_dir = shuran.Direction

	wait_for_sec(0.5)

	--리더 1 (윈링) 속도 1 (walk)로 0.5칸 좌측 이동 후 (eat) 1초 후
	self:target_move_eat(second_bomb_rock.Position, shuran, false, function()
		--초기화 (웨펀 사라지는 부분)
		self:medicine_clear()
	end)

	--(sleep_deep,cross_arm) 으로 0.5초 대기
	scene_util.set_emotion(shuran, self, 'sleep_deep')
	scene_util.set_anim(shuran, self, { name = 'cross_arm', one_shot_sfx = '03_dialogue_ready_01' })

	wait_for_sec(0.5)

	--윈링 표정 (attack) (attack)(katana_attack3)(0.5배속) 애니메이션 1회 재생
	scene_util.set_emotion(shuran, self, 'attack')
	scene_util.set_anim(shuran, self, { name = 'katana_attack3', count = 1, scale = 0.5 })

	--모션 시작 0.5초 후
	wait_for_sec(0.5)

	local bomb_rock = function(target)
		camera_util.shake(0.03, 0.3)

		music_player_util.play_sfx_one_shot('03_rock_break_02')

		self.fx.obj_smoke():Instantiate(target.Bounds.center)

		target.ActiveState = active_state('disabled')
	end

	--캐릭터 기준 우측 앞에 빨간색(1) 표시한 바위가 shake0.03 시작 이 후 파란색(2) - 초록색(3) 순서대로 0.5초 간격으로 shake0.03 시작
	local earthquake_sfx = music_player_util.play_sfx({ sfx_name = '01_earthquake_05', loop = true })

	music_player_util.play_sfx_one_shot('02_hit_monster_01')
	music_player_util.play_sfx_one_shot('02_magic_hit_02')

	for idx = 1, group_count - 1 do
		field_object_util.shake(first_bomb_rock_table[idx], 0.03, 1)

		wait_for_sec(0.5)
	end

	--바위 부서질 때 마다 화면 shake0.03/0.3초 씩 추가 부탁드립니다.
	bomb_rock(first_bomb_rock_table[1])

	field_object_util.shake(second_bomb_rock, 0.03, 1)

	wait_for_sec(0.5)

	bomb_rock(first_bomb_rock_table[2])

	--각 바위들은 shake 시작 1초 후 fx_obj_smoke와 함께 사라진다.
	wait_for_sec(0.5)

	bomb_rock(second_bomb_rock)

	music_player_util.fade_out_sfx(earthquake_sfx, 1)

	wait_for_sec(0.2)

	character_util.remove_anim_and_emotion(shuran)
end
--endregion interact_event

--region custom_function
function local_class:pre_setting()
	--곰
	for idx = 1, self.gimmick_interact_count.sleepwalk do
		local bear = self.get_medicine_interact_bear(idx)
		local bear_table = self.align_table['bear_' .. idx]

		scene_util.set_anim(bear, self, 'block_sleep')
		scene_util.set_emotion(bear, self, 'deep_sleep')

		--히트 박스 조정
		local bear_scale = unity_class.vector3.one * 1.5

		bear.transform.localScale = bear_scale
		if bear_table.hit_box.pivot then
			bear.Hitbox = CS.Oak.Hitbox(bear_table.hit_box.pivot, bear_table.hit_box.scale)
		else
			bear.Hitbox = CS.Oak.Hitbox(bear_table.hit_box.scale)
		end

		--start 위치 저장
		bear_table.start_info.pos = bear.Position

		--end 위치 저장
		bear_table.end_info.pos = bear.Position + bear_table.end_info.pos
	end

	--히트박스 조절 (점프 상호작용체)
	for idx = 1, self.gimmick_interact_count.jump do
		local target_fo = self.get_medicine_jump_interact_object(
				self.medicine_manager.medicine_table.medicine_jump.name, idx)
		local angle_y = target_fo.transform.eulerAngles.y

		if angle_y == 0 or angle_y == 90 then
			target_fo.Hitbox = CS.Oak.Hitbox(vector(1, 1, 6))
		elseif angle_y == 180 or angle_y == 270 then
			target_fo.Hitbox = CS.Oak.Hitbox(vector(6, 1, 1))
		end
	end

	--medicine_interact_diamond_1_1
	--히트박스 조절 (다이아몬드 상호작용체)
	for group_idx = 1, self.gimmick_interact_count.diamond.group_max_count do
		for member_idx = 1, self.gimmick_interact_count.diamond.group_member_max_count do
			local target_fo = self.get_medicine_diamond_interact_object(
					self.medicine_manager.medicine_table.medicine_diamond.name, group_idx, member_idx)
			local angle_y = target_fo.transform.eulerAngles.y
			local target_pos = self.get_diamond_interact_pos(group_idx, member_idx)

			target_fo.Position = target_pos

			if angle_y == 0 or angle_y == 90 then
				target_fo.Hitbox = CS.Oak.Hitbox(vector(1, 1, 2))
			elseif angle_y == 180 or angle_y == 270 then
				target_fo.Hitbox = CS.Oak.Hitbox(vector(2, 1, 1))
			end
		end
	end
end

--메디신 사용 시 또는 제조 실패 시 초기화 기능
function local_class:medicine_clear()
	if self.medicine_manager.herb_bit == 0 then
		return
	end

	local shuran = get_party_leader()
	-- ui 제거 및 세팅 초기화
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'ui_off' }))

	self:set_medicine_attachment(shuran, false)

	--인터렉트 비활성화
	self:all_setting_interact_object(false)

	self.medicine_manager:bit_clear()
	self.medicine_manager.current_state = self.medicine_manager.state.default
end

--타겟 앞으로가서 eat 모션 (3가지 비약 공용 연출)
function local_class:target_move_eat(target_pos, shuran, is_back, call_back)
	local look_dir = vector_util.to_direction(target_pos - shuran.Position)

	--바위를 바라보며 0.5칸 간격
	local str_dir = direction_util.to_str(look_dir)
	local side_dir = direction_util.to_str(direction_util.to_side_dir(shuran.Direction))
	local start_move_pos = shuran.Position
	local pos_interval = 0.5

	local end_move_pos

	--리더가 보고있는 방향
	if str_dir == 'left' then
		end_move_pos = shuran.Position + vector(-pos_interval, 0, 0)
	elseif str_dir == 'right' then
		end_move_pos = shuran.Position + vector(pos_interval, 0, 0)
	elseif str_dir == 'up' then
		end_move_pos = shuran.Position + vector(0, 0, pos_interval)
	elseif str_dir == 'down' then
		end_move_pos = shuran.Position + vector(0, 0, -pos_interval)
	end

	--리더 1 (윈링) 속도 1 (walk)로 0.5칸 우측 이동 후 (eat) 1초 후
	wp_util.move_async(shuran, end_move_pos, 1)

	if call_back then
		call_back()
	end

	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01' })

	scene_util.play_wait_action(shuran, self,
			{ dir = side_dir, sfx = false },
			'eat',
			nil,
			1)

	eat_sfx:Stop()

	--윈링 속도1 (walk) 로 0.5칸 좌측 이동 (바라보는 방향 고정)
	if is_back then
		wp_util.move_async(shuran, start_move_pos, 1, nil, { locked_dir = str_dir })
	else
		scene_util.set_direction(shuran, str_dir, false)
	end
end

--파티 정렬 함수
function local_class:align_party(target_pos, shuran, fo_table)
	local align_dir
	local look_dir

	if fo_table.wp_state == 1 then
		look_dir = vector_util.to_direction(target_pos - shuran.Position)

		align_dir = fo_table.align_info.first[direction_util.to_str(look_dir)]

	elseif fo_table.wp_state == 2 then
		look_dir = vector_util.to_direction(target_pos - shuran.Position)

		align_dir = fo_table.align_info.second[direction_util.to_str(look_dir)]
	end

	--추가 거리가 있을 경우
	if fo_table.align_info.add_pos then
		if fo_table.align_info.back_add_pos and align_dir == 'up' then
			if type_util.is_number(fo_table.align_info.back_add_pos) then
				target_pos = target_pos +
						(direction_util.to_vector3_ver2(align_dir) * fo_table.align_info.back_add_pos)
			else
				target_pos = target_pos + fo_table.align_info.back_add_pos
			end
		else
			if type_util.is_number(fo_table.align_info.add_pos) then
				target_pos = target_pos +
						(direction_util.to_vector3_ver2(align_dir) * fo_table.align_info.add_pos)
			else
				target_pos = target_pos + fo_table.align_info.add_pos
			end
		end
	end

	party_util.align_party(target_pos, align_dir, 1, 'linear')
end

--무기 장착 및 해제 함수
function local_class:set_medicine_attachment(target, is_medicine)
	if is_medicine then
		target.CustomIdleAnimationName = 'staff_idle'
		target.CustomWalkAnimationName = 'staff_walk'
		target.CustomRunAnimationName = 'staff_run'
		target.CustomDamagedAnimationName = 'staff_damaged'

		character_util.set_equipment(target, CS.Oak.EquipmentSlot.Weapon1, 9092584, true)

		party_util.stop_and_disable_control()
	else
		character_util.set_equipment(target, CS.Oak.EquipmentSlot.Weapon1, -1)

		target.CustomIdleAnimationName = nil
		target.CustomWalkAnimationName = nil
		target.CustomRunAnimationName = nil
		target.CustomDamagedAnimationName = nil
	end
end

--파티 멤버 체크 함수
function local_class:get_party_member(is_sort)
	local rabbit = self.get_rabbit()
	local shuran = get_party_leader()
	local jungpa_master = self.get_jungpa_master()
	local party_table

	if is_sort then
		if user_party.Count == 3 then
			party_table = {
				shuran,
				jungpa_master,
				rabbit,
			}
		elseif user_party.Count == 2 then
			party_table = {
				shuran,
				rabbit,
			}
		end
	else
		if user_party.Count == 3 then
			party_table = {
				rabbit,
				shuran,
				jungpa_master
			}
		elseif user_party.Count == 2 then
			party_table = {
				rabbit,
				shuran,
			}
		end
	end

	return party_table
end

--비약 이름 체크 함수
function local_class:is_medicine_same_check_event(medicine_bit)
	local shuran = get_party_leader()

	if not self.medicine_manager:check_medicine(medicine_bit) then
		--(tired, bomb_idle): 이 비약은 여기서 쓸 수 없어.
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		scene_util.play_normal_speech_action(shuran, self,
				nil,
				'bomb_idle',
				'tired',
				'short_story_sr_gimmick_2')

		return false
	end

	return true
end

--비약에 사용되는 인터렉트 활성화 및 비활성화 함수
function local_class:all_setting_interact_object(is_active)
	--천보환
	for idx = 1, self.gimmick_interact_count.jump do

		local target = self.get_medicine_jump_interact_object(
				self.medicine_manager.medicine_table.medicine_jump.name, idx)

		if is_active then
			target.Interactable = CS.Oak.PublishInteractable.Create()
		else
			target.Interactable = CS.Oak.NonInteractable.Instance
		end
	end

	--금강단
	for group_idx = 1, self.gimmick_interact_count.diamond.group_max_count do
		for member_idx = 1, self.gimmick_interact_count.diamond.group_member_max_count do
			local target = self.get_medicine_diamond_interact_object(
					self.medicine_manager.medicine_table.medicine_diamond.name, group_idx, member_idx)

			if is_active then
				target.Interactable = CS.Oak.PublishInteractable.Create()
			else
				target.Interactable = CS.Oak.NonInteractable.Instance
			end
		end
	end

	--몽유환
	for idx = 1, self.gimmick_interact_count.sleepwalk do
		local bear = self.get_medicine_interact_bear(idx)

		if is_active then
			character_util.add_listener(bear, self)
		else
			character_util.remove_relate_event(bear, self)
		end
	end

	--외강산
	for group_idx = 1, self.gimmick_interact_count.break_1.group_max_count do
		for member_idx = 1, self.gimmick_interact_count.break_1.group_member_max_count - 1 do
			local target = self.get_medicine_break_interact_object(
					self.medicine_manager.medicine_table.medicine_break.name, group_idx, member_idx)
			if is_active then
				target.Interactable = CS.Oak.PublishInteractable.Create()
			else
				target.Interactable = CS.Oak.NonInteractable.Instance
			end
		end
	end
end

--곰이 존재하는 그리드 입장 시 소리 세팅
function local_class:grid_enter_bear_sfx_setting(e)
	for idx = 1, self.gimmick_interact_count.sleepwalk do
		local bear = self.get_medicine_interact_bear(idx)
		local bear_table = self.align_table['bear_' .. idx]

		local check = CS.BoundsExtensions.ContainsXZ(e.CameraGrid.bounds, bear.Position)

		if bear_table.sleep_sfx then
			bear_table.sleep_sfx:Stop()
			bear_table.sleep_sfx = nil
		end

		if check then
			bear_table.sleep_sfx = music_player_util.play_sfx({
				sfx_name = '01_sleep_02',
				loop = true, parent = bear,
				volume = 0.5,
				max_distance = 5,
				type_priority = 'event',
				player_priority = 'npc' })

			wait_for_sec(0.2)
		end
	end

	return true
end
--endregion custom_function

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
