local local_class = newclass("DemonWorldBuildingTransparentController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_2_name = 'demonworld_part1_1_2'
	self.stage_3_name = 'demonworld_part1_1_3'
	self.stage_4_name = 'demonworld_part1_1_4'

	-- 플레이어 가리는 빌딩 투명화 작업 플래그
	self.is_activated = true

	-- 레이어 구분 Transform 이름
	self.upper_transform_name = 'upper'

	-- 플레이어가 옥상에 있는지 확인하는 플래그
	self.is_player_in_looftop = false

	-- 지면의 캐릭터 크기 비례 감소 정도
	self.shrink_scale = 0.3

	-- 기준 y값
	self.looftop_height = 7

	-- 옥상 Zone 이름
	self.looftop_zone_name = 'looftop'
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.resource_holder = CS.Foundations.ResourceHolder()

	-- 메테리얼을 가지고 있는 컨테이너를 로드하여 투명화 할 메테리얼을 가져온다.
	local container_obj_1 = load_util.load_prefab_async(self.resource_holder,
			'ondemand/v2_15_demonworld/tilesets/demonworld', 'transparent_material_container')
	local container_obj_2 = load_util.load_prefab_async(self.resource_holder,
			'tilesets/gimmick', 'gimmick_transparent_material_container')

	local mat_container_1 = container_obj_1:GetComponent(typeof(CS.Oak.MaterialContainer))
	local mat_container_2 = container_obj_2:GetComponent(typeof(CS.Oak.MaterialContainer))

	-- 두 컨테이너의 마테리얼 리스트를 합한 새 리스트를 만들어서 저장
	self.transparent_mat_list = create_generic_list(CS.UnityEngine.Material)
	self.transparent_mat_list:AddRange(mat_container_1.MaterialList)
	self.transparent_mat_list:AddRange(mat_container_2.MaterialList)

	-- 로드했던 오브젝트 바로 제거
	CS.UnityEngine.Object.Destroy(container_obj_1)
	CS.UnityEngine.Object.Destroy(container_obj_2)

	-- 레이케스트 결과값을 저장해서 받아올 RaycastHit 의 배열, 최대 다섯개까지 받아온다.
	self.raycast_hit_array = CS.PhysicsExtensions.GetRaycastHitArray(5)

	-- 현재 투명상태인 오브젝트의 리스트
	self.transparent_objects = {}

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	-- message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_field_object_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	-- message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))

	if self.resource_holder ~= nil then
		self.resource_holder:Dispose()
		self.resource_holder = nil
	end

	self.transparent_mat_list = nil

	self.transparent_objects = nil

	self.raycast_hit_array = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_building_transparent, self))
end

--[[
function local_class:on_move_field_object_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party_leader) and self.is_activated then
		if not self.is_player_in_looftop and field:IsOnUpperFloor(user_party_leader.Position) then
			self.is_player_in_looftop = true

			self:set_floor_character_giant_factor(self.shrink_scale)
		elseif self.is_player_in_looftop and not field:IsOnUpperFloor(user_party_leader.Position) then
			self.is_player_in_looftop = false

			self:reset_floor_character_giant_factor()
		end
	end
end
]]

-- 빌딩 투명화 체크
function local_class:check_building_transparent()
	while true do
		self:make_building_transparent()

		coroutine.yield(nil)
	end
end

--[[
-- 지상에 있는 모든 캐릭터들의 크기를 줄인다
function local_class:set_floor_character_giant_factor(val)
	local parent_transform = stage.StageTransform
	local child_count = parent_transform.childCount

	for i = 0, child_count - 1 do
		local cur_child = parent_transform:GetChild(i)
		local character = cur_child:GetComponent(typeof(CS.Oak.Character))

		if character ~= nil and character.Position.y < user_party_leader.Position.y then
			-- 파티원들은 무시
			local is_party = false

			for j = 0, user_party.Count - 1 do
				if lua_helper.reference_equals(user_party[j], character) then
					is_party = true

					break
				end
			end

			if not is_party and not field:IsOnUpperFloor(character.Position) then
				character_util.set_scale_factor(character, character.Name,
						(1 - val * (self.looftop_height - character.Position.y) / self.looftop_height))
			end
		end
	end
end

-- 지상에 있는 모든 캐릭터들의 크기를 복구한다
function local_class:reset_floor_character_giant_factor()
	local parent_transform = stage.StageTransform
	local child_count = parent_transform.childCount

	for i = 0, child_count - 1 do
		local cur_child = parent_transform:GetChild(i)
		local character = cur_child:GetComponent(typeof(CS.Oak.Character))

		if character ~= nil then
			character_util.remove_scale_factor(character, character.Name)
		end
	end
end
]]

-- 카메라 위치 기반으로 Ray를 발사해서 검출되는 빌딩은 리스트에 추가하고 투명하게 설정, 대상 변경되면 기존 빌딩은 원래대로 복구
function local_class:make_building_transparent()
	local vp = stage_camera.Camera:WorldToViewportPoint(user_party_leader.Position)
	local ray = stage_camera.Camera:ViewportPointToRay(vp)

	-- 카메라에서 Ray를 쏜다. Ray의 거리는 카메라 위치까지로 제한.
	local count = ray:RaycastNonAlloc(self.raycast_hit_array,
			(ray.origin - stage_camera.LookAtPosition).magnitude - 0.5)

	local hit_objects = {}

	for i = 0, count - 1 do
		local transparent_object = self.raycast_hit_array[i].transform:GetComponent(typeof(CS.Oak.TransparentController))

		if not is_unity_null(transparent_object) then
			table.insert(hit_objects, transparent_object)
		end
	end

	-- 이미 투명상태인 오브젝트들을 순회하며 현재 Ray에 안 걸린 오브젝트가 있다면 복구해준다.
	for i = #self.transparent_objects, 1, -1 do
		-- 레이에 걸려있는지 여부를 저장하는 로컬 변수
		local is_hit = false
		local transparent_object = self.transparent_objects[i]

		for j = #hit_objects, 1, -1 do
			if hit_objects[j] == transparent_object then
				-- 여전히 레이에 걸려있다면 is_hit 를 true 로 변경하고
				is_hit = true

				-- hit_objects 에서 해당 오브젝트 지운다.
				-- 추후 hit_objects에 남아있는 오브젝트는 Hide 를 호출하여 투명하게 변경된다.
				table.remove(hit_objects, j)
				break
			end
		end

		-- 기존에 Ray 에 걸렸다가, 안 걸리게 된 오브젝트는 투명을 해제한다.
		if is_hit == false then
			table.remove(self.transparent_objects, i)
			transparent_object:Unhide()

			-- 아래와 같은 방식으로 시간을 조절할 수 있다.
			-- transparent_object:Unhide(2)
		end
	end

	-- hit_objects 에 아직 남아있는 오브젝트(이번에 Ray에 새로 걸린 오브젝트)는 숨겨준다.
	for i = 1, #hit_objects do
		local transparent_object = hit_objects[i]

		table.insert(self.transparent_objects, transparent_object)

		transparent_object:Hide(self.transparent_mat_list)

		-- 아래와 같은 방식으로 투명도와 시간을 조절할 수 있다.
		-- transparent_object:Hide(self.transparent_mat_list, 2, 50/255)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}