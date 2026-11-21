
-- VIPChat | Roube uma Espada
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

TextChatService.OnIncomingMessage = function(message)
	local properties = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local player = Players:GetPlayerByUserId(
			message.TextSource.UserId
		)

		if player and player:GetAttribute("HasVIP") == true then
			properties.PrefixText =
				'<font color="#FFD700">[VIP]</font> '
				.. message.PrefixText
		end
	end

	return properties
end

print("[VIPChat] Sistema de tag VIP iniciado!")
