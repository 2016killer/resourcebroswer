local phrase = language.GetPhrase

function RBProgress(...)
	local text = ''
	for _, v in ipairs({...}) do
		text = text .. phrase(v) .. ' '
	end
	notification.AddProgress('fcmd_notify_progress', text)
	timer.Simple(0.5, function()
		notification.Kill('fcmd_notify_progress')
	end)
end

function RBHelp(...)
	surface.PlaySound('NPC.ButtonBlip1')
	local text = ''
	for _, v in ipairs({...}) do
		text = text .. phrase(v) .. ' '
	end
	notification.AddLegacy(text, NOTIFY_HINT, 5)
end

function RBError(...)
	surface.PlaySound('Buttons.snd10')
	local text = ''
	for _, v in ipairs({...}) do
		text = text .. phrase(v) .. ' '
	end
	notification.AddLegacy(text, NOTIFY_ERROR, 5)
end

function RBWarn(...)
	surface.PlaySound('Buttons.snd8')
	local text = ''
	for _, v in ipairs({...}) do
		text = text .. phrase(v) .. ' '
	end
	notification.AddLegacy(text, NOTIFY_GENERIC, 5)
end
