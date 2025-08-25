local GameBrowser = nil
local function OpenGameBrowser()
	if IsValid(GameBrowser) then GameBrowser:Remove() end

	GameBrowser = vgui.Create('DFrame')
	GameBrowser:SetTitle('声音素材浏览')
	GameBrowser:SetSize(500, 500)
	GameBrowser:Center()
	GameBrowser:SetSizable(true)
	GameBrowser:MakePopup()
	GameBrowser:SetDeleteOnClose(true)
	GameBrowser.soundobj = nil
    GameBrowser.selectFile = nil
	
	local browser = vgui.Create('DFileBrowser', GameBrowser)
	browser:Dock(FILL)
	browser:SetPath('GAME') 
	browser:SetBaseFolder('') 
	browser:SetOpen(true) 

	function GameBrowser:SetCurrentFolder(folder) 
		browser:SetCurrentFolder(folder)
	end
	
	return GameBrowser
end

concommand.Add('rb_open_gamebrow', function(ply, cmd, args)
	local browser = OpenGameBrowser()
	local folder = args[1] or ''
	browser:SetCurrentFolder(folder)
end)





