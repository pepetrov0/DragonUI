-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.
-- Adapted from Blizzard's retail FrameXML NineSlice system for DragonUI.

local addon = select(2, ...)

local ipairs, pairs, error, setmetatable = ipairs, pairs, error, setmetatable

local atlasShim = addon.AtlasShim

-- Kept in apply order: corners first, since edges and the centre anchor to them.
local pieceRules = {}
local kitPieces = {}

local function addRule(name, rule)
	rule.name = name
	pieceRules[#pieceRules + 1] = rule
end

-- Anchor pair spanning spot a to spot b; a nil target means the container itself.
local function span(a, b, targetA, targetB)
	local pointA, pointB = a:upper(), b:upper()
	return { { pointA, targetA, pointB }, { pointB, targetB, pointA } }
end

for _, row in ipairs({ "Top", "Bottom" }) do
	for _, column in ipairs({ "Left", "Right" }) do
		local spot = row .. column
		addRule(spot .. "Corner", { corner = spot:upper() })
		kitPieces[spot .. "Corner"] = { atlas = "%s-nineslice-corner" .. spot:lower() }
	end
end

for _, side in ipairs({ "Top", "Bottom", "Left", "Right" }) do
	local across = side == "Top" or side == "Bottom"
	local a, b = "Top" .. side, "Bottom" .. side
	if across then
		a, b = side .. "Left", side .. "Right"
	end
	local toContainer = span(a, b)
	addRule(side .. "Edge", {
		anchors = span(a, b, a .. "Corner", b .. "Corner"),
		vertical = toContainer,
		horizontal = toContainer,
	})
	-- Atlas naming marks strips that tile across with "_" and strips that tile down with "!".
	kitPieces[side .. "Edge"] = { atlas = (across and "_" or "!") .. "%s-nineslice-edge" .. side:lower() }
end

addRule("Center", {
	anchors = span("TopLeft", "BottomRight", "TopLeftCorner", "BottomRightCorner"),
	vertical = { { "TOPLEFT", "TopEdge", "BOTTOMLEFT" }, { "BOTTOMRIGHT", "BottomEdge", "TOPRIGHT" } },
	horizontal = { { "TOPLEFT", "LeftEdge", "TOPRIGHT" }, { "BOTTOMRIGHT", "RightEdge", "BOTTOMLEFT" } },
})
kitPieces.Center = { atlas = "%s-nineslice-center" }

local layoutRegistry = {
	-- Retail's PortraitFrameTemplate. The top-left corner carries the portrait cutout, so it
	-- overhangs 13px left / 16px up; the bottom-left must match or LeftEdge joins two offsets.
	PortraitFrameTemplate = {
		TopLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft", x = -13, y = 16},
		TopRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight", x = 4, y = 16},
		BottomLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -13, y = -3},
		BottomRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3},
		TopEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", x = -4, y = 0, x1 = 4, y1 = 0},
		BottomEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", x = 0, y = 0, x1 = 0, y1 = 0},
		LeftEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", x = 0, y = 0, x1 = 0, y1 = 0},
		RightEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", x = 0, y = 0, x1 = 0, y1 = 0}
	},

	-- PortraitFrameTemplate with the wide top-right corner for a maximize button beside close.
	PortraitFrameTemplateMinimizable = {
		TopLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft", x = -13, y = 16},
		TopRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRightDouble", x = 4, y = 16},
		BottomLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -13, y = -3},
		BottomRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3},
		TopEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", x = -4, y = 0, x1 = 4, y1 = 0},
		BottomEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", x = 0, y = 0, x1 = 0, y1 = 0},
		LeftEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", x = 0, y = 0, x1 = 0, y1 = 0},
		RightEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", x = 0, y = 0, x1 = 0, y1 = 0}
	},

	-- Retail's ButtonFrameTemplateNoPortrait: PortraitFrameTemplate with the cutout corner swapped
	-- for the plain one. Geometry is untouched because both carry the same 12px of left padding --
	-- the -13 is what every left-side piece on this sheet needs, cutout or not.
	NoPortraitFrameTemplate = {
		TopLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft", x = -13, y = 16},
		TopRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight", x = 4, y = 16},
		BottomLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -13, y = -3},
		BottomRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3},
		TopEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", x = -4, y = 0, x1 = 4, y1 = 0},
		BottomEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", x = 0, y = 0, x1 = 0, y1 = 0},
		LeftEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", x = 0, y = 0, x1 = 0, y1 = 0},
		RightEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", x = 0, y = 0, x1 = 0, y1 = 0}
	},

	-- Retail InsetFrameTemplate: thin inner gold trim around a recessed content area.
	InsetFrameTemplate = {
		TopLeftCorner = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerTopLeft" },
		TopRightCorner = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerTopRight" },
		BottomLeftCorner = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerBotLeftCorner", y = -1 },
		BottomRightCorner = { layer = "BORDER", subLevel = -5, atlas = "UI-Frame-InnerBotRight", y = -1 },
		TopEdge = { layer = "BORDER", subLevel = -5, atlas = "_UI-Frame-InnerTopTile" },
		BottomEdge = { layer = "BORDER", subLevel = -5, atlas = "_UI-Frame-InnerBotTile" },
		LeftEdge = { layer = "BORDER", subLevel = -5, atlas = "!UI-Frame-InnerLeftTile" },
		RightEdge = { layer = "BORDER", subLevel = -5, atlas = "!UI-Frame-InnerRightTile" },
	},

	-- What DialogBorderTemplate resolves to: retail frames a popup with this, NOT with the inset trim.
	-- Every piece is pushed out by RAIL_PAD because the rail is only 16 thick inside a 64 piece and
	-- sits 8.5 in; anchored flush the whole border draws inset and the window's ground shows past it.
	Dialog = {
		TopLeftCorner = {atlas = "UI-Frame-DiamondMetal-CornerTopLeft", x = -8, y = 8},
		TopRightCorner = {atlas = "UI-Frame-DiamondMetal-CornerTopRight", x = 8, y = 8},
		BottomLeftCorner = {atlas = "UI-Frame-DiamondMetal-CornerBottomLeft", x = -8, y = -8},
		BottomRightCorner = {atlas = "UI-Frame-DiamondMetal-CornerBottomRight", x = 8, y = -8},
		-- No offsets of their own: SetupEdge chains these to the CORNERS, so they already carry the
		-- corners' push. Repeating it here is what left the rails floating off their own frame.
		TopEdge = {atlas = "_UI-Frame-DiamondMetal-EdgeTop"},
		BottomEdge = {atlas = "_UI-Frame-DiamondMetal-EdgeBottom"},
		LeftEdge = {atlas = "!UI-Frame-DiamondMetal-EdgeLeft"},
		RightEdge = {atlas = "!UI-Frame-DiamondMetal-EdgeRight"}
	},

	-- The metal frame without the portrait cutout. All four corners are the 32px pair, the top two
	-- flipped: mixing them with the ornate 75px tops makes each side edge join two widths.
	MetalFrameTemplate = {
		TopLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft-Thin", x = -4, y = 3},
		TopRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight-Thin", x = 4, y = 3},
		BottomLeftCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -4, y = -3},
		BottomRightCorner = {layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3},
		-- Flush against both corners. The portrait layout insets the top edge because its left
		-- corner overhangs 13px; with symmetric corners that inset just opens a gap at the join.
		TopEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", x = 0, y = 0, x1 = 0, y1 = 0},
		BottomEdge = {layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", x = 0, y = 0, x1 = 0, y1 = 0},
		LeftEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", x = 0, y = 0, x1 = 0, y1 = 0},
		RightEdge = {layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", x = 0, y = 0, x1 = 0, y1 = 0}
	},
}

-- Its atlas names embed the texture kit, so one kit picks the whole art set.
layoutRegistry.UniqueCornersLayout = kitPieces

-- ---------------------------------------------------------------------------
-- Window border styles. Each named window layout has a variant per art kit; GetLayout hands out
-- the one the "Window Borders" setting picks, so a window built for either kit wears either art.
-- Layers match the DragonUI variant of the same name so a window's stacking never changes.
-- ---------------------------------------------------------------------------

-- Forever's metal frame, corner offsets as its own chrome places them (forever_atlas_chrome.lua).
local function foreverMetal(layer, topLeft, left)
	return {
		TopLeftCorner = { layer = layer, atlas = topLeft, x = left, y = 16 },
		TopRightCorner = { layer = layer, atlas = "ui-frame-metal-cornertopright", x = 2, y = 16 },
		BottomLeftCorner = { layer = layer, atlas = "ui-frame-metal-cornerbottomleft", x = left, y = -8 },
		BottomRightCorner = { layer = layer, atlas = "ui-frame-metal-cornerbottomright", x = 2, y = -8 },
		TopEdge = { layer = layer, atlas = "_ui-frame-metal-edgetop" },
		BottomEdge = { layer = layer, atlas = "_ui-frame-metal-edgebottom" },
		LeftEdge = { layer = layer, atlas = "!ui-frame-metal-edgeleft" },
		RightEdge = { layer = layer, atlas = "!ui-frame-metal-edgeright" },
	}
end

local foreverPortrait = foreverMetal("OVERLAY", "ui-frame-portraitmetal-cornertopleft", -13)
local foreverPlain = foreverMetal("OVERLAY", "ui-frame-metal-cornertopleft", -8)

local styleVariants = {
	forever = {
		PortraitFrameTemplate = foreverPortrait,
		-- Forever has no double corner; the maximize button sits on the plain top edge.
		PortraitFrameTemplateMinimizable = foreverPortrait,
		NoPortraitFrameTemplate = foreverPlain,
		MetalFrameTemplate = foreverPlain,
		-- Forever's diamond art is the same 64px sheet drawn at half size, flush with the frame.
		Dialog = {
			TopLeftCorner = { atlas = "ui-frame-diamondmetal-cornertopleft", scale = 0.5 },
			TopRightCorner = { atlas = "ui-frame-diamondmetal-cornertopright", scale = 0.5 },
			BottomLeftCorner = { atlas = "ui-frame-diamondmetal-cornerbottomleft", scale = 0.5 },
			BottomRightCorner = { atlas = "ui-frame-diamondmetal-cornerbottomright", scale = 0.5 },
			TopEdge = { atlas = "_ui-frame-diamondmetal-edgetop", scale = 0.5 },
			BottomEdge = { atlas = "_ui-frame-diamondmetal-edgebottom", scale = 0.5 },
			LeftEdge = { atlas = "!ui-frame-diamondmetal-edgeleft", scale = 0.5 },
			RightEdge = { atlas = "!ui-frame-diamondmetal-edgeright", scale = 0.5 },
		},
	},
}

-- The name rides on the table so a frame dressed with it can be redressed when the style changes.
-- Only window layouts are tagged: the action bars' kit layout has no style to follow.
for _, variants in pairs(styleVariants) do
	for name, layout in pairs(variants) do
		layoutRegistry[name]._name = name
		variants[name] = setmetatable({ _name = name }, { __index = layout })
	end
end

-- "auto" follows the unit frame art, like every other style switch.
local function currentStyle()
	local profile = addon.db and addon.db.profile
	local wanted = profile and profile.style and profile.style.window_borders
	if wanted == "dragonui" or wanted == "forever" then
		return wanted
	end
	local unitframe = profile and profile.unitframe
	return unitframe and unitframe.frame_style == "forever" and "forever" or "dragonui"
end

local function getLayout(name, style)
	if name == nil then
		return nil
	end
	local variants = styleVariants[style or currentStyle()]
	return variants and variants[name] or layoutRegistry[name]
end

local function acquirePiece(container, pieceName)
	local supplier = container.GetNineSlicePiece
	local found = supplier and supplier(container, pieceName) or container[pieceName]
	if found then
		return found, false
	end
	local fresh = container:CreateTexture()
	container[pieceName] = fresh
	return fresh, true
end

local function anchorTarget(container, pieceName)
	if pieceName == nil then
		return container
	end
	return (acquirePiece(container, pieceName))
end

-- Read from the plain Lua field, never the XML attribute of the same name.
local function threeSliceMode(container)
	local named = getLayout(container.layoutType)
	if not named then
		return nil
	end
	if named.threeSliceVertical then
		return "vertical"
	end
	if named.threeSliceHorizontal then
		return "horizontal"
	end
	return nil
end

local function anchorPiece(container, tex, rule, spec, mode)
	tex:ClearAllPoints()
	if rule.corner then
		local point, relativePoint = spec.point or rule.corner, spec.relativePoint or rule.corner
		tex:SetPoint(point, container, relativePoint, spec.x, spec.y)
		return
	end
	local anchors = mode and rule[mode] or rule.anchors
	local near, far = anchors[1], anchors[2]
	tex:SetPoint(near[1], anchorTarget(container, near[2]), near[3], spec.x, spec.y)
	tex:SetPoint(far[1], anchorTarget(container, far[2]), far[3], spec.x1, spec.y1)
end

local function dressPiece(tex, spec, textureKit)
	tex:SetAtlasTexture(atlasShim.GetFinalNameFromTextureKit(spec.atlas, textureKit), true)
	local scale = spec.scale
	if scale then
		tex:SetSize(tex:GetWidth() * scale, tex:GetHeight() * scale)
	end
end

-- Every container dressed with a named window layout, so a style change can redress it in place.
local styled = setmetatable({}, { __mode = "k" })

-- layer, when given, overrides each piece's own: the caller owns where its border stacks.
local function applyLayout(container, layout, textureKit, layer)
	if not layout then
		error("DragonUI_NineSlice.ApplyLayout: layout is nil", 2)
	end
	local mode = threeSliceMode(container)
	for _, rule in ipairs(pieceRules) do
		local spec = layout[rule.name]
		if spec then
			local piece, isNew = acquirePiece(container, rule.name)
			if layer then
				piece:SetDrawLayer(layer)
			elseif isNew then
				piece:SetDrawLayer(spec.layer or "BORDER", spec.subLevel)
			end
			anchorPiece(container, piece, rule, spec, mode)
			dressPiece(piece, spec, textureKit)
		end
	end
	if layout._name then
		styled[container] = { name = layout._name, kit = textureKit, layer = layer }
	end
end

-- Close buttons wear the border's art too. Each entry is { file, left, right, top, bottom } per state;
-- DragonUI's sheet keeps disabled at 41..79, not pushed.
local REDBUTTON = addon._dir .. "UI\\redbutton2x"
local closeArt = {
	dragonui = {
		Normal = { REDBUTTON, 39/256, 75/256, 1/128, 39/128 },
		Pushed = { REDBUTTON, 39/256, 75/256, 81/128, 119/128 },
		Disabled = { REDBUTTON, 39/256, 75/256, 41/128, 79/128 },
		-- Left as the client's old minimize glow otherwise: a square Wrath flare over a modern red X.
		Highlight = { REDBUTTON, 115/256, 151/256, 1/128, 39/128 },
	},
}

-- Forever's pieces come from its atlas, which loads after this file.
local function foreverCloseArt()
	local atlas = addon.ForeverAtlas
	local function state(name)
		local info = atlas[name]
		return { info[1], info[4], info[5], info[6], info[7] }
	end
	return {
		Normal = state("redbutton-exit"),
		Pushed = state("redbutton-exit-pressed"),
		Disabled = state("redbutton-exit-disabled"),
		Highlight = state("redbutton-highlight"),
	}
end

local closeButtons = setmetatable({}, { __mode = "k" })

local function dressCloseButton(button)
	local style = currentStyle()
	if style == "forever" and not closeArt.forever then
		closeArt.forever = foreverCloseArt()
	end
	local art = closeArt[style] or closeArt.dragonui
	for _, state in ipairs({ "Normal", "Pushed", "Disabled" }) do
		local piece = art[state]
		button["Set" .. state .. "Texture"](button, piece[1])
		button["Get" .. state .. "Texture"](button):SetTexCoord(piece[2], piece[3], piece[4], piece[5])
	end
	local glow = art.Highlight
	button:SetHighlightTexture(glow[1], "ADD")
	button:GetHighlightTexture():SetTexCoord(glow[2], glow[3], glow[4], glow[5])
end

-- Each kit seats its X against its own corner: DragonUI windows at (1, 0), Forever's at (-2, 1).
local FOREVER_CLOSE_SHIFT_X, FOREVER_CLOSE_SHIFT_Y = -3, 1

local function placeCloseButton(button)
	local spot = closeButtons[button]
	if not (spot and spot.owner) then
		return
	end
	local x, y = spot.x, spot.y
	if currentStyle() == "forever" then
		x, y = spot.foreverX or x + FOREVER_CLOSE_SHIFT_X, spot.foreverY or y + FOREVER_CLOSE_SHIFT_Y
	end
	button:ClearAllPoints()
	button:SetPoint("TOPRIGHT", spot.owner, "TOPRIGHT", x, y)
end

-- Dresses a window's close button in the current style and keeps it in step when the style changes.
-- With an owner it also seats the button: x, y is the DragonUI spot (default 1, 0); the Forever spot
-- defaults to the same shift Forever's own windows use.
local function skinCloseButton(button, owner, x, y, foreverX, foreverY)
	closeButtons[button] = { owner = owner, x = x or 1, y = y or 0, foreverX = foreverX, foreverY = foreverY }
	dressCloseButton(button)
	placeCloseButton(button)
end

-- A red title-bar button's atlas in the current style: Forever's twin carries the client's -c60 suffix.
local function buttonAtlas(name)
	if currentStyle() == "forever" then
		local forever = name .. "-c60"
		if addon.ForeverAtlas and addon.ForeverAtlas[forever] then
			return forever
		end
	end
	return name
end

-- Painters for title-bar buttons a module draws itself (expand/condense); rerun on a style change.
local restylers = {}
local function onRestyle(painter)
	restylers[#restylers + 1] = painter
end

-- Redresses every styled border with the current style's art; vertex colours (dark mode) survive.
local function restyle()
	-- Some close buttons are secure (spellbook); moving those in combat is blocked, so wait it out.
	if InCombatLockdown() and addon.CombatQueue then
		addon.CombatQueue:Add("window_borders_restyle", restyle)
		return
	end
	for container, applied in pairs(styled) do
		applyLayout(container, getLayout(applied.name), applied.kit, applied.layer)
	end
	for button in pairs(closeButtons) do
		dressCloseButton(button)
		placeCloseButton(button)
	end
	for _, painter in ipairs(restylers) do
		painter()
	end
end

_G.DragonUI_NineSlice = {
	ApplyLayout = applyLayout,
	GetLayout = getLayout,
	GetStyle = currentStyle,
	Restyle = restyle,
	SkinCloseButton = skinCloseButton,
	PlaceCloseButton = placeCloseButton,
	ButtonAtlas = buttonAtlas,
	OnRestyle = onRestyle,
}

local function inheritedAttribute(frame, key)
	return frame:GetAttribute(key) or frame:GetParent():GetAttribute(key)
end

_G.DragonUI_NineSlicePanelMixin = {
	GetFrameLayoutType = function(self)
		return inheritedAttribute(self, "layoutType")
	end,
	GetFrameLayoutTextureKit = function(self)
		return inheritedAttribute(self, "layoutTextureKit")
	end,
	-- layoutTextureLayer and ignoreInLayout stay unread, so both action-bar slices draw in BORDER.
	OnLoad = function(self)
		local chosen = getLayout(self:GetFrameLayoutType())
		if chosen ~= nil then
			applyLayout(self, chosen, self:GetFrameLayoutTextureKit())
		end
	end,
}
