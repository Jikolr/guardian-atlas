require('base/class')
util = require('xlua.util')
-- 전역적으로 자주 불러서 사용 되는 변수들

--TODO: BattleSystem쪽에서 사용하지 않는 기능들은 삭제하자...

function init()
	-- 시스템
	message_system = CS.Oak.LuaMessageSystemAdapter.GetOrCreate(CS.Oak.LuaMessageSystemLifeCycle.None)
	coroutine_manager = CS.Foundations.CoroutineManager.Instance
	unity_object_pool = CS.Oak.UnityObjectPool
	object_pool_extensions = CS.Oak.UnityObjectPoolExtensions
	game_data_service = CS.Oak.GameDataService
	music_player = CS.Oak.MusicPlayer.Instance

	-- 스테이지 변수들
	stage = CS.Oak.Stage.Instance
	stage_camera = CS.Oak.Stage.Instance.StageCamera
	character_manager = CS.Oak.Stage.Instance.CharacterManager
	battle_manager = CS.Oak.Stage.Instance.BattleManager
	buff_manager = CS.Oak.Stage.Instance.BuffManager
	buff_extentions = CS.Oak.IBuffExtensions
	party_manager = CS.Oak.PartyManager.Instance

	field = CS.Oak.Stage.Instance.Field
	user_party = CS.Oak.PartyManager.Instance.UserParty
	user_party_leader = user_party.Leader

	position_skill_extensions = CS.Oak.IPositionBattleActionExtensions

	constants = {
		epsilon = CS.Oak.Constants.Epsilon
	}

	character_cache = {}

	get_character = function(name)
		if name == nil then return nil end

		if character_cache[name] == nil then
			local c = stage:GetCharacter(name)
			character_cache[name] = c
		end
		return character_cache[name]
	end

	fo_cache = {}
	get_field_object = function(name)
		if name == nil then return nil end
		if fo_cache[name] == nil then
			local c = field:GetFieldObject(name)
			fo_cache[name] = c
		end
		return fo_cache[name]
	end

	--- 배틀액션에서 사용할 상수
	battle_constants = {
		--- 메뉴얼 캐릭터들이 대상을 찾을 때 사용하는 기본 거리
		default_search_range = 7,
		--- 메뉴얼 캐릭터가 아닌 경우 dash에 사용할 speedScale
		non_manual_speed_scale = 0.6,
		--- 메뉴얼 캐릭터가 hittable을 체크할때 사용할 기본 scale
		default_hittable_scale = 0.8,
		--- 옵션 기본 쿨타임 (의도치 않은 빈번한 능력 사용 방지 및 밸런싱 이슈 방지 목적)
		option_default_cool_time = CS.Oak.Constants.ProbOptionDefaultCoolTime
	}

	--- 치유 액션의 종류
	heal_type = {
		--- 일반적인 치유
		normal = CS.Oak.HealType.Normal,
		--- HP 흡수 옵션을 통한 치유
		drain = CS.Oak.HealType.Drain
	}

	--- 스턴 관련 상수
	--- IMPORTANT: 해당 기능 확장시 클라이언트 팀에 꼭 확인 하고 확장 부탁 드립니다.
	stun_constants = {
		--- 영웅 평타
		factor_normal = CS.Oak.DamageStunConstants.FactorNormal,
		--- 무기 기술
		factor_normal_enhanced = CS.Oak.DamageStunConstants.FactorNormalEnhanced,
		--- 몬스터 시그니처 기술, 특수 무기 기술 (영웅도 영향 받음)
		factor_normal_strong = CS.Oak.DamageStunConstants.FactorNormalStrong,
		--- 꼭 스턴 되어야 하는 보스 몬스터 기술 (개화가 추가되면서 이캐릭터 저캐릭터 쓰는 상황이라 아래 새로운 단계 2개를 더 만들엇다.)
		factor_strong = CS.Oak.DamageStunConstants.FactorStrong,
		--- [myth]  개화 스킬에 의해 방어 되어야하는 경우
		factor_ult = CS.Oak.DamageStunConstants.FactorUltimateStrong,
		--- 보스나 시스템적으로 기믹에 의해서 반드시 넉백 되어야 하는 경우 (의도가 넉백등으로 캐릭터 위치를 맞추거나 안하면 고장나는 경우)
		factor_gimmick = CS.Oak.DamageStunConstants.FactorSystemGimmick
	}

	--- 넉백 관련 상수
	--- IMPORTANT: 해당 기능 확장시 클라이언트 팀에 꼭 확인 하고 확장 부탁 드립니다.
	knock_back_constants = {
		standard_force = CS.Oak.DamageKnockBackConstants.StandardForce,
		standard_melee_force = CS.Oak.DamageKnockBackConstants.StandardMeleeForce,
		default_impact_time = CS.Oak.DamageKnockBackConstants.DefaultImpactTime,
		default_friction_coefficient = CS.Oak.DamageKnockBackConstants.DefaultFrictionCoefficient,
		--- 영웅 평타
		factor_normal = CS.Oak.DamageKnockBackConstants.FactorNormal,
		--- 무기 기술
		factor_normal_enhanced = CS.Oak.DamageKnockBackConstants.FactorNormalEnhanced,
		--- 몬스터 시그니처 기술, 특수 무기 기술 (영웅도 영향 받음)
		factor_normal_strong = CS.Oak.DamageKnockBackConstants.FactorNormalStrong,
		--- 꼭 스턴 되어야 하는 보스 몬스터 기술
		factor_strong = CS.Oak.DamageKnockBackConstants.FactorStrong,
		--- [myth] 개화 스킬에 의해 방어 되어야하는 경우
		factor_ult = CS.Oak.DamageKnockBackConstants.FactorUltimateStrong,
		--- 보스나 시스템적으로 기믹에 의해서 반드시 넉백 되어야 하는 경우 (의도가 넉백등으로 캐릭터 위치를 맞추거나 안하면 고장나는 경우)
		factor_gimmick = CS.Oak.DamageKnockBackConstants.FactorSystemGimmick
	}

	--- Projectile이 충돌 혹은 소멸할 때 원인이 무엇인가
	projectile_hit_type = {
		--- 지속시간 만료로 인한 해제
		self_destruction = CS.Oak.Projectile.HitType.SelfDestruction,
		--- FieldObject에 부딫힘
		field_object = CS.Oak.Projectile.HitType.FieldObject,
		--- 벽 등의 맵에 부딫힘
		map_hit = CS.Oak.Projectile.HitType.MapHit,
		--- shooter의 사망 등으로 인한 강제 제거
		force_eliminate = CS.Oak.Projectile.HitType.ForceEliminate,
	}

	--- 어떤 애니메이션을 스파인 몇 번 트랙에 할당할지
	spine_animation_track = {
		--- 베이스 애니메이션 트랙 번호
		base = CS.Oak.Character.SpineAnimationTrack.Base,
		--- 상체 애니메이션 트랙 번호
		upper = CS.Oak.Character.SpineAnimationTrack.Upper
	}

	--- weapon attachment request 에서 사용되는 우선순위
	weapon_attachment_priority = {
		--- 기본값. 코스튬을 덮어씌움.
		default = CS.Oak.WeaponAttachmentPriorities.Default,
		--- 옵션 등에서 사용
		option = CS.Oak.WeaponAttachmentPriorities.Option,
		--- 배틀액션에서 사용
		battle_action = CS.Oak.WeaponAttachmentPriorities.BattleAction
	}

	--- weapon attachment request 에서 사용되는 슬롯
	weapon_attachment_slot = {
		Weapon1 = CS.Oak.AttachmentRequestSlot.Weapon1,
		Weapon2 = CS.Oak.AttachmentRequestSlot.Weapon2,
	}

	parent_follow_flag = {
		none = CS.Oak.ParentFollowFlag.None,
		position = CS.Oak.ParentFollowFlag.Position
	}

	-- 캐싱 한 클래스 타입들
	unity_class = {
		list = CS.System.Collections.Generic.List,
		queue = CS.System.Collections.Generic.Queue,
		dictionary = CS.System.Collections.Generic.Dictionary,
		hashset = CS.System.Collections.Generic.HashSet,
		mathf = CS.UnityEngine.Mathf,
		quaternion = CS.UnityEngine.Quaternion,
		vector2 = CS.UnityEngine.Vector2,
		vector3 = CS.UnityEngine.Vector3,
		vector4 = CS.UnityEngine.Vector4,
		time = CS.UnityEngine.Time,
		color = CS.UnityEngine.Color,
		random = CS.UnityEngine.Random,
		bounds = CS.UnityEngine.Bounds
	}

	-- coroutine 클래스 캐싱
	coroutine_class = {
		coroutine = CS.Foundations.Coroutine,
		wait_for_sec =  function(time)
			local s = unity_class.time.time
			while unity_class.time.time - s < time do
				coroutine.yield(nil)
			end
		end,
		wait_for_unscaled_sec = function(time)
			local s = unity_class.time.unscaledTime
			while unity_class.time.unscaledTime - s < time do
				coroutine.yield(nil)
			end
		end,
		wait_all = CS.Foundations.WaitAll
	}

	wait_for_sec = function(time)
		local s = unity_class.time.time
		while unity_class.time.time - s < time do
			coroutine.yield(nil)
		end
	end

	wait_for_unscaled_sec = function(time)
		local s = unity_class.time.unscaledTime
		while unity_class.time.unscaledTime - s < time do
			coroutine.yield(nil)
		end
	end

	-- 기존 CS.Foundations.WaitAll의 경우 Param이 1개일 때 문제가 생겨(루아 오류인듯...?)
	-- Param이 1개 일 때 예외 처리함
	wait_all = function(...)
		local params = {}
		if type_util.is_table(...) then
			params = ...
		else
			params = table.pack(...)
		end

		local count = #params
		if count == 1 then
			-- cs_generator 또는 coroutine이 넘어올 수 있기 때문에 체크
			local co
			if CS.Oak.LuaScriptQuestUtil.CheckType(params[1], typeof(CS.Foundations.Coroutine)) then
				co = params[1]
			else
				co = coroutine_class.coroutine(params[1])
			end
			-- HACK: 우리 코루틴은 던지면 바로 실행 시켜야 되므로 여기서 실행
			-- 바로 한번 실행
			local co = coroutine_class.coroutine(params[1])

			-- co:MoveNext()
			coroutine.yield(co)
			return
		end

		coroutine.yield(coroutine_class.wait_all(table.unpack(params)))
	end

	--- 대상 fo가 nil(정의되지 않았음)이거나 Null인지 판별
	is_unity_null = function(fo)
		--- nil(정의 되지 않음)
		if fo == nil then
			return true
		end

		--- Null
		if fo:Equals(nil) then
			return true
		end

		return false
	end

	-- vector 생성, 인자 수에 따라 가능
	vector = function(x, y, z, w)
		if z == nil then
			return unity_class.vector2(x, y)
		end

		if w == nil then
			return unity_class.vector3(x, y, z)
		end

		return unity_class.vector4(x, y, z, w)
	end

	create_generic_list = function(type)
		local list_type = unity_class.list(type)
		return list_type()
	end

	create_generic_queue = function(type)
		local queue_type = unity_class.queue(type)
		return queue_type()
	end

	create_generic_dictionary = function(type1, type2)
		local dic_type = unity_class.dictionary(type1, type2)
		return dic_type()
	end

	create_generic_hashset = function(type)
		local hashset_type = unity_class.hashset(type)
		return hashset_type()
	end

	lua_helper = {
		get_value = function(table, key, default)
			if table == nil then return default end
			if key == nil then return nil end
			if table[key] ~= nil then return table[key] end
			return default
		end,
		get_or_default = function(value, default)
			if value == nil then return default end
			return value
		end,
		transform_value = function(table, key, transform_func)
			if table[key] ~= nil then return transform_func(table[key]) end
			return nil
		end,
		call_nullable = function(object, function_name, ...)
			if object == nil or object[function_name] == nil then return end
			local args = {...}
			local func = object[function_name]

			return func(table.unpack(args))
		end,

		reference_equals = function(a, b)
			return CS.System.Object.ReferenceEquals(a, b)
		end,
		--- interface 는 namespace 까지 포함
		call_interface = function(target, interface, function_name, ...)
			if target == nil then return end

			xlua.private_accessible(target:GetType())
			local args = {...}
			local func = target[function_name]
			if func == nil then
				local private_impl_name = string.format('%s.%s', interface, function_name)
				func = target[private_impl_name]
			end

			if func ~= nil then
				return func(target, table.unpack(args))
			end

			return nil
		end,

		type_compare = function(target, type)
			if target == nil or type == nil then return false end

			return CS.Oak.LuaScriptQuestUtil.CheckType(target, typeof(type))
		end,

		get_conditional_value = function(conditional, v1, v2)
			if conditional then
				return v1
			else
				return v2
			end
		end
	}

	type_util = {
		is_table = function(table)
			return table ~= nil and type(table) == 'table'
		end,
		is_array = function(table)
			return table ~= nil and type(table) == 'table' and table[1] ~= nil
		end,
		is_number = function(data)
			return data ~= nil and type(data) == 'number'
		end,
		is_string = function(data)
			return data ~= nil and type(data) == 'string'
		end,
		is_character = function(data)
			return data['character'] ~= nil
		end,
		is_function = function(data)
			return data ~= nil and type(data) == 'function'
		end,
	}

	--- CS Utils 에 있는 유틸들 래핑을 위한 유틸
	cs_util = {}

	--- parameters 내부에서 해당 key의 float(number) 가져옴
	--- @param key string 파라미터 키
	--- @return number parameter에서 가져온 number(float)
	cs_util.get_float_from_dictionary = function(params, key)
		return CS.Utils.GetFloatFromDictionary(params, key)
	end

	cs_util.get_nullable_float_from_dictionary = function(params, key)
		return CS.Utils.GetNullableFloatFromDictionary(params, key)
	end

	--- parameters 내부에서 해당 key의 int(number) 가져옴
	--- @param key string 파라미터 키
	--- @return number parameter에서 가져온 number(int)
	cs_util.get_int_from_dictionary = function(params, key)
		return CS.Utils.GetIntFromDictionary(params, key)
	end

	--- parameters 내부에서 해당 key의 string 가져옴
	--- @param key string 파라미터 키
	--- @return string parameter에서 가져온 string
	cs_util.get_string_from_dictionary = function(params, key)
		return CS.Utils.GetStringFromDictionary(params, key)
	end

	--- parameters 내부에서 해당 key의 boolean 가져옴
	--- @param key string 파라미터 키
	--- @return string parameter에서 가져온 boolean
	cs_util.get_bool_from_dictionary = function(params, key)
		return CS.Utils.GetBoolFromDictionary(params, key)
	end

	--- parameters 내부에서 해당 key의 Vector3 가져옴
	--- @param key string 파라미터 키
	--- @return any parameter에서 가져온 Vector3
	cs_util.get_vector3_from_dictionary = function(params, key, default_value)
		return CS.Utils.GetVector3FromDictionary(params, key, lua_helper.get_or_default(default_value, vector(0, 0, 0)))
	end

	--- parameters 내부에서 해당 key의 number(float) list를 가져온뒤 lua table로 변환
	--- @param key string 파라미터 키
	--- @return table parameter에서 가져온 number(float) 테이블
	cs_util.get_float_table_from_dictionary = function(params, key)
		--- 파람에서 가져온 C# 리스트 결과값
		local cs_list = CS.Utils.GetFloatListFromDictionary(params, key)

		--- 리스트 결과값이 없다면 아무것도 던져주지 않음
		if cs_list == nil then return nil end

		--- number를 저장할 lua table
		local number_table = {}

		--- 순회하며 값을 insert
		for _, value in pairs(cs_list) do
			table.insert(number_table, value)
		end

		--- xlua gc가 불안해서 리스트 클리어
		cs_list:Clear()
		cs_list = nil

		return number_table
	end

	--- parameters 내부에서 해당 key의 number(int) list를 가져온뒤 lua table로 변환
	--- @param key string 파라미터 키
	--- @return table parameter에서 가져온 number(float) 테이블
	cs_util.get_int_table_from_dictionary = function(params, key)
		--- 파람에서 가져온 C# 리스트 결과값
		local cs_list = CS.Utils.GetIntListFromDictionary(params, key)

		--- 리스트 결과값이 없다면 아무것도 던져주지 않음
		if cs_list == nil then return nil end

		--- number를 저장할 lua table
		local number_table= {}

		--- 순회하며 값을 insert
		for _, value in pairs(cs_list) do
			table.insert(number_table, value)
		end

		--- xlua gc가 불안해서 리스트 클리어
		cs_list:Clear()
		cs_list = nil

		return number_table
	end

	--- parameters 내부에서 해당 key의 string list를 가져온뒤 lua table로 변환
	--- @param key string 파라미터 키
	--- @return table parameter에서 가져온 string 테이블
	cs_util.get_string_table_from_dictionary = function(params, key)
		--- 파람에서 가져온 C# 리스트 결과값
		local cs_list = CS.Utils.GetStringListFromDictionary(params, key)

		--- 리스트 결과값이 없다면 아무것도 던져주지 않음
		if cs_list == nil then return nil end

		--- string를 저장할 lua table
		local str_table = {}

		--- 순회하며 값을 insert
		for _, value in pairs(cs_list) do
			table.insert(str_table, value)
		end

		--- xlua gc가 불안해서 리스트 클리어
		cs_list:Clear()
		cs_list = nil

		return str_table
	end

	--- parameters 내부에서 해당 key의 bool list를 가져온뒤 lua table로 변환
	--- @param key string 파라미터 키
	--- @return table parameter에서 가져온 boolean 테이블
	cs_util.get_bool_table_from_dictionary = function(params, key)
		--- 파람에서 가져온 C# 리스트 결과값
		local cs_list = CS.Utils.GetBoolListFromDictionary(params, key)

		--- 리스트 결과값이 없다면 아무것도 던져주지 않음
		if cs_list == nil then return nil end

		--- boolean 값을 저장할 lua table
		local bool_table = {}

		--- 순회하며 값을 insert
		for _, value in pairs(cs_list) do
			table.insert(bool_table, value)
		end

		--- xlua gc가 불안해서 리스트 클리어
		cs_list:Clear()
		cs_list = nil

		return bool_table
	end

	--- parameters 내부에서 해당 key의 vector3 list를 가져온뒤 lua table로 변환
	--- @param key string 파라미터 키
	--- @return table parameter에서 가져온 vector3 테이블
	cs_util.get_vector3_table_from_dictionary = function(params, key)
		--- 파람에서 가져온 C# 리스트 결과값
		local cs_list = CS.Utils.GetVector3ListFromDictionary(params, key)

		--- 리스트 결과값이 없다면 아무것도 던져주지 않음
		if cs_list == nil then return nil end

		--- boolean 값을 저장할 lua table
		local vector3_table = {}

		--- 순회하며 값을 insert
		for _, value in pairs(cs_list) do
			table.insert(vector3_table, value)
		end

		--- xlua gc가 불안해서 리스트 클리어
		cs_list:Clear()
		cs_list = nil

		return vector3_table
	end

	--- parameters 내부에서 해당 key의 CS.Oak.DamageType을 가져옴
	--- @param key string 파라미터 키
	cs_util.get_damage_type_from_dictionary = function(params, key)
		return CS.Utils.GetDamageTypeFromDictionary(params, key, CS.Oak.DamageType.None)
	end

	--- parameters 내부에서 해당 key의 CS.Oak.ElementalType 가져옴
	--- @param key string 파라미터 키
	cs_util.get_elemental_type_from_dictionary = function(params, key)
		return CS.Utils.GetElementalTypeFromDictionary(params, key, CS.Oak.ElementalType.Unassigned)
	end

	--- parameters 내부에서 해당 key의 CS.Oak.Ailment를 가져옴
	--- @param key string 파라미터 키
	cs_util.get_ailment_from_dictionary = function(params, key)
		return CS.Utils.GetAilmentFromDictionary(params, key, CS.Oak.Ailment.None)
	end

	--- parameters 내부에서 해당 key의 json object를 가져옴
	--- @param key string 파라미터 키
	cs_util.get_json_object_from_dictionary = function(params, key)
		return CS.Utils.GetJsonObjectFromDictionary(params, key)
	end

	character_util = {}

	character_util.get_position = function(fo)
		return fo.Position
	end

	--- 캐릭터의 direction을 가져옴
	character_util.get_direction = function(fo)
		return fo.Direction
	end

	--- LockedDirection 까지 체크해서 현재 보고 있는 방향을 반환
	character_util.get_look_direction = function(fo)
		return CS.Oak.IFieldObjectExtensions.GetLookDirection(fo)
	end

	character_util.get_transform = function(fo)
		return fo.Transform
	end

	--- 대상의 entity id를 반환
	character_util.get_entity_id = function(character)
		return character.EntityId
	end

	--- entity id를 가진 대상을 반환
	character_util.get_character_by_entity_id = function(id)
		return CS.Oak.LuaBattleExtensions.GetCharacterByEntityId(id)
	end

	--- 대상의 죽음 여부를 반환
	character_util.is_dead = function(character)
		return character.FieldObjectStatsBehaviour.IsDead
	end

	character_util.is_attackable = function(character)
		return CS.Oak.IFieldObjectExtensions.IsAttackable(character)
	end

	--- 대상의 dps를 반환
	character_util.get_dps = function(character)
		return CS.Oak.StatCalculator.GetDps(character)
	end

	--- 대상의 Atk2Dps를 반환
	character_util.get_atk_2_dps = function(character)
		--- 첫번째 무기 슬롯
		local weapon_1 = character_util.get_weapon_1(character)
		--- 두번재 무기 슬롯
		local weapon_2 = character_util.get_weapon_2(character)

		return CS.Oak.StatCalculator.GetAtk2Dps(weapon_1, weapon_2)
	end

	--- 대상의 defense를 반환
	character_util.get_defense = function(character)
		return character.CharacterStatsBehaviour.Defense
	end

	--- 대상의 버프를 제외한 방어력을 반환
	character_util.get_equipped_defense = function(character)
		return CS.Oak.StatCalculator.GetFinalDefense(character)
	end

	--- 대상의 recovery를 반환
	character_util.get_recovery = function(character)
		return character.CharacterStatsBehaviour.Recovery
	end

	--- 대상의 Hp 비율을 반환
	character_util.get_hp_ratio = function(character)
		return character.FieldObjectStatsBehaviour.HpRatio
	end

	--- 대상의 Hp 비율을 쉴드를 포함하여 반환
	character_util.get_hp_ratio_with_shield = function(character)
		return character.FieldObjectStatsBehaviour.HpRatioWithShield
	end

	--- 대상의 Global Modifier가 적용되지 않은 체력 수치를 반환
	character_util.get_max_hp = function(character)
		return character.FieldObjectStatsBehaviour.MaxHpWoMod
	end

	--- 대상의 Global Modifier가 적용된 체력 수치를 반환
	character_util.get_max_hp_mod = function(character)
		return character.FieldObjectStatsBehaviour.MaxHP
	end

	--- 대상의 Global Modifier가 적용된 체력 수치를 반환
	character_util.get_hp = function(character)
		return character.FieldObjectStatsBehaviour.HP
	end

	--- 대상의 치명타 확률을 반환
	character_util.get_critical_chance = function(character)
		return battle_util.get_number(character.CharacterStatsBehaviour.CriticalChance)
	end

	--- 대상의 기술 피해량을 반환
	--- 기본값은 1임을 유의할 것
	character_util.get_super_skill_multiplier = function(character)
		return character.CharacterStatsBehaviour.SuperSkillDamageMultiplier
	end

	--- 대상의 ai 데미지 보정에 사용할 계수를 반환
	character_util.get_ai_atk_modifier = function(character)
		return battle_util.get_number(character.CharacterStatsBehaviour.AIAttackModifier)
	end

	--- 현재 해당 이름 / 아이디의 버프가 걸려있는지 확인
	character_util.has_active_buff = function(character, buff)
		return character.FieldObjectStatsBehaviour:IsActiveBuff(buff)
	end

	--- 현재 해당 이름 / 아이디의 버프가 걸려있는지 확인
	character_util.get_debuff_count = function(character)
		return character.FieldObjectStatsBehaviour:GetDebuffCount()
	end

	--- sender가 부여한 버프가 target에 있는지 반환
	character_util.has_sender_buff = function(target, sender, buff)
		return target.FieldObjectStatsBehaviour:IsActiveBuff(sender, buff)
	end

	character_util.has_active_buff_consider_remove = function(character, buff)
		return character.FieldObjectStatsBehaviour:IsActiveBuffConsiderRemove(buff)
	end

	character_util.has_sender_buff_consider_remove = function(target, sender, buff)
		return target.FieldObjectStatsBehaviour:IsActiveBuffConsiderRemove(sender, buff)
	end

	--- 현재 활성화된 버프 리스트 반환
	character_util.get_active_buffs = function(character)
		--- 버프 테이블
		local buff_table = {}

		--- 활성화된 버프 리스트 가져옴
		local buffs = character.FieldObjectStatsBehaviour:GetActiveBuffs()

		--- 버프 순회
		for _, buff in pairs(buffs) do
			--- 테이블에 넣어줌
			table.insert(buff_table, buff)
		end

		--- PooledList dispose
		buffs:Dispose()

		--- 버프 리스트 반환
		return buff_table
	end

	--- 현재 활성화된 버프 리스트 반환
	character_util.get_buffs = function(character, id_or_name)
		--- 버프 테이블
		local buff_table = {}

		--- 활성화된 버프 리스트 가져옴
		local buffs = character.FieldObjectStatsBehaviour:GetCertainBuffs(id_or_name)

		--- 테이블로 옮겨줌
		for _, buff in pairs(buffs) do
			--- 테이블에 넣어줌
			table.insert(buff_table, buff)
		end

		--- PooledList dispose
		buffs:Dispose()

		--- 버프 리스트 반환
		return buff_table
	end

	--- 실드 버프가 부여되있는지 체크하는 유틸
	character_util.has_shield_buff = function(character)
		--- 활성화된 버프를 가져옴
		local buff_table = character_util.get_active_buffs(character)
		--- 버프 테이블 순회
		for _, buff in ipairs(buff_table) do
			--- 실드 버프가 활성화된 경우
			if lua_helper.type_compare(buff, CS.Oak.ShieldBuff) then
				return true
			end
		end

		return false
	end

	--- 대상의 무기를 반환 (검방 이라면 검 기준)
	character_util.get_weapon = function(character)
		--- 첫번째 무기를 가져옴
		local weapon = character_util.get_weapon_1(character)

		--- 웨폰이 없다면
		if weapon == nil then
			--- 두번째 무기를 가져옴
			weapon = character_util.get_weapon_2(character)
		end

		return weapon
	end

	--- 대상의 weapon 1 을 가져옴
	character_util.get_weapon_1 = function(character)
		return character.Weapon1
	end

	--- 대상의 weapon 2 를 가져옴
	character_util.get_weapon_2 = function(character)
		return character.Weapon2
	end

	--- 대상이 무기 코스튬을 장착하고 있는지 반환
	character_util.is_using_equip_costume = function(character, weapon)
		--- 체크할 무기가 없다면 생략함
		if not weapon then return false end
		--- 캐릭터 인포
		local character_info = character.CharacterInfo
		--- 캐릭터 인포가 없으면 생략함
		if not character_info then return false end

		--- 무기의 유형
		local weapon_type = weapon.WeaponSpec.WeaponTypeSpec.WeaponType
		--- 무기 코스튬 목록에 등록되있는지 반환
		return character_info.EquipCostumes:ContainsKey(weapon_type)
	end

	--- 프로젝타일 등을 쏜 반동 애니메이션 타입 1. 캐릭터가 크게 뒤로 젖혀진다.
	character_util.recoil_type_1 = function(
		character, shoot_dir, deviate_dist, jump_height, duration, angle
	)
		deviate_dist = lua_helper.get_or_default(deviate_dist, 0.2)
		jump_height = lua_helper.get_or_default(jump_height, 0.2)
		duration = lua_helper.get_or_default(duration, 0.3)
		angle = lua_helper.get_or_default(angle, 8)

		CS.Oak.CharacterExtensions.RecoilType1(character, shoot_dir, deviate_dist, jump_height, duration, angle)
	end

	--- 포지션 스프링
	character_util.deviate_local = function(
		fo, deviation, duration, clear_duration
	)
		spine_util.get_spine_controller(fo):DeviateLocal(deviation, duration, clear_duration)
	end

	--- RecoilType1에서 사용한 spine 내부 연출을 모두 취소
	character_util.cancel_recoil_type_1 = function(character)
		CS.Oak.CharacterExtensions.CancelRecoilType1(character)
	end

	--- 대상 캐릭터에게 알파 페이드를 먹힘
	character_util.spine_set_alpha_fade = function(fo, alpha, duration)
		spine_util.get_spine_controller(fo):SetAlphaFade(alpha, duration)
	end

	--- 대상 캐릭터를 진동 시킴
	character_util.shake = function(fo, magnitude, duration)
		spine_util.get_spine_controller(fo):Shake(magnitude, duration)
	end

	--- 대상 캐릭터를 진동을 멈춤
	character_util.cancel_shake = function(fo)
		spine_util.get_spine_controller(fo):CancelShake()
	end

	character_util.pulse_fade_color = function(
		fo, color, alpha, frequency, duration, anchor
	)
		spine_util.get_spine_controller(fo):PulseFadeColor(
			color, alpha, frequency, duration, lua_helper.get_or_default(anchor, 0.5)
		)
	end

	character_util.set_position = function(fo, position)
		fo.Position = position
	end

	character_util.set_locked_dir = function(fo, direction_str)
		if fo == nil then return end
		if type_util.is_string(fo) then
			fo = get_character(fo)

			if fo == nil then return end
		end

		if direction_str == 'left' then
			fo.LockedDirection = CS.Oak.Direction.Left
		elseif direction_str == 'right' then
			fo.LockedDirection = CS.Oak.Direction.Right
		elseif direction_str == 'up' then
			fo.LockedDirection = CS.Oak.Direction.Up
		elseif direction_str == 'down' then
			fo.LockedDirection = CS.Oak.Direction.Down
		elseif direction_str == 'none' then
			fo.LockedDirection = CS.Oak.Direction.None
		end
	end

	character_util.set_direction = function(fo, direction_str)
		if fo == nil then return end
		if type_util.is_string(fo) then
			fo = get_character(fo)

			if fo == nil then return end
		end

		if type_util.is_string(direction_str) then
			if direction_str == 'left' then
				fo.Direction = CS.Oak.Direction.Left
			elseif direction_str == 'right' then
				fo.Direction = CS.Oak.Direction.Right
			elseif direction_str == 'up' then
				fo.Direction = CS.Oak.Direction.Up
			elseif direction_str == 'down' then
				fo.Direction = CS.Oak.Direction.Down
			elseif direction_str == 'none' then
				fo.LockedDirection = CS.Oak.Direction.None
			end
		else
			fo.Direction = direction_str
		end
	end

	character_util.set_active_state = function(character, active_str)
		if character == nil then return end
		if active_str == 'enabled' then
			character.ActiveState = CS.Oak.ActiveState.Enabled
		elseif active_str == 'disabled' then
			character.ActiveState = CS.Oak.ActiveState.Disabled
		elseif active_str == 'visible' then
			character.ActiveState = CS.Oak.ActiveState.Visible
		elseif active_str == 'in_field' then
			character.ActiveState = CS.Oak.ActiveState.InField
		end
	end

	--- 장착한 무기를 감추거나 다시 보이게 한다.
	--- 보이는지 여부만 바꾸는 연출용. 실제로는 무기를 착용하고 있으며 모든 효과가 적용되고 있다
	--- @param hide boolean 숨길 것인가?
	character_util.hide_weapon = function(character, hide, key)
		character:HideWeapon(hide, key)
	end

	character_util.jump = function(fo, height, duration, aerial_duration, allow_add)
		fo.SpineController:Jump(height, duration, aerial_duration or 0, allow_add or false)
	end

	character_util.cancel_jump = function(fo)
		fo.SpineController:CancelJump()
	end

	character_util.is_targetable = function(fo)
		local damaged_behaviour = fo.DamagedBehaviour

		return (lua_helper.type_compare(damaged_behaviour, CS.Oak.NullDamagedBehaviour) or
			lua_helper.type_compare(damaged_behaviour, CS.Oak.CoopDeadCharacterDamagedBehaviour) or
			lua_helper.type_compare(damaged_behaviour, CS.Oak.NoneAttackableDamagedBehaviour) or
			lua_helper.type_compare(damaged_behaviour, CS.Oak.BossHelicopterDamagedBehaviour) or
			lua_helper.type_compare(damaged_behaviour, CS.Oak.MonsterIgnoreDamagedBehaviour)) == false
	end

	character_util.move_to = function(fo, position, duration, speed, auto_dir, auto_anim, play_sfx, use_unscaledtime)
		return coroutine_manager:StartCoroutine(stage.StageGameObject,
				CS.Oak.IFieldObjectExtensions.MoveTo(fo, position, duration, speed, auto_dir, auto_anim, play_sfx))
	end

	--- 해당 캐릭터의 역할 유형을 가져옴
	--- @param character any 역할 유형 가져올 캐릭터
	character_util.get_coop_class = function(character)
		if character.CharacterStatsBehaviour == nil then
			return CS.Oak.CoopClass.None
		end

		return character.CharacterStatsBehaviour.CharacterSpec.CoopClass
	end

	--- 해당 캐릭터의 협전대 역할 유형을 가져옴
	--- @param character any 역할 유형 가져올 캐릭터
	character_util.get_coop_expedition_class = function(character)
		if character.CharacterStatsBehaviour == nil then
			return CS.Oak.CoopExpeditionClass.None
		end

		return character.CharacterStatsBehaviour.CharacterSpec.CoopExpeditionClass
	end

	--- 해당 캐릭터의 속성을 가져옴
	--- @param character any 속성값 가져올 캐릭터
	character_util.get_elemental_type = function(character)
		if character.CharacterStatsBehaviour == nil then
			return CS.Oak.ElementalType.Unassigned
		end

		return character.CharacterStatsBehaviour.CharacterSpec.ElementalType
	end

	character_util.clear_holdup_state = function(holder, held)
		if held.Holdable ~= nil then
			held.Holdable:GetThrownBy(holder)
		end

		message_system:SendSync(held, CS.Oak.GetThrownEndEvent.Instance)
		message_system:SendSync(holder, CS.Oak.ReleaseHoldingObjectEvent.Create(holder))
	end

	character_util.set_anim = function(fo, args)
		if fo == nil or args == nil or args.name == nil then
			return
		end

		local anim_name = args.name
		local priority = lua_helper.get_value(args, "priority", CS.Oak.AnimationPriorities.Custom)
		local loop = lua_helper.get_value(args, "loop", true)
		local upper = lua_helper.get_value(args, "upper", false)
		local scale = lua_helper.get_value(args, "scale", 1)
		local remove_after = lua_helper.get_value(args, "remove_after", -1)
		local mix_duration = lua_helper.get_value(args, "mix_duration", nil)
		local sfx_name = lua_helper.get_value(args, "sfx_name", nil)
		local sfx_key = lua_helper.get_value(args, "sfx_key", nil)
		local next_anim = lua_helper.get_value(args, "next_anim", nil)

		-- sfx 콜백 추가 루틴
		local sfx_handler

		if type_util.is_string(sfx_name) and not string_helper.is_nil_or_empty(sfx_name) then
			sfx_handler = CS.Oak.LuaScriptOperationHelper.KeyframeSoundPlayDelegate(fo, sfx_key, sfx_name)
		elseif type_util.is_function(sfx_name) then
			sfx_handler = sfx_name
		end

		if upper == true then
			fo:SetUpperAnimation(
					CS.Oak.AnimationRequest(
							anim_name,
							priority,
							loop,
							scale,
							remove_after,
							mix_duration,
							sfx_handler,
							next_anim
					)
			)
		else
			fo:SetAnimation(
					CS.Oak.AnimationRequest(
							anim_name,
							priority,
							loop,
							scale,
							remove_after,
							mix_duration,
							sfx_handler,
							next_anim
					)
			)
		end
	end

	character_util.set_anim_with_request = function(requester, fo, animation_info, key)
		if animation_info and animation_info[key] then
			fo:SetAnimation(requester, animation_info[key])
		end
	end


	character_util.set_emotion_with_request = function(requester, fo, emotion_info, key)
		if emotion_info and emotion_info[key] then
			fo:SetEmotion(requester, emotion_info[key])
		end
	end

	character_util.remove_anim = function(fo, upper)
		if fo == nil then return end
		if upper ~= nil and upper == true then
			fo:RemoveUpperAnimation()
		else
			fo:RemoveAnimation()
		end
	end

	weapon_util = {}

	--- 해당 무기의 속성을 가져옴
	--- @param weapon any 해당 무기
	weapon_util.get_elemental_type = function(weapon)
		if weapon then
			return CS.Oak.WeaponExtensions.GetElementalType(weapon)
		end

		return CS.Oak.ElementalType.None
	end

	--- 해당 무기의 발사 오프셋을 가져옴
	--- @param weapon any 해당 무기
	weapon_util.get_shoot_offset = function(weapon)
		--- 무기가 유효한지
		local valid_weapon = weapon and weapon.WeaponSpec and weapon.WeaponSpec.ShootOffset

		return valid_weapon and battle_util.get_number(weapon.WeaponSpec.ShootOffset) or nil
	end

	--- 해당 캐릭터가 착용한 무기가 전용무기이고 그 캐릭터가 전용무기의 주인인가?
	--- @return boolean 해당 캐릭터가 착용한 무기가 전용무기이고 그 캐릭터가 전용무기의 주인인가?
	weapon_util.is_exclusive_character = function(owner)
		weapon = character_util.get_weapon(owner)

		if weapon then
			return weapon.WeaponSpec:IsExclusiveCharacter(owner.CharacterStatsBehaviour.CharacterSpec.OriginId)
		end

		return false
	end

	command_util = {}

	--- 배틀액션에서 사용해야하는 트리거 커맨드 유틸 (절대로 직전 excute 시키지 말 것)
	command_util.publish_trigger_action = function(owner, cs_battle_action, info)
		local cmd = CS.Oak.TriggerBattleActionCommand.CreateWithInfo(
			owner, cs_battle_action.HandleName, info
		)
		command_util.publish_cmd(owner.Owner, cmd)
	end

	--- 배틀액션에서 사용해야하는 싱크 커맨드 유틸 (절대로 직전 excute 시키지 말 것)
	command_util.publish_sync_action = function(owner, cs_battle_action, info)
		local cmd = CS.Oak.SyncBattleActionCommand.CreateWithInfo(
			owner, cs_battle_action.HandleName, info
		)
		command_util.publish_cmd(owner.Owner, cmd)
	end

	--- 배틀액션에서 사용해야하는 데미지 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	command_util.publish_damage = function(damage_info)
		--- 커맨드 생성
		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		--- 커맨드 생성에 결과에 따른 데미지 정보 가져옴
		--- 크레이그의 '전우 보호'가 발동할 경우에는 처리하지 않음 (DamageReplaceCommand)
		local result_info = lua_helper.type_compare(cmd, CS.Oak.DamageCommand) and cmd.DamageInfo or nil
		--- 커맨드 발행
		command_util.publish_cmd(damage_info.Owner, cmd)

		--- 커맨드에서 사용한 데미지 정보 반환
		return result_info
	end

	--- 배틀액션에서 사용해야하는 데미지 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	--- @param info_table damage_info_table damage_info_util.create_table을 통해 만들어진 데미지 정보
	command_util.publish_damage_v2 = function(info_table)
		return command_util.publish_damage(damage_info_util.convert_table_to_info(info_table))
	end

	--- 배틀액션에서 사용해야하는 힐 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	command_util.publish_heal = function(heal_info)
		--- 커맨드 생성
		local cmd = CS.Oak.HealCommand.Create(heal_info)
		--- 커맨드 생성 결과에 따른 힐 정보를 가져옴
		local result_info = cmd.HealInfo
		--- 커맨드 발행
		command_util.publish_cmd(heal_info.Owner, cmd)

		--- 커맨드에서 사용한 힐 정보 반환
		return result_info
	end

	--- 배틀액션에서 사용해야하는 어그로 추가 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	command_util.publish_aggro_add = function(subject, target, aggro, duration)
		if duration == nil then
			duration = 0
		end

		local cmd = CS.Oak.AggroAddCommand.Create(subject, target, aggro, duration)
		command_util.publish_cmd(subject.Owner, cmd)
	end

	--- 배틀액션에서 사용해야하는 마나 회복 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	command_util.publish_mana_recover = function(cmd_owner, target, amount)
		local cmd = CS.Oak.ManaRecoverCommand.Create(target, amount)
		command_util.publish_cmd(cmd_owner.Owner, cmd)
	end

	--- 배틀액션에서 사용해야하는 hp 강제 지정 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	command_util.publish_change_hp = function(owner, hp)
		local cmd = CS.Oak.ChangeHpCommand.Create(owner, hp)
		command_util.publish_cmd(owner.Owner, cmd)
	end

	--- 배틀ai에서 사용해야하는 대상 변경 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	command_util.publish_change_target = function(owner, target)
		local cmd = CS.Oak.ChangeTargetCommand.Create(owner, target)
		command_util.publish_cmd(owner.Owner, cmd)
	end

	--- 특정 트리거 옵션을 발동하기 위한 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	---@param option_trigger_table option_trigger_table
	command_util.publish_option_trigger = function(option_trigger_table)
		local owner = option_trigger_table.owner
		local cmd = option_trigger_util.convert_table_to_info(option_trigger_table)
		command_util.publish_cmd(owner.Owner, cmd)
	end

	--- 특정 트리거 옵션을 발동하기 위한 커맨드 유틸 (절대로 직접 execute 시키지 말 것)
	--- 옵션 스크립트 내 get_attack_modifier 및 get_defense_modifier
	---@param sender IFieldObject 데미지를 보내는 주체
	---@param target IFieldObject 데미지를 받는 수신자
	---@param option_trigger_table option_trigger_table
	command_util.publish_option_trigger_damage = function(sender, target, option_trigger_table)
		local owner_player = CS.Oak.LuaBattleExtensions.DecideDamageOwner(sender, target)
		local cmd = option_trigger_util.convert_table_to_info(option_trigger_table)
		command_util.publish_cmd(owner_player, cmd)
	end

	command_util.publish_cmd = function(owner, cmd)
		if cmd ~= nil then
			CS.Oak.CommandDispatcher.Publish(owner, cmd)
			cmd:Dispose()
		end
	end

	direction_util = {}

	direction_util.none = 		CS.Oak.Direction.None
	direction_util.up = 		CS.Oak.Direction.Up
	direction_util.right = 		CS.Oak.Direction.Right
	direction_util.down = 		CS.Oak.Direction.Down
	direction_util.left = 		CS.Oak.Direction.Left
	direction_util.side = 		CS.Oak.Direction.Side
	direction_util.up_down = 	CS.Oak.Direction.UpDown
	direction_util.up_right = 	CS.Oak.Direction.UpRight
	direction_util.up_left = 	CS.Oak.Direction.UpLeft
	direction_util.down_right = CS.Oak.Direction.DownRight
	direction_util.down_left = 	CS.Oak.Direction.DownLeft
	direction_util.all = 		CS.Oak.Direction.All

	direction_util.to_vector3 = function(dir)
		return CS.Oak.DirectionExtensions.ToVector3(dir)
	end

	direction_util.to_vector3_ver2 = function(dir)

		if dir == CS.Oak.Direction.Left then
			return vector_util.left
		elseif dir == CS.Oak.Direction.Right then
			return vector_util.right
		elseif dir == CS.Oak.Direction.Up then
			return vector_util.forward
		elseif dir == CS.Oak.Direction.Down then
			return vector_util.back
		end

		return vector_util.zero
	end

	direction_util.to_4way_vector3 = function(dir)
		return CS.Oak.DirectionExtensions.To4WayVector3(dir)
	end

	direction_util.to_4way_vector3_ver2 = function(dir)

		if (dir & CS.Oak.Direction.Up) ~= CS.Oak.Direction.None then
			return vector_util.forward
		elseif (dir & CS.Oak.Direction.Right) ~= CS.Oak.Direction.None then
			return vector_util.right
		elseif (dir & CS.Oak.Direction.Down) ~= CS.Oak.Direction.None then
			return vector_util.back
		elseif (dir & CS.Oak.Direction.Left) ~= CS.Oak.Direction.None then
			return vector_util.left
		end

		return vector_util.zero
	end

	direction_util.to_8way_vector3 = function(dir)
		return CS.Oak.DirectionExtensions.To8WayVector3(dir)
	end

	direction_util.get_opposite = function(dir)
		return CS.Oak.DirectionExtensions.GetOpposite(dir)
	end

	direction_util.to_side_dir = function(dir)
		return CS.Oak.DirectionExtensions.GetSideDirection(dir)
	end

	direction_util.get_cw_turn = function(dir, turn_count)
		return CS.Oak.DirectionExtensions.GetCWTurn(dir, turn_count)
	end

	direction_util.to_str = function(dir)
		if dir == CS.Oak.Direction.Left then
			return "left"
		elseif dir == CS.Oak.Direction.Right then
			return "right"
		elseif dir == CS.Oak.Direction.Up then
			return "up"
		elseif dir == CS.Oak.Direction.Down then
			return "down"
		end

		return "none"
	end

	vector_util = {}
	vector_util.to_direction = function(v)
		if v.magnitude == 0 then
			return CS.Oak.Direction.None
		end

		if math.abs(v.x) >= math.abs(v.z) then
			if v.x > 0 then
				return CS.Oak.Direction.Right
			else
				return CS.Oak.Direction.Left
			end
		else
			if v.z > 0 then
				return CS.Oak.Direction.Up
			else
				return CS.Oak.Direction.Down
			end
		end
	end

	vector_util.to_side_dir = function(v)
		if v.x < 0 then
			return CS.Oak.Direction.Left
		else
			return CS.Oak.Direction.Right
		end
	end

	vector_util.magnitude = function(v)
		return v.magnitude
	end

	vector_util.sqr_magnitude = function(v)
		return v.sqrMagnitude
	end

	vector_util.normalized = function(v)
		return v.normalized
	end

	vector_util.lerp = function(a, b, t)
		t = math.max(math.min(t, 1), 0)

		return vector(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
	end

	vector_util.rotate_xz = function(dir, radian)
		local cos = math.cos(radian)
		local sin = math.sin(radian)
		return unity_class.vector3(cos * dir.x - sin * dir.z, dir.y, sin * dir.x + cos * dir.z)
	end

	vector_util.get_0yz = function(v, x)
		x = lua_helper.get_or_default(x, 0)

		if v.z ~= nil then
			return unity_class.vector3(x, v.y, v.z)
		else
			return unity_class.vector3(x, v.x, v.y)
		end
	end

	vector_util.get_x0z = function(v, y)
		y = lua_helper.get_or_default(y, 0)

		if v.z ~= nil then
			return unity_class.vector3(v.x, y, v.z)
		else
			return unity_class.vector3(v.x, y, v.y)
		end
	end

	vector_util.get_xy0 = function(v, z)
		z = lua_helper.get_or_default(z, 0)

		if v.z ~= nil then
			return unity_class.vector3(v.x, v.y, z)
		else
			return unity_class.vector3(v.x, v.y, z)
		end
	end

	vector_util.sqr_distance = function(a, b)
		local ab = b - a
		return ab.x * ab.x + ab.y * ab.y + ab.z * ab.z
	end

	vector_util.sqr_xz_distance = function(a, b)
		local ab = b - a
		return ab.x * ab.x + ab.z * ab.z
	end

	vector_util.distance = function(a, b)
		local ab = b - a
		return math.sqrt(ab.x * ab.x + ab.y * ab.y + ab.z * ab.z)
	end

	vector_util.lerp = function(a, b, p)
		return CS.UnityEngine.Vector3.Lerp(a, b, p)
	end

	vector_util.get_xz = function(v)
		return unity_class.vector2(v.x, v.z)
	end

	vector_util.cross = function(a, b)
		return a.x * b.y - a.y * b.x
	end

	--- 해당 벡터를 4way vector로 바꿔줌
	vector_util.to_4way_vector = function(v)
		return direction_util.to_4way_vector3(vector_util.to_direction(v))
	end

	vector_util.to_4way_vector_ver2 = function(v)
		return direction_util.to_4way_vector3_ver2(vector_util.to_direction(v))
	end

	vector_util.is_almost_zero = function(v)
		return v.sqrMagnitude < constants.epsilon
	end

	vector_util.almost_close_to = function(a, b)
		return (a - b).sqrMagnitude < constants.epsilon
	end

	vector_util.dot = function(lhs, rhs)
		return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
	end

	vector_util.dot_x0z = function(lhs, rhs)
		return lhs.x * rhs.x + lhs.z * rhs.z
	end

	vector_util.project = function(dir, normal)
		local num = vector_util.dot(normal, normal)
		if num < CS.Oak.Constants.Epsilon then
			return vector(0,0,0)
		end
		local num2 = vector_util.dot(dir, normal)
		return vector(normal.x * num2 / num, normal.y * num2 / num, normal.z * num2 / num)
	end

	-- Vector3 constant 캐시
	vector_util.right = vector(1, 0, 0)
	vector_util.left = vector(-1, 0, 0)
	vector_util.up = vector(0, 1, 0)
	vector_util.down = vector(0, -1, 0)
	vector_util.forward = vector(0, 0, 1)
	vector_util.back = vector(0, 0, -1)
	vector_util.zero = vector(0, 0, 0)
	vector_util.one = vector(1, 1, 1)

	-- Vector2 constant 캐시
	vector_util.zero2 = vector(0, 0)

	float_util = require('base/float_util')

	--- Bounds 관련 유틸
	bounds_util = {}

	--- 대상의 Bounds를 가져옴
	bounds_util.get_bounds = function(fo)
		return fo.Bounds
	end

	--- 대상의 Bounds 중심을 가져옴
	bounds_util.get_center = function(fo)
		return bounds_util.get_bounds(fo).center
	end

	--- 대상의 Bounds 크기를 가져옴
	bounds_util.get_size = function(fo)
		return bounds_util.get_bounds(fo).size
	end

	bounds_util.get_closest_point = function(fo, pos)
		return bounds_util.get_bounds(fo):ClosestPoint(pos)
	end

	--- 주어진 OBB를 포함하는 AABB 구하기
	--- @param center any OBB의 중심
	--- @param size any OBB의 크기
	--- @param angle number OBB의 y축 회전 각도(Degree. (1,0,0) 방향을 0도로 함.)
	bounds_util.get_obb_bounds = function(center, size, angle)
		return CS.BoundsExtensions.GetOBBBounds(center, size, angle)
	end

	--- Oriented Bounding Box와 겹치는지 테스트
	--- @param bounds any 검사할 bounds
	--- @param center any OBB의 중심
	--- @param size any OBB의 크기
	--- @param angle number OBB의 y축 회전 각도(Degree. (1,0,0) 방향을 0도로 함.)
	bounds_util.is_intersecting_obb = function(bounds, center, size, angle)
		return CS.BoundsExtensions.IsIntersectingOBB(bounds, center, size, angle)
	end

	--- 원과 바운드 경계상에서 곂치는 좌표 위치 반환
	---@param bounds any 검사할 bounds
	---@param dir_str string 검사할 방향 스트링
	---@param circle_center any 검사할 원 위치
	---@param radius number 원 반지름
	bounds_util.circle_intersect_line = function(bounds, dir_str, circle_center, radius)

		local point_list = { }
		local p1 = nil
		local p2 = nil

		if dir_str == 'up' then
			p1 = unity_class.vector2(bounds.center.x + bounds.extents.x, bounds.center.z + bounds.extents.z)
			p2 = unity_class.vector2(bounds.center.x - bounds.extents.x, bounds.center.z + bounds.extents.z)
		elseif dir_str == 'left' then
			p1 = unity_class.vector2(bounds.center.x - bounds.extents.x, bounds.center.z + bounds.extents.z)
			p2 = unity_class.vector2(bounds.center.x - bounds.extents.x, bounds.center.z - bounds.extents.z)
		elseif dir_str == 'right' then
			p1 = unity_class.vector2(bounds.center.x + bounds.extents.x, bounds.center.z + bounds.extents.z)
			p2 = unity_class.vector2(bounds.center.x + bounds.extents.x, bounds.center.z - bounds.extents.z)
		elseif dir_str == 'down' then
			p1 = unity_class.vector2(bounds.center.x + bounds.extents.x, bounds.center.z - bounds.extents.z)
			p2 = unity_class.vector2(bounds.center.x - bounds.extents.x, bounds.center.z - bounds.extents.z)
		end

		local cx = circle_center.x
		local cy = circle_center.z

		local dx = p1.x - p2.x
		local dy = p1.y - p2.y

		local a = dx * dx + dy * dy
		local b = 2 * (dx * (p1.x - cx) + dy * (p1.y - cy))
		local c = (p1.x - cx) * (p1.x - cx) + (p1.y - cy) * (p1.y - cy) - radius * radius
		local det = b * b - 4 * a * c

		local point = unity_class.vector2.zero

		if a <= 0.000001 or det < 0 then
			-- 겹치는 점 없음.
		elseif det == 0 then
			-- 곂치는 점 한점
			local t = -b / (2 * a)
			point.x = p1.x + t * dx
			point.y = p1.y + t * dy
			if bounds.min.x <= point.x and bounds.max.x >= point.x and bounds.min.z <= point.y and bounds.max.z >= point.y then
				table.insert(point_list, point)
			end

		elseif det >= 2 then
			-- 곂치는점 두군데 계산
			local t1 = (-b - math.sqrt(det)) / (2 * a)
			local t1_x = p1.x + t1 * dx
			local t1_y = p1.y + t1 * dy
			if bounds.min.x <= t1_x and bounds.max.x >= t1_x and bounds.min.z <= t1_y and bounds.max.z >= t1_y then
				table.insert(point_list, unity_class.vector2(t1_x, t1_y))
			end
			local t2 = (-b + math.sqrt(det)) / (2 * a)
			local t2_x = p1.x + t2 * dx
			local t2_y = p1.y + t2 * dy
			if bounds.min.x <= t2_x and bounds.max.x >= t2_x and bounds.min.z <= t2_y and bounds.max.z >= t2_y then
				table.insert(point_list, unity_class.vector2(t2_x, t2_y))
			end
		end
		return point_list
	end

	bounds_util.convert_position_to_inside = function(zone_bound, owner, destination, dir, dist)
		if zone_bound:Contains(destination) then
			return destination
		else
			--- 이동할 포지션
			local target_xz = vector_util.get_x0z(destination)
			local owner_xz = vector_util.get_x0z(owner.Position)
			--- 중앙에서 이동할 포지션으로의 방향
			local center_to_target_dir = vector_util.normalized(target_xz - zone_bound.center)
			--- 바운드 외곽 위치
			local edge_pos = CS.BoundsExtensions.BoundaryFromCenter(zone_bound, center_to_target_dir)
			local inner_pos = edge_pos + dir * dist
			inner_pos.y = owner.Position.y
			return inner_pos
		end
	end

	--- 배틀액션/배틀AI 에서 주로 사용할 유틸 함수
	battle_util = {}

	--- 배틀액션 Json으로 정의된 param을 파싱해주는 편의 함수
	--- @return table,table,table,table 파리미터 기반으로 파싱된 animation, emotion, preset, sfx 정보
	battle_util.parse_action_param = function(
		cs_battle_action, params,
		animation_info, emotion_info, preset_info, sfx_info
	)
		local owner = cs_battle_action.Character

		animation_info = lua_helper.get_or_default(animation_info, {})
		emotion_info = lua_helper.get_or_default(emotion_info, {})
		preset_info = lua_helper.get_or_default(preset_info, {})
		sfx_info = lua_helper.get_or_default(sfx_info, {})

		animation_info = battle_util.try_parse_animation_info(owner, params, animation_info)

		emotion_info = battle_util.try_parse_emotion_info(owner, params, emotion_info)

		preset_info = battle_util.try_parse_preset_info(owner, params, preset_info)

		sfx_info = battle_util.try_parse_sfx_info(owner, params, sfx_info)

		return animation_info, emotion_info, preset_info, sfx_info
	end

	--- 옵션 Json으로 정의된 param을 파싱해주는 편의 함수
	--- @return table,table 파리미터 기반으로 파싱된 preset, sfx 정보
	battle_util.parse_option_param = function(owner, params, animation_info, emotion_info, preset_info, sfx_info)
		animation_info = lua_helper.get_or_default(animation_info, {})
		emotion_info = lua_helper.get_or_default(emotion_info, {})
		preset_info = lua_helper.get_or_default(preset_info, {})
		sfx_info = lua_helper.get_or_default(sfx_info, {})

		animation_info = battle_util.try_parse_animation_info(owner, params, animation_info)

		emotion_info = battle_util.try_parse_emotion_info(owner, params, emotion_info)

		preset_info = battle_util.try_parse_preset_info(owner, params, preset_info)

		sfx_info = battle_util.try_parse_sfx_info(owner, params, sfx_info)

		return animation_info, emotion_info, preset_info, sfx_info
	end

	--- 배틀액션 Json으로 정의된 param을 파싱하고, lua action에 적용함
	battle_util.parse_action_param_and_apply = function(
		lua_action, cs_battle_action, params
	)
		lua_action.animation_info, lua_action.emotion_info, lua_action.preset_info, lua_action.sfx_info =
		battle_util.parse_action_param(
			cs_battle_action, params,
			lua_action.animation_info, lua_action.emotion_info, lua_action.preset_info, lua_action.sfx_info
		)
	end

	--- 배틀액션 파라메터들 해제 편의 유틸
	--- @param ... table 해제하기 위한 파라메터들을 테이블로 받아옴
	battle_util.dispose_action_param = function(...)
		local params = { ... }

		--- 각 파라메터들 테이블로 받아온 후에 각 요소들 해제 시켜줌.
		table_util.each_pair(function(_, info)
			table_util.each_pair(function(inner_key, _)
				info[inner_key] = nil
			end, info)
		end, params)
	end

	--- 배틀액션 파라메터들 해제 편의 유틸
	--- dispose 펑션이 정의되있다면 함수를 호출한 뒤에 해제함
	--- @param ... table 해제하기 위한 파라메터들을 테이블로 받아옴
	battle_util.dispose_state_and_params = function(...)
		local params = { ... }

		--- 각 파라메터들 테이블로 받아온 후에 각 요소들 해제 시켜줌.
		table_util.each_pair(function(_, info)
			if info.dispose then
				info:dispose()
			end

			table_util.each_pair(function(inner_key, _)
				info[inner_key] = nil
			end, info)
		end, params)
	end

	--- 애니메이션 정보 파싱 시도
	battle_util.try_parse_animation_info = function(owner, params, infos)
		local has_value, value = params:TryGetValue('AnimationInfo')
		if has_value then
			infos = battle_util.parse_animation_info(owner, value, infos)
		end

		return infos
	end

	--- 이모션 정보를 파싱 시도
	battle_util.try_parse_emotion_info = function(owner, params, infos)
		local has_value, value = params:TryGetValue('EmotionInfo')

		if has_value then
			infos = battle_util.parse_animation_info(owner, value, infos)
		end

		return infos
	end

	--- 배틀액션 Json 형식의 AnimationRequest 정보를 파싱해주는 편의 유틸
	--- @return table 파리미터 기반으로 파싱된 AnimationRequest 정보
	battle_util.parse_animation_info = function(owner, param, infos)
		for _, info in pairs(param) do
			local key_name = CS.Utils.GetStringFromDictionary(info, 'Name')
			local animation_name = CS.Utils.GetStringFromDictionary(info, 'Animation')
			local loop = CS.Utils.GetBoolFromDictionary(info, 'Loop')
			local scale = CS.Utils.GetFloatFromDictionary(info, 'Scale', 1)
			local remove_after = CS.Utils.GetFloatFromDictionary(info, 'RemoveAfter', -1)
			local mix_duration = CS.Utils.GetNullableFloatFromDictionary(info, 'MixDuration')
			local next_anim = CS.Utils.GetStringFromDictionary(info, 'NextAnimation')

			local request = CS.Oak.AnimationRequest(animation_name,
				CS.Oak.AnimationPriorities.BattleAction, loop, scale, remove_after, mix_duration, nil, next_anim)

			local target_duration = CS.Utils.GetNullableFloatFromDictionary(info, 'TargetDuration')

			--- scale보다 target_duraction이 우선순위에 있음
			--- 모든 방향에 애니메이션이 존재해야함
			if target_duration then
				local animation_duration = spine_util.get_animation_duration(
					owner, animation_name
				)

				request.timescale = animation_duration / target_duration
			end

			infos[key_name] = request
		end

		return infos
	end

	--- 프리셋 정보 파싱을 시도함
	battle_util.try_parse_preset_info = function(owner, params, infos)
		local has_value, value = params:TryGetValue('PresetInfo')

		if has_value then
			infos = battle_util.parse_preset_info(value, infos)
		end

		has_value, value = override_util.get_override_info(owner, params)

		if has_value and value['PresetInfo'] then
			infos = battle_util.parse_preset_table(value['PresetInfo'], infos)
		end

		return infos
	end

	--- 배틀액션 Json 형식의 Preset 정보를 파싱해주는 편의 유틸
	--- @return table 파리미터 기반으로 파싱된 Preset 정보
	battle_util.parse_preset_info = function(param, infos)
		for _, info in pairs(param) do
			local name, preset_name

			for key, value in pairs(info) do
				if key == 'Name' then
					name = value

				elseif key == 'Preset' then
					preset_name = value

				else
					name = key
					preset_name = value
				end
			end

			local preset = unity_object_pool.GetOrCreate(preset_name)

			if preset then
				infos[name] = preset
			else
				CS.UnityEngine.Debug.LogError(string.format('[Error] BattleAction Preset Data %s is null', preset_name))
			end
		end

		return infos
	end

	battle_util.parse_preset_info_only = function(param, infos)
		for _, info in pairs(param) do
			for key, preset_name in pairs(info) do
				infos[key] = preset_name
			end
		end

		return infos
	end

	--- 배틀액션 LuaTable 형식의 Preset 정보를 파싱해주는 편의 유틸
	--- @return table 파리미터 기반으로 파싱된 Preset 정보
	battle_util.parse_preset_table = function(lua_table, infos)
		for name, preset_name in pairs(lua_table) do
			local preset = unity_object_pool.GetOrCreate(preset_name)

			if preset then
				infos[name] = preset
			else
				CS.UnityEngine.Debug.LogError(string.format('[Error] BattleAction Preset Data %s is null', preset_name))
			end
		end

		return infos
	end

	battle_util.try_parse_sfx_info = function(owner, params, infos)
		local has_value, value = params:TryGetValue('SfxInfo')

		if has_value then
			infos = battle_util.parse_sfx_info(owner, value, infos)
		end

		has_value, value = override_util.get_override_info(owner, params)

		if has_value and value['SfxInfo'] then
			infos = battle_util.parse_sfx_table(owner, value['SfxInfo'], infos)
		end

		return infos
	end

	--- 배틀액션 Json 형식의 SfxInfo 정보를 파싱해주는 편의 유틸
	--- @return table 파리미터 기반으로 파싱된 SfxInfo 정보
	battle_util.parse_sfx_info = function(owner, param, infos)
		--- 배틀액션의 오너를 기준으로한 우선순위
		local owner_priority = CS.Oak.SfxPlayerPriorityExtensions.GetPlayerType(owner)

		for _, info in pairs(param) do
			local key_name, sfx_name

			if info:ContainsKey('SfxName') then
				key_name = CS.Utils.GetStringFromDictionary(info, 'Name')
				sfx_name = CS.Utils.GetStringFromDictionary(info, 'SfxName')
			else
				if info.Keys.Count == 1 then
					for key, value in pairs(info) do
						key_name = key
						sfx_name = value
					end
				else
					CS.UnityEngine.Debug.LogError('[Error] invalid sfx data')
				end
			end

			local loop = CS.Utils.GetBoolFromDictionary(info, 'Loop')
			local fade_in_time = CS.Utils.GetNullableFloatFromDictionary(info, 'FadeInTime')
			local fade_out_time = CS.Utils.GetNullableFloatFromDictionary(info, 'FadeOutTime')
			local duration = CS.Utils.GetNullableFloatFromDictionary(info, 'Duration')
			local delay = CS.Utils.GetNullableFloatFromDictionary(info, 'Delay')
			local volume = CS.Utils.GetNullableFloatFromDictionary(info, 'Volume')
			local type_priority = CS.Oak.SfxTypePriorityExtensions.Parse(
				CS.Utils.GetStringFromDictionary(info, 'TypePriority', 'BattleAttack')
			)
			local spatial_blend = CS.Utils.GetNullableFloatFromDictionary(info, 'SpatialBlend')
			local is_skill_cut = CS.Utils.GetNullableBoolFromDictionary(info, 'SkillCut')


			--- loop = true일 때, SfxTypePriority의 최솟값을 Loop로 제한
			if loop and type_priority ~= CS.Oak.SfxTypePriority.Event then
				type_priority = CS.Oak.SfxTypePriority.Loop
			end

			local sfx_info = CS.Oak.SfxInfo()
			sfx_info.parent = owner
			sfx_info.sfxName = sfx_name
			sfx_info.loop = loop
			sfx_info.fadeInTime = fade_in_time
			sfx_info.fadeOutTime = fade_out_time
			sfx_info.duration = duration
			sfx_info.delayedTime = delay
			sfx_info.volume = volume
			sfx_info.typePriority = type_priority
			sfx_info.playerPriority = owner_priority
			sfx_info.targetChannel = is_skill_cut and CS.Oak.SfxChannelFilter.SkillCutIn or nil
			sfx_info.spatialBlend = spatial_blend


			CS.Oak.LuaBattleExtensions.PreloadSfx(sfx_name)

			infos[key_name] = sfx_info
		end

		return infos
	end

	--- 배틀액션 LuaTable 형식의 SfxInfo 정보를 파싱해주는 편의 유틸
	--- @return table 파리미터 기반으로 파싱된 SfxInfo 정보
	battle_util.parse_sfx_table = function(owner, lua_table, infos)
		--- 배틀액션의 오너를 기준으로한 우선순위
		local owner_priority = CS.Oak.SfxPlayerPriorityExtensions.GetPlayerType(owner)

		for name, sfx_name in pairs(lua_table) do
			if type_util.is_string(sfx_name) then
				if sfx_name ~= '' then
					local sfx_info = CS.Oak.SfxInfo()
					sfx_info.parent = owner
					sfx_info.sfxName = sfx_name
					sfx_info.playerPriority = owner_priority

					local override = infos[name]

					--- 오버라이드 된 sfx 데이터 인 경우 기존 데이터를 사용
					if override then
						sfx_info.typePriority = infos[name].typePriority
						sfx_info.loop = infos[name].loop
					end

					CS.Oak.LuaBattleExtensions.PreloadSfx(sfx_name)

					infos[name] = sfx_info
				else
					infos[name] = nil
				end

			elseif lua_table[name] then
				local table = lua_table[name]

				local sfx_info = CS.Oak.SfxInfo()
				sfx_info.parent = owner
				sfx_info.sfxName = table.sfx_name
				sfx_info.volume = table.volume
				sfx_info.playerPriority = owner_priority

				local override = infos[name]

				--- 오버라이드 된 sfx 데이터 인 경우 기존 데이터를 사용
				if override then
					sfx_info.typePriority = infos[name].typePriority
					sfx_info.loop = infos[name].loop
				end

				CS.Oak.LuaBattleExtensions.PreloadSfx(table.sfx_name)

				infos[name] = sfx_info
			end
		end

		return infos
	end

	--region myth parser
	--- parse_action_param + myth 리소스 파싱. 최적화 버전
	battle_util.parse_action_and_myth_param = function(cs_battle_action, params, animation_info, emotion_info, preset_info, sfx_info)
		local owner = cs_battle_action.Character

		animation_info = lua_helper.get_or_default(animation_info, {})
		emotion_info = lua_helper.get_or_default(emotion_info, {})
		preset_info = lua_helper.get_or_default(preset_info, {})
		sfx_info = lua_helper.get_or_default(sfx_info, {})

		local myth_key = myth_util.has_valid_myth_option(params, owner) and 'Myth' or nil

		animation_info = battle_util.try_parse_animation_info_v2(owner, params, animation_info, myth_key)
		emotion_info = battle_util.try_parse_emotion_info_v2(owner, params, emotion_info, myth_key)
		preset_info = battle_util.try_parse_preset_info_v2(owner, params, preset_info, myth_key)
		sfx_info = battle_util.try_parse_sfx_info_v2(owner, params, sfx_info, myth_key)

		return animation_info, emotion_info, preset_info, sfx_info
	end

	--- 애니메이션 정보 파싱 시도 엑스트키를 포함해서 한번 더시도(myth)
	battle_util.try_parse_animation_info_v2 = function(owner, params, infos, extra_key)
		local infos = battle_util.try_parse_animation_info(owner, params, infos)

		if not extra_key then return infos end

		local has_value, value = params:TryGetValue(extra_key .. 'AnimationInfo')
		if has_value then
			infos = battle_util.parse_animation_info(owner, value, infos)
		end

		return infos
	end

	--- 이모션 정보 파싱 시도 엑스트키를 포함해서 한번 더시도(myth)
	battle_util.try_parse_emotion_info_v2 = function(owner, params, infos, extra_key)
		local infos = battle_util.try_parse_emotion_info(owner, params, infos)

		if not extra_key then return infos end

		local has_value, value = params:TryGetValue(extra_key .. 'EmotionInfo')
		if has_value then
			infos = battle_util.parse_animation_info(owner, value, infos)
		end

		return infos
	end

	--- 프리셋 정보 파싱을 시도함 (myth 포함)
	battle_util.try_parse_preset_info_v2 = function(owner, params, infos, extra_key)
		-- 오버라이드 순서 5성 > 6성 > 5성 코스튬 > 6성 코스튬
		local has_value, value = params:TryGetValue('PresetInfo')

		if has_value then
			infos = battle_util.parse_preset_info_only(value, infos)
		end

		if extra_key then
			has_value, value = params:TryGetValue(extra_key .. 'PresetInfo')

			if has_value then
				infos = battle_util.parse_preset_info_only(value, infos)
			end
		end

		--- 코스튬 오버라이드
		local has_costume_value, costume_value = override_util.get_override_info(owner, params)

		if has_costume_value then
			local costume_preset_infos = costume_value['PresetInfo']
			if costume_preset_infos then
				for preset_key, override_value in pairs (costume_preset_infos) do repeat
					infos[preset_key] = override_value
				until true end
			end

			if extra_key then
				costume_preset_infos = costume_value[extra_key .. 'PresetInfo']
				if costume_preset_infos then
					for preset_key, override_value in pairs(costume_preset_infos) do repeat
						infos[preset_key] = override_value
					until true end
				end
			end
		end

		infos = battle_util.parse_preset_table(infos, infos)

		return infos
	end

	battle_util.try_parse_sfx_info_v2 = function(owner, params, infos, extra_key)
		local has_value, value = params:TryGetValue('SfxInfo')

		if has_value then
			infos = battle_util.parse_sfx_info(owner, value, infos)
		end

		if extra_key then
			has_value, value = params:TryGetValue(extra_key .. 'SfxInfo')

			if has_value then
				infos = battle_util.parse_sfx_info(owner, value, infos)
			end
		end

		has_value, value = override_util.get_override_info(owner, params)

		if has_value and value['SfxInfo'] then
			infos = value['SfxInfo'] and battle_util.parse_sfx_table(owner, value['SfxInfo'], infos) or infos
			if extra_key then
				infos = value[extra_key .. 'SfxInfo'] and battle_util.parse_sfx_table(owner, value[extra_key .. 'SfxInfo'], infos) or infos
			end
		end

		return infos
	end
	--endregion

	--- 옵션이 대상에 붙어있는지 확인하기 위한 유틸함수
	--- @param option_id number 옵션 아이디
	---	@return boolean 옵션 유무
	battle_util.has_valid_option = function(option_id, character)
		return option_id > 0 and character:HasValidOption(option_id)
	end

	--- 옵션 데이터를 가져옴
	--- @param option_id number 옵션 아이디
	---	@return boolean, any 옵션 유무, 옵션 스펙
	battle_util.parse_option_data = function(option_id, character)
		if battle_util.has_valid_option(option_id, character) then
			local option_data = game_data_service.GetData('OptionData')
			local option_param = option_data:GetSpec(option_id).Data

			return true, option_param
		end

		return false
	end

	--- 옵션에서 mythOptionId를 찾아서 값을가져온다.
	battle_util.parse_myth_option_data = function(option_param, character)
		local option_id = cs_util.get_int_from_dictionary(option_param, 'MythOptionId')

		return battle_util.parse_option_data(option_id, character)
	end

	--- 루아 슈터 생성
	battle_util.create_lua_shooter = function(lua_battle_action, owner)
		return CS.Oak.LuaIProjectileShooter(lua_battle_action, owner)
	end

	--- 배틀액션 Json으로 정의된 projectile param을 파싱해주는 편의 함수
	battle_util.parse_projectile_param = function(cs_projectile_shooter, params, shoot_helper, proj_spec, custom_key)
		shoot_helper = lua_helper.get_or_default(shoot_helper, {})
		proj_spec = lua_helper.get_or_default(proj_spec, {})

		custom_key = custom_key and custom_key or 'ProjectileInfo'

		local has_value, value = params:TryGetValue(custom_key)

		if has_value then
			for _, info in pairs(value) do
				--- get projectile name
				local name = CS.Utils.GetStringFromDictionary(info, 'Name')

				--- get move type
				local move_type = CS.Oak.Projectile.MoveType.Directional

				local value_str = CS.Utils.GetStringFromDictionary(info, 'MoveType')

				if value_str then
					move_type = CS.System.Enum.Parse(typeof(CS.Oak.Projectile.MoveType), value_str, true)
				end

				--- get pattern
				local pattern = CS.Oak.ShootPatternInfo.GetPatternInfoFromParameter(info)

				--- get shoot effect type
				local shoot_effect_type = CS.Oak.ShootHelperShootEffectType.None

				value_str = CS.Utils.GetStringFromDictionary(info, 'ShootEffectType')

				if value_str then
					shoot_effect_type = CS.System.Enum.Parse(typeof(CS.Oak.ShootHelperShootEffectType), value_str, true)
				end

				--- get offset
				local offset = CS.Utils.GetFloatFromDictionary(info, 'Offset')

				local has_data, each_helper, each_spec = battle_util.get_each_shoot_helper(
					cs_projectile_shooter, name, move_type, pattern, shoot_effect_type, offset, params, custom_key
				)

				--- 실제 올바른 데이터가 있는 경우에만 테이블에 넣어줌
				if has_data then
					table.insert(shoot_helper, each_helper)
					table.insert(proj_spec, each_spec)
				end
			end
		end

		return shoot_helper, proj_spec
	end

	--- projectile name을 기준으로 데이터를 파싱해주는 함수
	--- @param projectile_name string 발사체 이름
	--- @param shoot_offset number 발사 오프셋
	battle_util.get_each_shoot_helper = function(
		cs_projectile_shooter,
		projectile_name, move_type, pattern, effect_type, shoot_offset,
		params, custom_key
	)
		local owner = cs_projectile_shooter.Character

		if params then
			projectile_name = override_util.get_override_proj_name(owner, params, projectile_name, custom_key)
		end

		local has_data, proj_spec = battle_util.get_each_proj_spec(projectile_name)
		if not has_data then
			return false
		end

		--- set default value
		move_type = lua_helper.get_or_default(move_type, CS.Oak.Projectile.MoveType.Directional)
		pattern = lua_helper.get_or_default(pattern, CS.Oak.ShootPatternInfo())
		effect_type = lua_helper.get_or_default(effect_type, CS.Oak.ShootHelperShootEffectType.None)
		shoot_offset = lua_helper.get_or_default(shoot_offset, 0)

		local w = owner.Weapon1 or owner.Weapon2
		local weapon_type = w and w.WeaponSpec.WeaponTypeSpec.WeaponType or CS.Oak.WeaponType.Custom

		local shoot_helper = CS.Oak.ShootHelper(
			move_type, cs_projectile_shooter, proj_spec, pattern, effect_type, shoot_offset, weapon_type
		)

		return true, shoot_helper, proj_spec
	end

	--- 배틀액션 Json으로 정의된 projectile param을 파싱해주는 편의 함수
	--- battle_util.parse_projectile_param과 달리 proj_spec만 필요한 경우를 위해 사용
	battle_util.parse_projectile_param_simple = function(owner, params, proj_spec)
		proj_spec = lua_helper.get_or_default(proj_spec, {})

		local has_value, value = params:TryGetValue('ProjectileInfo')

		if has_value then
			for _, info in pairs(value) do
				--- get projectile name
				local name = CS.Utils.GetStringFromDictionary(info, 'Name')

				if params then
					name = override_util.get_override_proj_name(owner, params, name)
				end

				local has_data, each_spec = battle_util.get_each_proj_spec(name)

				--- 실제 올바른 데이터가 있는 경우에만 테이블에 넣어줌
				if has_data then
					table.insert(proj_spec, each_spec)
				end
			end
		end

		return proj_spec
	end

	--- projectile name을 기준으로 투사체 스펙을 가져옴
	--- @param projectile_name string 발사체 이름
	battle_util.get_each_proj_spec = function(projectile_name)
		--- projectile data
		local projectile_data = game_data_service.GetData('ProjectileData')

		local origin_spec = projectile_data:GetSpec(projectile_name)

		if not origin_spec then
			CS.UnityEngine.Debug.LogError(string.format('[Error] BattleAction Proj Data %s is null', projectile_name))
			return false
		end

		return true, origin_spec:Clone()
	end

	--- 배틀액션 Preset 데이터가 모두 로드 되었는지 체킹해주는 편의 유틸
	--- @return boolean Preset 데이터 로드 완료 여부 (로드 완료에는 LoadFailed 또한 포함)
	battle_util.is_loaded = function(preset_info)
		for _, preset in pairs(preset_info) do
			if not object_pool_extensions.IsLoaded(preset) then
				return false
			end
		end

		return true
	end

	--- 배틀액션 ShootHelper 가 모두 로드 되었는지 체킹해주는 편의 유틸
	--- @return boolean ShootHelper 데이터 로드 완료 여부
	battle_util.is_shoot_helper_loaded = function(shoot_helper)
		--- 테이블이라면 개별 helper를 체킹
		if type_util.is_table(shoot_helper) then
			for _, helper in pairs(shoot_helper) do
				if not helper:IsLoaded() then
					return false
				end
			end
		--- 아니라면 그것만 체킹
		else
			return shoot_helper:IsLoaded()
		end

		return true
	end

	--- 실제 메뉴얼 콤보 배틀액션을 트리거 할 수 있는지 체킹 해주는 편의 유틸
	--- @return boolean 트리거 가능 여부
	battle_util.can_trigger = function(cs_battle_action, lua_battle_action)
		local owner = cs_battle_action.Character

		if owner then
			if owner.CharacterBehaviour then
				local action_state = owner.CharacterBehaviour.CurrentActionState

				if action_state and
					not lua_helper.type_compare(action_state, CS.Oak.CharacterNoActionState) then
					return false
				end
			end

			return lua_battle_action:is_available() and
				CS.Oak.ICharacterBehaviourExtensions.CanTriggerBattleAction(owner.CharacterBehaviour)
		end

		return false
	end

	--- IPersistentBattleAction 기반 배틀액션이 실제로 available 한지 판단해주는 편의 유틸
	battle_util.persistent_is_available = function(cs_battle_action)
		return CS.Oak.IPersistentBattleActionExtensions.IsAvailableAction(cs_battle_action)
	end

	--- IStaminaBattleAction(IBattleAction) 기반 배틀 액션을 사용할 수 있는 스태미너가 있는지
	battle_util.is_there_stamina_for_action = function(cs_battle_action)
		return CS.Oak.StaminaBattleActionExtensions.IsThereStaminaForAction(cs_battle_action)
	end

	--- IRoleBattleAction 기반 배틀액션이 실제로 available 한지 판단해주는 편의 유틸
	battle_util.role_is_available = function(cs_battle_action)
		return CS.Oak.IRoleBattleActionExtensions.RoleActionIsAvailable(cs_battle_action)
	end

	--- 캐릭터 DPS 의 customModifier 를 곱한 만큼의 데미지를 주고 싶다고 할 때 사용
	--- @param custom_modifier number 밸런스 조절을 위한 해당 배틀 액션의 커스텀 계수
	--- @param num_hits number 해당 배틀액션의 최대 타격 횟수
	--- @return number 각 캐릭터의 atk2Dps 를 계산한 후 그를 numHits 로 나눈 뒤 customModifier 를 곱한 값을 리턴한다.
	battle_util.calculate_attack_modifier_from_dps = function(cs_battle_action, custom_modifier, num_hits)
		custom_modifier = lua_helper.get_or_default(custom_modifier, 1)
		num_hits = lua_helper.get_or_default(num_hits, 1)

		return CS.Oak.IBattleActionExtensions.CalculateAttackModifierFromDps(
			cs_battle_action, battle_util.get_number(custom_modifier), num_hits
		)
	end

	--- 캐릭터 atk2dps를 제외한 modifier 계산
	--- @param custom_modifier number 밸런스 조절을 위한 해당 배틀 액션의 커스텀 계수
	--- @param num_hits number 해당 배틀액션의 최대 타격 횟수
	--- @return number 캐릭터 atk2dps를 제외한 modifier 계산
	battle_util.calculate_attack_modifier = function(cs_battle_action, custom_modifier, num_hits)
		custom_modifier = lua_helper.get_or_default(custom_modifier, 1)
		num_hits = lua_helper.get_or_default(num_hits, 1)

		return CS.Oak.IBattleActionExtensions.CalculateAttackModifier(
			cs_battle_action, battle_util.get_number(custom_modifier), num_hits
		)
	end

	--- 캐릭터 Stats를 기반으로 해당 배틀액션에서 줘야할 힐의 계수를 구할때 써야 한다.
	--- @param custom_modifier number 밸런스 조절을 위한 해당 배틀 액션의 커스텀 계수
	--- @param num_hits number 해당 배틀액션의 최대 힐 횟수
	battle_util.calculate_heal_modifier_from_stats = function(cs_battle_action, custom_modifier, num_hits)
		custom_modifier = lua_helper.get_or_default(custom_modifier, 1)
		num_hits = lua_helper.get_or_default(num_hits, 1)

		return CS.Oak.IBattleActionExtensions.CalculateHealModifierFromStats(
			cs_battle_action, battle_util.get_number(custom_modifier), num_hits
		)
	end

	battle_util.is_targetable = function(searcher, target)
		return battle_util.is_hittable_target(searcher, target) and not bush_util.is_hide(target)
	end

	--- 먼 타겟을 찾아주는 편의 유틸
	--- @param range number 탐색 범위
	--- @param count number 최대 탐색 개수
	--- @return table,table 탐색한 대상 리스트, 오너 기준 대상 방향 리스트
	battle_util.get_farthest_target = function(cs_battle_action, range, count)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		local targets = {}
		local directions = {}
		local ifo_table = {}

		count = lua_helper.get_or_default(count, 1)

		--- 범위 내의 ifo
		local ifo_list = field:GetFieldObjectsInCylinder(owner.Bounds.center, range, owner.Bounds.size.y)

		--- ifo 루프
		for _, ifo in pairs(ifo_list) do
			table.insert(ifo_table, 1, ifo)
		end

		--- PooledSortedList dispose
		ifo_list:Dispose()

		--- ifo 루프
		for _, ifo in pairs(ifo_table) do
			--- 부쉬 상태 체크 / 대상이 공격 가능한 경우 체크
			if battle_util.is_targetable(owner, ifo) then
				table.insert(targets, ifo)
				table.insert(directions, battle_util.get_direction_xyz(owner, ifo))

				if #targets >= count then
					break
				end
			end
		end

		--- 대상이 없을 경우 바라보는 방향을 넣어줌
		if #targets == 0 then
			table.insert(directions, direction_util.to_vector3(character_util.get_look_direction(owner)))
		end

		return targets, directions
	end

	--- 먼 타겟을 찾아주는 편의 유틸 (table을 던지지 않도록)
	--- @param range number 탐색 범위
	--- @return any, any 탐색한 대상 리스트, 오너 기준 대상 방향 리스트
	battle_util.get_farthest_target_simple = function(cs_battle_action, range)
		local targets, directions = battle_util.get_farthest_target(cs_battle_action, range, 1)

		return targets[1], directions[1]
	end

	--- 가까운 타겟을 찾아주는 편의 유틸
	--- @param range number 탐색 범위
	--- @param count number 최대 탐색 개수
	--- @return table,table 탐색한 대상 리스트, 오너 기준 대상 방향 리스트
	battle_util.get_closest_target = function(cs_battle_action, range, count)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		local targets = {}
		local directions = {}

		count = lua_helper.get_or_default(count, 1)

		--- 범위 내의 ifo
		local ifo_list = field:GetFieldObjectsInCylinder(owner.Bounds.center, range, owner.Bounds.size.y)

		--- ifo 루프
		for _, ifo in pairs(ifo_list) do
			--- 부쉬 상태 체크 / 대상이 공격 가능한 경우 체크
			if battle_util.is_targetable(owner, ifo) then
				table.insert(targets, ifo)
				table.insert(directions, battle_util.get_direction_xyz(owner, ifo))

				if #targets >= count then
					break
				end
			end
		end

		--- PooledSortedList dispose
		ifo_list:Dispose()

		--- 대상이 없을 경우 바라보는 방향을 넣어줌
		if #targets == 0 then
			table.insert(directions, direction_util.to_vector3(character_util.get_look_direction(owner)))
		end

		return targets, directions
	end

	--- 가까운 타겟을 찾아주는 편의 유틸 (table을 던지지 않도록)
	--- @param range number 탐색 범위
	--- @return any, any 탐색한 대상 리스트, 오너 기준 대상 방향 리스트
	battle_util.get_closest_target_simple = function(cs_battle_action, range)
		local targets, directions = battle_util.get_closest_target(cs_battle_action, range, 1)

		return targets[1], directions[1]
	end

	battle_util.get_target_not_blocked = function(cs_battle_action, range)
		return CS.Oak.IBattleActionExtensions.GetUnblockedMeleeTarget(cs_battle_action, range, true)
	end

	--- 메뉴얼 조작 시에 현재 바라보는 방향과 조이패드 등의 요소를 고려하여 밀리 타겟을 찾음
	--- 타겟이 없을 경우에는 공격할 방향을 리턴
	--- @param range number 탐색 범위
	--- @return table,table 탐색한 대상, 오너 기준 대상 방향
	battle_util.get_target_for_manual_melee = function(cs_battle_action, range)
		return CS.Oak.IBattleActionExtensions.GetTargetForManualMelee(cs_battle_action, range, true)
	end

	--- 메뉴얼 조작 시에 현재 바라보는 방향과 조이패드 등의 요소를 고려하여 원거리 타겟을 찾음
	--- 타겟이 없을 경우에는 공격할 방향을 리턴
	--- @param range number 탐색 범위
	--- @param is_stationary boolean
	--- @param xz_normalize boolean xz평면을 기준으로 normalize할지 여부
	--- @param combo_action_check_hittable boolean Combo 액션일 경우 hittable을 기준으로 대상을 재설정 하는가?
	--- @return table,table 탐색한 대상, 오너 기준 대상 방향
	battle_util.get_target_for_manual_proj = function(
		cs_battle_action, range,
		is_stationary, xz_normalize, combo_action_check_hittable
	)
		xz_normalize = lua_helper.get_or_default(xz_normalize, false)
		combo_action_check_hittable = lua_helper.get_or_default(combo_action_check_hittable, false)

		return CS.Oak.IBattleActionExtensions.GetTargetForManualProjectile(
			cs_battle_action, range, is_stationary, xz_normalize, combo_action_check_hittable
		)
	end

	--- 전투 안에서 적들 중 가장 거리가 가까운 대상만 필터해서 보낸다,
	battle_util.get_closest_target_in_active_battle = function(owner)
		local target_table = battle_manager_util.get_targets_in_active_battle(owner)

		-- 대상이 없으니 그냥 바로 얼리 리턴함
		if #target_table == 0 then
			return nil, direction_util.to_vector3(character_util.get_look_direction(owner)), target_table
		end

		local closest_idx = nil
		local closest_dist = 999999

		for idx, target in pairs(target_table) do
			local target_dist = battle_util.distance_xyz(target, owner)

			if closest_dist > target_dist then
				closest_idx = idx
				closest_dist = target_dist
			end
		end

		-- 그럴일 없겠지만 대상을 못찾으면 얼리 리턴
		if not closest_idx then
			return nil, direction_util.to_vector3(character_util.get_look_direction(owner)), target_table
		end

		--- 대상 순서 바꾸기
		local closest_target = target_table[closest_idx]
		-- 순서를 바꿔서 반환할 필요가 있다면 처리
		if closest_idx ~= 1 then
			table.remove(target_table, closest_idx)
			table.insert(target_table, 1, closest_target)
		end

		-- 대상을 향하는 방향
		local dir_vector = battle_util.get_direction_toward(owner, closest_target)
		return closest_target, dir_vector, target_table
	end

	--- 콤보 타겟을 찾아주는 편의 유틸
	--- @param range number 탐색 범위
	--- @return any,any 탐색한 대상, 오너 기준 대상 방향
	battle_util.get_combo_target = function(cs_battle_action, range)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		local target
		local direction

		for _, action in pairs(owner.CharacterBehaviour.BattleActions) do
			--- 활성화된 Normal 타입 액션을 찾음
			if action.IsActive and action.Type == CS.Oak.BattleActionType.Normal then
				--- ICombo 타겟을 가져옴
				local has_value, combo_target

				if action.ComboTarget then
					has_value, combo_target = action.ComboTarget:TryGetTarget()
				end

				if has_value and not bush_util.is_hide(combo_target) and
					battle_util.distance_xz(combo_target, owner) <= range then
					--- 콤보 타겟 할당
					target = combo_target
					--- 콤보 타겟 방향 할당
					direction = battle_util.get_direction_xyz(owner, target)
				else
					target, direction = battle_util.get_target_for_manual_melee(cs_battle_action, range)
				end
			end
		end

		--- 콤보 타겟 탐색을 실패 했다면 전방위 탐색을 요청
		if target == nil then
			--- 전방위 탐색 결과
			target, direction = battle_util.get_closest_target_simple(cs_battle_action, range)
		end

		return target, direction
	end

	--- 파티원 중 방어력이 가장 높은 대상을 리턴 (장비 포함, 버프 제외)
	--- @param cs_battle_action any C# 배틀액션
	--- @param range number 탐색 범위
	--- @param closest_target boolean true면 가장 가까운 대상 우선
	--- @param include_self boolean 자신을 포함하는지 여부
	battle_util.get_highest_equipped_defense_target = function(cs_battle_action, range, closest_target, include_self)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		range = lua_helper.get_or_default(range, CS.System.Single.MaxValue)
		closest_target = lua_helper.get_or_default(closest_target, true)
		include_self = lua_helper.get_or_default(include_self, false)

		local target
		local highest_defense = CS.System.Single.MinValue
		local distance = closest_target and CS.System.Single.MaxValue or CS.System.Single.MinValue
		local direction = direction_util.to_4way_vector3(character_util.get_look_direction(owner))

		local party = party_util.get_party_for(owner)

		local members = party:GetStageMembers()

		if members then
			for _, member in pairs(members) do repeat
				--- 나는 무시라면 스킵
				if include_self == false and lua_helper.reference_equals(owner, member) then break end

				local target_dist = battle_util.distance_xz(member, owner)
				--- 범위 밖 대상은 무시
				if target_dist > range then break end

				--- 버프 제외 장비포함 방어력 비교
				local target_defense = character_util.get_equipped_defense(member)

				--- 방어력이 더 높을 경우만 갱신(같으면 파티원 순)
				if highest_defense > target_defense then break end

				--- 방어력이 동률이면 거리순으로 계산 (여기서도 동률이면 파티순, 여기까지는 현재 의미 없어서 미고려)
				if highest_defense == target_defense then
					if closest_target then
						if target_dist >= distance then break end
					else
						if target_dist <= distance then break end
					end
				end

				highest_defense = target_defense
				distance = target_dist
				target = member

			until true end
		end

		members:Dispose()

		--- 타겟이 있을 때만 방향 갱신
		if target then
			direction = battle_util.get_direction_toward(owner, target)
		end

		return target, direction
	end

	--- FIXME: 함수 밖으로 빼서 중복 코드 제거 하고, 높낮이 비교 쪽을 빼서 적용
	--- 파티원 중 방어력이 가장 낮은 대상을 리턴 (장비 포함, 버프 제외)
	--- @param cs_battle_action any C# 배틀액션
	--- @param range number 탐색 범위
	--- @param closest_target boolean true면 가장 가까운 대상 우선
	--- @param include_self boolean 자신을 포함하는지 여부
	battle_util.get_lowest_equipped_defense_target = function(cs_battle_action, range, closest_target, include_self)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		range = lua_helper.get_or_default(range, CS.System.Single.MaxValue)
		closest_target = lua_helper.get_or_default(closest_target, true)
		include_self = lua_helper.get_or_default(include_self, false)

		local target
		local lowest_defense = CS.System.Single.MaxValue
		local distance = closest_target and CS.System.Single.MaxValue or CS.System.Single.MinValue
		local direction = direction_util.to_4way_vector3(character_util.get_look_direction(owner))

		local party = party_util.get_party_for(owner)

		local members = party:GetStageMembers()

		if members then
			for _, member in pairs(members) do repeat
				--- 나는 무시라면 스킵
				if include_self == false and lua_helper.reference_equals(owner, member) then break end

				local target_dist = battle_util.distance_xz(member, owner)
				--- 범위 밖 대상은 무시
				if target_dist > range then break end

				--- 버프 제외 장비포함 방어력 비교
				local target_defense = character_util.get_equipped_defense(member)

				--- 방어력이 더 낮은 경우만 갱신(같으면 파티원 순)
				if lowest_defense < target_defense then break end

				--- 방어력이 동률이면 거리순으로 계산 (여기서도 동률이면 파티순, 여기까지는 현재 의미 없어서 미고려)
				if lowest_defense == target_defense then
					if closest_target then
						if target_dist >= distance then break end
					else
						if target_dist <= distance then break end
					end
				end

				lowest_defense = target_defense
				distance = target_dist
				target = member

			until true end
		end

		members:Dispose()

		--- 타겟이 있을 때만 방향 갱신
		if target then
			direction = battle_util.get_direction_toward(owner, target)
		end

		return target, direction
	end

	--- 파티원 중 체력 비율이 가장 낮은 대상을 리턴
	--- @param cs_battle_action any C# 배틀액션
	--- @param range number 탐색 범위
	--- @param include_self boolean 자신을 포함하는지 여부
	battle_util.get_lowest_hp_target = function(cs_battle_action, range, include_self, ignore_full_hp)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		range = lua_helper.get_or_default(range, CS.System.Single.MaxValue)
		include_self = lua_helper.get_or_default(include_self, false)
		ignore_full_hp = lua_helper.get_or_default(ignore_full_hp, true)

		local hp_ratio = ignore_full_hp and 1.0 or CS.System.Single.MaxValue
		local target
		local direction = direction_util.to_4way_vector3(character_util.get_look_direction(owner))

		local party = party_util.get_party_for(owner)

		local members = party:GetStageMembers()

		if members then
			for _, member in pairs(members) do
				--- 현재 대상이 힐을 받을 수 있는가
				if (include_self == true or not lua_helper.reference_equals(owner, member)) and
					battle_util.can_apply_heal(owner, member, ignore_full_hp) and
					battle_util.distance_xz(member, owner) <= range then
					local member_hp_ratio = character_util.get_hp_ratio(member)

					--- hp가 제일 적은 대상을 탐색
					if hp_ratio > member_hp_ratio then
						hp_ratio = member_hp_ratio
						target = member
						direction = battle_util.get_direction_toward(owner, member)
					end
				end
			end
		end

		members:Dispose()

		return target, direction
	end

	--- 파티원 중 체력 비율이 가장 낮은 대상들을 리턴
	--- @param cs_battle_action any C# 배틀액션
	--- @param range number 탐색 범위
	--- @param include_self boolean 자신을 포함하는지 여부
	battle_util.get_lowest_hp_targets = function(cs_battle_action, range, include_self, ignore_full_hp)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		range = lua_helper.get_or_default(range, CS.System.Single.MaxValue)
		include_self = lua_helper.get_or_default(include_self, false)
		ignore_full_hp = lua_helper.get_or_default(ignore_full_hp, true)

		local hp_ratio = ignore_full_hp and 1.0 or CS.System.Single.MaxValue
		local targets = {}
		local direction = direction_util.to_4way_vector3(character_util.get_look_direction(owner))

		local party = party_util.get_party_for(owner)

		local members = party:GetStageMembers()

		--- 멤버들이 있다면
		if members then
			--- 멤버들을 거리순과 힐 받을 수 있는 놈인지를 필터링
			for _, member in pairs(members) do
				--- 현재 대상이 힐을 받을 수 있는가
				if (include_self == true or not lua_helper.reference_equals(owner, member)) and
					battle_util.can_apply_heal(owner, member) and
					battle_util.distance_xz(member, owner) <= range then
					table.insert(targets, member)

					local member_hp_ratio = character_util.get_hp_ratio(member)

					--- hp가 제일 적은 대상을 탐색
					if hp_ratio > member_hp_ratio then
						hp_ratio = member_hp_ratio
						direction = battle_util.get_direction_toward(owner, member)
					end
				end
			end
		end

		members:Dispose()

		if #targets > 0 then
			--- 체력 적은순으로 정렬
			table.sort(targets,
				--- 체력 낮은 순으로 정렬
				function(a, b)
					return character_util.get_hp_ratio(a) < character_util.get_hp_ratio(b)
				end
			)

			--- 가장 피가 적은 친구 방향으로 바라본다
			direction = battle_util.get_direction_toward(owner, targets[1])
		end

		return targets, direction
	end

	--- 파티원 중 체력+쉴드 비율이 가장 낮은 대상을 리턴
	--- @param cs_battle_action any C# 배틀액션
	--- @param range number 탐색 범위
	--- @param include_self boolean 자신을 포함하는지 여
	--- @param ignore_full_hp boolean 체력이 가득 찬 대상도 포함시킬지 여부
	battle_util.get_lowest_hp_target_with_shield = function(cs_battle_action, range, include_self, ignore_full_hp)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character

		range = lua_helper.get_or_default(range, CS.System.Single.MaxValue)
		include_self = lua_helper.get_or_default(include_self, false)
		ignore_full_hp = lua_helper.get_or_default(ignore_full_hp, true)

		local hp_ratio = ignore_full_hp and 1.0 or CS.System.Single.MaxValue
		local target
		local direction = direction_util.to_4way_vector3(character_util.get_look_direction(owner))

		local party = party_util.get_party_for(owner)

		local members = party:GetStageMembers()

		if members then
			for _, member in pairs(members) do
				--- 현재 대상이 힐을 받을 수 있는가
				if (include_self == true or not lua_helper.reference_equals(owner, member)) and
					battle_util.can_apply_heal(owner, member, ignore_full_hp) and
					battle_util.distance_xz(member, owner) <= range then
					local member_hp_ratio = character_util.get_hp_ratio_with_shield(member)

					--- hp가 제일 적은 대상을 탐색
					if hp_ratio > member_hp_ratio then
						hp_ratio = member_hp_ratio
						target = member
						direction = battle_util.get_direction_toward(owner, member)
					end
				end
			end
		end

		members:Dispose()

		return target, direction
	end

	--- 파티원 중 체력 + 쉴드 비율이 가장 낮은 대상들을 리턴
	--- @param cs_battle_action any C# 배틀액션
	--- @param range number 탐색 범위
	--- @param include_self boolean 자신을 포함하는지 여부
	--- @param ignore_full_hp boolean 체력이 가득 찬 대상도 포함시킬지 여부
	battle_util.get_lowest_hp_targets_with_shield = function(cs_battle_action, range, include_self, ignore_full_hp)
		--- 배틀액션의 오너
		local owner = cs_battle_action.Character
		range = lua_helper.get_or_default(range, CS.System.Single.MaxValue)
		include_self = lua_helper.get_or_default(include_self, false)
		ignore_full_hp = lua_helper.get_or_default(ignore_full_hp, true)

		local hp_ratio = ignore_full_hp and 1.0 or CS.System.Single.MaxValue
		local targets = {}
		local direction = direction_util.to_4way_vector3(character_util.get_look_direction(owner))

		local party = party_util.get_party_for(owner)

		local members = party:GetStageMembers()

		--- 멤버들이 있다면
		if members then
			--- 멤버들을 거리순과 힐 받을 수 있는 놈인지를 필터링
			for _, member in pairs(members) do
				--- 현재 대상이 힐을 받을 수 있는가
				if (include_self == true or not lua_helper.reference_equals(owner, member)) and
					battle_util.can_apply_heal(owner, member, ignore_full_hp) and
					battle_util.distance_xz(member, owner) <= range then
					table.insert(targets, member)

					local member_hp_ratio = character_util.get_hp_ratio_with_shield(member)

					--- hp가 제일 적은 대상을 탐색
					if hp_ratio > member_hp_ratio then
						hp_ratio = member_hp_ratio
						direction = battle_util.get_direction_toward(owner, member)
					end
				end
			end
		end

		members:Dispose()

		if #targets > 0 then
			--- 체력 적은순으로 정렬
			table.sort(targets,
			--- 체력 낮은 순으로 정렬
				function(a, b)
					return character_util.get_hp_ratio(a) < character_util.get_hp_ratio(b)
				end
			)

			--- 가장 피가 적은 친구 방향으로 바라본다
			direction = battle_util.get_direction_toward(owner, targets[1])
		end

		return targets, direction
	end

	--- fo가 target이 보이는지 체크( 부쉬 )
	battle_util.can_see_target = function(fo, target)
		return CS.Oak.IFieldObjectExtensions.CanSeeTarget(fo, target)
	end

	--- 대상을 타격 가능한지 검사
	--- @return boolean 타격 가능한지 여부
	battle_util.is_hittable_target = function(attacker, target)
		if is_unity_null(target) then
			return false
		end

		if character_util.is_dead(target) then
			return false
		end

		if lua_helper.reference_equals(attacker, target) then
			return false
		end

		return CS.Oak.EntityGroupsExtensions.IsHittableTo(attacker.EntityGroup, target.EntityGroup)
	end

	--- 대상을 타격 가능한지 검사
	--- @return boolean 타격 가능한지 여부
	battle_util.is_hittable_coop_expedition_target = function(attacker, target)
		if is_unity_null(target) then
			return false
		end

		if character_util.is_dead(target) then
			return false
		end

		if lua_helper.reference_equals(attacker, target) then
			return false
		end

		if not CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(target, typeof(CS.Oak.ICharacter)) then
			return false
		end

		return CS.Oak.EntityGroupsExtensions.IsHittableTo(attacker.EntityGroup, target.EntityGroup)
	end

	--- 대상이 우호 마스크 인지 검사
	--- @return boolean 우호 마스크 여부
	battle_util.is_friendly_target = function(character, target)
		return CS.Oak.EntityGroupsExtensions.IsFriendlyTo(character.EntityGroup, target.EntityGroup)
	end

	--- 대상에게 힐을 할 수 있는지 검사
	--- @return boolean 회복 가능한지 여부
	battle_util.can_apply_heal = function(healer, target, ignore_full_hp)
		ignore_full_hp = lua_helper.get_or_default(ignore_full_hp, true)

		if is_unity_null(target) then
			return false
		end

		if CS.Oak.EntityGroupsExtensions.IsHittableTo(healer.EntityGroup, target.EntityGroup) then
			return false
		end

		if character_util.is_dead(target) then
			return false
		end

		if not character_util.is_targetable(target) then
			return false
		end

		if ignore_full_hp and float_util.almost_close_to(character_util.get_hp_ratio(target), 1) then
			return false
		end

		return CS.Oak.EntityGroupsExtensions.IsFriendlyTo(healer.EntityGroup, target.EntityGroup)
	end

	--- 대상에게 디버프 제거를 할 수 있는지 검사
	--- @return boolean 버프 제거 가능한지 여부
	battle_util.can_apply_cure = function(healer, target, ignore_full_hp)
		ignore_full_hp = lua_helper.get_or_default(ignore_full_hp, true)

		if is_unity_null(target) then
			return false
		end

		if CS.Oak.EntityGroupsExtensions.IsHittableTo(healer.EntityGroup, target.EntityGroup) then
			return false
		end

		if character_util.is_dead(target) then
			return false
		end

		if not character_util.is_targetable(target) then
			return false
		end

		return CS.Oak.EntityGroupsExtensions.IsFriendlyTo(healer.EntityGroup, target.EntityGroup)
	end

	--- 대상에게 충돌을 할 수 있는지 검사
	--- @return boolean 충돌 가능한지 여부
	battle_util.has_collision_with = function(attacker, target, ignore_ethereal)
		ignore_ethereal = lua_helper.get_or_default(ignore_ethereal, false)

		if is_unity_null(target) then
			return false
		end

		if character_util.is_dead(target) then
			return false
		end

		if lua_helper.reference_equals(attacker, target) then
			return false
		end

		if ignore_ethereal and CS.Oak.ICrashBehaviourExtensions.IsEthereal(target.CrashBehaviour) then
			return false
		end

		return CS.Oak.EntityGroupsExtensions.HasCollisionWith(attacker.EntityGroup, target.EntityGroup)
	end

	battle_util.distance_xyz = function (actor, target)
		return vector_util.distance(character_util.get_position(target), character_util.get_position(actor))
	end

	battle_util.sqr_distance_xyz = function (actor, target)
		return vector_util.sqr_distance(character_util.get_position(target), character_util.get_position(actor))
	end

	--- 두 캐릭터 간의 거리 계산 (y축을 무시함)
	--- @return number y축을 무시한 거리
	battle_util.distance_xz = function (actor, target)
		return vector_util.get_x0z(target.Position - actor.Position).magnitude
	end

	--- 두 바운딩 박스 사이의 거리 계산 (y축을 무시함)
	--- @return number y축을 무시한 바운딩 박스 사이 거리
	battle_util.distance_between_xz = function (actor, target)
		return CS.BoundsExtensions.GetXZDistanceBetween(actor.Bounds, target.Bounds)
	end

	--- 두 캐릭터 간의 방향 벡터 계산 (y축을 무시함)
	battle_util.get_direction_toward = function (actor, target)
		return vector_util.get_x0z(target.Position - actor.Position).normalized
	end

	--- 두 캐릭터 간의 방향 벡터 계산 (y축을 고려함)
	battle_util.get_direction_xyz = function(actor, target)
		return (target.Position - actor.Position).normalized
	end

	--- 구형 범위 내의 오브젝트 반환
	--- 반드시 'Dispose'할 것 (SortedList 아님)
	--- @param radius number 구의 반지름
	battle_util.get_field_objects_in_radius = function(position, radius)
		return field:GetFieldObjectsInRadius(position, battle_util.get_number(radius))
	end

	--- 원기둥 범위 내의 오브젝트 반환
	--- 반드시 'Dispose'할 것
	--- @param radius number 원기둥의 반지름
	--- @param height number 원기둥의 높이
	battle_util.get_field_objects_in_cylinder = function(position, radius, height)
		return field:GetFieldObjectsInCylinder(position, battle_util.get_number(radius), battle_util.get_number(height))
	end

	--- Bounds에서 시작하여 move만큼 이동하는 영역과 겹치는 ifo 구하기
	--- 반드시 'Dispose'할 것
	--- @param bounds any 시작할 위치의 바운딩 박스
	--- @param move any 이동 벡터(방향과 크기)
	battle_util.get_field_objects_collided_by = function(bounds, move)
		return field:GetFieldObjectsCollidedBy(bounds, move)
	end

	--- number type이 아닌 경우에 사용
	--- @return number 실제 수치
	battle_util.get_number = function(num)
		if type_util.is_number(num) then
			return num
		end

		return num:GetDecrypted()
	end

	--- 타겟을 기준으로 배틀액션의 Owner의 방향고정을 갱신 해주고, 타겟과 타겟 방향 또한 갱신
	battle_util.set_locked_target = function(cs_battle_action, target, dir_vector)
		if is_unity_null(target) or character_util.is_dead(target) then
			battle_util.set_locked_dir(cs_battle_action, vector_util.to_direction(dir_vector))

			return nil, dir_vector
		end

		dir_vector = battle_util.get_direction_toward(cs_battle_action.Character, target)

		--- vector의 크기 0일때는 바라보던 방향을 사용
		if float_util.is_almost_zero(dir_vector.magnitude) then
			dir_vector = direction_util.to_vector3(character_util.get_look_direction(cs_battle_action.Character))
		end

		battle_util.set_locked_dir(cs_battle_action, vector_util.to_direction(dir_vector))

		return target, dir_vector
	end

	--- 배틀액션의 Owner를 대상 방향으로 고정
	battle_util.set_locked_dir = function(cs_battle_action, dir)
		local priority = cs_battle_action.Type == CS.Oak.BattleActionType.Super and
			CS.Oak.LockDirectionPriorities.SuperBattleAction or
			CS.Oak.LockDirectionPriorities.BattleAction

		local locked_dir

		if lua_helper.type_compare(dir, unity_class.vector3) then
			locked_dir = vector_util.to_direction(dir)
		else
			locked_dir = dir
		end

		cs_battle_action.Character:SetLockedDirection(
			cs_battle_action, CS.Oak.LockDirectionRequest.Create(locked_dir, priority)
		)
	end

	--- 배틀액션에서 요청한 방향 고정을 해지
	battle_util.remove_locked_dir = function(cs_battle_action)
		cs_battle_action.Character:RemoveLockedDirection(cs_battle_action)
	end

	--- 벽을 만나기 전까지의 대쉬 시간을 반환한다. (벽을 만나지 않는 다면 오리지널 대쉬 시간을 반환)
	--- @param dash_duration number 대시 시간
	--- @param dash_speed number 대시 속도
	--- @return number 해당 속도로 돌진 시 벽까지 도달 시간
	battle_util.get_dash_duration_until_wall = function(owner, dash_duration, dash_speed, dir_vector)
		--- 충돌 체크를 위한 바운드
		local bounds = bounds_util.get_bounds(owner)
		local magnitude = dash_speed * dash_duration / 2

		--- 대상 방향으로 이동시 충돌하는 가장 가까운 대상
		local closest_object = field:GetClosestFieldObjectByLineSegment(
			bounds, CS.Oak.EntityGroups.Obstacle, magnitude * dir_vector
		)

		--- 가까운 대상이 존재할때
		if closest_object then
			--- 충돌 최소 거리
			local ray_dist = CS.BoundsExtensions.GetDistanceOnRay(
				bounds, bounds_util.get_bounds(closest_object), dir_vector
			)

			--- 실제 이동가능한 거리 갱신
			magnitude = math.min(magnitude, ray_dist)
		end

		return 2 * magnitude / dash_speed
	end

	--- 단순히 주어진 타겟 또는 방향을 향해 대시한다. 최종적으로 사용된 대시 속력을 반환
	--- @param stay_duration number 대시 시작 전 경직 시간
	--- @param dash_duration number 대시 시간
	--- @param speed number 대시 속도
	--- @param non_manual_speed number 메뉴얼 캐릭터가 아닐 경우 대시 속도
	--- @param cancel_by_atomic_move boolean 일반 조작이 들어온 경우 캔슬 여부
	--- @param manual_min_distance number 대상에게 대시할때 유지할 최소 거리
	--- @return number 실제 사용된 대시 속도
	battle_util.melee_short_dash = function(
		cs_battle_action, target, dir_vector,
		stay_duration, dash_duration, speed, non_manual_speed,
		on_block, cancel_by_atomic_move, manual_min_distance, can_recover_stamina)

		--- get or default value
		on_block = lua_helper.get_or_default(on_block, CS.Oak.ShortDashState.OnBlockType.Slide)
		cancel_by_atomic_move = lua_helper.get_or_default(cancel_by_atomic_move, false)
		manual_min_distance = lua_helper.get_or_default(manual_min_distance, -1)
		--- 대시중 스태미나 회복 불가는 기본 사양 (4주년 다빈, 스태미나 미사용 추가타 반동으로 넉백될 경우는 회복 가능하도록 수정)
		can_recover_stamina = lua_helper.get_or_default(can_recover_stamina, false)

		return CS.Oak.IBattleActionExtensions.MeleeShortDash(cs_battle_action, target, dir_vector,
			stay_duration, dash_duration, speed, non_manual_speed,
			on_block, cancel_by_atomic_move, manual_min_distance, can_recover_stamina
		)
	end

	--- 숏 대시애 사용 하는 주워진 시간만큼 대시를 할 때 원하는 거리에 도달하기 위해 필요한 스피드
	--- 최종 속력은 0 인것으로 한다.(정지)
	--- @param distance number 이동할 거리
	--- @param duration number 이동할 시간
	--- @return number 필요한 속도값
	battle_util.short_dash_speed_for_distance = function(distance, duration)
		return ((2 * distance) / duration)
	end

	--region battleaction info base util

	--- 특정 키에 지정된 애니메이션 요청을 실행 (Owner 기반 요청)
	--- @param key string 애니메이션 키
	battle_util.set_anim = function(lua_battle_action, cs_battle_action, key)
		if lua_battle_action.animation_info and lua_battle_action.animation_info[key] then
			cs_battle_action.Character:SetAnimation(cs_battle_action, lua_battle_action.animation_info[key])
		end
	end

	--- 특정 키에 지정된 상위 애니메이션 요청을 실행 (Owner 기반 요청)
	--- @param key string 애니메이션 키
	battle_util.set_upper_anim = function(lua_battle_action, cs_battle_action, key)
		if lua_battle_action.animation_info and lua_battle_action.animation_info[key] then
			cs_battle_action.Character:SetUpperAnimation(cs_battle_action, lua_battle_action.animation_info[key])
		end
	end

	--- 특정 키에 지정된 표정 애니메이션 요청을 실행 (Owner 기반 요청)
	--- @param key string 애니메이션 키
	battle_util.set_emotion = function(lua_battle_action, cs_battle_action, key)
		if lua_battle_action.emotion_info and lua_battle_action.emotion_info[key] then
			cs_battle_action.Character:SetEmotion(cs_battle_action, lua_battle_action.emotion_info[key])
		end
	end

	--- 특정 키에 지정된 서브 애니메이션 요청을 실행 (Owner 기반 요청)
	--- @param key string 애니메이션 키
	battle_util.set_sub_anim = function(lua_battle_action, cs_battle_action, key)
		if lua_battle_action.animation_info and lua_battle_action.animation_info[key] then
			cs_battle_action.Character:SetSubAnimation(cs_battle_action, lua_battle_action.animation_info[key])
		end
	end

	--- 배틀액션에서 요청한 애니메이션 해지 (Owner 기반 해지)
	battle_util.remove_anim = function(cs_battle_action, mix_duration)
		cs_battle_action.Character:RemoveAnimation(cs_battle_action, false, mix_duration)
	end

	--- 배틀액션에서 요청한 상위 애니메이션 해지 (Owner 기반 해지)
	battle_util.remove_upper_anim = function(cs_battle_action, mix_duration)
		cs_battle_action.Character:RemoveUpperAnimation(cs_battle_action, false, mix_duration)
	end

	--- 배틀액션에서 요청한 표정 해지 (Owner 기반 해지)
	battle_util.remove_emotion = function(cs_battle_action)
		cs_battle_action.Character:RemoveEmotion(cs_battle_action, false)
	end

	--- 배틀액션에서 요청한 서브 애니메이션 해지 (Owner 기반 해지)
	battle_util.remove_sub_anim = function(cs_battle_action, mix_duration)
		cs_battle_action.Character:RemoveSubAnimation(cs_battle_action, false, mix_duration)
	end

	--- 특정 키에 지정된 프리셋 오브젝트 풀에서 오브젝트를 생성해서 반환
	--- @param key string 프리셋 키
	battle_util.instantiate_effect = function(lua_battle_action, key, position, rot, transform, flag)
		if lua_battle_action.preset_info and lua_battle_action.preset_info[key] then
			return effect_util.instantiate_effect(lua_battle_action.preset_info[key], position, rot, transform, flag)
		end

		return nil
	end

	--- 특정 키에 지정된 프리셋 오브젝트 풀에서 오브젝트를 생성해서 반환 (오너쉽)
	--- @param key string 프리셋 키
	battle_util.instantiate_ownership_effect = function(lua_action, key, owner, position, rot, transform, flag)
		if lua_action.preset_info and lua_action.preset_info[key] then
			return effect_util.instantiate_effect(lua_action.preset_info[key], position, rot, transform, flag, owner)
		end

		return nil
	end

	--- 특정 키에 지정된 프리셋 오브젝트 풀에서 오브젝트를 생성해서 반환
	--- @param lua_script any 루아 스크립트 (LuaBattleAction, LuaOption..)
	--- @param owner any 이펙트 오너
	--- @param key string 프리셋 키
	--- @param force_apply boolean 강제 적용 여부
	--- @return any 생성된 스크린 이펙트
	battle_util.instantiate_screen_effect = function(lua_script, owner, key, force_apply)
		if not battle_util.is_screen_effect_enabled() then
			return
		end

		if owner == nil then
			CS.UnityEngine.Debug.LogError('screen fx owner is nil')
			return
		end

		key = key or 'screen'

		if lua_script.preset_info == nil or lua_script.preset_info[key] == nil then
			return nil
		end

		force_apply = lua_helper.get_or_default(force_apply, false)
		return CS.Oak.LuaBattleExtensions.InstantiateScreenEffect(owner, lua_script.preset_info[key], force_apply, nil)
	end

	--- 현재 스크린 이펙트가 활성화 되어 있는지를 반환
	battle_util.is_screen_effect_enabled = function()
		return CS.Oak.ScreenEffectOptionManager.Instance.ScreenEffectOption
	end

	--- 특정 키에 지정된 사운드 정보를 기반해 audio source를 생성해서 반환
	--- @param key string 사운드 정보 키
	battle_util.play_sfx = function(lua_battle_action, key)
		if lua_battle_action.sfx_info and lua_battle_action.sfx_info[key] then
			return music_player:PlaySfx(lua_battle_action.sfx_info[key])
		end

		return nil
	end

	--- 특정 키에 지정된 사운드 정보를 기반해 audio source를 생성해서 반환 (카메라 이펙트 용)
	--- @param key string 사운드 정보 키
	battle_util.play_sfx_for_camera_fx = function(lua_battle_action, key)
		if lua_battle_action.sfx_info and lua_battle_action.sfx_info[key] then
			return music_player:PlaySfx(
				CS.Oak.SfxInfoExtensions.ReplaceParent(lua_battle_action.sfx_info[key], null)
			)
		end

		return nil
	end

	--- 특정 키에 지정된 사운드 정보를 기반해 audio source를 생성해서 반환
	--- @param key string 사운드 정보 키
	battle_util.play_sfx_and_replace_parent = function(lua_battle_action, key, parent)
		if lua_battle_action.sfx_info and lua_battle_action.sfx_info[key] then
			local info = lua_battle_action.sfx_info[key]

			if parent then
				info = CS.Oak.SfxInfoExtensions.ReplaceParent(info, parent)
			end

			return music_player:PlaySfx(info)
		end

		return nil
	end

	--- 특정 키에 지정된 사운드 정보를 기반해 audio source를 생성해서 반환
	--- @param key string 사운드 정보 키
	battle_util.play_sfx_and_replace_position = function(lua_battle_action, key, position)
		if lua_battle_action.sfx_info and lua_battle_action.sfx_info[key] then
			local info = lua_battle_action.sfx_info[key]

			if position then
				info = CS.Oak.SfxInfoExtensions.ReplacePlayPosition(info, position)
			end

			return music_player:PlaySfx(info)
		end

		return nil
	end

	--endregion

	--- 대상 오브젝트가 메뉴얼 로컬인지 여부를 판단
	--- @return boolean 대상 오브젝트가 메뉴얼 로컬인지 여부
	battle_util.is_manual_local = function(target_object)
		return CS.Oak.IFieldObjectExtensions.IsManualLocal(target_object)
	end

	--- 대상 오브젝트의 오너가 메뉴얼인지 여부를 판단
	--- @return boolean 대상 오브젝트의 오너가 메뉴얼인지 여부
	battle_util.is_manual_fo = function(fo)
		return CS.Oak.FieldObjectControllerTypesExtensions.IsManual(fo.FieldObjectController)
	end

	--- 대상 오브젝트의 오너가 로컬인지 여부를 판단
	--- @return boolean 대상 오브젝트의 오너가 로컬인지 여부
	battle_util.is_local_fo = function(fo)
		if fo and fo.Owner then
			return fo.Owner == CS.Oak.Player.Local
		end

		return false
	end

	--- 대상 오브젝트가 ICharacter 기반인 "캐릭터" 오브젝트인지 판단
	--- @return boolean 대상 오브젝트가 캐릭터인지 여부
	battle_util.is_character_fo = function(fo)
		return CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(fo, typeof(CS.Oak.ICharacter))
	end

	--- 스테이지 컨트롤이 시작한 상태인지
	battle_util.is_control_started = function()
		return stage.StageControlStarted
	end

	--- 최적화 루틴
	battle_util.is_usable_routine = function(owner)
		--- 예외 처리 스테이지 타입
		--- Async Battle (콜로세움, 궤도 엘베)
		--- Elemental Tower (속성 미궁)
		--- Hero Tower (영웅 미궁)
		--- Coop BotMatch (멀티를레이 봇 매치)
		--- Guild Conquest (길드 점령전)
		--- RogueChess (로그체스)
		if stage.Spec.ChapterCode.IsAsyncBattleStage or
			stage.Spec.ChapterCode.StageType == CS.StageType.ElementalTowerStage or
			stage.Spec.ChapterCode.StageType == CS.StageType.HeroTowerStage or
			stage.Spec.StageType == CS.StageType.CoopStage and CS.Oak.CoopClient.IsBotMatch or
			stage.Spec.StageType == CS.StageType.GuildConquestStage or
			stage.Spec.StageType == CS.StageType.RogueChess then
			return true
		end

		return battle_util.is_local_fo(owner)
	end

	--- 전투에 오너가 포함되어 있는지 판단 (파티전용)
	battle_util.is_in_battle = function(owner)
		return battle_manager ~= nil and
			party_util.get_party_for(owner) ~= nil and
			battle_manager:GetBattleFor(owner) ~= nil
	end

	--- 전투에 케릭터가 포함되어 있는지 판단
	battle_util.is_character_in_battle = function(owner)
		return battle_manager ~= nil and
				battle_manager:GetBattleFor(owner) ~= nil
	end

	--- 전투에 포함되어 있고 현재 몬스터 웨이브에도 포함되어 있는지 체크
	battle_util.is_character_in_active_battle = function(owner)
		return battle_manager ~= nil and
				battle_manager:IsCharacterInActiveBattle(owner)
	end

	--- 기본적인 스킬 사용 쉐이크와 보이스를 재생
	battle_util.default_shake_and_play_voice = function(cs_battle_action)
		--- 메뉴얼 로컬 플래그 체크
		if not battle_util.is_manual_local(cs_battle_action.Character) then
			return
		end

		stage_camera:Shake(0.25, 0.1)

		battle_util.default_play_voice(cs_battle_action)
	end

	--- 기본적인 보이스를 재생
	battle_util.default_play_voice = function(cs_battle_action)
		--- 액션의 오너
		local owner = cs_battle_action.Character

		--- 액션의 타입을 가져옴
		local action_type = CS.Oak.LuaBattleExtensions.GetBattleActionType(cs_battle_action)
		--- 연계기인지
		local is_support_action = action_type == CS.Oak.BattleActionType.Support

		--- 연계기가 아닐때는 메뉴얼 로컬 / 연계기 일때는 로컬
		if not is_support_action and not battle_util.is_manual_local(owner) or
			is_support_action and not battle_util.is_local_fo(owner) then
			return
		end

		music_player:PlayDefaultSkillVoice(cs_battle_action.Character)
	end

	battle_util.play_voice = function(cs_battle_action, voice_type)
		--- 액션의 오너
		local owner = cs_battle_action.Character

		--- 액션의 타입을 가져옴
		local action_type = CS.Oak.LuaBattleExtensions.GetBattleActionType(cs_battle_action)
		--- 연계기인지
		local is_support_action = action_type == CS.Oak.BattleActionType.Support

		--- 연계기가 아닐때는 메뉴얼 로컬 / 연계기 일때는 로컬
		if not is_support_action and not battle_util.is_manual_local(owner) or
			is_support_action and not battle_util.is_local_fo(owner) then
			return
		end

		music_player:PlayVoice(cs_battle_action.Character, voice_type)
	end

	battle_util.play_voice_in_args = function(cs_action, denominator, ...)
		--- 보이스 출력 시도
		battle_util.play_voice_in_table(cs_action, denominator, {...})
	end

	--- oldTimePassed와 timePassed를 가지고 실제로 targetPassed 시점인지 판별해주는 편의 유틸
	--- @param total_weight number 전체 가중치의 총합.
	--- @param ... number 재생이 필요한 보이스 타입 - 개별 가중치를 페어로 기입
	--- ex) Skill_1 과 Skill_2 를 1:2 비율로 재생하고 싶을 경우,
	--- ..(cs_action, 3, Skill_1, 1, Skill_2, 2) 형태로 기입
	battle_util.play_voice_in_weight = function(cs_action, total_weight, ...)
		local table = {...}

		--- 가중치 비교값
		local current_weight = 0

		--- 랜덤 값
		local value = random_util.get_random_int(1, total_weight)

		--- 테이블을 돌면서 적절한 보이스를 찾음
		for idx = 1, #table, 2 do
			local type = table[idx]
			local weight = table[idx + 1]

			current_weight = current_weight + weight

			--- 적절한 가중치에 도달하면 보이스 재생
			if value <= current_weight then
				battle_util.play_voice(cs_action, type)
				return
			end
		end
	end

	battle_util.play_voice_in_table = function(cs_action, denominator, voice_table)
		denominator = lua_helper.get_or_default(denominator, 2)

		--- 보이스 키 수
		local count = #voice_table
		--- 랜덤 값
		local value = random_util.get_random_int(1, count * denominator)
		--- 유효하지 않다면 생략함
		if value > count then return end

		---보이스 재생
		battle_util.play_voice(cs_action, voice_table[value])
	end

	--- 기본적인 필살기(Role, Super) 사용 시에 나타나는 효과
	battle_util.start_effect = function(cs_battle_action, owner, force_shake)
		force_shake = lua_helper.get_or_default(force_shake, false)

		CS.Oak.ITriggerBattleActionExtensions.StartEffect(cs_battle_action, owner, force_shake)
	end

	--- 필살기(Role, Super) 사용이 끝났을 경우 화면 효과를 해제
	battle_util.end_effect = function(cs_battle_action, owner)
		CS.Oak.ITriggerBattleActionExtensions.EndEffect(cs_battle_action, owner)
	end

	--- 전용무기 배틀액션 공용으로 사용할 어두워지는 연출
	--- @param target_darken number 목표 연출 강도
	--- @param duration number 연출에 걸릴 시간
	battle_util.set_cwp_darken = function(cs_battle_action, target_darken, duration)
		--- 메뉴얼 로컬 플래그 체크
		if not battle_util.is_manual_local(cs_battle_action.Character) then
			return
		end

		if field then
			duration = lua_helper.get_or_default(duration, 0.2)

			field:Darken('cwp_skill_trigger', target_darken, duration)
		end
	end

	--- 전용무기 배틀액션 공용으로 사용할 어두워지는 연출 해지
	--- @param duration number 연출 해지에 걸릴 시간
	battle_util.unset_cwp_darken = function(cs_battle_action, duration)
		--- 메뉴얼 로컬 플래그 체크
		if not battle_util.is_manual_local(cs_battle_action.Character) then
			return
		end

		if field then
			duration = lua_helper.get_or_default(duration, 0.2)

			field:Undarken('cwp_skill_trigger', duration)
		end
	end

	--- oldTimePassed와 timePassed를 가지고 실제로 targetPassed 시점인지 판별해주는 편의 유틸
	--- @param old_time_passed number 지난 프레임의 time_passed
	--- @param time_passed number 현재 프레임의 time_passed
	--- @param target_passed number 목표로 하는 시점
	--- @return boolean 실제 그 시점에 도달했는지 여부
	battle_util.check_time_passed = function(old_time_passed, time_passed, target_passed)
		return target_passed == 0 and old_time_passed == 0 or
			old_time_passed < target_passed and target_passed <= time_passed
	end

	--- oldTimePassed와 timePassed를 가지고 실제로 min_time, max_time 에 포함되는 시점인지 판별해주는 편의 유틸
	--- @param old_time_passed number 지난 프레임의 time_passed
	--- @param time_passed number 현재 프레임의 time_passed
	--- @param min_time number 최소 시간 (inclusive)
	--- @param max_time number 최대 시간 (exclusive)
	--- @return boolean min_time, max_time 내부에 존재하는 시간인지
	battle_util.check_time_between = function(old_time_passed, time_passed, min_time, max_time)
		return min_time <= time_passed and old_time_passed < max_time
	end

	--- oldTimePassed와 timePassed를 가지고 실제로 min_time, max_time 에 포함되는 시점인지 판별해주는 편의 유틸
	--- @param old_time_passed number 지난 프레임의 time_passed
	--- @param time_passed number 현재 프레임의 time_passed
	--- @param dt number delta time
	--- @param min_time number 최소 시간 (inclusive)
	--- @param max_time number 최대 시간 (exclusive)
	--- @return number 실제 delta time
	battle_util.get_real_dt = function(old_time_passed, time_passed, dt, min_time, max_time)
		--- 실제 delta time
		local real_dt = dt

		--- 앞 부분 보정
		if old_time_passed < min_time then
			real_dt = real_dt - (min_time - old_time_passed)
		end

		--- 뒷 부분 보정
		if time_passed > max_time then
			real_dt = real_dt - (time_passed - max_time)
		end

		return real_dt
	end

	-- 해당 위치의 존을 반환
	battle_util.get_zone = function(position)
		local candidate_zone
		local zone_list = stage.Field:GetZoneListFor(position)
		if zone_list ~= nil then
			if zone_list.Count > 0 then
				candidate_zone = zone_list[0]
			end
			zone_list:Dispose()
		end

		return candidate_zone
	end

	--- 해당 위치를 포함하는 배틀존의 바운드를 리턴
	battle_util.get_zone_bound = function(position)
		local zone_bound

		local zone = battle_util.get_zone(position)
		if zone ~= nil then
			zone_bound = zone.Bounds
		end

		return zone_bound
	end

	--- 컨트롤러에 지정된 배틀존 우선적으로 찾아주는 유틸
	battle_util.get_event_zone = function(user, t)
		local zone_name = CS.Oak.IFieldObjectControllerExtensions.GetZone(t.FieldObjectController)
		if zone_name ~= nil then
			local zone = field:GetZone(zone_name)
			if zone ~= nil and zone:Contains(user.Position) then
				return zone
			end
		end

		local zone_list = field:GetZoneListFor(t.Position)
		local candidate = nil
		for _, v in pairs(zone_list) do
			if v:Contains(user.Position) and v:GetType() == typeof(CS.Oak.Zone) then
				candidate = v
				break
			end
		end
		zone_list:Dispose()

		return candidate
	end

	--- 컨트롤러에 지정된 배틀존 우선적으로 찾아주는 유틸, 바운드로 반환한다.
	battle_util.get_event_zone_bound = function(owner, target)
		local zone = battle_util.get_event_zone(owner, target)
		if zone then
			return zone.Bounds
		end

		return nil
	end

	--- 해당 위치의 바닥 포지션을 찾아주는 편의 유틸
	battle_util.get_ground_pos = function(position)
		return vector_util.get_x0z(position, battle_util.get_height(position))
	end

	--- 해당 위치의 높이를 찾아주는 편의 유틸
	battle_util.get_height = function(position)
		return field:GetTileInfoAt(position):GetHeightAt(position)
	end

	--- 실제로 밟을 수 있는 타일이 해당 위치에 존재하는지
	battle_util.is_there_floor_at = function(position)
		return field:IsThereFloorAt(position)
	end

	--- 해당 위치에 밟을 수 있는 바닥이 있는지
	--- Obstacle 등에 의해 밟을 수 없게된 바닥도 false 판정을 발생시킨다.
	battle_util.is_there_approachable_floor_at = function(position)
		return field:IsThereApproachableFloorAt(position)
	end

	--- XZ평면 상에서 기준 방향에 수직한 방향을 구해주는 유틸
	battle_util.get_vertical_direction = function(base_dir, target_dir)
		local xz_target = target_dir:GetXz().normalized
		local xz_base = base_dir:GetXz().normalized

		if xz_base:IsClockWise(xz_target) then
			return unity_class.quaternion.Euler(0, 90, 0) * base_dir
		else
			return unity_class.quaternion.Euler(0, -90, 0) * base_dir
		end
	end

	--- 역넉백을 주기 위해 힘을 계산하는 함수
	--- @param distance number 끌어당길 거리
	--- @param mass number 대상의 질량
	battle_util.get_pull_knock_back_force = function(distance, mass)
		--- 질량이 없거나 음수인 경우는 없다고 가정. 만약 있다면 애초에 문제가 있는 것. 다른 곳(physics)에서 이미 문제가 생겼을 것
		if mass <= 0 then
			return 0
		end

		--- 거리가 0일 경우 계산할 필요가 없음
		if float_util.is_almost_zero(distance) then
			return 0
		end

		--- 일반적인 넉백을 사용할때 F에 대해 유도된 식은 아래와 같음
		--- 1.0f / (mass * coefficient) * F ^ 2 - F - (2 * distance * mass) / (time ^ 2) = 0
		local a = 1 / (mass * knock_back_constants.default_friction_coefficient)
		local b = -1
		local c = -2 * distance * mass / (knock_back_constants.default_impact_time ^ 2)
		local discriminant = b ^ 2 - 4 * a * c

		--- discriminant에 대한 다른 체킹을 하지 않는 이유는 다음과 같음
		--- d를 유도하게 되면 b * b + 8 * distance / (coefficient * time * time) 이고,
		--- b는 -1임이 항상 보장(const), coefficient * time * time은 양수임이 항상 보장.
		--- 결과적으로 d > 1 일 경우 밖에 없다
		local force = (-b * math.sqrt(discriminant)) / (2 * a)

		--- 동일한 논리로 d > 1 이기 때문에 abs(sqrt(d)) > 1 이고 sqrt(d) < -1 이거나 1 < sqrt(d) 이다.
		--- -b + sqrt(d)는 양의 제곱근일 경우 항상 양수
		--- -b + sqrt(d)는 음의 제곱근일 경우 항상 음수이게 된다.
		--- 현재 상황에서 F가 음수인 경우는 필요없으므로 항상 양의 제곱근을 이용하면 된다.
		return force
	end

	--- 크래시 비헤비어 어태치를 도와주는 유틸
	--- attach 이후 Set은 직접 해야함
	battle_util.attach_crash_behaviour = function(cs_battle_action, crash_behaviour)
		CS.Oak.LuaBattleExtensions.AttachCrashBehavior(cs_battle_action, crash_behaviour)
	end

	--- 크래시 비헤비어 디태치를 도와주는 유틸
	--- detach 이후 비워주는 작업은 직접 해야함
	battle_util.detach_crash_behaviour = function(cs_battle_action, crash_behaviour)
		CS.Oak.LuaBattleExtensions.DetachCrashBehavior(cs_battle_action, crash_behaviour)
	end

	--- 배틀액션의 소유자가 ai상태인지 판단하는 유틸
	battle_util.is_ai = function(cs_battle_action)
		return CS.Oak.LuaBattleExtensions.IsAI(cs_battle_action)
	end

	battle_util.camera_shake = function(owner, magnitude, duration, key)
		if battle_util.is_manual_local(owner) then
			if key == nil then
				stage_camera:Shake(magnitude, duration)
			else
				local shake_info = CS.Oak.ShakeInfo(key, magnitude, duration, false)

				stage_camera:Shake(shake_info)
			end
		end
	end

	--- 점점 쉐이킹 감소 가능한 쉐이킹. diminish_scale = 1이면 지속시간에 걸쳐 0까지 감소. 0.5면 끝날 때 진폭이 절반.
	--- damageTerm 을 1 틱이라고 가정했을 때.
	--- @param diminish_scale number 시간에 걸친 감소율. 1이면 끝날때 진폭이 100% 감소된 상태가 됨.
	battle_util.camera_shake_fadeout = function(owner, magnitude, duration, key, diminish_scale)
		if not battle_util.is_manual_local(owner) then return end

		local shake_info = CS.Oak.ShakeInfo(key, magnitude, duration, diminish_scale)

		stage_camera:Shake(shake_info)
	end

	battle_util.cancel_camera_shake = function(key)
		stage_camera:CancelShake(key)
	end

	--- 메뉴얼로 프로젝타일을 쏠 때 사용하는 흔들기 유틸
	battle_util.default_shooting_shake = function(owner, direction, magnitude, duration)
		if battle_util.is_manual_local(owner) then
			local shake_direction

			if lua_helper.type_compare(direction, unity_class.vector3) then
				shake_direction = vector_util.to_direction(direction)
			else
				shake_direction = direction
			end

			stage_camera:DefaultShootingShake(shake_direction, magnitude or 0.01, duration or 0.14)
		end
	end

	battle_util.get_role_action = function(owner)
		--- 오너의 액션 순회
		for _, cs_action in pairs(owner.CharacterBehaviour.BattleActions) do
			--- 타입 검증
			local action_type = CS.Oak.LuaBattleExtensions.GetBattleActionType(cs_action)
			if action_type == CS.Oak.BattleActionType.Role then
				--- 역할 액션 캐싱
				return cs_action
			end
		end

		return nil
	end

	--- 배틀 액션 type에 따라 source_type을 반환하는 유틸
	battle_util.get_source_from_action = function(cs_action)
		local action_type = CS.Oak.LuaBattleExtensions.GetBattleActionType(cs_action)
		return CS.Oak.DamageSourceTypeExtensions.ToDamageSource(action_type)
	end

	--- 해당 cs action에서 가장 최근에 입력된 valid 한 스틱 입력을 반환 (보정 없는 360 도 입력)
	battle_util.get_stick_direction = function(cs_action, input_window)
		input_window = lua_helper.get_or_default(input_window, 0.3)
		return CS.Oak.IJoypadBattleActionExtensions.GetStickDirection(cs_action, input_window)
	end

	--- 해당 cs action에서 가장 최근에 입력된 valid 한 보정 없는 스틱 입력을 반환 (보정 없는 360 도 입력)
	battle_util.get_raw_stick_direction = function(cs_action, input_window)
		input_window = lua_helper.get_or_default(input_window, 0.3)
		return CS.Oak.IJoypadBattleActionExtensions.GetRawStickDirection(cs_action, input_window)
	end

	--- 해당 cs action에서 가장 최근에 입력된 valid한 스틱 입력을 반환 (4방향)
	battle_util.get_4_way_stick_direction = function(cs_action, input_window)
		input_window = lua_helper.get_or_default(input_window, 0.3)
		return CS.Oak.IJoypadBattleActionExtensions.Get4WayStickDirection(cs_action, input_window)
	end

	--- 액션의 트리거를 실패할 경우 플로팅 텍스트 출력과 액션 사용불가 이벤트 발송처리를 위한 유틸
	battle_util.action_trigger_error = function(owner, string_key)
		--- 플루팅 텍스트를 가져옴
		local floating_text = CS.Oak.FieldUIFloatingText.Get(owner)

		--- nil 체크
		if floating_text then
			local text = CS.GameStrings.Instance:GetString(string_key)
			floating_text:ActivateForManaEmptyText(text, 0, unity_class.color.red)
		end

		--- 액션이 사용 불가능하다는 이벤트 발송
		message_system:Publish(CS.Oak.BattleActionUnavailableEvent.Create(owner))
	end

	--- 대상에게서 특정 handle name의 cs 배틀액션을 반환
	battle_util.get_battle_action_by_name = function(owner, handle_name)
		return CS.Oak.LuaBattleExtensions.GetBattleActionByName(owner, handle_name)
	end

	--- cs 배틀액션의 handle name을 반환
	battle_util.get_battle_action_handle_name = function(cs_action)
		return CS.Oak.LuaBattleExtensions.GetBattleActionHandleName(cs_action)
	end

	battle_util.setup_override_parameter = function(param)
		return CS.Oak.BattleConstantsDataSystem.SetupOverrideParameter(param)
	end

	--- cs 배틀액션에 달려있는 캐릭터의 특정 슬롯 무기의 스프라이트 및 attachment 를 사라지게 세팅한다.
	--- add_weapon_attachment 에서 sprite name 과 attachment 에 nil 을 넣은 것. 추가기능은 없다.
	battle_util.set_hide_weapon_attachment = function(cs_battle_action, request_slot, priority)
		battle_util.add_weapon_attachment(cs_battle_action, nil, nil, request_slot, priority)
	end

	--- cs 배틀액션에 달려있는 캐릭터에 특정 슬롯 무기의 sprite 및 attachment 를 덮어씌운다.
	battle_util.add_weapon_attachment = function(cs_battle_action, sprite_name, attachment, request_slot, priority)
		cs_battle_action.Character:RequestWeaponAttachment(cs_battle_action, sprite_name, attachment, request_slot, priority)
	end

	--- cs 배틀액션에 달려있는 캐릭터에 요청 해 놓은 sprite/attachment request 를 제거한다.
	battle_util.remove_weapon_attachment = function(cs_battle_action, request_slot)
		cs_battle_action.Character:RemoveWeaponAttachment(cs_battle_action, request_slot)
	end

	--- IMythBattleAction 기반 배틀액션이 실제로 available 한지 판단해주는 편의 유틸
	battle_util.myth_is_available = function(cs_battle_action)
		return CS.Oak.IMythBattleActionExtensions.MythActionIsAvailable(cs_battle_action)
	end

	battle_util.parse_ai_action_data = function(param)
		local has_value, value = param:TryGetValue('ActionData')

		local action_list = {}

		if has_value then
			for _, info in pairs(value) do
				local action_table = {}

				action_table.index = CS.Utils.GetIntFromDictionary(info, "Index")
				action_table.action_name = CS.Utils.GetStringFromDictionary(info, "ActionName")
				action_table.rest_time = CS.Utils.GetFloatFromDictionary(info, "RestTime", 1)
				action_table.show_arrow = CS.Utils.GetBoolFromDictionary(info, "ShowTargetArrow", true)

				table.insert(action_list, action_table)
			end
		end

		return action_list
	end

	-- pattern_util은 공격패턴에 쓰이는 다양한 형태를 편의 목적으로 고도화 해둔 패턴들이다.
	pattern_util = {}

	--- 원 위 각도가 동일한 n개의 점들을 반환.
	pattern_util.vertexes_on_circle = function(center_pos, radius, n, start_angle)
		local vertexes = {}
		if center_pos == nil or n < 1 then
			return vertexes
		end

		if start_angle == nil then
			start_angle = 0
		end

		local internal_angle = 360 / n
		for i = 1, n do
			local angle = internal_angle * i
			--회전에 대한 nomalize된 정점을 구한다
			local rotation_vector = (unity_class.quaternion.AngleAxis(angle + start_angle, vector_util.up) * vector_util.forward).normalized
			local vertex_position = center_pos + rotation_vector * radius
			table.insert(vertexes, vertex_position)
		end

		return vertexes
	end

	--- 원 위에서 무작위 점하나를 반환한다. 찾기의 실패할 경우 center_pos를 반환.
	pattern_util.random_direction_point = function(character, radius, search_angle_interval, check_block)
		--region nil check
		if character == nil then
			CS.UnityEngine.Debug.LogError('[pattern_util] center_pos is nil. Set Vector.zero')
			return vector_util.zero, vector_util.zero
		end

		if radius == nil then
			radius = 3
		end

		--무작위 각도 이후 360도 모두 순회를 하려면 11이 적당하다. 서칭 간격으로도.
		if search_angle_interval == nil then
			search_angle_interval = 11
		end

		--이동 중 벽에 막히는지 체크는 안한다.
		if check_block == nil then
			check_block = false
		end
		--endregion

		local center_pos = character.Position
		local character_dir = character.Direction
		local start_angle = random_util.get_random_int(0, 359)
		local search_angle = 0

		local check_angle = 0.0
		local clamped_angle = 0.0		--360도가 넘는 경우 0도부터 재환산해줌
		local destination_dir = vector(0, 0, 0)
		local destination_pos = center_pos

		repeat
			check_angle = start_angle + search_angle
			clamped_angle = unity_class.mathf.Clamp(check_angle - math.floor(check_angle / 360.0) * 360.0, 0, 360.0)
			destination_dir = unity_class.quaternion.AngleAxis(clamped_angle, vector_util.up) * vector_util.forward
			destination_pos = center_pos + (destination_dir * radius)

			-- 이동 방향에 대해서 뭔가 걸리적 거리는게 있는지 체크한다.
			if check_block == true then
				if CS.Oak.IFieldObjectExtensions.IsMovementBlockedBetween(character, center_pos, destination_pos, CS.Oak.EntityGroups.Obstacle) == false then
					return destination_pos, destination_dir

				elseif search_angle >= 360.0 then
					return vector_util.zero, vector_util.zero

				else
					search_angle = search_angle + search_angle_interval
				end
			else 		--블록킹 체크를 할 필요 없다면 바로 반환해주고 끝낸다.
				return destination_pos, destination_dir
			end
		until false

		return destination_pos, destination_dir	--방향 벡터에 0 넘겨도 되나?
	end

	-- TODO: 조금 깔끔한 산탄총 분포를 낼 수 있는 알고리즘 고민 필요
	--- 도넛 범위 내 무작위 개체들을 반환. (min을 0으로 주면 산탄하고 비슷. angle_scatter는 조금만 줄것)
	pattern_util.vertexes_on_donut = function(center_pos, min_radius, max_radius, n, angle_scatter)
		local vertexes_result = {}
		if center_pos == nil or n < 1 then return vertexes_result end	-- 0이면 중심만 반환 (어쨋던 반환)
		if angle_scatter == nil then angle_scatter = 0 end

		local start_angle = random_util.get_random_int(1,360)	--무작위 시작 각도를 구한다.


		local middle_radius = (min_radius + max_radius) / 2					--도넛의 중심라인을 구한다

		local internal_angle = 360 / n
		for i = 1, n do
			-- 약간의 오차각을 포함한 도넛 중심라인 위 오리지널 정점
			local scattered_angle = unity_class.random.Range(-angle_scatter, angle_scatter) -- 랜덤 오차각
			local angle = internal_angle * i + start_angle + scattered_angle
			local vertex_center_pos = (unity_class.quaternion.AngleAxis(angle, vector_util.up) * vector_util.forward).normalized * middle_radius

			-- 오리지널 정점으로부터 삐져나갈 값
			local random_angle = random_util.get_random_int(1, 360)
			local scattered_radius = unity_class.random.Range(0, middle_radius / 2)
			local scattered_pos = (unity_class.quaternion.AngleAxis(random_angle, vector_util.up) * vector_util.forward).normalized * scattered_radius

			-- 중심으로부터 분산된 정점
			local scattered_vertex_position = center_pos + vertex_center_pos + scattered_pos
			table.insert(vertexes_result, scattered_vertex_position)
		end

		return vertexes_result
	end

	--[[
	나중에 중심위치를 무작위로 찍고 거기서 산탄을 찍는 기능도 구현해서 테스트 해보자.
	중심에서 r 이내 무작위 위치를 중심으로 적당한 간격으로 탄을 분포하는 기능
	(위 도넛도 min을 0으로 하면 비슷하지만 중심점 기주으로 발포 된다는데 있어 실제 느낌이 다를 수 있음)
	]]

	--- 해당 존을 가로 세로로 나누고 그중 n개를 픽한다(무작위로)
	pattern_util.random_positions_on_battlezone = function(zone, width_count, height_count, select_count, padding)
		local results = {}

		if zone == nil then return results end
		if width_count == nil or width_count <= 0 then return results end
		if height_count == nil or height_count <= 0 then return results end
		if select_count == nil or select_count <= 0 then return results end

		if padding == nil then padding = 0 end


		local candidates = {}
		local total_count = width_count * height_count
		for idx = 1, total_count do
			table.insert(candidates, idx)
		end

		--랜덤 후보 목록 추출
		local result_indexes = {}
		for idx = 1, select_count do
			local rand_idx = random_util.get_random_int(1, #candidates)
			table.insert(result_indexes, candidates[rand_idx])
			table.remove(candidates, rand_idx)
		end

		if #result_indexes <= 0 then return results end

		-- 한 칸의 가로 세로 실 크기
		local width_size = zone.extents.x * 2 / width_count
		local height_size = zone.extents.z * 2 / height_count

		for idx = 1, #result_indexes do
			-- 랜덤 칸의 idx를 기준으로 가로 세로를 더해서 실 포지션을 구한다.
			local x = zone.min.x + ((result_indexes[idx] - 1) % width_count) * width_size + padding
			local z = zone.min.z + math.floor((result_indexes[idx] - 1) / width_count) * height_size + padding

			if padding ~= nil and padding > 0 then
				local rand_x = random_util.get_random_value() * (width_size - padding * 2)
				local rand_z = random_util.get_random_value() * (height_size - padding * 2)

				x = x + rand_x
				z = z + rand_z
			end
			local v = vector(x, 0, z)
			if not zone:Contains(v) then
				local a = 1
			end

			table.insert(results, vector(x, 0, z))
		end


		return results
	end

	pattern_util.random_pos_non_overlap = function(bounds, y, amount, space)
		local results = {}
		local max_try_count = 100
		local try_count = 0

		local function check_valid_pos(list, new_pos, min_space)
			for _, pos in pairs(list) do
				if (pos - new_pos).magnitude < min_space then
					return false
				end
			end
			return true
		end

		-- >>
		while #results < amount and try_count < max_try_count do
			local x = unity_class.random.Range(bounds.min.x, bounds.max.x)
			local z = unity_class.random.Range(bounds.min.z, bounds.max.z)
			local new_pos = vector(x, y, z)
			if check_valid_pos(results, new_pos, space) then
				table.insert(results, new_pos)
				try_count = 0
			end
			try_count = try_count + 1
		end

		return results
	end

	--- 탄창형 스태미너 액션이 사용할 유틸
	discrete_stamina_action_util = {}

	--- 사용시 스테미너 브레이크인지
	discrete_stamina_action_util.is_break_attack = function(cs_battle_action)
		return cs_battle_action:IsBreakAttack()
	end

	--- 스테미너 사용
	discrete_stamina_action_util.use_stamina = function(cs_battle_action)
		cs_battle_action:UseStamina()
	end

	--- 탄창형 액션이 사용할 한 번 공격을 하는데 들어가는 스태미너 양
	discrete_stamina_action_util.get_stamina_per_action = function(cs_battle_action)
		return cs_battle_action:GetStaminaPerAction()
	end

	--- [LuaBattleExtensions] 스태미너 소모량 / 회복속도를 감안해 이 배틀액션의 DPS 가 여타 메뉴얼 배틀액션들과 동일하도록 공격당 Attack modifier 를 계산해 리턴.
	---
	--- 만약 한 공격당 다단히트가 들어간다면 여기서 리턴한 값을 히트 수로 나누어 줘야 한다.
	--- @param attack_duration number ShootTerm, ShootPeriod 등 스테미나 공격 사이 간격 혹은 길이
	--- @param stamina_break_extra_modifier number 스테미나 브레이크 샷이 있다면, 스테미나 브레이크의 추가 Modifier
	--- @return number attack modifier
	discrete_stamina_action_util.calculate_attack_modifier = function(
		cs_battle_action,
		attack_duration, stamina_break_extra_modifier
	)
		local stamina_per_action = battle_util.get_number(
			discrete_stamina_action_util.get_stamina_per_action(cs_battle_action)
		)

		stamina_break_extra_modifier = lua_helper.get_or_default(stamina_break_extra_modifier, 0)

		return CS.Oak.LuaBattleExtensions.CalculateAtkModBasedDiscreteStamina(
			cs_battle_action, attack_duration, stamina_per_action, stamina_break_extra_modifier
		)
	end

	--- 지속형 스태미너 액션이 사용할 유틸
	continuous_stamina_action_util = {}

	--- 스테미너 사용
	continuous_stamina_action_util.use_stamina = function(cs_battle_action, dt)
		cs_battle_action:UseStamina(dt)
	end

	--- 탄창형 액션이 사용할 한 번 공격을 하는데 들어가는 스태미너 양
	continuous_stamina_action_util.get_stamina_per_second = function(cs_battle_action)
		return cs_battle_action:GetStaminaPerSecond()
	end

	--- [LuaBattleExtensions] 스태미너 소모량 / 회복속도를 감안해 이 배틀액션의 DPS 가 여타 메뉴얼 배틀액션들과 동일하도록 공격당 Attack modifier 를 계산해 리턴.
	---
	--- damageTerm 을 1 틱이라고 가정했을 때.
	--- @param damage_term number 스테미나 브레이크 샷이 있다면, 스테미나 브레이크의 추가 Modifier
	--- @return number attack modifier
	continuous_stamina_action_util.calculate_attack_modifier = function(cs_battle_action, damage_term)
		local stamina_per_second = battle_util.get_number(
			continuous_stamina_action_util.get_stamina_per_second(cs_battle_action)
		)

		return CS.Oak.LuaBattleExtensions.CalculateAtkModBasedContinuousStamina(
			cs_battle_action, damage_term, stamina_per_second
		)
	end

	charge_util = {}

	--- 차지 ui를 세팅
	charge_util.set_ui = function(cs_battle_action, lua_battle_action)
		--- 차지 UI 타입
		local ui_type = CS.Oak.FieldUiType.ManualChargeGauge

		--- UI를 Set 하고 해당 ui가 포함된 Dictionary를 반환
		local ui_dictionary = stage.FieldUIManager:SetUI(cs_battle_action.Character, ui_type)

		lua_battle_action.manual_charge_gauge = ui_dictionary[ui_type]
	end

	--- 차지 ui를 보여주도록
	charge_util.show_ui = function(lua_battle_action, elemental_type)
		if lua_battle_action and lua_battle_action.manual_charge_gauge then
			lua_battle_action.manual_charge_gauge:ShowUI(elemental_type)
		end
	end

	--- 차지 ui 레벨을 세팅
	charge_util.change_charge_level = function(lua_battle_action, level)
		if lua_battle_action and lua_battle_action.manual_charge_gauge then
			lua_battle_action.manual_charge_gauge:ChangeChargeLevel(level - 1)
		end
	end

	--- 차지 ui를 숨기도록
	charge_util.hide_ui = function(lua_battle_action)
		if lua_battle_action and lua_battle_action.manual_charge_gauge then
			lua_battle_action.manual_charge_gauge:HideUI()
		end
	end

	--- 차지 ui 업데이트
	charge_util.update_charge_gauge = function(
		lua_battle_action,
		old_time_passed, time_passed, dt
	)
		if lua_battle_action and lua_battle_action.manual_charge_gauge then
			local charge_duration = math.min(lua_battle_action.max_charge_duration, time_passed)
			local percent = unity_class.mathf.RoundToInt((lua_battle_action.attack_duration + charge_duration) * 100)

			lua_battle_action.manual_charge_gauge:UpdateFrame(dt)
			lua_battle_action.manual_charge_gauge:SetNumber(percent)

			if battle_util.check_time_passed(old_time_passed, time_passed, lua_battle_action.max_charge_duration) then
				lua_battle_action.manual_charge_gauge:SetMaxChargingUI()
			end
		end
	end

	--- [LuaBattleExtensions] 차지 시간, 공격 시간을 고려해 이 배틀액션의 DPS 가 여타 메뉴얼 배틀액션들과 동일하도록 공격당 Attack modifier 를 계산해 리턴
	--- @param current_charge_duration number 현재 차지한 시간
	--- @param max_charge_duration number 최대 차지 시간
	--- @param attack_duration number 공격 시간
	--- @return number attack modifier
	charge_util.calculate_atk_modifier = function(
		cs_battle_action, current_charge_duration, max_charge_duration, attack_duration
	)
		return CS.Oak.LuaBattleExtensions.CalculateAtkModBasedChargeAction(
			cs_battle_action, current_charge_duration, max_charge_duration, attack_duration
		)
	end

	--- 멀티 모드 액션이 사용할 유틸
	multi_mode_util = {}

	--- 배틀액션 Multi Mode 관련 param 데이터를 자동으로 가져오고 해당 데이터를 CS액션에 할당
	--- 데이터 세팅을 따로하는 이유는 상황에 따라 데이터를 다른 파라미터(옵션 등)에서 가져와야 하기 때문
	multi_mode_util.setup_action = function(cs_battle_action, param)
		local num_modes = cs_util.get_int_from_dictionary(param, 'NumModes')

		cs_battle_action:SetupAction(num_modes)
	end

	multi_mode_util.set_mode = function(cs_battle_action, mode)
		cs_battle_action:SetMode(mode - 1)
	end

	multi_mode_util.get_current_mode = function(cs_battle_action)
		return cs_battle_action:GetCurrentMode() + 1
	end

	multi_mode_util.get_num_modes = function(cs_battle_action)
		return cs_battle_action:GetNumModes()
	end

	--- 역할 액션이 사용할 유틸
	role_util = {}

	--- 배틀액션 Role 관련 param 데이터를 자동으로 가져오고 해당 데이터를 CS액션에 할당
	--- 데이터 세팅을 따로하는 이유는 상황에 따라 데이터를 다른 파라미터(옵션 등)에서 가져와야 하기 때문
	role_util.setup_role_action = function(cs_battle_action, param)
		local use_count = cs_util.get_int_from_dictionary(param, 'UseCount')
		local cool_time = cs_util.get_int_from_dictionary(param, 'CoolTime')
		local role = cs_util.get_string_from_dictionary(param, 'Role')
		local max_hit = cs_util.get_int_from_dictionary(param, 'MaxHitCount')
		local targeting_role = cs_util.get_string_from_dictionary(param, 'TargetingRole')
		local use_left_decrement = CS.Utils.GetIntFromDictionary(param, 'UseLeftDecrement', 1)

		cs_battle_action:SetupRoleAction(use_count, cool_time, role, max_hit, targeting_role, use_left_decrement)
	end

	--- 배틀액션 Role 관련 데이터를 CS액션에 할당
	role_util.setup_role_action_directly = function(cs_battle_action, use_count, cool_time, role, max_hit, targeting_role, use_left_decrement)
		cs_battle_action:SetupRoleAction(
			lua_helper.get_or_default(use_count, 0),
			lua_helper.get_or_default(cool_time, 0),
			lua_helper.get_or_default(role, ''),
			lua_helper.get_or_default(max_hit, 0),
			lua_helper.get_or_default(targeting_role, ''),
			lua_helper.get_or_default(use_left_decrement, 1)
		)
	end

	--- HitCount 사용하는 배틀액션에서 카은트를 증가시킴
	role_util.increase_hit_count = function(cs_battle_action, amount)
		CS.Oak.IRoleBattleActionExtensions.IncreaseHitCount(cs_battle_action, lua_helper.get_or_default(amount, 1))
	end

	--- 롤 액션의 현재 UseLeft를 반환
	--- HitCount를 사용하는 경우 HitCount / MaxHitCount를 대신 반환한다.
	role_util.get_use_left = function(cs_battle_action)
		return CS.Oak.IRoleBattleActionExtensions.GetUseLeft(cs_battle_action)
	end

	--- 롤 액션의 현재 HitCount를 반환
	--- HitCount 를 사용하지 않다면 의미가 없다.
	role_util.get_hit_count = function(cs_battle_action)
		return CS.Oak.IRoleBattleActionExtensions.GetHitCount(cs_battle_action)
	end

	--- 롤 액션의 UseLeft를 증가
	--- HitCount를 사용하는 경우 HitCount를 amount * MaxHitCount만큼 증가한다.
	role_util.increase_use_left = function(cs_battle_action, amount)
		CS.Oak.IRoleBattleActionExtensions.IncreaseUseLeft(cs_battle_action, lua_helper.get_or_default(amount, 1))
	end

	--- 롤 액션의 UseLeft를 감소
	--- HitCount를 사용하는 경우는 HitCount를 amount * MaxHitCount만큼 감소한다.
	role_util.decrease_use_left = function(cs_battle_action, amount)
		CS.Oak.IRoleBattleActionExtensions.DecreaseUseLeft(cs_battle_action, lua_helper.get_or_default(amount, 1))
	end

	--- 롤 액션의 쿨타임을 해당 dt만큼 업데이트 함
	-- TODO : Charge 유형의 경우 비 전투 상황에선 적용할 수가 없다. 따로 분기처리 등이 필요할 듯
	role_util.update_cool_time = function(cs_action, dt)
		CS.Oak.IRoleBattleActionExtensions.UpdateCooltime(cs_action, dt)
	end

	myth_util = {}

	myth_util.has_valid_myth_option = function(param, owner, option_id)

		if option_id == nil then
			option_id = cs_util.get_int_from_dictionary(param, 'MythOptionId')
		end

		return battle_util.has_valid_option(option_id, owner)
	end

	myth_util.get_prefix_key = function(param, owner, option_id)

		if myth_util.has_valid_myth_option(param, owner, option_id) then
			return 'Myth'
		else
			return ''
		end
	end

	--- 배틀액션 Role 관련 param 데이터를 자동으로 가져오고 해당 데이터를 CS액션에 할당
	--- 데이터 세팅을 따로하는 이유는 상황에 따라 데이터를 다른 파라미터(옵션 등)에서 가져와야 하기 때문
	myth_util.setup_myth_action = function(cs_battle_action, param)
		local cool_time = cs_util.get_int_from_dictionary(param, 'CoolTime')

		cs_battle_action:SetupMythAction(cool_time)
	end

	--- 배틀액션 Role 관련 데이터를 CS액션에 할당
	myth_util.setup_myth_action_directly = function(cs_battle_action, cool_time)
		cs_battle_action:SetupMythAction(
				lua_helper.get_or_default(use_count, 0),
				lua_helper.get_or_default(cool_time, 0),
				lua_helper.get_or_default(role, ''),
				lua_helper.get_or_default(max_hit, 0),
				lua_helper.get_or_default(targeting_role, ''),
				lua_helper.get_or_default(use_left_decrement, 1)
		)
	end

	spine_util = {}

	--- 해당 캐릭터의 스파인 컨트롤러를 반환
	--- @param owner any Character 스파인 컨트롤러를 가진 캐릭터
	spine_util.get_spine_controller = function(owner)
		local spine_controller = owner.SpineController

		if not is_unity_null(spine_controller) then
			return spine_controller
		end

		if CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(owner, typeof(CS.UnityEngine.Component)) then
			return owner:GetComponent(typeof(CS.Oak.SpineController))
		end

		return nil
	end

	--- 해당 캐릭터의 스파인 컨테이너를 반환
	--- 해당 캐릭터가 스파인 컨테이너를 가지고 있지 않으면 그냥 Transform을 반환한다.
	--- see also: IFieldObjectExtensions.GetTransform(true)
	--- @param owner any Character 스파인 컨트롤러를 가진 캐릭터
	spine_util.get_spine_container = function(owner)
		local controller = spine_util.get_spine_controller(owner)

		if not is_unity_null(controller) then
			return controller.SpineContainerTransform
		end

		local cached_transform = owner.Transform

		if not is_unity_null(cached_transform) then
			return cached_transform
		end

		local go = owner.UnityGameObject

		if not is_unity_null(go) then
			return go.transform
		end

		return nil
	end

	--- 해당 캐릭터의 스파인 컨테이너의 active 여부를 가져옴
	--- @param ignore_hierarchy boolean 참인 경우 activeInHierarchy 대신 activeSelf로 반환함
	spine_util.get_spine_container_active = function(owner, ignore_hierarchy)
		local container = spine_util.get_spine_container(owner)

		--- 컨테이너가 없다면 무조건 false
		if not container then
			return false
		end

		local container_go = container.gameObject
		ignore_hierarchy = lua_helper.get_or_default(ignore_hierarchy, false)

		if ignore_hierarchy then
			return container_go.activeSelf
		else
			return container_go.activeInHierarchy
		end
	end

	--- 해당 캐릭터의 현재 스켈레톤 애니메이션을 반환 (현재 방향)
	--- @param owner any Character 스파인 컨트롤러를 가진 캐릭터
	spine_util.get_skeleton_animation = function(owner)
		return spine_util.get_spine_controller(owner).SkeletonAnimation
	end

	--- 해당 캐릭터의 스파인의 오프셋을 반환받는다.
	--- 필드 오브젝트 포지션 변화는 없지만 스파인만 위치가 바뀔 경우 이걸로 반환받아 더해주면 된다.
	--- @param owner any Character 스파인 컨트롤러를 가진 캐릭터
	spine_util.get_spine_total_offset = function(owner)
		return spine_util.get_spine_controller(owner).SpineTotalOffset
	end

	--- 스파인 컨트롤러에서 해당 슬롯을 가져옴
	--- @param owner any Character 스파인 컨트롤러를 가진 캐릭터
	spine_util.get_slot = function(owner, slot_name)
		local spine_controller = spine_util.get_spine_controller(owner)
		return CS.Oak.SpineControllerExtensions.GetSlot(spine_controller, slot_name)
	end

	--- 해당 방향에 해당 애니메이션이 있는지 판단해주는 유틸
	--- @param owner any Character 스파인 컨트롤러를 가진 캐릭터
	--- @param animation_name string 애니메이션 이름
	--- @param direction any Direction 스파인 방향
	spine_util.has_animation = function(owner, animation_name, direction)
		local spine_controller = spine_util.get_spine_controller(owner)
		return spine_controller:HasAnimation(animation_name, direction)
	end

	spine_util.set_aim_point = function(owner, aim_world_pos, pivot_world_pos)
		local point = CS.Oak.IKSupportUtil.GetAimPointInSpineSpace(aim_world_pos, pivot_world_pos)

		spine_util.get_spine_controller(owner).AimPoint = point
	end

	--- 해당 방향에 해당 애니메이션이 있는지 판단해주는 유틸
	--- @param owner any Character 스파인 컨트롤러를 가진 캐릭터
	--- @param animation_name string 애니메이션 이름
	spine_util.get_animation_duration = function(owner, animation_name)
		local spine_controller = spine_util.get_spine_controller(owner)

		return CS.Oak.SpineControllerExtensions.GetAnimationDuration(spine_controller, animation_name)
	end

	--- 스파인 콜백을 검증해주는 편의 함수
	--- @param cs_battle_action any 콜백을 구현한 C# 배틀액션
	--- @param track_entry any 해당 콜백을 호출한 TrackEntry
	--- @param track_index any 애니메이션 Track
	--- @param animation_name string 애니메이션 이름
	spine_util.is_variable_callback = function(cs_battle_action, track_entry, track_index, animation_name)
		return CS.Oak.SuperBaseActionExtensions.IsVariableSpineCallback(cs_battle_action, track_entry, track_index, animation_name)
	end

	--- 스파인 sub idle 애니메이션을 재생해주는 편의 함수
	--- @param owner any 스파인 컨트롤러를 가진 객체
	spine_util.set_spine_sub_idle_anim = function(owner)
		spine_util.set_sub_idle_anim(spine_util.get_spine_controller(owner))
	end

	--- 스파인 sub idle 애니메이션을 재생해주는 편의 함수
	--- 캐릭터라면 반드시 이것 대신에 battle_util.set_sub_anim 등으로 처리할 것
	--- @param spine_controller any 스파인 컨트롤러
	spine_util.set_sub_idle_anim = function(spine_controller)
		--- 스파인 컨트롤러 체크
		if spine_controller == nil then
			CS.UnityEngine.Debug.LogError('spine controller is nil')
		end

		--- sub idle 애니메이션 세팅
		CS.Oak.SpineControllerExtensions.SetSubIdleAnimation(spine_controller)
	end

	--- 스파인 애니메이션 설정
	--- @param spine_controller any 스파인 컨트롤러
	--- @param track any spine_animation_track의 트랙
	--- @param animation_name string 애니메이션 이름
	--- @param loop boolean 루프 여부
	--- @param time_scale number 애니메이션 스케일
	--- @param mix_duration number 믹스 시간
	spine_util.set_track_animation = function(spine_controller, track, animation_name, loop, time_scale, mix_duration)
		--- 스파인 컨트롤러 체크
		if spine_controller == nil then
			CS.UnityEngine.Debug.LogError('spine controller is nil')
		end

		--- 트랙 넘버
		local track_index = CS.System.Convert.ToInt32(track)
		time_scale = time_scale or 1
		--- 스파인 애니메이션 설정
		spine_controller:SetAnimation(track_index, animation_name, loop, time_scale)
	end

	--- 해당 트랙을 clear 처리함
	--- @param spine_controller any 스파인 컨트롤러
	--- @param track any spine_animation_track의 트랙
	spine_util.clear_track = function(spine_controller, track)
		--- 스파인 컨트롤러 체크
		if spine_controller == nil then
			CS.UnityEngine.Debug.LogError('spine controller is nil')
		end

		--- 트랙 넘버
		local track_index = CS.System.Convert.ToInt32(track)
		--- 해당 트랙을 clear 처리함
		spine_controller:ClearTrack(track_index)
	end

	--- 스파인 알파 페이드 세팅
	--- @param spine_controller any 스파인 컨트롤러
	--- @param alpha number 목표 알파
	--- @param duration number 시간
	spine_util.set_spine_alpha_fade = function(owner, alpha, duration)
		spine_util.set_alpha_fade(spine_util.get_spine_controller(owner), alpha, duration)
	end

	--- 스파인 알파 페이드 세팅
	--- @param spine_controller any 스파인 컨트롤러
	--- @param alpha number 목표 알파
	--- @param duration number 시간
	spine_util.set_alpha_fade = function(spine_controller, alpha, duration)
		--- 스파인 컨트롤러 체크
		if spine_controller == nil then
			CS.UnityEngine.Debug.LogError('spine controller is nil')
		end

		--- 스파인 알파 페이드 세팅
		spine_controller:SetAlphaFade(alpha, duration)
	end

	--- 스파인 오프셋 세팅
	--- @param spine_controller any 스파인 컨트롤러
	--- @param offset any Vector3 오프셋 벡터
	spine_util.set_spine_offset = function(spine_controller, offset)
		--- 스파인 컨트롤러 체크
		if spine_controller == nil then
			CS.UnityEngine.Debug.LogError('spine controller is nil')
		end

		--- 스파인 오프셋 세팅
		spine_controller.SpineOffset = offset
	end

	--- 스파인 컨트롤러 내용 교체
	--- 주어진 새 컨트롤러에서 스파인을 빼서 현재 컨트롤러에 넣어주는 방식이므로 새 컨트롤러는 사용불가능한 상태가 된다.
	--- 원본은 내용물은 파괴된다.
	--- @param spine_controller any 스파인 컨트롤러
	--- @param new_controller any 새로운 스파인 컨트롤러
	spine_util.switch_spine_controller = function(spine_controller, new_controller)
		--- 스파인 컨트롤러 체크
		if spine_controller == nil or new_controller == nil then
			CS.UnityEngine.Debug.LogError('spine controller is nil')
		end

		--- 스파인 컨트롤러 내용 교체
		spine_controller:SwitchSpineController(new_controller)
	end

	--- 프로젝타일 등을 쏜 반동 애니메이션 타입 1. 캐릭터가 크게 뒤로 젖혀진다. fx형 spine에서도 쓸 수 있도록 추가
	--- @param shoot_dir any 발사 벡터. 반동벡터는 내부적으로 자동으로 반대로 처리해줌.
	--- @param deviate_dist number 반동 거리
	--- @param jump_height number 반동시 공중으로 뜨는 정도
	--- @param duration number 반동 연출의 총 시간
	--- @param angle number 뒤로 재껴지는 연출을 할 각도.
	spine_util.recoil_type_1 = function(
		spine_controller, shoot_dir, deviate_dist, jump_height, duration, angle
	)
		deviate_dist = lua_helper.get_or_default(deviate_dist, 0.2)
		jump_height = lua_helper.get_or_default(jump_height, 0.2)
		duration = lua_helper.get_or_default(duration, 0.3)
		angle = lua_helper.get_or_default(angle, 8)

		CS.Oak.SpineControllerExtensions.RecoilType1(spine_controller, shoot_dir, deviate_dist, jump_height, duration, angle)
	end

	--- RecoilType1에서 사용한 spine 내부 연출을 모두 취소
	spine_util.cancel_recoil_type_1 = function(spine_controller)
		CS.Oak.SpineControllerExtensions.CancelRecoilType1(spine_controller)
	end

	--- 이펙트 관련 유틸
	effect_util = {}

	effect_util.instantiate_effect = function(
		preset, position, rot, transform, flag, owner
	)
		local pool

		if type_util.is_string(preset) then
			pool = unity_object_pool.GetOrCreate(preset)
		else
			pool = preset
		end

		rot = lua_helper.get_or_default(rot, unity_class.vector3.zero)
		flag = lua_helper.get_or_default(flag, CS.Oak.ParentFollowFlag.PositionAndRotation)

		if lua_helper.type_compare(rot, unity_class.vector3) then
			return object_pool_extensions.Instantiate(
				pool, position, rot, transform, flag, owner
			)
		elseif lua_helper.type_compare(rot, unity_class.quaternion) then
			return pool:Instantiate(
				position, rot, transform, flag, owner
			)
		end
	end

	effect_util.update_object = function(
		pooled_unity_object, position, direction
	)
		if pooled_unity_object then
			direction = lua_helper.get_or_default(direction, unity_class.vector3.zero)

			object_pool_extensions.UpdateObject(pooled_unity_object, position, direction)
		end
	end

	--- 이펙트를 타입에 따라 dispose 시킴
	--- @param is_immediate boolean 타입에 상관없이 dispose 시킬 것인가
	effect_util.dispose_via_type = function(
		pooled_unity_object, is_immediate
	)
		if pooled_unity_object then
			is_immediate = lua_helper.get_or_default(is_immediate, false)

			object_pool_extensions.DisposeViaType(pooled_unity_object, is_immediate)
		end
	end

	--- 익펙트의 active 상태를 변경함
	--- disposing type이 OnDisabled인 경우 풀에 반활될 수 있으니 주의할 것
	effect_util.change_active_self = function(pooled_unity_object, active_flag)
		if pooled_unity_object then
			pooled_unity_object.gameObject:SetActive(active_flag)
		end
	end

	--- sfx 관련 유틸
	sfx_util = {}

	--- 해당 오디오 소스 홀더를 페이드 시켜줌
	--- @param audio_source_holder any 페이드 시킬 오디오 소스 홀더
	--- @param duration number 페이드 시킬 시간
	sfx_util.fade_out = function(audio_source_holder, duration)
		if audio_source_holder and audio_source_holder.IsUsing then
			audio_source_holder:FadeOut(duration)
		end
	end

	--- 해당 오디오 소스 홀더의 소스의 위치를 옮긴다
	--- @param audio_source_holder any 위치를 옮길 오디오 소스 홀더
	--- @param position any 옮길 위치
	sfx_util.set_position = function(audio_source_holder, position)
		if audio_source_holder and audio_source_holder.IsUsing then
			audio_source_holder:SetPosition(position)
		end
	end

	trigger_info_util = {}

	--- 기본적인 트리거 정보를 생성
	trigger_info_util.create_default = function(owner)
		return CS.Oak.BattleActionTriggerInfo.CreateDefault(owner)
	end

	--- 트리거 정보에 위치 정보를 Append
	trigger_info_util.append_position = function(info, position)
		if position then
			info:AppendPosition(position)
		end
	end

	--- 트리거 정보에 방향(Vector3) 정보를 Append
	trigger_info_util.append_direction = function(info, direction)
		if direction then
			info:AppendDirection(direction)
		end
	end

	--- 트리거 정보에 타겟 정보를 Append
	trigger_info_util.append_target = function(info, target)
		if target then
			info:AppendTarget(target)
		end
	end

	--- 트리거 정보에 실수 정보를 Append
	trigger_info_util.append_number = function(info, number)
		if number then
			info:AppendNumber(number)
		end
	end

	--- 트리거 정보에 정수 정보를 Append
	trigger_info_util.append_integer = function(info, number)
		if number then
			info:AppendInteger(number)
		end
	end

	--- 트리거 정보의 트리거 위치를 가져옴
	trigger_info_util.get_trigger_pos = function(info)
		return info.TriggerPosition
	end

	--- 트리거 정보의 index 번째 위치를 가져옴
	trigger_info_util.get_position_at = function(info, index)
		return info:GetPositionAt(index or 0)
	end

	--- 트리거 정보의 index 번째 방향을 가져옴
	trigger_info_util.get_direction_at = function(info, index)
		return info:GetDirectionAt(index or 0)
	end

	--- 트리거 정보의 index 번째 대상을 가져옴
	trigger_info_util.get_target_at = function(info, index)
		return info:GetTargetAt(index or 0)
	end

	--- 트리거 정보의 index 번째 실수값을 가져옴
	--- @return number index 번째 실수값
	trigger_info_util.get_number_at = function(info, index)
		return info:GetNumberAt(index or 0)
	end

	--- 트리거 정보의 index 번째 정수값을 가져옴
	--- @return number index 번째 정수값
	trigger_info_util.get_integer_at = function(info, index)
		return info:GetIntegerAt(index or 0)
	end

	--- 트리거 정보의 위치 리스트의 크기를 가져옴
	--- @return number 방향 리스트의 크기
	trigger_info_util.get_position_count = function(info)
		if info.Positions then
			return info.Positions.Count
		end

		return 0
	end

	--- 트리거 정보의 방향 리스트의 크기를 가져옴
	--- @return number 방향 리스트의 크기
	trigger_info_util.get_direction_count = function(info)
		if info.Directions then
			return info.Directions.Count
		end

		return 0
	end

	--- 트리거 정보의 타겟 리스트를 루아 테이블 형태로 반환
	trigger_info_util.get_targets = function(info)
		local targets = {}
		if info.Targets then
			for idx = 0, info.Targets.Count - 1 do
				table.insert(targets, info.Targets[idx])
			end
		end

		return targets
	end

	--- 트리거 정보의 타겟 리스트의 크기를 가져옴
	--- @return number 방향 리스트의 크기
	trigger_info_util.get_target_count = function(info)
		if info.Targets then
			return info.Targets.Count
		end

		return 0
	end

	--- 트리거 정보의 실수값 리스트의 크기를 가져옴
	--- @return number 실수값 리스트의 크기
	trigger_info_util.get_number_count = function(info)
		if info.Numbers then
			return info.Numbers.Count
		end

		return 0
	end

	--- 트리거 정보의 정수값 리스트의 크기를 가져옴
	--- @return number 정수값 리스트의 크기
	trigger_info_util.get_integer_count = function(info)
		if info.Integers then
			return info.Integers.Count
		end

		return 0
	end

	--- 트리거 정보에 위치 정보가 포함되어 있는가?
	--- @return boolean 위치가 포함 되어 있는지 여부
	trigger_info_util.contains_position = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.Type, CS.Oak.BattleActionTargetType.Position)
	end

	--- 트리거 정보에 방향 정보가 포함되어 있는가?
	--- @return boolean 방향이 포함 되어 있는지 여부
	trigger_info_util.contains_direction = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.Type, CS.Oak.BattleActionTargetType.Direction)
	end

	--- 트리거 정보에 타겟 정보가 포함되어 있는가?
	--- @return boolean 타겟이 포함 되어 있는지 여부
	trigger_info_util.contains_target = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.Type, CS.Oak.BattleActionTargetType.Target)
	end

	--- 트리거 정보에 실수 정보가 포함되어 있는가?
	--- @return boolean 실수가 포함 되어 있는지 여부
	trigger_info_util.contains_number = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.Type, CS.Oak.BattleActionTargetType.Number)
	end

	--- 트리거 정보에 정수 정보가 포함되어 있는가?
	--- @return boolean 정수가 포함 되어 있는지 여부
	trigger_info_util.contains_integer = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.Type, CS.Oak.BattleActionTargetType.Integer)
	end

	collision_info_util = {}

	--- 원기둥(Cylinder)형태 충돌체 정보 생성
	--- @param radius number 원기둥의 반지름
	--- @param height number 원기둥의 높이
	--- @param duration number 충돌체 판정 길이
	--- @param damage_term number 충돌체 판정 간격
	--- @param hole_radius number 판정을 제외할 내부 반지름
	--- @param is_center_to_bottom boolean 판정의 기준이 바닥 면인지
	collision_info_util.create_cylinder = function(
		radius, height, duration, damage_term, hole_radius, is_center_to_bottom
	)
		local info = CS.Oak.CylinderCollisionInfo()

		info.Radius = radius
		info.HoleRadius = lua_helper.get_or_default(hole_radius, 0)
		info.Height = height
		info.IsCenterToBottom = lua_helper.get_or_default(is_center_to_bottom, false)
		info.Duration, info.DamageTerm = collision_info_util.set_common_variable(duration, damage_term)

		return info
	end

	--- 부채꼴(Pie)형태 충돌체 정보 생성
	--- @param radius number 부채꼴의 반지름
	--- @param angle number 부채꼴의 각
	--- @param height number 부채꼴의 높이
	--- @param duration number 충돌체 판정 길이
	--- @param damage_term number 충돌체 판정 간격
	--- @param hole_radius number 판정을 제외할 내부 반지름
	collision_info_util.create_pie = function(
		radius, angle, height, duration, damage_term, hole_radius
	)
		local info = CS.Oak.PieCollisionInfo()

		info.Radius = radius
		info.HoleRadius = lua_helper.get_or_default(hole_radius, 0)
		info.Angle = angle
		info.Height = height
		info.Duration, info.DamageTerm = collision_info_util.set_common_variable(duration, damage_term)

		return info
	end

	--- 구(Sphere)형태 충돌체 정보 생성
	--- @param radius number 구의 반지름
	--- @param duration number 충돌체 판정 길이
	--- @param damage_term number 충돌체 판정 간격
	collision_info_util.create_sphere = function(radius, duration, damage_term)
		local info = CS.Oak.SphereCollisionInfo()

		info.Radius = radius
		info.Duration, info.DamageTerm = collision_info_util.set_common_variable(duration, damage_term)

		return info
	end

	--- 회전가능한 큐브(Cube)형태 충돌체 정보 생성
	--- @param size any 충돌체의 크기
	--- @param duration number 충돌체 판정 길이
	--- @param damage_term number 충돌체 판정 간격
	--- @param is_center_to_side boolean 충돌체의 판정 중심이 왼쪽 면에 붙어있는가
	collision_info_util.create_rotatable_cube = function(
		size, duration, damage_term, is_center_to_side
	)
		local info = CS.Oak.RotatableCubeCollisionInfo()

		info.Size = size
		info.IsCenterToSide = lua_helper.get_or_default(is_center_to_side, false)
		info.Duration, info.DamageTerm = collision_info_util.set_common_variable(duration, damage_term)

		return info
	end

	--- 회전가능한 다각(Polygon) 기둥 충돌체 정보 생성
	--- 다른 충돌체로 대체가 가능하다면 무조건 그것을 사용해야 함
	collision_info_util.create_polygon_cube = function(points, height, duration, damage_term)
		if #points % 2 ~= 0 then
			return
		end

		local points_list = create_generic_list(unity_class.vector2)

		for index = 1, #points, 2 do
			points_list:Add(vector(points[index], points[index + 1]))
		end

		local info = CS.Oak.PolygonCollisionInfo.Create(points_list, height)

		info.Duration, info.DamageTerm = collision_info_util.set_common_variable(duration, damage_term)

		return info
	end

	collision_info_util.create_donut = function(inner, outer, height, duration, damage_term)
		local info = CS.Oak.DonutCollisionInfo()
		info.InnerRadius = inner
		info.OuterRadius = outer
		info.Height = height
		info.Duration, info.DamageTerm = collision_info_util.set_common_variable(duration, damage_term)

		return info
	end

	collision_info_util.create_arc_donut = function(inner, outer, angle, height, duration, damage_term)
		local info = CS.Oak.ArcDonutCollisionInfo()
		info.InnerRadius = inner
		info.OuterRadius = outer
		info.Angle = angle
		info.Height = height
		info.Duration, info.DamageTerm = collision_info_util.set_common_variable(duration, damage_term)

		return info
	end

	collision_info_util.set_common_variable = function(duration, damage_term)
		return duration or CS.System.Single.MaxValue, damage_term or -1
	end

	area_collision_util = {}

	--- 충돌체 계산기 생성
	--- @param only_hittable_target boolean 공겨 가능한 대상만 판정하는가
	--- @param delay number 첫 판정까지 지연시간
	--- @param max_hit number 명시적으로 지정된 최대 히트 수
	area_collision_util.create = function(
		attacker, info, only_hittable_target, delay, max_hit, only_friendly_target
	)
		only_hittable_target = lua_helper.get_or_default(only_hittable_target, true)
		delay = lua_helper.get_or_default(delay, 0)
		max_hit = lua_helper.get_or_default(max_hit, 0)
		only_friendly_target = lua_helper.get_or_default(only_friendly_target, false)

		return CS.Oak.AreaBattleCollision(attacker, info, only_hittable_target, delay, max_hit, only_friendly_target)
	end

	--- 충돌체 계산기의 위치를 갱신
	area_collision_util.set_position = function(calculator, position)
		calculator.Position = position
	end

	---- 충돌체 계산기의 방향을 갱신
	area_collision_util.set_direction = function(calculator, direction)
		calculator.Direction = direction
	end

	--- 충돌체 계산기에 설정된 방향을 가져오기 위한 유틸 함수
	area_collision_util.get_position = function(calculator)
		return calculator.Position
	end

	--- 충돌체 계산기에 설정된 방향을 가져오기 위한 유틸 함수
	area_collision_util.get_direction = function(calculator)
		return calculator.Direction
	end

	--- 충돌체 계산기를 시작
	area_collision_util.start = function(calculator)
		calculator:Start()
	end

	--- 공격을 주어진 시간만큼 진행시키고 이번 프레임에 피격당한 타겟의 리스트를 리턴
	--- 반드시 'Dispose'할 것
	--- @param dt number delta time
	area_collision_util.update = function(calculator, dt)
		return calculator:UpdateFrame(dt or 0)
	end

	--- 공격을 주어진 시간만큼 진행시키고 이번 프레임에 피격당한 타겟의 리스트를 리턴
	--- @param dt number delta time
	--- @return table ifo_list를 테이블 형태로 던져줌
	area_collision_util.update_v2 = function(calculator, dt)
		local ifo_table = {}

		local ifo_list = calculator:UpdateFrame(dt or 0)

		for _, ifo in pairs(ifo_list) do
			table.insert(ifo_table, ifo)
		end

		--- PooledSortedList dispose
		ifo_list:Dispose()

		return ifo_table
	end

	--- 충돌체 계산기를 종료
	area_collision_util.calc_end = function(calculator)
		calculator:End()
	end

	--- 충돌체 계산기가 시작되었는지
	--- ** 시간이 모두 지났어도 End 호출 전까진 진행중인 것으로 판단 **
	area_collision_util.is_started = function(calculator)
		return calculator.IsStarted
	end

	--- 현재 공격이 완료되었는지
	area_collision_util.is_finished = function(calculator)
		return calculator.IsFinished
	end

	--- 해당 충돌체 계산기의 MaxHit을 가져옴
	area_collision_util.get_max_hit = function(calculator)
		return calculator.MaxNumHits
	end

	--- 대상이 해당 충돌체 계산기에 처음 판정된 것인지 반환
	area_collision_util.is_first_hit = function(calculator, target)
		local hit_count = calculator:GetHitCount(target)
		return hit_count == 1
	end

	--- 해당 대상에 대한 이번 공격이 마지막 공격인지 여부 (= 더 때릴 수 있다면 false)
	area_collision_util.is_last_hit = function(calculator, target)
		return calculator:IsLastHit(target)
	end

	--- hit_timing 판정 식 처리를 하나로 묶은 유틸 함수
	--- 특정 타이밍에 한 프레임 동안의 판정을 처리가 필요한 경우 사용
	--- 로직 특성상 죽복 체크는 되지 않으니 주의할 것
	area_collision_util.calculate_once = function(calculator, position, direction)
		--- 판정 위치 설정
		area_collision_util.set_position(calculator, position)
		--- 판정 방향 설정 (유효한 경우에만 처리한다)
		if direction then
			area_collision_util.set_direction(calculator, direction)
		end
		--- 판정 시작
		area_collision_util.start(calculator)
		--- 판정 처리
		local fo_list = area_collision_util.update_v2(calculator)
		--- 판정 종료
		area_collision_util.calc_end(calculator)

		--- 판정된 대상 목록을 반환한다.
		return fo_list
	end

	shoot_helper_util = {}

	--- 주어진 타겟을 공격할 수 있는지 반환해주는 함수
	--- @return boolean 탄이 타겟에게 도달할 수 있는지
	shoot_helper_util.is_hittable = function(shoot_helper, target)
		return shoot_helper:IsHittable(target)
	end

	--- 지정된 위치에서 주어진 방향으로 프로젝타일 패턴을 쏨
	--- @param label number 탄환에 식별자가 필요할 경우를 위한 interger label
	--- @param distance number Cannon 타입일 경우 발사체가 날아갈 거리
	--- @param target_to_follow any ifo 호밍을 한다면 대상
	--- @param calculate_inner_target boolean
	shoot_helper_util.shoot_direction_at_position = function(shoot_helper,
		shoot_pos, target_direction_vector, label,
		distance, target_to_follow, calculate_inner_target,
		attack_modifier, target_pos
	)
		--- get default value
		label = lua_helper.get_or_default(label, 0)
		distance = lua_helper.get_or_default(distance, 0)
		calculate_inner_target = lua_helper.get_or_default(calculate_inner_target, true)
		attack_modifier = lua_helper.get_or_default(attack_modifier, 0)

		if target_pos == nil then
			--- shoot projectile
			shoot_helper:ShootDirectionAtPosition(
				shoot_pos, target_direction_vector,
				label, distance, target_to_follow, calculate_inner_target, attack_modifier
			)
		else
			--- shoot projectile
			shoot_helper:ShootDirectionAtPosition(
				shoot_pos, target_direction_vector,
				label, distance, target_to_follow, calculate_inner_target, attack_modifier, target_pos
			)
		end
	end

	--- 피탄시의 기본적인 처리, 특이사항이 없으면 이 함수를 부르면 된다.
	--- 영웅은 주로 사용하지 않고, 개별 구현한다.
	--- @param hitInfo any 프로젝타일 충돌 정보
	shoot_helper_util.general_on_hit = function(shoot_helper, hit_info)
		shoot_helper:OnHit(hit_info)
	end

	projectile_spec_util = {}

	--- 프로젝타일의 최대 이동거리
	projectile_spec_util.get_max_distance = function(projectile_spec)
		return projectile_spec:GetMaxDistance()
	end

	--- 프로젝타일 스펙 기반 스피드
	projectile_spec_util.get_speed = function(projectile_spec)
		return battle_util.get_number(projectile_spec.Speed)
	end

	--- 프로젝타일 스펙 기반 유도 탄환의 방향 전환 각속도
	projectile_spec_util.get_homing_angular_speed = function(projectile_spec)
		return battle_util.get_number(projectile_spec.HomingAngularSpeed)
	end

	--- 프로젝타일 스펙 기반 폭발 여부
	projectile_spec_util.is_exploding = function(projectile_spec)
		return projectile_spec.IsExploding
	end

	--- 프로젝타일 스펙 기반 폭발 반경
	projectile_spec_util.get_explosion_radius = function(projectile_spec)
		return battle_util.get_number(projectile_spec.ExplosionRadius)
	end

	--- 프로젝타일 스펙 기반 넉백 팩터
	projectile_spec_util.get_knock_back_factor = function(projectile_spec)
		return battle_util.get_number(projectile_spec.KnockBackFactor)
	end

	--- 프로젝타일 스펙 기반 스턴 팩터
	projectile_spec_util.get_stun_factor = function(projectile_spec)
		return battle_util.get_number(projectile_spec.StunFactor)
	end

	--- 프로젝타일 스펙 기반 공격력 계수
	projectile_spec_util.get_attack_modifier = function(projectile_spec)
		return battle_util.get_number(projectile_spec.AttackModifier)
	end

	--- 프로젝타일 스펙 기반 LifeTime
	projectile_spec_util.get_life_time = function(projectile_spec)
		return battle_util.get_number(projectile_spec.Lifetime)
	end

	--- 프로젝타일 스펙 기반 Accel
	projectile_spec_util.get_accel = function(projectile_spec)
		return battle_util.get_number(projectile_spec.Accel)
	end

	--- 프로젝타일 스펙 기반 hit box width
	projectile_spec_util.get_hit_box_width = function(projectile_spec)
		return battle_util.get_number(projectile_spec.HitBoxWidth)
	end

	--- 프로젝타일 스펙 기반 hit box height
	projectile_spec_util.get_hit_box_height = function(projectile_spec)
		return battle_util.get_number(projectile_spec.HitBoxHeight)
	end

	--- 프로젝타일 스펙 기반 pixel to world
	projectile_spec_util.get_p2w = function(projectile_spec)
		return battle_util.get_number(projectile_spec.PixelToWorld)
	end

	--- 프로젝타일 스펙 기반 발사 sfx 생성
	projectile_spec_util.play_shoot_sfx = function(projectile_spec)
		if projectile_spec.ShootSfxName then
			music_player:PlaySfx(projectile_spec.ShootSfxName)
		end
	end

	--- 프로젝타일 스펙 기반 발사 fx, sfx 생성
	projectile_spec_util.instantiate_shoot_fx = function(projectile_spec, shoot_pos, shoot_dir, transform, mute_sfx)
		if lua_helper.get_or_default(mute_sfx, false) == false then
			projectile_spec_util.play_shoot_sfx(projectile_spec)
		end

		if projectile_spec.ShootEffectPreset then
			return effect_util.instantiate_effect(projectile_spec.ShootEffectPreset, shoot_pos, shoot_dir, transform)
		end

		return nil
	end

	--- 프로젝타일 스펙 기반 타격 fx, sfx 생성
	projectile_spec_util.instantiate_proj_hit_fx = function(projectile_spec, hit_pos, direction)
		if projectile_spec.HitPreset then
			effect_util.instantiate_effect(projectile_spec.HitPreset, hit_pos, direction)
		end

		projectile_spec_util.play_hit_sfx(projectile_spec, hit_pos)
	end

	--- 프로젝타일 스펙 기반 타격 프리셋 반환
	projectile_spec_util.get_hit_preset_name = function(projectile_spec)
		return projectile_spec.HitPreset
	end

	--- 프로젝타일 스펙 기반 타격 sfx 생성
	projectile_spec_util.play_hit_sfx = function(projectile_spec, hit_pos)
		if projectile_spec.HitSfxName then
			if hit_pos then
				music_player:PlaySfx(projectile_spec.HitSfxName):SetPosition(hit_pos)
			else
				music_player:PlaySfx(projectile_spec.HitSfxName)
			end
		end
	end

	--- 프로젝타일 스펙 기반 타격 sfx 명칭 반환
	projectile_spec_util.get_hit_sfx_name = function(projectile_spec)
		return projectile_spec.HitSfxName
	end

	--- 프로젝타일 스펙 기반 폭발 fx, sfx 생성
	projectile_spec_util.instantiate_proj_explosion_fx = function(projectile_spec, explosion_pos, direction)
		if projectile_spec.ExplosionPreset then
			effect_util.instantiate_effect(projectile_spec.ExplosionPreset, explosion_pos, direction)
		end

		projectile_spec_util.play_explosion_sfx(projectile_spec, explosion_pos)
	end

	--- 프로젝타일 스펙 기반 폭발 sfx 생성
	projectile_spec_util.play_explosion_sfx = function(projectile_spec, explosion_pos)
		if projectile_spec.ExplosionSfxName then
			if explosion_pos then
				music_player:PlaySfx(projectile_spec.ExplosionSfxName):SetPosition(explosion_pos)
			else
				music_player:PlaySfx(projectile_spec.ExplosionSfxName)
			end
		end
	end

	--- 프로젝타일 스펙 기반 만료 fx, sfx 생성
	projectile_spec_util.instantiate_proj_expire_fx = function(projectile_spec, expire_pos, direction)
		if projectile_spec.ExpirePreset then
			effect_util.instantiate_effect(projectile_spec.ExpirePreset, expire_pos, direction)
		end

		projectile_spec_util.play_expire_sfx(projectile_spec, expire_pos)
	end

	--- 프로젝타일 스펙 기반 폭발 sfx 생성
	projectile_spec_util.play_expire_sfx = function(projectile_spec, expire_pos)
		if projectile_spec.ExpireSfxName then
			if expire_pos then
				music_player:PlaySfx(projectile_spec.ExpireSfxName):SetPosition(expire_pos)
			else
				music_player:PlaySfx(projectile_spec.ExpireSfxName)
			end
		end
	end

	buff_util = {}

	buff_util.get_game_data = function()
		return game_data_service.GetData('BuffData')
	end

	--- Name으로버프 스펙 검색
	buff_util.get_buff_spec_from_name = function(buff_name)
		return buff_util.get_game_data():GetBuffSpecFromName(buff_name)
	end

	--- 파라미터를 파싱하여 버프 정보를 만듬
	buff_util.parse_buff_info = function(param, custom_key)
		--- 구버전 코드 호환
		if custom_key ~= nil and custom_key == false then
			custom_key = 'Debuff'
		else
			custom_key = lua_helper.get_or_default(custom_key, 'Buff')
		end

		local buff_table = {
			--- 버프 이름
			name = cs_util.get_string_from_dictionary(param, custom_key .. 'Name'),
			--- 버프 레벨
			level = cs_util.get_int_from_dictionary(param, custom_key .. 'Level')
		}

		return buff_table
	end

	--- 해당 버프의 스코어 값을 가져온다.
	buff_util.get_score = function(buff_instance)
		return buff_extentions.GetScore(buff_instance)
	end

	--- 해당 버프의 스택 캡을 고려한 버프 스택을 반환
	buff_util.get_buff_stack = function(buff_instance)
		return buff_extentions.GetCurrentBuffStack(buff_instance)
	end

	--- 주어진 버프 스펙 이름으로 버프를 생성해 대상에게 검
	--- @param sender any 버프를 거는 주체
	--- @param target any 버프가 걸릴 대상
	--- @param buff_info table 버프 정보
	--- @param show_effect boolean 버프 이펙트를 보여줄 것인지
	--- @param show_text boolean 버프 텍스트를 보여줄 것인지
	--- @return boolean 버프 부여에 성공했는가
	buff_util.apply_buff_info = function(
		sender, target, buff_info,
		show_effect,  show_text, slot
	)
		return buff_util.apply_buff(sender, target, buff_info.name, buff_info.level, show_effect, show_text, slot)
	end

	--- 주어진 버프 스펙 이름으로 버프를 생성해 대상에게 검
	--- @param sender any 버프를 거는 주체
	--- @param target any 버프가 걸릴 대상
	--- @param name string 버프 스펙 이름
	--- @param level number 버프 레벨
	--- @param show_effect boolean 버프 이펙트를 보여줄 것인지
	--- @param show_text boolean 버프 텍스트를 보여줄 것인지
	--- @return boolean 버프 부여에 성공했는가
	buff_util.apply_buff = function(
		sender, target, name, level,
		show_effect,  show_text, slot
	)
		show_effect = lua_helper.get_or_default(show_effect, false)
		show_text = lua_helper.get_or_default(show_text, false)
		slot = lua_helper.get_or_default(slot, CS.Oak.EquipmentSlot.None)

		return buff_manager:AddBuff(sender, slot, target, name, battle_util.get_number(level), show_effect, show_text)
	end

	--- 주어진 버프 스펙 이름으로 버프를 해제
	--- @param sender any 버프를 거는 주체
	--- @param target any 버프가 걸릴 대상
	--- @param name string 버프 스펙 이름
	buff_util.remove_buff = function(sender, target, name, slot)
		slot = lua_helper.get_or_default(slot, CS.Oak.EquipmentSlot.None)

		buff_manager:RemoveBuff(sender, slot, target, name)
	end

	--- 대상에게서 모든 디버프를 해제
	--- @param sender any 해제 시전 주체
	--- @param target any 해제 받는 대상
	buff_util.cure_all_debuffs = function(sender, target)
		buff_manager:CureAllDebuffs(sender, target)
	end

	--- 대상에게 실드 버프를 사용
	--- @param sender any 실드 시전 주체
	--- @param target any 실드 받는 대상
	--- @param amount number 적용될 실드 양
	--- @return boolean 버프 부여에 성공했는가 (비전투 중 시도 시 버프 부여에 실패한 것으로 취급한다.)
	buff_util.add_shield = function(sender, target, amount, visible, slot)
		visible = lua_helper.get_or_default(visible, true)
		slot = lua_helper.get_or_default(slot, CS.Oak.EquipmentSlot.None)
		return buff_manager:AddShieldBuff(sender, slot, target, CS.System.Convert.ToInt32(amount), visible)
	end

	--- 대상에게 흡혈 실드를 부여
	--- @param sender any 실드 시전 주체
	--- @param target any 실드 받는 대상
	--- @param damage_value number 피해량 (정수형임)
	--- @param ratio number 변환 배율
	--- @return boolean 버프 부여에 성공했는가 (비전투 중 시도 시 버프 부여에 실패한 것으로 취급한다.)
	buff_util.add_drain_shield = function(sender, target, damage_value, ratio, visible, slot)
		ratio = lua_helper.get_or_default(ratio, 1)
		visible = lua_helper.get_or_default(visible, true)
		slot = lua_helper.get_or_default(slot, CS.Oak.EquipmentSlot.None)
		return buff_manager:AddDrainShieldBuff(sender, slot, target, damage_value, ratio, visible)
	end

	--- BuffExpiredEvent로 받은 해제된 버프 목록에 해당 버프가 포함하는지 체크하는 유틸함수
	--- @param buff_id number 체크할 버프의 id
	--- @param buff_expired_event any 받은 BuffExpiredEvent
	buff_util.is_buff_expired = function(buff_id, buff_expired_event)
		--- 해지된 버프 체크
		for _, expired_id in pairs(buff_expired_event.BuffIds) do
			if expired_id == buff_id then
				return true
			end
		end

		return false
	end

	--- 방향 보정 및 hittable 보조를 위한 유틸
	assist_util = {}

	--- collision info의 위치 (혹은 방향)을 갱신
	--- @param info any ICollisionInfo 기반 충돌체 정보
	--- @param center_position any Vector3 충돌체 위치
	--- @param dir_vector any Vector3 충돌체 방향
	assist_util.update_collision_info = function(info, center_position, dir_vector)
		if info and info.Center then
			info.Center = center_position

			if info.Direction then
				info.Direction = dir_vector
			end
		end
	end

	assist_util.get_dir_vector_from_assistant = function(info, owner, find_only_hittable)
		find_only_hittable = lua_helper.get_or_default(find_only_hittable, true)

		local direction = CS.Oak.IBattleActionExtensions.GetDirectionFromAssistant(info, owner, find_only_hittable)

		return direction_util.to_vector3(direction)
	end

	--- 방향 보정을 할때 대상을 공격하는 것이 가능한지?
	assist_util.is_hittable = function(cs_action, info, target)
		return CS.Oak.IBattleActionExtensions.IsHittableAssistant(cs_action, info, target)
	end

	random_util = {}

	random_util.get_random_value = function()
		return CS.UnityEngine.Random.value
	end

	random_util.get_random_int = function(min, max)
		return CS.Utils.GetRandomInt(min, max + 1)
	end

	-- overlap : 중복해서 뽑을 것인지
	-- count : 뽑을 개수
	random_util.get_values_in_array = function(list, data)
		local array
		local is_array = type_util.is_array(list)

		if not is_array and type_util.is_table(list) then
			array = {}

			for _, v in pairs(list) do
				table.insert(array, v)
			end

		elseif is_array then
			array = list
		else
			return
		end

		local overlap = lua_helper.get_value(data, 'overlap', false)
		local count = lua_helper.get_value(data, 'count', 1)

		local pulled_array = {}

		if overlap then
			local remain_array = {}

			local pulled_flag = {}
			for i = 1, count do
				local random_number = random_util.get_random_int(1, #array)
				pulled_array[i] = array[random_number]

				pulled_flag[random_number] = true
			end

			for k, v in pairs(array) do
				if pulled_flag[k] ~= true then
					table.insert(remain_array, v)
				end
			end

			return pulled_array, remain_array

		else
			count = math.min(count, #array)

			for i = 1, count do
				local random_number = random_util.get_random_int(1, #array)
				pulled_array[i] = array[random_number]
				table.remove(array, random_number)
			end

			return pulled_array, array
		end
	end

	coroutine_util = {}

	coroutine_util.wait_coroutines = function(coroutines)
		if coroutines == nil then return end

		local is_array = type_util.is_array(coroutines)
		while true do

			local all_routines_over = true
			if is_array then
				for _, coroutine in ipairs(coroutines) do
					if not coroutine.IsDone then
						all_routines_over = false
					end
				end
			else
				for _, coroutine in pairs(coroutines) do
					if not coroutine.IsDone then
						all_routines_over = false
					end
				end
			end

			if all_routines_over then
				break
			end

			coroutine.yield()
		end
	end

	function try(f, catch_f)
		local status, exception = pcall(f)
		if not status then
			catch_f(exception)
		end
	end

	--self.func(self, ...) or self:func(...) or CS.Oak.Class.Instance:Func(...)
	yield_return = function(object, function_name, ...)
		if object == nil or object[function_name] == nil then return end
		local args = {...}
		local func = object[function_name]

		try(function ()
			coroutine.yield(func(object, table.unpack(args)))
		end, function(e)
			exception_stage_exit("[LUA_Script]" .. e)
		end)
	end

	--func(...) or CS.Oak.Class.Func(...)
	yield_return_func = function(func, ...)
		local args = {...}

		try(function ()
			coroutine.yield(func(table.unpack(args)))
		end, function(e)
			exception_stage_exit(e)
		end)
	end

	function exception_stage_exit(e)
		CS.Oak.LuaScriptEngine.LuaException(get_call_stack() .. "\n" .. debug.traceback(e))
	end

	function check_gen_func(func, ...)
		try(func(table.unpack(...)),function()
			CS.Oak.LuaDebugLogger.LogError("check_gen_func")
		end)
	end

	get_call_stack = function()
		local str = "[LuaScript stack traceback]:"
		--level1 Is This Function
		local level = 1
		while true do
			local info = debug.getinfo(level)
			if not info then break end
			local errorLine = ""
			if info.what == "C" then
				errorLine = string.format("%d: %s", level, "C function")
			elseif info.source == "=(tail call)" then
				errorLine = string.format("%d: %s", level, "Tail call")
			elseif not info.name or info.name == "" then
				errorLine = string.format("%d: %s: %d", level, (info.source or "nil"), (info.currentline or "-1"))
			else
				errorLine = string.format("%d: %s %s: %d", level, (info.name or "nil"), (info.source or "nil"), (info.currentline or "-1"))
			end
			str = str .. "\n[LEVEL]" .. errorLine
			level = level + 1
		end
		return str
	end

	queue = function()
		local out = {}
		local first, last = 0, -1
		out.push = function(item)
			last = last + 1
			out[last] = item
		end
		out.pop = function()
			if first <= last then
				local value = out[first]
				out[first] = nil
				first = first + 1
				return value
			end
		end
		out.iterator = function()
			return function()
				return out.pop()
			end
		end
		out.length = function()
			return (last + 1) - first
		end
		setmetatable(out, {
			__len = function()
				return (last-first+1)
			end,
		})
		return out
	end

	table_util = {}

	-- C++ STL의 std::transform
	-- Python에서의 map
	-- e.g: table_util.map(function(x) return x + 1 end, {1, 2, 3})
	-- => {2, 3, 4}
	table_util.map = function(func, arr)
		local new_array = {}
		for i, v in ipairs(arr) do
			new_array[i] = func(v)
		end
		return new_array
	end

	-- map with multiple argument
	-- e.g: table_util.mapn(function(x, y) return x + y end, {1, 2, 3}, {2, 3, 4})
	-- => {3, 5, 7}
	table_util.mapn = function(func, ...)
		local new_array = {}
		local args = { ... }
		local i = 1
		local arg_length = #args
		while true do
			local arg_list = table_util.map(function(arr) return arr[i] end, args)
			if #arg_list < arg_length then
				return new_array
			end
			new_array[i] = func(table.unpack(arg_list))
			i = i + 1
		end
	end

	-- C++ STL의 std::remove_if
	-- Python에서의 filter
	-- e.g: table_util.remove_if(function(x) return x == 1 end, {1, 2, 3, 4, 5})
	-- => {2, 3, 4, 5}
	table_util.remove_if = function(func, arr)
		local new_array = {}
		for _, v in ipairs(arr) do
			if not func(v) then
				table.insert(new_array, v)
			end
		end

		return new_array
	end

	-- C++ STL의 std::accumulate
	-- Python에서의 reduce
	-- e.g: table_util.reduce(function(x, y) return x + y end, {1, 2, 3, 4, 5})
	-- => 15
	table_util.reduce = function(func, arr)
		local acc
		for k, v in ipairs(arr) do
			if k == 1 then
				acc = v
			else
				acc = func(acc, v)
			end
		end
		return acc
	end

	-- foreach with calling function
	-- For pairs only
	table_util.each_pair = function(func, table)
		for k, v in pairs(table) do
			func(k, v)
		end
	end

	-- foreach with calling function
	-- For ipairs only
	table_util.each_ipair = function(func, table)
		for k, v in ipairs(table) do
			func(k, v)
		end
	end

	table_util.contain_value = function(t, v)
		if t== nil or v == nil then return false end

		if type_util.is_array(t) then
			for _, compare in ipairs(t) do
				if v == compare then
					return true
				end
			end
		else
			for _, compare in pairs(t) do
				if v == compare then
					return true
				end
			end
		end

		return false
	end

	-- lua function util
	func_util = {}

	-- safe navigation and call if flag is true.
	func_util.call_if = function(func, flag, ...)
		if func and flag then
			return func(...)
		else
			return
		end
	end

	--- 파티 유틸
	party_util ={}

	--- 캐릭터의 파티를 가져오는 유틸
	party_util.get_party_for = function(character)
		--- 캐릭터의 파티를 가져옴
		return party_manager:GetPartyFor(character)
	end

	--- 스테이지 멤버를 가져오는 편의 유틸
	party_util.get_stage_members = function(character)
		--- 캐릭터의 파티를 가져옴
		local party = party_util.get_party_for(character)

		return party_util.get_stage_members_of_party(party)
	end

	--- 특정 파티의 스테이지 맴버를 가져오는 편의 유틸
	party_util.get_stage_members_of_party = function(party)
		--- 스테이지 멤버 테이블
		local member_table = {}
		local member_hash = {}

		--- 파티가 존재할때만
		if party ~= nil then
			--- 실제 스테이지 멤버를 가져옴
			local members = party:GetStageMembers()

			--- 멤버 순회
			for _, member in pairs(members) do
				--- 테이블에 넣어줌
				table.insert(member_table, member)
				member_hash[member] = true
			end

			--- PooledList dispose
			members:Dispose()
		end

		return member_table, member_hash
	end

	--- 캐릭터가 스테이지 맴버에 포함 여부에 따라 맴버 목록을 가져오는 유틸
	--- 포함되지 않은 경우 빈 테이블을 넘기는 점은 고려할 것
	party_util.get_members_of_target = function(character)
		--- 멤버 테이블
		local member_table = {}
		local member_hash = {}

		--- 캐릭터의 파티를 가져옴
		local party = party_util.get_party_for(character)

		--- 파티가 존재할때만
		if party ~= nil then
			--- 대상의 맴버들을 가져옴
			local members = party:GetMembersOfTarget(character)

			--- 멤버 순회
			for _, member in pairs(members) do
				--- 테이블에 넣어줌
				table.insert(member_table, member)
				member_hash[member] = true
			end

			--- PooledList dispose
			members:Dispose()
		end

		return member_table, member_hash
	end

	--- 캐릭터가 파티 리더인지 판단하는 유틸
	party_util.is_party_leader = function(character, party)
		--- 파티를 가져옴
		party = party or party_util.get_party_for(character)

		--- 캐릭터와 파티 리더 객체 비교
		return lua_helper.reference_equals(character, party.Leader)
	end

	--- 파티 리더를 가져옴
	party_util.get_party_leader_for = function(character)
		--- 파티 리더 객체 반환
		return party_util.get_party_for(character).Leader
	end

	party_util.is_in_user_party = function(character)
		return party_util.is_in_party(character, CS.Oak.PartyManager.Instance.UserParty)
	end

	--- 파티에 포함되있나 판단
	party_util.is_in_party = function(character, party)
		--- 파티가 없다면 속하지 않은것으로 취급한다.
		if not party then
			return false
		end

		return party:Contains(character)
	end

	--- 스테이지 맴버에 포함되있나 판단.
	party_util.is_in_stage_members = function(character, party)
		--- 파티가 없다면 속하지 않은것으로 취급한다.
		if not party then
			return false
		end

		return party:ContainsInStageMember(character)
	end

	summonable_util = {}

	---@return boolean, number 소환 요청을 하나라도 성공했는가, 그리고 커맨드에 포함된 소환 요청 수를 반환
	summonable_util.summon = function(master, summonable_id, summon_count, summon_pos)
		local pos_list

		if summon_pos then
			pos_list = create_generic_list(unity_class.vector3)

			for _, pos in pairs(summon_pos) do
				pos_list:Add(pos)
			end
		end

		local success_count = stage.SummonableManager:Summon(master, summonable_id, summon_count, pos_list)

		return success_count > 0, success_count
	end

	summonable_util.unsummon = function(character)
		if stage.SummonableManager:IsSummoned(character) then
			if character.DamagedBehaviour then
				character.DamagedBehaviour:SetDead()
			end
		end
	end

	--- 소환수의 주인을 가져옴
	summonable_util.get_master = function(character)
		return stage.SummonableManager:GetMaster(character)
	end

	--- 캐릭터의 소환수들을 가져옴
	summonable_util.get_summonables = function(master)
		--- 소환수 매니저
		local manger = stage.SummonableManager

		--- 소환수 리스트를 받아옴
		local summonable_list = manger:GetSummonables(master)

		local summonable_table = {}

		--- 소환수 리스트가 있다면
		if summonable_list then
			for _, value in pairs(summonable_list) do
				local entity = CS.Oak.LuaBattleExtensions.GetCharacterByEntityId(value)
				table.insert(summonable_table, entity)
			end
		end

		return summonable_table
	end

	--- 캐릭터의 소환수 중 소환된 것들을 가져옴
	summonable_util.get_summmoned = function(master)
		--- 소환수 매니저
		local manger = stage.SummonableManager

		--- 소환수 리스트를 받아옴
		local summonable_list = manger:GetSummonables(master)

		local summonable_table = {}

		--- 소환수 리스트가 있다면
		if summonable_list then
			for _, value in pairs(summonable_list) do
				local entity = CS.Oak.LuaBattleExtensions.GetCharacterByEntityId(value)
				if manger:IsSummoned(entity) then
					table.insert(summonable_table, entity)
				end
			end
		end

		return summonable_table
	end

	--- 해당 소환수가 소환된 상태인지 반환
	summonable_util.is_summoned = function(summonable)
		return stage.SummonableManager:IsSummoned(summonable)
	end

	--- 캐릭터의 소환수 중 소환된 것들을 역소환함
	summonable_util.unsummon_all = function(master)
		CS.Oak.SummonableManager.UnsummonAll(master)
	end

	override_util = {}

	override_util.get_override_info = function(owner, params)
		--- 소환수라면
		if lua_helper.type_compare(owner, CS.Oak.OptionCharacter) then
			--- 마스터의 정보를 가져옴
			owner = summonable_util.get_master(owner)
		end

		--- 코스튬
		local costume = owner.Costume

		--- 코스튬이 있을 경우에 검사
		if costume == nil then return false end

		--- 배틀액션은 Id를 사용하지 않으므로 옵션 파라미터
		local is_battle_action_params = not params:ContainsKey('Id')

		--- 오버라이드 정보에서 사용할 키
		local key, has_value, override_data

		if is_battle_action_params then
			has_value, override_data = CS.Oak.CostumeOverrideData.Value:TryGetBattleActions(costume.CostumeSpec.Id)

			if has_value then
				key = cs_util.get_string_from_dictionary(params, 'Name')
			end
		else
			has_value, override_data = CS.Oak.CostumeOverrideData.Value:TryGetOptions(costume.CostumeSpec.Id)

			if has_value then
				key = tostring(cs_util.get_int_from_dictionary(params, 'Id'))
			end
		end

		local table

		if key ~= nil then
			table = override_data[key]
		end

		return table ~= nil, table
	end

	override_util.get_override_proj_name = function(owner, params, proj_name, custom_key)
		if params == nil then return proj_name end

		local has_value, value = override_util.get_override_info(owner, params)

		if has_value == false then return proj_name end

		custom_key = custom_key and custom_key or 'ProjectileInfo'

		--- 테이블에서 발사체 정보를 가져옴
		local projectile_table = value[custom_key]

		--- 대응하는 발사체 정보가 있다면 오버라이드된 이름 반환
		if projectile_table and projectile_table[proj_name] then
			return projectile_table[proj_name]
		end

		return proj_name
	end

	stop_coroutine = function(c)
		xlua.private_accessible(typeof(CS.Foundations.CoroutineManager))

		local wq = CS.Foundations.CoroutineManager.Instance.waitQueue
		for i = wq.Count - 1, 0, -1 do
			if wq[i] == c then
				wq[i]:Stop()
				wq:RemoveAt(i)
				return
			end
		end

		local stop_wq = CS.Foundations.CoroutineManager.Instance.stopWaitQueue
		stop_wq:Add(c)
	end

	--- 부쉬 유틸
	bush_util = {}

	--- 대상이 부쉬에 숨은 상태인지 판단해주는 유틸
	bush_util.is_hide = function(character)
		return CS.Oak.IFieldObjectExtensions.IsHideInBush(character)
	end

	--- 배틀 매니저 유틸
	battle_manager_util = {}

	--- 객체가 포함된 전투를 가져오는 유틸
	battle_manager_util.get_battle_for = function(ifo, ignore_dead_state)
		--- 죽은 상태를 포함하는가 (디폴트 세팅)
		ignore_dead_state = ignore_dead_state or false

		--- 배틀 매니저 체크, 포함된 전투 반환
		return battle_manager and battle_manager:GetBattleFor(ifo, ignore_dead_state) or nil
	end

	--- 파티의 구성원이 포함된 전투를 가져오는 유틸
	battle_manager_util.get_battle_for_party = function(party, ignore_dead_state)
		--- 죽은 상태를 포함하는가 (디폴트 세팅)
		ignore_dead_state = ignore_dead_state or false

		--- 배틀 매니저 체크, 포함된 전투 반환
		return CS.Oak.LuaBattleExtensions.GetBattleForParty(party, ignore_dead_state)
	end

	--- 특정 id의 전투를 가져오는 유틸
	battle_manager_util.get_battle_by_id = function(instance_id)
		return battle_manager and battle_manager:GetBattleById(instance_id) or nil
	end

	--- 객체가 전투에 포함된 여부를 판단하는 유틸
	battle_manager_util.is_in_battle = function(ifo, battle_instance, ignore_dead_state)
		--- 죽은 상태를 포함하는가 (디폴트 세팅)
		ignore_dead_state = ignore_dead_state or false

		--- 배틀 인스턴스를 기준으로 하는 경우
		if battle_instance then
			--- 객체가 포함된 여부 체크
			return battle_instance:IsInBattle(ifo, ignore_dead_state)
		end

		--- 포함된 전투가 있는지 여부 체크
		return battle_manager_util.get_battle_for(ifo, ignore_dead_state) ~= nil
	end

	--- 파티의 구성원이 포함된 전투의 존재 여부를 판단하는 유틸
	battle_manager_util.is_party_in_battle = function(party, battle_instance, ignore_dead_state)
		--- 죽은 상태를 포함하는가 (디폴트 세팅)
		ignore_dead_state = ignore_dead_state or false

		--- 배틀 인스턴스를 기준으로 하는 경우
		if battle_instance then
			--- 파티가 유효하지 않다면 없는 것으로 취급한다.
			if not party or party.Count == 0 then
				return false
			end

			for idx = 0, party.Count - 1 do
				--- 파티원 포함 여부 체크
				if battle_instance:IsInBattle(party[idx], ignore_dead_state) then
					return true
				end
			end

			--- 아무도 없으면 없는 것
			return false
		end

		--- 포함된 전투가 있는지 여부 체크
		return battle_manager_util.get_battle_for_party(party, ignore_dead_state) ~= nil
	end

	--- 객체가 전투에 포함되있고 전투의 현재 웨이브에 포함되있거나 활성화되있는지 판단하는 유틸
	battle_manager_util.is_in_active_battle = function(ifo)
		return battle_manager and battle_manager:IsCharacterInActiveBattle(ifo)
	end

	--- 전투에 포함된 적들을 가져옴
	battle_manager_util.get_targets = function(ifo, battle_instance)
		--- 타겟 테이블
		local target_table = {}

		--- 전투에 포함된 적 리스트
		local targets

		--- 배틀 인스턴스를 명시한 경우
		if battle_instance then
			--- 해당 인스턴스를 기준으로 적을 가져옴
			targets = battle_instance:GetTargets(ifo, false)
		else
			--- 배틀 매니저에서 인스턴스를 찾아 적을 가져옴
			targets = battle_manager:GetTargets(ifo)
		end

		--- 적이 존재할때
		if targets ~= nil then
			--- 리스트 순회
			for _, each_target in pairs(targets) do
				--- 테이블에 넣어줌
				table.insert(target_table, each_target)
			end

			--- PooledList dispose
			targets:Dispose()
		end

		--- 타겟 테이블 반환
		return target_table
	end

	--- 전투에 포함된 적들에서 가져옴
	--- 실제로 활성중인 웨이브에 포함된 경우에만 목록에 포함됨
	battle_manager_util.get_targets_in_active_battle = function(ifo)
		--- 타겟 테이블
		local target_table = {}

		--- 전투에 포함된 적 리스트
		local targets = battle_manager:GetTargetsInActiveBattle(ifo)

		--- 적이 존재할때
		if targets ~= nil then
			--- 리스트 순회
			for _, each_target in pairs(targets) do
				--- 테이블에 넣어줌
				table.insert(target_table, each_target)
			end

			--- PooledList dispose
			targets:Dispose()
		end

		--- 타겟 테이블 반환
		return target_table
	end

	--- 가까운 아군의 N개를 가져옴
	battle_manager_util.get_closet_friendly_targets = function(ifo, dist, count)
		--- 아군 테이블
		local target_table = {}

		---아군 리스트
		local targets = battle_manager:GetClosetFriendlyTargets(ifo,dist,count)

		--- 아군이 존재할때
		if targets ~= nil then
			--- 리스트 순회
			for _, each_target in pairs(targets) do
				--- 테이블에 넣어줌
				table.insert(target_table, each_target)
			end

			--- PooledList dispose
			targets:Dispose()
		end

		--- 아군 테이블 반환
		return target_table
	end

	--- 전투에 포함된 아군을 가져옴 (자기자신도 포함되있으니 유의할 것)
	--- TODO : BattleManager에 인스턴스 없는 버전 작성해서 대체할 것
	battle_manager_util.get_friendly_targets = function(ifo, battle_instance)
		--- 타겟 테이블
		local target_table = {}

		--- 전투에 포함된 아군 리스트
		local targets

		--- 배틀 인스턴스를 명시한 경우
		if battle_instance then
			--- 해당 인스턴스를 기준으로 적을 가져옴
			targets = battle_instance:GetFriendlyTargets(ifo, false)
		else
			--- 배틀 매니저에서 인스턴스를 찾아 적을 가져옴
			local instance = battle_manager_util.get_battle_for(ifo)
			--- 인스턴스 없는 경우 에러 방지
			if instance ~= nil then
				targets = instance:GetFriendlyTargets(ifo)
			end
		end

		--- 아군이 존재할때
		if targets ~= nil then
			--- 리스트 순회
			for _, each_target in pairs(targets) do
				--- 테이블에 넣어줌
				table.insert(target_table, each_target)
			end

			--- PooledList dispose
			targets:Dispose()
		end

		--- 타겟 테이블 반환
		return target_table
	end

	--- 메세지 시스템 유틸
	message_system_util = {}

	--- 메세지 시스템 인스턴스 캐싱
	message_system_util.instance = CS.Oak.MessageSystem.Instance

	--- 메세지 시스템 이벤트 구독 처리
	message_system_util.subscribe = function(event_class, func)
		--- 메세지 시스템 구독 요청
		message_system_util.instance:Subscribe(event_class, func)
	end

	--- 메세지 시스템 이벤트 구독 해지 처리
	message_system_util.unsubscribe = function(event_class, func)
		--- 메세지 시스템 구독 해지 요청
		message_system_util.instance:Unsubscribe(event_class, func)
	end

	--- 메세지 시스템 이벤트 배포 처리
	message_system_util.publish = function(event)
		message_system_util.instance:Publish(event)
	end

	--- 메세지 시스템 이벤트 즉시 배포 처리
	--- 메세지 루프 중이 아닌 바로 부르는 형태
	message_system_util.publish_sync = function(event)
		message_system_util.instance:PublishSync(event)
	end

	--- 메세지 시스템 이벤트를 리스너에 전달 처리
	message_system_util.send = function(listener, event)
		message_system_util.instance:Send(listener, event)
	end

	--- 메세지 시스템 이벤트를 리스너에 즉시 전달 처리
---	--- 메세지 루프 중이 아닌 바로 부르는 형태
	message_system_util.send_sync = function(listener, event)
		message_system_util.instance:SendSync(listener, event)
	end

	--- 이벤트 캐싱
	event_type = {
		--- 전투 참여 이벤트
		battle_enter = typeof(CS.Oak.BattleEnterEvent),
		--- 전투 이탈 이벤트
		battle_leave = typeof(CS.Oak.BattleLeaveEvent),
		--- 전투 시작 이벤트
		battle_start = typeof(CS.Oak.BattleStartEvent),
		--- 전투 종료 이벤트
		battle_end = typeof(CS.Oak.BattleEndEvent),
		--- 대미지 이벤트
		damage = typeof(CS.Oak.DamageEvent),
		--- 필드 오브젝트 파괴 이벤트
		fo_destroyed = typeof(CS.Oak.FieldObjectDestroyedEvent),
		--- 멀티플레이 페이즈 전환 관련 이벤트
		multiplay_phase_status = typeof(CS.Oak.MultiPlayPhaseStatusEvent),
		--- 버프 추가 이벤트
		buff_add = typeof(CS.Oak.BuffAddEvent),
		--- 버프 만료 이벤트
		buff_expired = typeof(CS.Oak.BuffExpiredEvent),
		--- [아레나] 페이즈 관련 이벤트
		arena_stage_flow_start = typeof(CS.Oak.ArenaStageFlowStartEvent),
		--- [아레나] 페이즈 관련 이벤트
		arena_stage_flow_finish = typeof(CS.Oak.ArenaStageFlowFinishedEvent),
		--- [원정대] 파티 스위칭 이벤트
		party_switching = typeof(CS.Oak.PartySwitchingEvent),
		--- 스테이지 컨트롤 시작 이벤트
		stage_control_start = typeof(CS.Oak.StageControlStartEvent),
		--- 파티원 추가 이벤트
		party_member_added = typeof(CS.Oak.PartyMemberAddedEvent),
		--- 파티원 이탈 이벤트
		party_member_removed = typeof(CS.Oak.PartyMemberRemovedEvent),
		--- [데스매치] 데스매치 리스폰 이벤트. 첫 출전땐 안불림
		death_match_revive = typeof(CS.Oak.DeathMatchCharacterReviveEvent),
		--- 선행 배틀 액션 시전 이벤트
		pre_battle_action_started = typeof(CS.Oak.PreBattleActionStartedEvent),
		--- 배틀 액션 시전 이벤트
		battle_action_started = typeof(CS.Oak.BattleActionStartedEvent),
		--- 소환수 소환 이벤트
		summon_summonable = typeof(CS.Oak.SummonSummonableCharacterEvent),
		--- 소환수 역소환 이벤트
		unsummon_summonable = typeof(CS.Oak.UnsummonSummonableCharacterEvent),
		--- 전투 시작으로 인한 소환수 재활성화 이벤트
		enable_summonable = typeof(CS.Oak.EnableSummonableCharacterEvent),
		--- 전투 종료로 인한 소환수 비활성화 이벤트
		disable_summonable = typeof(CS.Oak.DisableSummonableCharacterEvent),
		--- 회복 이벤트
		heal = typeof(CS.Oak.HealEvent),
		--- 액션 트리거 이벤트
		battle_action_trigger = typeof(CS.Oak.BattleActionTriggerEvent),
		--- 액션 종료 이벤트
		battle_action_finished = typeof(CS.Oak.BattleActionFinishedEvent),
		--- 액션 캔슬 이벤트
		battle_action_cancelled = typeof(CS.Oak.BattleActionCancelledEvent),
	}

	--- 데미지 인포 유틸
	damage_info_util = {}

	--- 데미지 인포에 넘길 값을 저장하기 위한 테이블을 반환한다.
	damage_info_util.create_table = function()
		--- 데미지 정보 페티블
		---@class damage_info_table
		local info_table = {}

		--- 데이지 종류
		info_table.damage_type = nil
		--- 데미지 출처
		info_table.source_type = nil

		--- 데미지를 보낸 오브젝트
		info_table.sender = nil
		--- 데미지를 받은 오브젝트
		info_table.target = nil

		--- sender의 스텟으로부터 공격력을 읽어오는 경우 스텟상 공격력의 몇 배의 데미지를 입히는지
		info_table.modifier = nil
		--- 데미지가 가해진 방향 **유닛** 벡터
		info_table.direction = vector_util.zero

		--- 크리티컬 히트인가
		info_table.critical = nil
		--- 이 값이 true 일 경우 HP를 무조건 1은 남겨둔다.
		info_table.not_mortal = nil
		--- 치명타를 무시할 것인지
		info_table.no_critical = nil

		--- 스턴 판정 용 수치
		info_table.stun_factor = nil
		--- 스턴 판정 성공시 적용할 스턴 길이
		info_table.stun_duration = nil

		--- 넉백 판정용 수치
		info_table.knock_back_factor = nil
		--- 넉백용 방향
		info_table.knock_back_dir = vector_util.zero
		--- 넉백 판정 성공시 작용할 넉백의 힘
		info_table.knock_back_force = nil

		--- 타격 연출에 사용할 클래스
		info_table.hit_effect = nil
		--- 타격 효과음 연출에 사용할 구조체
		info_table.hit_sfx_info = nil

		--- 상태 이상 정보를 가지고 있는 구조체
		info_table.ailment_info = nil
		--- 적용할 상태 이상 게이지 비율
		info_table.ailment_ratio = nil
		--- 상태 이상 수치가 더해지는 것을 강제한다. 방어력을 무시하고 이미 같은 상태 이상이 걸려있는 상태에서도 더한다.
		info_table.force_ailment = nil
		--- 피격 연출을 감추는 기능
		--- 현재는 PhoenixDamagedBehaviour, MonsterDamagedBehaviour에만 적용하였다.
		info_table.hide_damage = nil

		--- 화속성 데미지
		info_table.fire_damage = nil
		--- 수속성 데미지
		info_table.ice_damage = nil
		--- 지속성 데미지
		info_table.earth_damage = nil
		--- 광속성 데미지
		info_table.light_damage = nil
		--- 암속성 데미지
		info_table.dark_damage = nil
		--- 무속성 데미지
		info_table.damage = nil

		--- 부상 상태이상에서 부여할 독 디버프 id
		--- 사용 지양
		info_table.poison_ailment_buff_id = nil

		return info_table
	end

	--- 데미지 인포 테이블에 근접 넉백을 설정해준다.
	--- @param info_table damage_info_table
	damage_info_util.fill_melee_knock_back = function(info_table, force, factor, allow_non_manual)
		force = lua_helper.get_or_default(force, knock_back_constants.standard_melee_force)
		factor = lua_helper.get_or_default(factor, knock_back_constants.factor_normal)
		allow_non_manual = lua_helper.get_or_default(allow_non_manual, false)

		if allow_non_manual or battle_util.is_manual_fo(info_table.sender) then
			--- 넉백용 방향
			info_table.knock_back_dir = info_table.direction
			--- 넉백 판정용 수치
			info_table.knock_back_factor = factor
			--- 넉백 판정 성공시 작용할 넉백의 힘
			info_table.knock_back_force = force
		end

		return info_table
	end

	--- 데미지 인포 테이블에 상태이상을 설정해준다.
	--- 실제로 FillAilmentGauge를 하진 않는다.
	--- @param info_table damage_info_table
	damage_info_util.fill_ailment_gauge = function(info_table, ailment_info, ratio)
		--- 상태이상 정보가 없다면 잘못된 것
		if ailment_info then
			--- 상태 이상 정보를 가지고 있는 구조체
			info_table.ailment_info = ailment_info
			--- 적용할 상태 이상 게이지 비율
			info_table.ailment_ratio = ratio
		end

		return info_table
	end

	--- 유니티 오브젝트 풀 기반 히트 이펙트를 생성
	damage_info_util.create_unity_object_hit_effect = function(lua_action, key, position, direction, follow_flag)
		--- 이펙트 정보가 없다면 생략함
		if lua_action.preset_info and lua_action.preset_info[key] then
			return damage_info_util.create_unity_object_hit_simple(
				lua_action.preset_info[key].PresetName, position, direction, follow_flag
			)
		end

		return nil
	end

	--- 투사체 스펙 기반 히트 이펙트를 생성
	damage_info_util.create_unity_object_hit_projectile = function(projectile_spec, position, direction, follow_flag)
		local preset_name = projectile_spec_util.get_hit_preset_name(projectile_spec)

		if preset_name then
			return damage_info_util.create_unity_object_hit_simple(
				preset_name, position, direction, follow_flag
			)
		end

		return nil
	end

	--- 유니티 오브젝트 풀 기반 히트 이펙트를 생성
	damage_info_util.create_unity_object_hit_simple = function(preset_name, position, direction, follow_flag)
		--- 방향이 있다면 돌아가는 이펙트로 간주한다.
		local rotate_effect = direction ~= nil
		direction = lua_helper.get_or_default(direction, vector_util.zero)
		follow_flag = lua_helper.get_or_default(follow_flag, parent_follow_flag.position)

		return CS.Oak.UnityObjectPoolHitEffect.Create(
			preset_name, position, direction, rotate_effect, follow_flag
		)
	end

	--- 피격음 정보 생성
	damage_info_util.create_hit_sfx_info = function(lua_action, key)
		--- sfx 정보가 없다면 생략함
		if lua_action.sfx_info and lua_action.sfx_info[key] then
			return damage_info_util.create_hit_sfx_simple(lua_action.sfx_info[key].sfxName)
		end

		return nil
	end

	--- 투사체 스펙 기반 피격음 정보 생성
	damage_info_util.create_hit_sfx_projectile = function(projectile_spec)
		local sfx_name = projectile_spec_util.get_hit_sfx_name(projectile_spec)

		if sfx_name then
			return damage_info_util.create_hit_sfx_simple(sfx_name)
		end

		return nil
	end

	--- 피격음 정보 생성
	damage_info_util.create_hit_sfx_simple = function(sfx_name)
		return CS.Oak.HitSfxInfo(false, sfx_name)
	end

	--- 피격음 음소거 정보 생성
	damage_info_util.create_mute_sfx_info = function()
		return CS.Oak.HitSfxInfo(true)
	end

	--- damage_info_util.create_table로 생성한 데미지 인포 테이블을 C# Oak.DamageInfo로 변환해준다.
	--- @param info_table damage_info_table
	damage_info_util.convert_table_to_info = function(info_table)
		local info = CS.Oak.DamageInfo.GenerateDamageFromLua(
			--- 데이지 종류
			info_table.damage_type,
			--- 데미지를 보낸 오브젝트
			info_table.sender,
			--- 데미지를 받은 오브젝트
			info_table.target,

			--- sender의 스텟으로부터 공격력을 읽어오는 경우 스텟상 공격력의 몇 배의 데미지를 입히는지
			info_table.modifier,
			--- 데미지가 가해진 방향 **유닛** 벡터
			info_table.direction,

			--- 크리티컬 히트인가
			info_table.critical,
			--- 이 값이 true 일 경우 HP를 무조건 1은 남겨둔다.
			info_table.not_mortal,
			--- 치명타를 무시할 것인지
			info_table.no_critical,

			--- 스턴 판정 용 수치
			info_table.stun_factor,
			--- 스턴 판정 성공시 적용할 스턴 길이
			info_table.stun_duration,

			--- 넉백 판정용 수치
			info_table.knock_back_factor,
			--- 넉백용 방향
			info_table.knock_back_dir,
			--- 넉백 판정 성공시 작용할 넉백의 힘
			info_table.knock_back_force,

			--- 타격 연출에 사용할 클래스
			info_table.hit_effect,
			--- 타격 효과음 연출에 사용할 구조체
			info_table.hit_sfx_info
		)

		if info_table.source_type then
			info.sourceType = info_table.source_type
		end

		--- 상태이상 정보가 있다면 추가 설정
		if info_table.ailment_info then
			--- 적용할 상태 이상 게이지 비율
			local ratio = lua_helper.get_or_default(info_table.ailment_ratio, 1)
			--- 상태이상 게이지 적용
			info:FillAilmentGauge(info_table.ailment_info, ratio)

			--- 상태 이상 수치가 더해지는 것을 강제한다. 방어력을 무시하고 이미 같은 상태 이상이 걸려있는 상태에서도 더한다.
			if info_table.force_ailment then
				info.forceAilment = info_table.force_ailment
			end
		end

		--- 데미지 감추기
		if info_table.hide_damage then
			info.hideDamage = info_table.hide_damage
		end

		--- 화속성 데미지
		if info_table.fire_damage then
			info.fireDamage = info_table.fire_damage
		end
		--- 수속성 데미지
		if info_table.ice_damage then
			info.iceDamage = info_table.ice_damage
		end
		--- 지속성 데미지
		if info_table.earth_damage then
			info.earthDamage = info_table.earth_damage
		end
		--- 광속성 데미지
		if info_table.light_damage then
			info.lightDamage = info_table.light_damage
		end
		--- 암속성 데미지
		if info_table.dark_damage then
			info.darkDamage = info_table.dark_damage
		end
		--- 무속성 데미지
		if info_table.damage then
			info.damage = info_table.damage
		end

		--- 부상 상태이상에서 부여할 독 디버프 id, 사용 지양할 것
		if info_table.poison_ailment_buff_id then
			info.poisonBuffId = info_table.poison_ailment_buff_id
		end

		return info
	end

	--- 힐 인포 유틸
	-- TODO : 데미지 인포처럼 힐 인포도 테이블 래퍼를 만드는 것이 좋지 않을까...
	heal_info_util = {}

	--- CS.Oak.HealInfo의 힐량을 받아옴
	heal_info_util.get_heal_amount = function(heal_info)
		return heal_info.heal
	end

	--- 옵션 트리거 유틸
	option_trigger_util = {}

	option_trigger_util.create = function()
		--- 트리거 정보 테이블
		---@class option_trigger_table
		local info_table = {}

		--- 옵션의 쇼유자
		info_table.owner = nil
		--- 옵션 id
		info_table.option_id = nil
		--- 목표 위치
		info_table.target_position = nil
		--- 목표 방향
		info_table.target_direction = nil
		--- 목표 ifo
		info_table.target = nil
		--- 목표 실수
		info_table.number = nil
		--- 목표 정수
		info_table.integer = nil

		return info_table
	end

	--- option_trigger_util.create로 생성한 옵션 트리거 인포 테이블을 C# Oak.DamageInfo로 변환해준다.
	--- @param option_trigger_table option_trigger_table
	option_trigger_util.convert_table_to_info = function(option_trigger_table)
		local info_type = CS.Oak.BattleActionTargetType.None

		-- TODO : StageOptionTriggerInfo도 target 레퍼런스를 들고있어서 플래그 설정 및 인포 세팅을 C#쪽에 일임할 수 있도록 할 것.
		--- 옵션 트리거 인포 생성
		local info = CS.Oak.StageOptionTriggerInfo()

		--- 위치 추가
		if option_trigger_table.target_position then
			info_type = info_type | CS.Oak.BattleActionTargetType.Position
			info.targetPosition = option_trigger_table.target_position
		end

		--- 방향 추가
		if option_trigger_table.target_direction then
			info_type = info_type | CS.Oak.BattleActionTargetType.Direction
			info.targetDirection = option_trigger_table.target_direction
		end

		--- 대상 ifo 추가
		if option_trigger_table.target then
			info_type = info_type | CS.Oak.BattleActionTargetType.Target
			info.target = option_trigger_table.target
		end

		--- 실수 추가
		if option_trigger_table.number then
			info_type = info_type | CS.Oak.BattleActionTargetType.Number
			info.number = option_trigger_table.number
		end

		--- 정수 추가
		if option_trigger_table.integer then
			info_type = info_type | CS.Oak.BattleActionTargetType.Integer
			info.integer = option_trigger_table.integer
		end

		--- 타입 최종 할당
		info.type = info_type

		local owner = option_trigger_table.owner
		local option_id = option_trigger_table.option_id
		local cmd = CS.Oak.TriggerStageOptionCommand.CreateWithInfo(owner, option_id, info)

		return cmd
	end

	--- 트리거 정보에 위치 정보가 포함되어 있는가?
	--- @return boolean 위치가 포함 되어 있는지 여부
	option_trigger_util.contains_position = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.type, CS.Oak.BattleActionTargetType.Position)
	end

	--- 트리거 정보에 방향 정보가 포함되어 있는가?
	--- @return boolean 방향이 포함 되어 있는지 여부
	option_trigger_util.contains_direction = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.type, CS.Oak.BattleActionTargetType.Direction)
	end

	--- 트리거 정보에 타겟 정보가 포함되어 있는가?
	--- @return boolean 타겟이 포함 되어 있는지 여부
	option_trigger_util.contains_target = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.type, CS.Oak.BattleActionTargetType.Target)
	end

	--- 트리거 정보에 실수 정보가 포함되어 있는가?
	--- @return boolean 실수가 포함 되어 있는지 여부
	option_trigger_util.contains_number = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.type, CS.Oak.BattleActionTargetType.Number)
	end

	--- 트리거 정보에 정수 정보가 포함되어 있는가?
	--- @return boolean 정수가 포함 되어 있는지 여부
	option_trigger_util.contains_integer = function(info)
		return CS.Oak.BattleActionTargetTypeExtensions.Contains(info.type, CS.Oak.BattleActionTargetType.Integer)
	end

	--- 루아 콜랙션 유틸
	--- 트래킹 편의를 위해 하나의 유틸로 묶는다.
	lua_collection_util = {}

	--- 루아 HashSet 생성자.
	--- 루아 테이블로 의미 없는 Value(true라던지)를 세팅해 사용하고 있었는데, 명시적이지 못해서 주로 쓰는 기능들로 구성
	--- count 연산자 (#) 및 pairs 사용 가능
	--- global_util.lua에서 가져옴
	lua_collection_util.create_hashset = function(...)
		-- private 변수 구현을 위해 UpValue 사용
		local container = {}
		local default_value = true
		local count = 0

		local out = {}

		--- item을 Hashset에 추가.
		---@return boolean 해당 값이 이미 들어가 있다면 false 리턴
		function out:add(item)
			if self:contains(item) then
				return false
			end

			container[item] = default_value
			count = count + 1

			return true
		end

		--- item을 Hashset에서 삭제
		---@return boolean 해당 값이 들어가있지 않았다면 false
		function out:remove(item)
			if not self:contains(item) then
				return false
			end

			container[item] = nil
			count = count - 1

			return true
		end

		--- HashSet이 특정 item을 가지고 있는지
		---@return boolean
		function out:contains(item)
			return container[item] == default_value
		end

		--- 컨테이너 전체 비워줌
		function out:clear()
			battle_util.dispose_action_param(container)
			count = 0
		end

		--- UpValue 까지 완전 해제
		--- 사용 완료 시 (스테이지 나가는 등) 꼭 호출할 것!!
		function out:dispose()
			battle_util.dispose_action_param(container)
			container = nil
			count = nil
			default_value = nil
		end

		-- 생성 시 넣은 Arguments는 아이템으로 간주하여 미리 넣어둠
		local preset_items = { ... }

		for i = 1, #preset_items do
			out:add(preset_items[i])
		end

		return setmetatable(out, {
			-- #으로 HashSet의 Count 접근
			__len = function(_)
				return count
			end,
			-- pairs(hashset) 기능. 튜플로 반환되는 value값은 항상 nil임
			__pairs = function(_)
				return function(table, key)
					key = next(table, key)

					return key, nil
				end, container, nil
			end
		})
	end

	--- 현재 스테이지가 어떤 모드인지 판별하기 위한 유틸
	stage_mode_util = {}

	stage_mode_util.is_colosseum = function()
		return stage.Spec.StageType == CS.StageType.ColosseumStage
	end

	stage_mode_util.is_coop = function()
		return CS.Oak.CoopClient.Instance.IsCoopMode
	end

	stage_mode_util.is_guild_castle = function()
		return stage.Spec.StageType == CS.StageType.GuildCastleStage
	end

	--- 아레나(마스터 아레나)인지 체크
	stage_mode_util.is_arena = function()
		return stage.Spec.StageType == CS.StageType.CoopStage and CS.Oak.CoopClient.Instance.CoopModel.IsArena
	end

	--- 데스매치인지 체크
	stage_mode_util.is_death_match = function()
		return stage.Spec.StageType == CS.StageType.DeathMatch
		--return stage.Spec.StageType == CS.StageType.CoopStage and CS.Oak.CoopClient.Instance.CoopMode == CS.Oak.CoopMode.DeathMatch
	end

	--- 스토리 모드인지 체크
	stage_mode_util.is_story = function()
		return stage.Spec.StageType == CS.StageType.IsStoryStage
	end

	--- 연계기 액션에서 주로 사용하는 유틸
	support_action_util = {}

	--- 이동형 연계기용 벽관통 크래시 비헤비어 캐시
	support_action_util.ethereal_crash_behaviour = CS.Oak.EtherealSupportCrashBehaviour.Instance

	--- 이동형 연계기용 pass 크래시 비헤비어 캐시
	support_action_util.pass_crash_behaviour = CS.Oak.PassSupportCrashBehaviour.Instance

	--- 충돌 체크를 위한 바운드 생성
	support_action_util.create_checker_bounds = function(owner, target_pos)
		--- 대상 위치의 바닥 위치
		local ground_pos = battle_util.get_ground_pos(target_pos)
		--- 대상 위치에서 높이를 맞춘 위치
		local center = ground_pos + bounds_util.get_size(owner).y * 0.5 * vector_util.up

		return CS.UnityEngine.Bounds(center, bounds_util.get_size(owner))
	end

	--- 이동형 연계기에서 이동할 위치를 계산한다.
	support_action_util.calculate_move_position = function(owner, target, dir_vector, magnitude)
		--- 대상 위치
		local target_pos = character_util.get_position(target)

		--- 충돌 체크를 위한 바운드
		local bounds = support_action_util.create_checker_bounds(owner, target_pos)

		--- 대상 방향으로 이동시 충돌하는 가장 가까운 대상
		local closest_object = field:GetClosestFieldObjectByLineSegment(
			bounds, CS.Oak.EntityGroups.Obstacle, magnitude * dir_vector
		)

		--- 가까운 대상이 존재할때
		if closest_object then
			--- 충돌 최소 거리
			local ray_dist = CS.BoundsExtensions.GetDistanceOnRay(
				bounds, bounds_util.get_bounds(closest_object), dir_vector
			)

			--- 실제 이동가능한 거리 갱신
			magnitude = math.min(magnitude, ray_dist)
		end

		local dist_vector = magnitude * dir_vector
		local dest_pos = target_pos + dist_vector

		--- 실제 전투 이벤트 찾기
		local zone_bound = battle_util.get_event_zone_bound(owner, target)
		--- 존 바운더리가 있는 경우
		if zone_bound then
			dest_pos = bounds_util.convert_position_to_inside(zone_bound, owner, dest_pos, -dir_vector, bounds_util.get_size(owner).x * 0.5)
		end

		return dest_pos
	end

	--- diff 만큼 one frame 이동을 함
	support_action_util.execute_move = function(owner, diff)
		--- 이동 거리가 거의 없다면 생략함
		if float_util.is_almost_zero(vector_util.sqr_magnitude(diff)) then
			return
		end

		--- 이동 처리
		CS.Oak.MoveOneFrameStageLogic.ExecuteMove(
			owner, vector_util.normalized(diff), vector_util.magnitude(diff), CS.Oak.MoveOneFrameTypes.IgnoreCrash | CS.Oak.MoveOneFrameTypes.IgnoreSlope
		)
	end

	--- 시간 사이동안 start_pos -> dest_pos로 이동함
	support_action_util.execute_move_between_time = function(owner, start_pos, dest_pos, min_time, max_time, time_passed)
		--- 진행도
		local progress = math.min((time_passed - min_time) / (max_time - min_time), 1)

		support_action_util.execute_lerp_move(owner, start_pos, dest_pos, progress)
	end

	--- start_pos, dest_pos 간에 lerp 이동을 함
	support_action_util.execute_lerp_move = function(owner, start_pos, dest_pos, progress)
		--- 진행도에 따른 새로운 위치
		local new_pos = vector_util.lerp(start_pos, dest_pos, progress)
		--- 새로운 위치까지의 diff
		local diff = new_pos - character_util.get_position(owner)

		support_action_util.execute_move(owner, diff)
	end

	--- 특정 위치로 복귀하게 하기 위한 기능
	support_action_util.return_to_position = function(owner, dest_pos)
		local diff = dest_pos - character_util.get_position(owner)

		support_action_util.execute_move(owner, diff)
	end

	--- 연계기 액션의 크래시 비헤비어를 변경하는 유틸 함수
	--- 해당 함수를 통한 경우 수동으로 attach_to 및 detach_from을 해줄 필요가 없다.
	support_action_util.change_crash_behaviour = function(cs_action, crash_behaviour)
		cs_action:SetupCrashBehaviour(crash_behaviour)
	end

	--- 연계기 액션의 크래시 비헤비어를 EtherealSupportCrashBehaviour 변경하는 유틸 함수
	--- 해당 함수를 통한 경우 수동으로 attach_to 및 detach_from을 해줄 필요가 없다.
	support_action_util.change_to_ethereal_crash_behaviour = function(cs_action)
		support_action_util.change_crash_behaviour(cs_action, support_action_util.ethereal_crash_behaviour)
	end

	--- 연계기 액션의 크래시 비헤비어를 PassSupportCrashBehaviour 변경하는 유틸 함수
	--- 해당 함수를 통한 경우 수동으로 attach_to 및 detach_from을 해줄 필요가 없다.
	support_action_util.change_to_pass_crash_behaviour = function(cs_action)
		support_action_util.change_crash_behaviour(cs_action, support_action_util.pass_crash_behaviour)
	end

	support_action_util.set_darken_on_declare = function(owner, action, target_darken, duration)
		--- 오너와 액션이 있어야 함
		if not owner or not action then
			return
		end

		--- 필드가 없다면 생략함
		if not field then
			return
		end

		local time_mod = 1

		--- 콜로세움에서는 내 파티 캐릭터, 적 파티 캐릭터 둘 다 슬로우 된다.
		if stage_mode_util.is_colosseum() then
			time_mod = 0.3
		--- 멀티 플레이 컨텐츠이고 유저 파티에 속하지 않은 경우
		elseif stage_mode_util.is_coop() or stage_mode_util.is_guild_castle() or not party_util.is_in_user_party(owner) then
			--- 메뉴얼 로컬이 아니면 생략함
			if not battle_util.is_manual_local(owner) then
				return
			end
		else
			time_mod = 0.3
		end

		action.is_darkened = true

		target_darken = lua_helper.get_or_default(target_darken, 0.5)
		duration = lua_helper.get_or_default(duration, 0.15)

		field:Darken('support_skill_declare', target_darken, duration * time_mod)
	end

	support_action_util.unset_darken = function(action, duration)
		if not action then
			return
		end

		--- 암전을 한 적이 없다면 생략함
		if not action.is_darkened then
			return
		end

		action.is_darkened = nil

		--- 필드가 없다면 생략함
		if not field then
			return
		end

		duration = lua_helper.get_or_default(duration, 0.15)

		field:Undarken('support_skill_declare', duration)
	end

	--- 포지션 스킬 유틸
	position_skill_util = {}

	position_skill_util.is_charged = function(cs_action)
		return position_skill_extensions.IsCharged(cs_action)
	end

	--- 쿨타임 체커의 지난 시간을 초기화함
	position_skill_util.reset_time_passed = function(cs_action)
		cs_action:ResetTimePassed()
	end

	--- 특정 조건에 따라 쿨타임을 변경함
	position_skill_util.set_cool_time = function(cs_action, target_cool_time, reset_time_passed)
		--- 목표 쿨타임 설정
		cs_action:SetCoolTime(target_cool_time)

		--- 지난 시간 초기화 필요한 경우의 처리
		if reset_time_passed then
			position_skill_util.reset_time_passed(cs_action)
		end
	end

	--- set_cool_time으로 설정된 쿨타임을 기본값으로 롤백함
	position_skill_util.reset_cool_time = function(cs_action)
		cs_action:ResetCoolTime()
	end

	--- 쿨타임 업데이트 재개함
	position_skill_util.enable_update_time_passed = function(cs_action)
		cs_action.StopCharge = false
	end

	--- 쿨타임 업데이트 중단함
	position_skill_util.disable_update_time_passed = function(cs_action)
		cs_action.StopCharge = true
	end

	--- 현재 지정된 쿨타임 반환
	position_skill_util.get_cool_time = function(cs_action)
		return cs_action.CoolTime
	end

	--- 협동원정대 포지션 스킬 배틀액션 공용으로 사용할 어두워지는 연출
	--- @param target_darken number 목표 연출 강도
	--- @param duration number 연출에 걸릴 시간
	position_skill_util.set_darken = function(cs_action, target_darken, duration)
		--- 메뉴얼 로컬 플래그 체크
		if not battle_util.is_manual_local(cs_action.Character) then
			return
		end

		if field then
			duration = lua_helper.get_or_default(duration, 0.2)

			field:Darken(cs_action.HandleName, target_darken, duration)
		end
	end

	--- 협동원정대 포지션 스킬 배틀액션 공용으로 사용할 어두워지는 연출 해지
	--- @param duration number 연출 해지에 걸릴 시간
	position_skill_util.unset_darken = function(cs_action, duration)
		--- 메뉴얼 로컬 플래그 체크
		if not battle_util.is_manual_local(cs_action.Character) then
			return
		end

		if field then
			duration = lua_helper.get_or_default(duration, 0.2)

			field:Undarken(cs_action.HandleName, duration)
		end
	end

	--- 협동원정대용 유틸
	coop_expedition_util = {}

	--- 협동원정대용 어그로 시스템에 따라 타겟 체인지 이벤트를 발행하기 위한 래퍼
	--- @param sender table  이벤트 발행주체 캐릭터
	--- @param target table 타겟되는 캐릭터
	--- @param is_show boolean 화살표 표시 여부
	coop_expedition_util.send_target_marker_event = function(sender, target)
		message_system:SendSync(sender.CharacterBehaviour, CS.Oak.TargetMarkerEvent.Create(target))
	end


	coop_expedition_util.is_proj_shield_fo = function(target)
		return lua_helper.type_compare(target.CrashBehaviour, CS.Oak.ProjectileShieldCrashBehaviour)
	end

	-- 테티스 영웅전 유틸
	rogue_chess_util = {}

	rogue_chess_util.on_summoner_spell_use_result = function(is_success)
		return CS.Oak.RogueChessSystem.Instance.SummonerSpell:UseSummonerSpellResult(is_success)
	end

	--로그체스 어빌리티 옵션 파싱
	rogue_chess_util.parse_ability_buff_info = function(params)
		local buff_info_table = {}
		local buff_name = cs_util.get_string_from_dictionary(params, 'BuffName')

		if buff_name == nil then
			local idx = 1
			buff_name = cs_util.get_string_from_dictionary(params, 'BuffName_' .. idx)

			while buff_name ~= nil do
				table.insert(buff_info_table, {
					name = cs_util.get_string_from_dictionary(params, 'BuffName_' .. idx),
				})

				idx = idx + 1
				buff_name = cs_util.get_string_from_dictionary(params, 'BuffName_' .. idx)
			end
		else
			table.insert(buff_info_table, {
				name = cs_util.get_string_from_dictionary(params, 'BuffName'),
			})
		end

		return buff_info_table
	end

	rogue_chess_util.handle_summoner_spell_range = function(zone, pos, range_green, range_red)
		local pos_contained = false
		local range
		if zone.Bounds:Contains(pos) then
			pos_contained = true
			range = range_green
			range_red:Hide()
		else
			range = range_red
			range_green:Hide()
		end

		if not range.gameObject.activeSelf then
			range:Show()
		end
		range:SetupByPosition(pos, pos.y)
		return pos_contained
	end

	rogue_chess_util.count_elemental_type_in_rosters = function(target_class)
		-- 현재 서브 시스템 로그체스
		local rc_sub_system = CS.Oak.Game:GetCurrentSubSystem()
		if rc_sub_system.Deck == nil then
			return 0
		end

		-- 로스터 캐릭터 속성 카운트
		local rosters = rc_sub_system.Deck.Rosters
		local elemental_count_table = {}
		local highest_value = 0
		local highest_type = nil

		for i = 0, rosters.Count - 1 do repeat
			local character = rosters[i].Character
			if target_class ~= nil and character.CharacterStatsBehaviour.CharacterSpec.CoopClass ~= target_class then
				break
			end

			local elemental_type = character.CharacterStatsBehaviour.CharacterSpec.ElementalType
			local new_value
			if elemental_count_table[elemental_type] == nil then
				new_value = 1
			else
				new_value = elemental_count_table[elemental_type] + 1
			end

			elemental_count_table[elemental_type] = new_value

			if highest_value < elemental_count_table[elemental_type] then
				highest_value = new_value
				highest_type = elemental_type
			end
		until true end

		return highest_type, highest_value
	end

	rogue_chess_util.is_all_same_elemental_type = function(target_class)
		-- 현재 서브 시스템 로그체스
		local rc_sub_system = CS.Oak.Game:GetCurrentSubSystem()
		if rc_sub_system.Deck == nil then
			return false
		end

		-- 로스터 캐릭터 속성 카운트
		local elemental_type = nil
		local rosters = rc_sub_system.Deck.Rosters
		for i = 0, rosters.Count - 1 do
			local character = rosters[i].Character
			if target_class ~= nil and character.CharacterStatsBehaviour.CharacterSpec.CoopClass ~= target_class then
				break
			end

			if elemental_type then
				if elemental_type ~= character.CharacterStatsBehaviour.CharacterSpec.ElementalType then
					return false
				end
			else
				elemental_type = character.CharacterStatsBehaviour.CharacterSpec.ElementalType
			end
		end
		return true
	end

	--- CS.Oak.DamageType의 캐시된 버전
	--- 일단 기본적인 것들만 등록함
	damage_attribute_type = {
		--- 초기화 되지 않은 상태 (기본값)
		none = CS.Oak.DamageType.None,
		--- 근거리 피해
		melee = CS.Oak.DamageType.Melee,
		--- 원거리 피해
		projectile = CS.Oak.DamageType.Projectile,
		--- DOT (부상)
		dot = CS.Oak.DamageType.DotDamage,
		--- DOT (파멸)
		doom = CS.Oak.DamageType.DotDamage | CS.Oak.DamageType.Trap,
		--- 발동한 패시브 액션에 의한 데미지인지. (패시브의 결과로 패시브를 발동하지 않도록.)
		passive = CS.Oak.DamageType.Passive,
		--- 옵션에 의한 자동 공격
		--- 얘 자체는 기능이 없고, 추후 트레킹에 문제 없도록 추가해둠
		auto_attack = CS.Oak.DamageType.None,
		--- 방어 무기 피해
		ignore_defense = CS.Oak.DamageType.IgnoreDefense,
		--- DathRattle 옵션 혹은 데미지 회피옵션(면책등) 및 immune 무시하고
		--- 무조건 데미지가 들어가도록 한다.
		ignore_options = CS.Oak.DamageType.IgnoreOptions,
		--- 보호막 피해 데미지 타입. 체력에는 데미지가 들어가지 않고 오직 보호막에만 피해를 주는 데미지 타입
		shield_break = CS.Oak.DamageType.ShieldBreak,
		--- 즉사광선! 방어및 각종 옵션 다 무시하고 데미지를 주는것이 가능하다.
		death = CS.Oak.DamageType.Death
	}

	--- CS.Oak.DamageSourceType의 캐시된 버전
	--- 일단 기본적인 것들만 등록함
	damage_source_type = {
		--- 초기화 되지 않은 상태(기본값)
		none = CS.Oak.DamageSourceType.None,
		--- 일반 기술
		manual = CS.Oak.DamageSourceType.Manual,
		--- 역할 기술
		role = CS.Oak.DamageSourceType.Role,
		--- 무기 기술
		super = CS.Oak.DamageSourceType.Super,
		--- 연계 기술
		support = CS.Oak.DamageSourceType.Support,
		--- 기타 옵션
		option = CS.Oak.DamageSourceType.Option,
		--- 각성 특수 능력
		awakening_option = CS.Oak.DamageSourceType.AwakeningOption,
		--- 전용 무기 옵션
		cwp_option = CS.Oak.DamageSourceType.CwpOption,
		--- 특수 능력
		special_option = CS.Oak.DamageSourceType.SpecialOption,
		--- 승급 능력
		ascent_option = CS.Oak.DamageSourceType.AscentOption
	}

	character_voice_type = {
		attack_1 = CS.Oak.CharacterVoiceType.Attack1,
		attack_2 = CS.Oak.CharacterVoiceType.Attack2,
		attack_3 = CS.Oak.CharacterVoiceType.Attack3,
		skill_1 = CS.Oak.CharacterVoiceType.Skill1,
		skill_2 = CS.Oak.CharacterVoiceType.Skill2,
		touch_reaction_bad_1 = CS.Oak.CharacterVoiceType.TouchReactionBad1,
		touch_reaction_bad_2 = CS.Oak.CharacterVoiceType.TouchReactionBad2,
		special_1 = CS.Oak.CharacterVoiceType.Special1,
		special_2 = CS.Oak.CharacterVoiceType.Special2,
		special_3 = CS.Oak.CharacterVoiceType.Special3
	}

	--- 배틀 ai관련 유틸
	--- 주로 몬스터에서 사용될 것
	battle_ai_util = {}

	--- 현재 설정된 ai 상태를 가져옴
	battle_ai_util.get_ai_state = function(owner)
		local controller_state = owner.FieldObjectController.CurrentState
		local is_ai_state = CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(controller_state, typeof(CS.Oak.IBattleAIState))
		return is_ai_state and controller_state or nil
	end

	--- 어그로 기반 ai를 위한 타겟팅 탐색
	battle_ai_util.search_target = function(cs_state)
		return CS.Oak.IBattleAIStateExtensions.SearchTarget(cs_state)
	end

	-- TODO: 수정
	battle_ai_util.search_target_ignore_summonables = function(cs_state, owner)
		local targets = battle_manager:GetTargets(owner)
		if targets == nil then
			return nil
		end
		for i = targets.Count - 1, 0, -1 do
			local target = targets[i]
			local master = summonable_util.get_master(target)
			if master == nil then
				-- 마스터가 없으면 블랙리스트에 넣지 않음
				targets:RemoveAt(i)
			end
		end
		-- TODO: SearchTarget에서 블랙리스트에 있는 사람이 최대 어그로에 가장 가까운 대상이면 null을 반환 해버림,
		-- TODO: 가까운 대상을 탐색할 때는, 블랙리스트를 제외하고 탐색해야 함
		local target = CS.Oak.IBattleAIStateExtensions.SearchTarget(cs_state, targets)
		if target == nil then
			target = CS.Oak.IBattleAIStateExtensions.SearchClosestTarget(cs_state, false, targets)
		end
		targets:Dispose()
		return target
	end

	--- 가장 가까운 적을 반환
	battle_ai_util.search_closest_target = function(cs_state, check_zone, black_list)
		check_zone = lua_helper.get_or_default(check_zone, false)
		return CS.Oak.IBattleAIStateExtensions.SearchClosestTarget(cs_state, check_zone, black_list)
	end

	battle_ai_util.search_heal_target = function(cs_state, min_hp_threshold, is_ignore_self)
		return CS.Oak.IBattleAIStateExtensions.SearchHealTarget(cs_state, min_hp_threshold, is_ignore_self)
	end

	battle_ai_util.search_random_friendly_target = function(cs_state, is_ignore_self)
		return CS.Oak.IBattleAIStateExtensions.SearchRandomFriendlyTarget(cs_state, is_ignore_self)
	end

	--- 가장 먼 적을 반환
	battle_ai_util.search_farthest_target = function(cs_state, check_zone, black_list)
		check_zone = lua_helper.get_or_default(check_zone, false)
		return CS.Oak.IBattleAIStateExtensions.SearchFarthestTarget(cs_state, check_zone, black_list)
	end

	--- 직접 조작중인 영웅 아무나 타겟팅함
	battle_ai_util.search_random_manual_target = function (cs_state, check_zone)
		check_zone = lua_helper.get_or_default(check_zone, false)
		return CS.Oak.IBattleAIStateExtensions.SearchRandomManualTarget(cs_state, check_zone)
	end

	--- Manual 타겟 반환
	battle_ai_util.search_manual_target = function(cs_state)
		return CS.Oak.IBattleAIStateExtensions.SearchManualCharacterTargets(cs_state)
	end

	--- 대상의 ai가 타겟팅중인 대상을 반환
	battle_ai_util.get_ai_target = function(owner)
		local target = CS.Oak.LuaBattleExtensions.GetAITarget(owner)

		-- 대상이 없다면 보던 방향을 반환한다.
		if is_unity_null(target) then
			return nil, character_util.get_look_direction(owner)
		end

		return target, battle_util.get_direction_toward(owner, target)
	end

	--- 배틀액션이 시전 가능한 상태인지 확인
	battle_ai_util.is_battle_action_available = function(battle_action)
		return CS.Oak.LuaBattleExtensions.BattleActionIsAvailable(battle_action)
	end

	--- 배틀액션으로 대상을 판정할 수 있는 환경인지 확인
	battle_ai_util.is_battle_action_hittable = function(battle_action, target)
		return CS.Oak.LuaBattleExtensions.BattleActionIsHittable(battle_action, target)
	end

	--- 배틀액션 시전 시도, 시전 성공 여부를 반환함
	battle_ai_util.trigger_battle_action = function(owner, battle_action)
		return CS.Oak.LuaBattleExtensions.TriggerBattleAction(owner, battle_action)
	end

	--- 배틀액션이 시전 중인지를 반환
	battle_ai_util.is_battle_action_active = function(battle_action)
		return CS.Oak.LuaBattleExtensions.BattleActionIsActive(battle_action)
	end

	--- 상태이상 관련 유틸
	ailment_util = {}

	--- 상태이상과 관련된 이벤트인지 체크하는 유틸함수
	ailment_util.is_ailment_event = function(event)
		return CS.Oak.LuaBattleExtensions.IsAilmentEvent(event)
	end

	--- 상태이상에 걸릴 대상을 이벤트로부터 추출하여 반환
	ailment_util.get_target_from_event = function(event)
		return CS.Oak.LuaBattleExtensions.GetTargetFromAilmentEvent(event)
	end

	--- 어택레인지 표시 유형 캐시
	attack_range_show_type = {
		none = CS.Oak.AttackRangeShowType.NONE,
		fade_in = CS.Oak.AttackRangeShowType.FadeIn,
		fade_out = CS.Oak.AttackRangeShowType.FadeOut,
		overlay_forward = CS.Oak.AttackRangeShowType.OverlayForward,
		overlay_reverse = CS.Oak.AttackRangeShowType.OverlayReverse,
		--- rect 만 가능
		overlay_outward = CS.Oak.AttackRangeShowType.OverlayOutward,
	}

	--- 전투 내에서 범용적으로 사용될 어택레인지 색상 프리셋
	--- battle_range_util 전용임
	battle_range_color_preset = {
		--- 비 오버레이용 blue 색상 프리셋
		normal_blue = {
			--- 안쪽 색상
			main_color = CS.UnityEngine.Color32(53, 70, 255, 76),
			--- 외각선 색상
			outline_color = CS.UnityEngine.Color32(53, 70, 255, 153)
		},
		--- 비 오버레이용 green 색생 프리셋
		normal_green = {
			--- 안쪽 색상
			main_color = CS.UnityEngine.Color32(53, 255, 70, 76),
			--- 외각선 색상
			outline_color = CS.UnityEngine.Color32(53, 255, 70, 153)
		}
	}

	--- 어택 레인지 관련 유틸
	battle_range_util = {}

	--- battle_range_util에 넘길 사용할 색상을 정의할 테이블을 할당
	battle_range_util.create_color_table = function()
		--- battle_range 생성시 넘길 색상 테이블
		---@class battle_range_color_table
		local color_table = {}
		--- 안쪽 색상
		color_table.main_color = nil
		--- 외각선 색상
		color_table.outline_color = nil
		--- 오버레이 위 안쪽 색상
		color_table.cover_main_color = nil
		--- 오버레이 위 외각선 색상
		color_table.cover_outline_color = nil
		return color_table
	end

	--- 오버레이 타입일 때 잘못된 색상일 때 fallback 해주기 위함
	--- 오버레이 외에선 2개만 설정 할 수 있도록 하기 위함
	battle_range_util.invalid_overlay_color = CS.UnityEngine.Color32(255, 0, 255, 255)

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	battle_range_util.get_common_cover_colors = function(color_table)
		local cover_main_color = lua_helper.get_or_default(color_table.cover_main_color, battle_range_util.invalid_overlay_color)
		local cover_outline_color = lua_helper.get_or_default(color_table.cover_outline_color, battle_range_util.invalid_overlay_color)
		return cover_main_color, cover_outline_color
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	battle_range_util.create_rect = function(size, show_type, color_table)
		show_type = lua_helper.get_or_default(show_type, attack_range_show_type.none)

		-- 컬러 테이블이 유효한 경우 처리
		if color_table then
			local cover_main_color, cover_outline_color = battle_range_util.get_common_cover_colors(color_table)
			return CS.AttackRange.CreateRect(vector_util.zero, size, color_table.main_color, color_table.outline_color, cover_main_color, cover_outline_color, show_type)
		end

		return CS.AttackRange.CreateRect(vector_util.zero, size, show_type)
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	battle_range_util.create_circle = function(radius, show_type, color_table)
		show_type = lua_helper.get_or_default(show_type, attack_range_show_type.none)

		-- 컬러 테이블이 유효한 경우 처리
		if color_table then
			local cover_main_color, cover_outline_color = battle_range_util.get_common_cover_colors(color_table)
			return CS.AttackRange.CreateCircle(vector_util.zero, radius, color_table.main_color, color_table.outline_color, cover_main_color, cover_outline_color, show_type)
		end

		return CS.AttackRange.CreateCircle(vector_util.zero, radius, show_type)
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	battle_range_util.create_arc = function(radius, angle, show_type, color_table)
		show_type = lua_helper.get_or_default(show_type, attack_range_show_type.none)

		-- 컬러 테이블이 유효한 경우 처리
		if color_table then
			local cover_main_color, cover_outline_color = battle_range_util.get_common_cover_colors(color_table)
			return CS.AttackRange.CreateArc(vector_util.zero, radius, angle, color_table.main_color, color_table.outline_color, cover_main_color, cover_outline_color, show_type)
		end

		return CS.AttackRange.CreateArc(vector_util.zero, radius, angle, show_type)
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	battle_range_util.create_donut = function(inner_radius, outer_radius, show_type, color_table)
		show_type = lua_helper.get_or_default(show_type, attack_range_show_type.none)

		-- 컬러 테이블이 유효한 경우 처리
		if color_table then
			local cover_main_color, cover_outline_color = battle_range_util.get_common_cover_colors(color_table)
			return CS.AttackRange.CreateDonut(vector_util.zero, inner_radius, outer_radius, color_table.main_color, color_table.outline_color, cover_main_color, cover_outline_color, show_type)
		end

		return CS.AttackRange.CreateDonut(vector_util.zero, inner_radius, outer_radius, show_type)
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	battle_range_util.create_arc_donut = function(inner_radius, outer_radius, angle, show_type, color_table)
		show_type = lua_helper.get_or_default(show_type, attack_range_show_type.none)

		-- 컬러 테이블이 유효한 경우 처리
		if color_table then
			local cover_main_color, cover_outline_color = battle_range_util.get_common_cover_colors(color_table)
			return CS.AttackRange.CreateArcDonut(vector_util.zero, inner_radius, outer_radius, angle, color_table.main_color, color_table.outline_color, cover_main_color, cover_outline_color, show_type)
		end

		return CS.AttackRange.CreateArcDonut(vector_util.zero, inner_radius, outer_radius, angle, show_type)
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	battle_range_util.create_hollow_rect = function(size, hollow_size, hollow_offset, show_type, color_table)
		hollow_offset = lua_helper.get_or_default(hollow_offset, vector_util.zero2)
		show_type = lua_helper.get_or_default(show_type, attack_range_show_type.none)

		-- 컬러 테이블이 유효한 경우 처리
		if color_table then
			local cover_main_color, cover_outline_color = battle_range_util.get_common_cover_colors(color_table)
			return CS.AttackRange.CreateHollowRectangle(vector_util.zero, size, hollow_size, hollow_offset, color_table.main_color, color_table.outline_color, cover_main_color, cover_outline_color, show_type)
		end

		return CS.AttackRange.CreateHollowRectangle(vector_util.zero, size, hollow_size, hollow_offset, show_type)
	end

	battle_range_util.destroy = function(attack_range)
		if is_unity_null(attack_range) then
			return
		end

		CS.UnityEngine.Object.Destroy(attack_range.gameObject)
	end

	battle_range_util.show = function(attack_range, duration)
		duration = lua_helper.get_or_default(duration, 0)
		attack_range:Show(duration)
	end

	battle_range_util.hide = function(attack_range)
		attack_range:Hide()
	end

	battle_range_util.setup_by_position = function(attack_range, pos, height)
		height = lua_helper.get_or_default(height, pos.y)
		attack_range:SetupByPosition(pos, height)
	end

	battle_range_util.setup_by_direction = function(attack_range, pos, dir, height)
		height = lua_helper.get_or_default(height, pos.y)
		attack_range:SetupByDirection(pos, dir, height)
	end

	battle_range_util.increase_sorting_order = function(attack_range, order)
		attack_range:IncreaseSortingOrder(order)
	end

	battle_range_util.publish_update = function(owner, attack_range)
		message_system_util.publish(CS.Oak.AttackRangeUpdateEvent.Create(owner, attack_range))
	end

	battle_range_util.publish_end = function(owner, attack_range)
		message_system_util.publish(CS.Oak.AttackRangeEndEvent.Create(owner, attack_range))
	end

	--- 가상 어택 레인지 관련 유틸
	virtual_range_util = {}

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	virtual_range_util.create_rect = function(size)
		return CS.Oak.VirtualAttackRange.CreateRect(vector_util.zero, size.x, size.y, 0)
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	virtual_range_util.create_circle = function(radius)
		return CS.Oak.VirtualAttackRange.CreateCircle(vector_util.zero, radius)
	end

	--- @param color_table battle_range_color_table 적용할 색상의 테이블
	virtual_range_util.create_arc = function(radius, angle)
		return CS.Oak.VirtualAttackRange.CreateArc(vector_util.zero, radius, angle, 0)
	end

	virtual_range_util.setup_by_position = function(virtual_range, pos)
		virtual_range.Position = pos
	end

	virtual_range_util.setup_by_direction = function(virtual_range, pos, dir)
		virtual_range:SetupByDirection(pos, dir)
	end

	virtual_range_util.publish_update = function(owner, virtual_range)
		message_system_util.publish(CS.Oak.AttackRangeUpdateEvent.Create(owner, virtual_range))
	end

	virtual_range_util.publish_end = function(owner, virtual_range)
		message_system_util.publish(CS.Oak.AttackRangeEndEvent.Create(owner, virtual_range))
	end

	--- 어택 큐 (캐스팅 UI) 관련 유틸
	attack_queue_util = {}

	attack_queue_util.publish_start = function(owner, duration)
		message_system_util.publish(CS.Oak.AttackQueueStartEvent.Create(owner, duration))
	end

	attack_queue_util.publish_end = function(owner)
		message_system_util.publish(CS.Oak.AttackQueueEndEvent.Create(owner))
	end

	--- Oak.BattleSessionOptionHelper의 래핑에서 활용하기 위한 유틸
	battle_session_helper_util = {}

	--- 세션 핼퍼를 생성함
	--- 주의 : 사용을 완료하면 반드시 battle_session_helper_util.dispose로 해제해줘야 함
	--- @param owner any 이 핼퍼의 소유 IFieldObject
	--- @param target_type any 이 핼퍼에서 트래킹 할 대상 유형
	--- @param session_begin_func function 트래킹 대상의 전투 세션이 시작될 때 불릴 함수 (battle_enter)
	--- @param session_finish_func function 트래킹 대상의 전투 세션이 종료될 때 불릴 함수 (fo_destroy, battle_end)
	battle_session_helper_util.create = function (owner, target_type, session_begin_func, session_finish_func)
		return CS.Oak.BattleSessionOptionHelper(owner, target_type, session_begin_func, session_finish_func)
	end

	--- 세션 핼퍼를 해제함
	--- 주의 : nil로 바꿔주진 않기 때문에 dispose 호출 이후 직접 레퍼런스를 날려야 함
	battle_session_helper_util.dispose = function (session_helper)
		if session_helper then session_helper:Dispose() end
	end

	--- 세션 핼퍼에서에서 트래킹 할 대상 유형
	battle_session_target_type = {
		--- 자기 자신만
		self = CS.Oak.BattleSessionOptionHelper.TargetType.Self,
		--- 파티원에게 반영 (본인이 편성한 캐릭터)
		party = CS.Oak.BattleSessionOptionHelper.TargetType.Party,
		--- 아군에게 반영 (실제 출전해있는 캐릭터, 예 : 데스매치)
		stage_member = CS.Oak.BattleSessionOptionHelper.TargetType.StageMember
	}

	--- battle state 기본 형태
	---@class battle_state_base
	battle_state_base = {
		--- 해당 state의 진입점
		enter = nil,
		--- 해당 state의 이탈점
		exit = nil,
		--- 해당 state가 매 프레임
		update = nil
	}
	battle_state_base.mt = { __index = battle_state_base }

	--- battle_state 생성, 별도 구현을 사용할 경우 mt에 meta_table을 전달할 것
	function battle_state_base:new(mt, parent_class)
		local obj = {}
		setmetatable(obj, mt or self.mt)

		--- battle_state 상속받는 클래스 중복처리 여기서
		if parent_class then
			--- 오너
			obj.action = parent_class
			--- 상위 클래스
			obj.owner = parent_class.owner
			--- CS 클래스
			obj.cs_action = parent_class.cs_action
		end
		return obj
	end


	--- battle_state를 구동하기 위한 머신
	---@class battle_state_machine
	battle_state_machine = {
		--- 현재 작동중인 state
		---@type battle_state_base
		state = nil,
		--- combo_state 처리를 도와주기 위한 helper
		---@type combo_state_helper
		combo_helper = nil,
	}
	battle_state_machine.mt = { __index = battle_state_machine }

	function battle_state_machine:new(combo_helper)
		local obj = {}
		setmetatable(obj, self.mt)
		obj.combo_helper = combo_helper
		return obj
	end

	--- 상태가 있는지 체크
	function battle_state_machine:is_nil_state()
		return self.state == nil
	end

	--- 다음 상태로 전이
	function battle_state_machine:change(new_state)
		local prev_state = self.state

		if prev_state and prev_state.exit then
			prev_state:exit(new_state)
		end

		self.state = new_state

		if self.state then
			if self.state.current_time_passed then
				self.state.current_time_passed = 0
			end

			if self.combo_helper ~= nil then
				self.combo_helper:reset_time_passed(self.state)
			end

			if self.state.enter then
				self.state:enter(prev_state)
			end
		end
	end

	function battle_state_machine:update(dt)
		if self:is_nil_state() or self.state.current_time_passed == nil then
			return
		end

		local old_time_passed = self.state.current_time_passed
		self.state.current_time_passed = self.state.current_time_passed + dt

		if self.state.update then
			self.state:update(old_time_passed, self.state.current_time_passed, dt)
		end

		if self:is_nil_state() or self.combo_helper == nil then
			return
		end

		if not self.combo_helper:check_update_time(self.state, old_time_passed, self.state.current_time_passed, dt) then
			return
		end

		self.combo_helper:state_end_routine(self)
	end

	--- 콤보 액션 state_machine의 처리를 도와줄 핼퍼
	---@class combo_state_helper
	combo_state_helper = {
		--- 이 객체의 ifo 소유주
		owner = nil,
		--- 이 객체의 cs_action 소유주
		cs_action = nil,
	}
	combo_state_helper.mt = { __index = combo_state_helper }

	function combo_state_helper:new(cs_action, owner)
		local obj = {}
		setmetatable(obj, self.mt)
		obj.owner = owner
		obj.cs_action = cs_action
		return obj
	end

	function combo_state_helper:reset_time_passed(state)
		if state.finished_time_passed then
			state.finished_time_passed = 0
		end
	end

	function combo_state_helper:check_update_time(state, old_time_passed, time_passed, dt)
		-- combo action용 state만 지원함
		if state.finished_time_passed == nil then return false end

		-- 아직 state가 종료되기 전인 경우 생략
		if state.action_duration > time_passed then return false end

		-- state가 종료된 뒤에는 지난 시간을 측정한다.
		if state.action_duration <= old_time_passed then
			state.finished_time_passed = state.finished_time_passed + dt
		end

		return true
	end

	function combo_state_helper:state_end_routine(battle_machine)
		local is_there_next = self.cs_action.IsThereNext
		local combo_window = self.cs_action.ComboWindow

		-- 콤보 액션의 경우에 한하여 처리를 진행한다.
		if is_there_next == nil or combo_window == nil then
			return
		end

		if is_there_next and combo_window > 0 then
			if battle_machine.state.finished_time_passed > combo_window then
				--- 스테이트 리셋
				battle_machine:change(nil)
			elseif battle_machine.state.finished_time_passed == 0 then
				--- 배틀액션이 완료됨을 publish
				message_system_util.publish(CS.Oak.BattleActionFinishedEvent.Create(self.owner, self.cs_action))
			end
		else
			--- 스테이트 리셋
			battle_machine:change(nil)
			--- 배틀액션이 완료됨을 publish
			message_system_util.publish_sync(CS.Oak.BattleActionFinishedEvent.Create(self.owner, self.cs_action))
		end
	end
end


function finish()
	message_system = nil

	coroutine_manager = nil
	unity_object_pool = nil
	object_pool_extensions = nil
	game_data_service = nil
	music_player = nil

	-- 스테이지 변수들
	stage = nil
	stage_camera = nil
	buff_manager = nil
	buff_extentions = nil
	party_manager = nil
	field = nil
	user_party = nil
	user_party_leader = nil

	constants = nil
	stun_constants = nil
	knock_back_constants = nil
	projectile_hit_type = nil

	unity_class = nil
	coroutine_class = nil
	wait_for_sec = nil
	wait_for_unscaled_sec = nil
	wait_all = nil
	is_unity_null = nil
	vector = nil
	create_generic_dictionary = nil
	create_generic_hashset = nil
	lua_helper = nil
	type_util = nil
	character_util = nil
	weapon_util = nil
	command_util = nil
	direction_util = nil
	vector_util = nil
	float_util = nil
	bounds_util = nil
	battle_util = nil
	discrete_stamina_action_util = nil
	continuous_stamina_action_util = nil
	charge_util = nil
	role_util = nil
	spine_util = nil
	effect_util = nil
	sfx_util = nil
	trigger_info_util = nil
	collision_info_util = nil
	area_collision_util = nil
	shoot_helper_util = nil
	buff_util = nil
	assist_util = nil
	random_util = nil
	coroutine_util = nil
	table_util = nil
	func_util = nil
	party_util = nil
	summonable_util = nil
	override_util = nil
	fo_cache = nil
	character_cache = nil
	bush_util = nil
	battle_manager_util = nil
	message_system_util = nil
	event_type = nil
	damage_info_util = nil
	heal_info_util = nil
	option_trigger_util = nil
	lua_collection_util = nil
	stage_mode_util = nil
	support_action_util = nil
	coop_expedition_util = nil

	damage_attribute_type = nil
	damage_source_type = nil
	character_voice_type = nil
	position_skill_extensions = nil
	battle_ai_util = nil
	ailment_util = nil
	attack_range_show_type = nil
	battle_range_color_preset = nil
	battle_range_util = nil
	attack_queue_util = nil
	battle_session_helper_util = nil
	battle_session_target_type = nil

	battle_state_base = nil
	battle_state_machine = nil
	combo_state_helper = nil
end
