local local_class = newclass("TrainNightmareStageEventController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.get_train = function(index) return get_character('train_' .. index) end
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	if stage.Name == 'nightmare_steampunk_1' or stage.Name == 'nightmare_steampunk_4' or stage.Name == 'nightmare_steampunk_5' then
		local train = self.get_train(1)
		train.SpineController.IsShadowActive = false
	elseif stage.Name == 'nightmare_steampunk_3' or stage.Name == 'nightmare_steampunk_6' then
		for i = 1, 2 do
			local train = self.get_train(i)
			train.SpineController.IsShadowActive = false
		end
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}