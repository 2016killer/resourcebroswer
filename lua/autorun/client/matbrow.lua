local min, max = math.min, math.max

local icondefault = Material('error')

local function LoadMaterials(path, failed)
	-- 加载游戏目录的材质或插件封面
	-- 失败默认不应用于插件模式
	if tonumber(path) ~= nil then
		local wsid = path
		local asyncmat = {
			mat = icondefault, 
			downloading = true
		}

		local start = CurTime()
		steamworks.FileInfo(wsid, function(result)
			// PrintTable(result)
			local err = result.error
			if err then
				RBWarn('查询失败', tostring(err), 'wsid:'..tostring(wsid))
			elseif result.previewurl == '' then
				RBWarn('插件无预览图', 'wsid:'..tostring(wsid))
			else
				local previewid = result.previewid
				steamworks.Download(previewid, true, function(name)
					asyncmat.downloading = false
					if name == nil then
						RBWarn('下载失败', 'previewid:'..tostring(previewid))
					else
						local mat = AddonMaterial(name)		
						if mat == nil then 
							RBWarn('加载失败', name)
						else
							asyncmat.mat = mat
						end
						print('加载时间:', CurTime() - start)
					end
				end)	
			end
		end)
	
		return asyncmat
	elseif isstring(path) and path ~= '' then
		return Material(path)
	else
		return failed or icondefault
	end
end

local function SetMaterial(mat)
	if istable(mat) then
		-- 处理异步材质
		surface.SetMaterial(mat.mat)
	else
		surface.SetMaterial(mat)
	end
end

-- 创建文本浏览器函数
function CreateTextBrowser(title, filePath)
    -- 创建主窗口
    local frame = vgui.Create("DFrame")
    frame:SetTitle(title or "文本浏览器")
    frame:SetSize(400, 300)
    frame:Center()
    frame:MakePopup()
    
    -- 创建滚动面板（用于支持长文本滚动）
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    
    -- 创建文本显示区域
    local textPanel = vgui.Create("DLabel", scroll)
    textPanel:Dock(TOP)
    textPanel:SetFont("DermaDefaultBold") -- 设置字体
    textPanel:SetTextColor(Color(255, 255, 255)) -- 文本颜色
    textPanel:SetWrap(true) -- 自动换行
    textPanel:SetContentAlignment(7) -- 左对齐
    textPanel:SetWide(frame:GetWide() - 20) -- 宽度
    
    -- 尝试读取文件内容
    if filePath and file.Exists(filePath, "GAME") then
        local content = file.Read(filePath, "GAME")
        textPanel:SetText(content or "文件内容为空")
    else
        textPanel:SetText("无法找到指定文件: " .. (filePath or "未知路径"))
    end
    
    -- 调整文本面板高度以适应内容
    textPanel:SizeToContentsY()
    
    return frame
end
----------------------------
local MaterialsBrowser
local page = 1
local filterinput = ''
local function OpenMaterialsBrowser()
	if IsValid(MaterialsBrowser) then MaterialsBrowser:Remove() end
	local scrw, scrh = ScrW(), ScrH()
	
	MaterialsBrowser = vgui.Create('DFrame')
	MaterialsBrowser:SetTitle('材质素材浏览')
	MaterialsBrowser:SetSize(scrw * 0.5, scrh * 0.5)
	MaterialsBrowser:Center()
	MaterialsBrowser:SetSizable(true)
	MaterialsBrowser:MakePopup()
	MaterialsBrowser:SetDeleteOnClose(true)
	MaterialsBrowser:SetMinimumSize(120 , 100)
	MaterialsBrowser.selectmaterial = nil
	MaterialsBrowser.selectFile = nil

	local Tabs = vgui.Create('DPropertySheet', MaterialsBrowser)
	local ViewPort = vgui.Create('DPanel', MaterialsBrowser)
	local Div = vgui.Create('DHorizontalDivider', MaterialsBrowser)

	Div:Dock(FILL)
	Div:SetLeft(Tabs)
	Div:SetRight(ViewPort)
	Div:SetDividerWidth(4)
	Div:SetLeftMin(20) 
	Div:SetRightMin(20)
	Div:SetLeftWidth(scrw * 0.5 * 0.7)

	local background = Color(255, 255, 255, 200)
	function ViewPort:Paint(w, h)
		draw.RoundedBox(5, 0, 0, w, h, background)
		if MaterialsBrowser.selectmaterial then
			local matWidth = min(w, h)
			local cx, cy = (w - matWidth) * 0.5, (h - matWidth) * 0.5
			surface.SetDrawColor(255, 255, 255, 255)
			SetMaterial(MaterialsBrowser.selectmaterial)
			surface.DrawTexturedRect(cx, cy, matWidth, matWidth)
		end
	end
	----
	local AddonBrowser = vgui.Create('DPanel', Tabs)
	local AddonFilterInput = vgui.Create('DTextEntry', AddonBrowser)
	local AddonTree = vgui.Create('DTree', AddonBrowser)
	local ButtonPanel = vgui.Create('DPanel', AddonBrowser)
	local LastBtn = vgui.Create('DButton', ButtonPanel)
	local NextBtn = vgui.Create('DButton', ButtonPanel)
	local PageLabel = vgui.Create('DLabel', ButtonPanel)

	AddonFilterInput:Dock(TOP)
	AddonTree:Dock(FILL)
	ButtonPanel:Dock(BOTTOM)

	LastBtn:SetText('上一页')
	NextBtn:SetText('下一页')

	LastBtn:Dock(LEFT)
	NextBtn:Dock(LEFT)
	NextBtn:DockMargin(10, 0, 10, 0)
	PageLabel:Dock(LEFT)
	PageLabel:SetColor(Color(0, 0, 0))

	local pnum = 20
	local addonsfilter = {}
	
	function AddonTree:OnNodeSelected()
		local wsid = self:GetSelectedItem().wsid
		if MaterialsBrowser.selectFile == wsid then return end

		MaterialsBrowser.selectmaterial = LoadMaterials(wsid, icondefault)
		MaterialsBrowser.selectFile = wsid

		if isfunction(MaterialsBrowser.OnSelect) then
			MaterialsBrowser:OnSelect(MaterialsBrowser.selectFile, MaterialsBrowser.selectmaterial)
		end
	end

	function AddonBrowser:Search(str)
		filterinput = str
		if str == '' then
			addonsfilter = engine.GetAddons()
		else
			addonsfilter = {}
			local lowerSearchStr = string.lower(str)
			for _, addon in pairs(engine.GetAddons()) do
				if addon.wsid ~= '' and string.find(string.lower(addon.title), lowerSearchStr, 1, true) then
					table.insert(addonsfilter, addon)
				end
			end
		end
	end

	function AddonBrowser:GetPage()
		return page
	end

	function AddonBrowser:SetPage(num)
		AddonTree:Clear()
		local pagemax = math.max(1, math.ceil(#addonsfilter / pnum))
		page = math.Clamp(num, 1, pagemax) 

		local start = (page - 1) * pnum + 1
		local ed = min(page * pnum, #addonsfilter)
		for i = start, ed do
			local addon = addonsfilter[i]
			local wsid = addon.wsid
			if wsid ~= '' then
				local node = AddonTree:AddNode(addon.title or '', 'icon16/page.png')
				node.wsid = wsid	
			end
		end

		PageLabel:SetText(tostring(page) .. '/' .. tostring(pagemax))
	end


	LastBtn.DoClick = function()
		AddonBrowser:SetPage(AddonBrowser:GetPage() - 1)
	end

	NextBtn.DoClick = function()
		AddonBrowser:SetPage(AddonBrowser:GetPage() + 1)
	end

	function AddonFilterInput:OnValueChange(value)
		AddonBrowser:Search(value)
		AddonBrowser:SetPage(1)
	end
	----
	local GameMatBrowser = vgui.Create('DPanel', Tabs)
	local FileBrowser = vgui.Create('DFileBrowser', GameMatBrowser)

	FileBrowser:Dock(FILL)
	FileBrowser:SetPath('GAME') 
	FileBrowser:SetBaseFolder('materials') 
	FileBrowser:SetOpen(true) 

	function FileBrowser:OnSelect(filePath, _) 
		local matfile = string.sub(filePath, 11, -1)
		if MaterialsBrowser.selectFile == matfile then return end

		MaterialsBrowser.selectmaterial = Material(matfile)
		MaterialsBrowser.selectFile = matfile
		if isfunction(MaterialsBrowser.OnSelect) then
			MaterialsBrowser:OnSelect(MaterialsBrowser.selectFile, MaterialsBrowser.selectmaterial)
		end
	end
	
	function FileBrowser:OnRightClick(filePath, _) 
		local menu = DermaMenu() 
		local copy = menu:AddOption('复制', function() 
			SetClipboardText(string.sub(filePath, 11, -1)) 
		end)
		copy:SetImage('materials/icon16/application_double.png')
		
		menu:Open()
	end

	function FileBrowser:OnDoubleClick(filePath, selectedPanel)
		if string.EndsWith(filePath, '.vmt') then
			CreateTextBrowser(filePath, filePath)
		end
	end

	function MaterialsBrowser:SetCurrentFolder(folder) 
		FileBrowser:SetCurrentFolder(folder)
	end

	Tabs:AddSheet('游戏', GameMatBrowser, 'materials/icon16/add.png', false, false, '')
	Tabs:AddSheet('插件', AddonBrowser, 'icon16/bricks.png', false, false, '')
	
	AddonBrowser:Search(filterinput)
	AddonBrowser:SetPage(page)

	return MaterialsBrowser
end

concommand.Add('rb_open_matbrow', function(ply, cmd, args)
	local browser = OpenMaterialsBrowser()
	local folder = args[1] or ''
	browser:SetCurrentFolder(folder)
end)




-- 示例：创建一个显示"example.txt"文件的文本浏览器
-- 注意：文件需要放在garrysmod/data/目录下
-- CreateTextBrowser("我的文本文件", "example.txt")