local SoundsBrowser = nil
local function OpenSoundsBrowser()
	if IsValid(SoundsBrowser) then SoundsBrowser:Remove() end

	SoundsBrowser = vgui.Create('DFrame')
	SoundsBrowser:SetTitle('声音素材浏览')
	SoundsBrowser:SetSize(500, 500)
	SoundsBrowser:Center()
	SoundsBrowser:SetSizable(true)
	SoundsBrowser:MakePopup()
	SoundsBrowser:SetDeleteOnClose(true)
	SoundsBrowser.soundobj = nil
    SoundsBrowser.selectFile = nil
	
	local browser = vgui.Create('DFileBrowser', SoundsBrowser)
	browser:Dock(FILL)
	browser:SetPath('GAME') 
	browser:SetBaseFolder('sound') 
	browser:SetOpen(true) 

	function browser:OnDoubleClick(path)
		if SoundsBrowser.soundobj then
			SoundsBrowser.soundobj:Stop()
			SoundsBrowser.soundobj = nil	
		end
        SoundsBrowser.selectFile = string.sub(path, 7, -1)
		SoundsBrowser.soundobj = CreateSound(LocalPlayer(), SoundsBrowser.selectFile)
		SoundsBrowser.soundobj:PlayEx(1, 100)

        if isfunction(SoundsBrowser.OnSelect) then
            SoundsBrowser:OnSelect(SoundsBrowser.selectFile)
        end
	end

	function SoundsBrowser:OnRemove()
		if SoundsBrowser.soundobj then
			SoundsBrowser.soundobj:Stop()
			SoundsBrowser.soundobj = nil	
		end
	end

	function SoundsBrowser:SetCurrentFolder(folder) 
		browser:SetCurrentFolder(folder)
	end
	
	return SoundsBrowser
end

concommand.Add('rb_open_soundbrow', function(ply, cmd, args)
	local browser = OpenSoundsBrowser()
	local folder = args[1] or ''
	browser:SetCurrentFolder(folder)
end)





