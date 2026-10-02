return {
	init_spine_character = function(game_data_service, character, spine_controller, character_info, sorting_order, shader_selector, shadow_angle, is_hide_character, spine_top_shader)
		if character_info.SkinName ~= nil then
			spine_controller.SkinName = character_info.SkinName
		end

		local shader_selector_type = CS.System.Enum.Parse(typeof(CS.Oak.WeaponAttachmentShaderSelector), shader_selector, true)
		local create_desc = CS.Oak.WeaponAttachmentCreateDesc(shader_selector_type)
		CS.Oak.SpineControllerExtensions.SetWeaponAttachments(spine_controller, character_info, create_desc)

		local battle_style_data = game_data_service.GetData('BattleStyleData')
		local battle_style = battle_style_data:FindBattleStyle(character_info)
		local spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Base)
		local animation_name = 'idle'

		if battle_style ~= nil then
			local custom_anim_name = CS.Oak.BattleStyleSpecExtensions.GetCustomIdleAnimation(battle_style, character_info.Costume)
			animation_name = custom_anim_name ~= nil and custom_anim_name or animation_name
		end

		spine_controller.Direction = CS.Oak.Direction.Right
		CS.Oak.SpineControllerExtensions.SetSubIdleAnimation(spine_controller)
		spine_controller:SetAnimation(spine_track, animation_name, true)

		spine_controller:SetSortingLayer('UI', sorting_order)
		spine_controller.IsShadowActive = true
		spine_controller.ShadowTransform.localEulerAngles = shadow_angle

		CS.Utils.ChangeLayersRecursively(character.transform, 'SpecialEvents')

		if is_hide_character then
			spine_controller.gameObject:SetActive(false)
		end
		-- 캐릭터가 어떠한 상황에서라도 더 위에 그려질 수 있도록 함
		if spine_top_shader ~= nil then
			spine_controller.CustomShader = spine_top_shader
		end
	end,

	is_pool_loading = function(pool_table)
		local is_loaded_all = true

		while true do
			is_loaded_all = true

			for k,v in pairs(pool_table) do
				if v.State ~= CS.Oak.UnityObjectPoolState.Loaded and
						v.State ~= CS.Oak.UnityObjectPoolState.LoadFailed then
					is_loaded_all = false
				end
			end

			if is_loaded_all then
				break
			end

			coroutine.yield(nil)
		end
	end,

	get_bezier_curve = function(p0, p1, p2, t)
		local a = p0
		local b = p1
		local c = p2

		local aa = a + (b - a) * t
		local bb = b + (c - b) * t
		return aa + (bb - aa) * t
	end,

	get_idle_animation_name = function(character_info)
		-- 배틀 스타일을 가져옴
		local battle_style_data = CS.Oak.GameDataService.GetData('BattleStyleData')
		local battle_style = battle_style_data:FindBattleStyle(character_info)
		-- 배틀 스타일이 유효하지 않다면 생략
		if battle_style == nil then
			return 'idle'
		end

		-- idle 애니메이션 가져옴
		local idle_anim = CS.Oak.BattleStyleSpecExtensions.GetCustomIdleAnimation(battle_style, character_info.Costume)
		return idle_anim ~= nil and idle_anim or 'idle'
	end,

	get_walk_animation_name = function(character_info)
		-- 배틀 스타일을 가져옴
		local battle_style_data = CS.Oak.GameDataService.GetData('BattleStyleData')
		local battle_style = battle_style_data:FindBattleStyle(character_info)
		-- 배틀 스타일이 유효하지 않다면 생략
		if battle_style == nil then
			return 'walk'
		end

		-- walk 애니메이션 가져옴
		local walk_anim = CS.Oak.BattleStyleSpecExtensions.GetCustomWalkAnimation(battle_style, character_info.Costume)
		return walk_anim ~= nil and walk_anim or 'walk'
	end,
}
