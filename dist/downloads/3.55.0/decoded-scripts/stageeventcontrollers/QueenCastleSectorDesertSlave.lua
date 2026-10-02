local local_class = newclass('QueenCastleSectorDesertSlaveController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.android_parts_sprite_cache = {}
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	self:dispose_all_android_parts_sprite()
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
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



--region 안드로이드 관련 로직

-- 안드로이드 신체 부위 스프라이트 배치 함수
function local_class:place_android_parts_sprite()
	local function create_android_parts_sprite_by_id(sprite_id, position)
		local part_item_info = {
			pos = position,
			itemid = sprite_id, 
			notforinven = true, 
			showoncharacter = false,
			lootstate = 'dontfindlooter',
			sprscale = 1
		}
		
		return drop_item_util.create_item(part_item_info)
	end

	-- SoA 구조로 되어있음
	-- 즉, id_list 사이즈와 position_list 사이즈를 보장할 것.
	local android_parts_id_position_relation = {
		id_list = {},
		position_list = {}
	}

	for i = 1, #android_parts_id_position_relation do
		local android_parts_sprite_id = android_parts_id_position_relation.id_list[i]
		local android_parts_position = android_parts_id_position_relation.position_list[i]

		local created_parts = create_android_parts_sprite_by_id(android_parts_sprite_id, android_parts_position)
		if is_unity_null(created_parts) then
			logger_util.error("Failed to created android parts id: " .. android_parts_sprite_id .. " at: " .. android_parts_position)
			goto continue
		end

		table.insert(self.android_parts_sprite_cache, created_parts)

		::continue::
	end
end

function local_class:dispose_all_android_parts_sprite()
	for i = 1, #self.android_parts_sprite_cache do
		self.android_parts_sprite_cache[i]:ConsumeComplete()
		self.android_parts_sprite_cache[i] = nil
	end

	self.android_parts_sprite_cache = nil
end

-- 몸통만 남은 안드로이드 캐릭터 세팅 함수
function local_class:place_broken_android_bodyies()
end

--endregion



--region 마법진 관련 로직

--마법진 초기화 함수
function local_class:init_magic_circle()
	if not self:is_magic_circle_available() then
		return
	end
end

--마법진을 활성화 시킬 수 있는 확인하는 유틸
---@return boolean
function local_class:is_magic_circle_available()
	return false
end

--마법진 사용시 연출 로직
function local_class:co_step_on_magic_cirle()
end
--endregion


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
