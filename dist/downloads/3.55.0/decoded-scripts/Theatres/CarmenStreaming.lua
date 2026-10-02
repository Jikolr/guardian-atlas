local local_class = newclass('CarmenStreaming')

function local_class:init(cs_theatre)
	self.cs_theatre = cs_theatre
	self.carmen = cs_theatre.Carmen
	self.donation_widget = cs_theatre.DonationWidget
	self.dialogue = cs_theatre.Dialogue
	self.spine_holder = cs_theatre.SpineHolder
	self.live_dot = cs_theatre.LiveDot

	self.parts = {
		eyes = 'eyes',
		hand = 'hand',
		mouth = 'mouth'
	}

	self.progress = {
		none = 1,
		streaming = 2,
		over = 3
	}
	self.current_progress = self.progress.none

	self.normal_chat_pool = { 'cafe_s1_0_1', 'cafe_s1_0_2', 'cafe_s1_0_3', 'cafe_s1_0_4', 'cafe_s1_0_5' }
	self.special_chat_pool = {'cafe_s1_1_1', 'cafe_s1_1_2', 'cafe_s1_1_3'}
	self.spine_carmen = nil
	self.res_holder = nil
end

function local_class:start_streaming()
	return util.cs_generator(self.process, self)
end

function local_class:load()
	return util.cs_generator(self.on_load, self)
end
function local_class:on_load()
	self.res_holder = CS.Foundations.ResourceHolder()
	local asset_path = lua_helper.get_conditional_value(CS.Foundations.GameEnvironment.IsKongJapan,
			'ondemand/cafe/characters_kong', 'ondemand/cafe/characters')
	local asset_name = lua_helper.get_conditional_value(CS.Foundations.GameEnvironment.IsKongJapan,
			'boss_carmen_kong', 'boss_carmen')
	local carmen_go = load_util.load_prefab_async(self.res_holder, asset_path,asset_name)
	local carmen = carmen_go:GetComponent(typeof(CS.Oak.SpineController))

	carmen.transform.position = self.spine_holder.position
	carmen.transform.localScale = unity_class.vector3.one * 0.25
	carmen.Direction = character_util.get_direction('right')
	carmen:SetEmotion('smile', true)
	carmen:SetAnimation(1, 'dance', true)
	carmen:SetAlphaFade(0, 0)
	CS.Utils.ChangeLayersRecursively(carmen.transform, 'UI')
	self.spine_carmen = carmen
end

function local_class:process()
	self.current_progress = self.progress.streaming

	local amb_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_cf_02', loop = true, type_priority = 'event', fade_in_time = 2})
	screen_util.fade_in_async(1, unity_class.color.black)

	coroutine_manager:StartCoroutine(self.cs_theatre, util.cs_generator(self.viewers_chatting, self))
	coroutine_manager:StartCoroutine(self.cs_theatre, util.cs_generator(self.live_dot_animation, self))
	coroutine_manager:StartCoroutine(self.cs_theatre, util.cs_generator(self.blinking_eyes, self))

	-- 안뇽! 프렌즈들!
	self:set_eye('smile')
	self:set_hand('hi')
	self:talk('cafe_s1_1')

	-- 여러분들의 귀요미! 디지털 아이돌 카르멘쨩 등장이오!
	self:set_eye('open')
	self:set_hand('cute')
	self:talk('cafe_s1_2')

	-- 스페셜 챗 클리어
	self.special_chat_pool = {}

	-- 이름만 설정하고 대사창 클리어
	self.dialogue:SetName('cafe_carmen', true)
	self.dialogue:Show('')

	-- 도네이션 이벤트
	coroutine_manager:StartCoroutine(self.cs_theatre, util.cs_generator(self.donation_event, self))
	self:donation_reaction(0.7)

	-- 오늘은... 아, 카르멘님사랑해님 10000정기 후원 감사합니다~
	self:talk('cafe_s1_3')

	-- 나도 사랑해~ 쪽!
	self:talk('cafe_s1_4')

	-- 바로 본 방송으로 들어가 봅시다! 여러분은 서큐버스 타운의 드림 테라피에 대해 알고 계시나요?
	self:set_eye('open')
	self:set_hand('none')
	self:talk('cafe_s1_5')

	self.special_chat_pool = {}

	-- 서큐버스들이 음침한 구석으로 끌고 가서 반강제적으로 정기를 빼앗아 버린다고 하네요. 으윽... 기분 나빠...
	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	self:set_eye('hate')
	self:set_mouth('hate')
	self:talk('cafe_s1_6', true, false)

	-- 하지만! 우리 시청자분들은 그런 델 갈 필요가 전~혀 없다는 거! 이유는 다들 알고 계시죠?
	self:set_eye('open')
	self:set_hand('point')
	self:talk('cafe_s1_7')

	-- 깨끗하고 빠르고 간편한 온라인 시스템! OnlyFriends 너무 좋아!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	self:set_eye('smile')
	self:set_hand('heart')
	self:talk('cafe_s1_8')

	-- 드림 테라피 누가 감 ㅋㅋㅋ / 응~ 절대 안 가~ / OnlyFriends 보기도 바쁨 / OnlyFriends! OnlyFriends! OnlyFriends! OnlyFriends!
	self.special_chat_pool = {'cafe_s1_3_1', 'cafe_s1_3_2', 'cafe_s1_3_3', 'cafe_s1_3_4'}

	-- 이제 아무도 드림 테라피 같은 건 안 간다고~ 그렇죠, 여러분?
	self:talk('cafe_s1_9')

	-- 그런 의미에서! 잠깐 광고 타임!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	self:set_eye('open')
	self:set_hand('point')
	self:talk('cafe_s1_10')

	-- 손 / 손손손 / 발 / 저욧!
	self.special_chat_pool = {'cafe_s1_4_1', 'cafe_s1_4_2', 'cafe_s1_4_3', 'cafe_s1_4_4'}

	-- 저희 OnlyFriends에서 크리에이터 분들을 모집합니다!
	self:set_hand('none')
	self:talk('cafe_s1_11')

	-- 여러분들의 아이돌! 저 카르멘처럼 귀엽고 이쁜 사람부터~
	music_player:PlaySfxOneShot('01_bad_fairy_01')
	self:set_eye('smile')
	self:set_hand('cute')
	self:talk('cafe_s1_12')

	-- 카바 / 잘가~ / 방송 너무 짧네 / 가지 마!!!
	self.special_chat_pool = {'cafe_s1_5_1', 'cafe_s1_5_2', 'cafe_s1_5_3', 'cafe_s1_5_4'}

	-- 오늘의 카르멘은 여기까지! 다들, 카바~
	self:set_eye('smile')
	self:set_hand('hi')
	self:talk('cafe_s1_14')

	amb_sfx:FadeOut(2)
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	screen_util.fade_out_async(1, unity_class.color.black)

	-- 방송을 종료시켜주고 코루틴들이 끝날때까지 한프레임 기다려준다.
	self.current_progress = self.progress.over
	coroutine.yield()
end

function local_class:talk(key, skip, use_animation)
	skip = lua_helper.get_or_default(skip, true)
	use_animation = lua_helper.get_or_default(use_animation, true)

	local mouth_routine = function()
		local time_passed = 0
		local cycle = 0
		while self.dialogue.IsTalking do
			if time_passed >= cycle then
				local mouth_opened = self.carmen:Find('mouth/open').gameObject.activeSelf
				self:set_mouth(mouth_opened and 'half_close' or 'open')
				time_passed = 0
				cycle = unity_class.random.Range(0.1, 0.15)
			end

			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield()
		end
	end

	local routines = { self.dialogue:Show('cafe_carmen', key, skip) }
	if use_animation then
		table.insert(routines, util.cs_generator(mouth_routine))
	end
	wait_all(routines)
end

function local_class:live_dot_animation()
	local active_cycle = 1
	local dot = self.live_dot

	local time_passed = 0
	while self.current_progress == self.progress.streaming do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed >= active_cycle then
			time_passed = 0
			dot.cachedGameObject:SetActive(not dot.cachedGameObject.activeSelf)
		end

		coroutine.yield()
	end
end

function local_class:set_part(part_name, type_name)
	local part = self.carmen:Find(part_name).transform
	local child_count = part.childCount
	for i = 0, child_count - 1 do
		local child = part:GetChild(i)
		if child.name == type_name then
			child.gameObject:SetActive(true)
		else
			child.gameObject:SetActive(false)
		end
	end
end

function local_class:set_eye(type_name)
	self:set_part(self.parts.eyes, type_name)
end

function local_class:set_hand(type_name)
	self:set_part(self.parts.hand, type_name)
end

function local_class:set_mouth(type_name)
	self:set_part(self.parts.mouth, type_name)
end

function local_class:viewers_chatting()
	local normal_time_passed = 0
	local normal_cycle = 1
	local special_time_passed = 0
	local special_cycle = 1
	while self.current_progress == self.progress.streaming do
		normal_time_passed = normal_time_passed + unity_class.time.deltaTime
		special_time_passed = special_time_passed + unity_class.time.deltaTime

		if normal_time_passed >= normal_cycle then
			local chat_key = self.normal_chat_pool[random_util.get_random_int(1, #self.normal_chat_pool)]
			self.cs_theatre:AppendChat(chat_key)
			normal_time_passed = 0
			normal_cycle = unity_class.random.Range(0.5, 1)
		end

		if special_time_passed >= special_cycle then
			special_time_passed = 0
			if self.special_chat_pool ~= nil and #self.special_chat_pool > 0 then
				local chat_key = self.special_chat_pool[random_util.get_random_int(1, #self.special_chat_pool)]
				self.cs_theatre:AppendChat(chat_key)
				special_cycle = unity_class.random.Range(0.5, 1)
			end
		end

		coroutine.yield()
	end
end

function local_class:donation_event()
	local label = self.donation_widget.cachedTransform:Find('label'):GetComponent(typeof(CS.UILabel))
	label.text = game_string:GetString('cafe_carmen_donation')

	music_player:PlaySfxOneShot('01_alarm_01')
	self.spine_carmen:SetAlphaFade(1, 0.5)
	coroutine.yield(CS.Oak.UI.UIAnimations.Alpha(self.donation_widget, 0.5, 1))

	wait_for_sec(5)

	self.spine_carmen:SetAlphaFade(0, 1)
	coroutine.yield(CS.Oak.UI.UIAnimations.Alpha(self.donation_widget, 1, 0))
end

function local_class:donation_reaction(delay)
	wait_for_sec(delay)

	self:set_eye('smile')
	self:set_hand('heart')

	-- 카르멘 시청자들이 리액션에 반응
	-- 와 미쳤다 / 개 부럽네 진짜 / 나도 해줘!!! / 10000정기는 인정이지
	self.special_chat_pool = { 'cafe_s1_2_1', 'cafe_s1_2_2', 'cafe_s1_2_3', 'cafe_s1_2_4' }
end

function local_class:get_current_eyes()
	local eyes = self.carmen:Find('eyes').transform
	local child_count = eyes.childCount
	for i = 0, child_count - 1 do
		local child = eyes:GetChild(i)
		if child.gameObject.activeSelf then
			return child.gameObject
		end
	end
end

function local_class:blinking_eyes()
	local cycle = 0;
	local time_passed = 0;
	local last_eyes

	while self.current_progress == self.progress.streaming do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed >= cycle then
			time_passed = 0

			local current_eyes = self:get_current_eyes()
			if current_eyes.name ~= 'close' and current_eyes.name ~= 'smile' then
				last_eyes = current_eyes.name
				self:set_eye('close')
				cycle = unity_class.random.Range(0.1, 0.15)
			elseif current_eyes.name == 'close' then
				self:set_eye(last_eyes)
				cycle = unity_class.random.Range(3, 4)
			end
		end

		coroutine.yield()
	end
end

function local_class:dispose()
	if self.spine_carmen ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.spine_carmen.gameObject)
	end

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end

	self.res_holder = nil
	self.dialogue = nil
	self.spine_holder = nil
	self.live_dot = nil
	self.spine_carmen = nil
	self.carmen = nil
	self.donation_widget = nil
	self.normal_chat_pool = nil
	self.special_chat_pool = nil
	self.progress = nil
	self.parts = nil
	self.cs_theatre = nil
end


return {
	create = function(cs_theatre)
		return local_class(cs_theatre)
	end
}
