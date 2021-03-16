CompilerIf Not Defined(MaterialVector,#PB_Module)
	IncludeFile "MaterialVector\MaterialVector.pbi"
CompilerEndIf

CompilerIf Not Defined(CanvasButton,#PB_Module)
	IncludeFile "CanvasButton\CanvasButton.pbi"
CompilerEndIf

DeclareModule PureTL
	; Public variables, structures, constants...
	EnumerationBinary ;Flags
		#Default = 0
		#LightTheme = 0
		
		#DarkTheme
		#Header
		#Border
	EndEnumeration
	
	EnumerationBinary 1 ; Items flags
		#Item_ShowChildrenPoints
		#Item_ShowParentBlocks
		#Item_InheritColor
	EndEnumeration
	
	Enumeration ;Content Type
		#Content_Media
		#Content_DataPoints
	EndEnumeration
	
	; Public procedures declaration
	Declare Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
	
	Declare AddItem(Gadget, Name.s, Position, ParentID = 0, Flags = #Default)
	Declare AddMediaBlock(Gadget, ItemID, Start, Finish, ID)
	Declare AddDataPoint(Gadget, ItemID, Position, ID)
	
	Declare GetItemID(Gadget, Position, ParentID = 0)
	
	Declare SetDuration(Gadget, Duration)
	
	Declare RemoveItem(Gadget, Item)
	
	Declare Freeze(Gadget, State) ;Disable the redrawing of the gadget (Should be used before a large amount is done to avoid CPU consumption spike)
	Declare Resize(Gadget, x, y, Width, Height)
	
EndDeclareModule

Module PureTL
	EnableExplicit
	;{ Private variables, structures, constants...
	
	Enumeration ;Fold
		#NoFold
		#Folded
		#Unfolded
	EndEnumeration
	
	Enumeration 1 ; MediaBlock Type
		#MediaBlock_Start
		#MediaBlock_Body
		#MediaBlock_End
	EndEnumeration
	
	EnumerationBinary
		#Redraw_Body = 0
		#Redraw_Header
		#Redraw_ItemList
		#Redraw_StateOnly
		#Redraw_Everything = #Redraw_Header | #Redraw_ItemList
	EndEnumeration
	
	#Color_Palette_Count = 4
	
	#DefaultDuration = 119
	
	Structure Content
		MediaBlock_End.l
		MediaBlock_Origin.l
		MediaBlock_ID.i
		MediaBlock_Type.b
		
		DataPoint.b
		DataPoint_Count.i
		DataPoint_ID.i
	EndStructure

	Structure Itemlist
		*item.Item
	EndStructure
	
	Structure Item
		Name.s
		Folded.b
		ShowChildrenPoints.b
		ShowParentsBlocks.b
		DisplayListAdress.i
		*Parent.Item
		List Items.Itemlist()
		Array Content.Content(1)
		Color_Light.l
		Color.l
		Color_Dark.l
		
		;Draw info
		XOffset.i
; 		Image.i
	EndStructure
	
	Structure GadgetData
		;Flags & options
		Header.b
		Border.b
		
		;Componants
		VScrollbar_ID.i
		VScrollbar_Visible.b
		VScrollbar_Width.i
		VScrollbar_Page.i
		VScrollbar_Position.i
		
		HScrollbar_ID.i
		HScrollbar_Visible.b
		HScrollbar_Height.i
		HScrollbar_Page.i
		HScrollbar_Position.i
		
		ButtonPlay_ID.i
		ButtonEnd_ID.i
		ButtonStart_ID.i
		
		;state
		ItemList_Width.i
		State.i
		ItemList_Warm.i
		ItemList_PreviousWarm.i
		ItemList_Toggle.i
		ItemList_PreviousToggle.i
		
		Duration.i
		
		;Redraw
		Frozen.b
		YOffset.i
		XOffset.i
		Body_Height.i
		Body_Width.i
		Body_ColumnWidth.i
		FontID.i
		Font.i
		FontSize.i
		VisibleItems.i												;current maximum number of displayable item. Will change when resizing or showing/hiding the header
		VisibleColumns.i											;current  maximum number of displayable time unit. Will change when resizing or zooming.
			
		Color_Border.i
		
		Color_Body_Back.i
		Color_Body_BackAlt.i
		Color_Body_BackHot.i
		
		Color_ItemList_Back.i
		Color_ItemList_Front.i
		Color_ItemList_BackHot.i
		Color_ItemList_FrontHot.i
		Color_ItemList_BackWarm.i
		Color_ItemList_FrontWarm.i
		
		Color_Index.i
		
		Array Color_Content.l(#Color_Palette_Count)
		Array Color_Content_Light.l(#Color_Palette_Count)
		Array Color_Content_Dark.l(#Color_Palette_Count)
		
		List DisplayList.Itemlist()
		
		;Items
		List Items.Itemlist()
		
	EndStructure
	
	;Style
	#Style_Header_Height = 60
	#Style_Header_ButtonSize = 30
	#Style_Header_ButtonSpace = 20
	#Style_BorderThickness = 1
	
	#Style_ItemList_Width = 240
	#Style_ItemList_ItemHeight = 58
	
	#Style_ItemList_XOffset = 24
	#Style_ItemList_FoldSize = 12
	#Style_ItemList_FoldOffset = 10
	#Style_ItemList_RoundedBoxOffset = 8
	#Style_ItemList_SubItemOffset = 12
	
	#Style_ItemList_FoldVOffset = (#Style_ItemList_ItemHeight - #Style_ItemList_FoldSize) / 2 + 1
	#Style_ItemList_TextVOffset = (#Style_ItemList_ItemHeight - 20) / 2
	#Style_ItemList_FontSize	= 20
	
	#Style_VectorText = #True 										; I find the vector drawn text to impair readability too much on Windows, so we'll fallback on the classic 2D drawing for text... Though drawing twice on the same canvas provokes the occasional flikering.
	
	#Style_Body_DefaultColumnWidth = 14								
	#Style_Body_Margin = 2											; Number of empty column placed at the start and the end of the timeline, making the gadget more legible.
	#Style_Body_PointSize = 4.5
	#Style_Body_VOffset = #Style_ItemList_ItemHeight / 2
	#Style_Body_HOffset = #Style_Body_DefaultColumnWidth / 2
	#Style_Body_MediablockMargin = 2
	#Style_Body_MediablockLineThickness = 2
	
	Global DefaultFont = LoadFont(#PB_Any, "Bebas Neue", #Style_ItemList_FontSize, #PB_Font_HighQuality)
	
	;Colors
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows ; RGB/GBR switcharoo...
		#Color_Border = $FF101010
		
		#Color_ItemList_Dark_Back = $FF36312F
		#Color_ItemList_Dark_BackHot = $FF433C39
		#Color_ItemList_Dark_BackWarm = $FF3C3734
		
		#Color_ItemList_Dark_Front = $FF97928E
		#Color_ItemList_Dark_FrontHot = $FFFFFFFF
		#Color_ItemList_Dark_FrontWarm = $FFDEDDDC
		
		#Color_ItemList_Light_Back = $FFF5F3F2
		#Color_ItemList_Light_BackHot = $FFDCD7D4
		#Color_ItemList_Light_BackWarm = $FFEDEAE8
		
		#Color_ItemList_Light_Front = $FF80746A
		#Color_ItemList_Light_FrontHot = $FF070606
		#Color_ItemList_Light_FrontWarm = $FF38332E
		
		#Color_Body_Dark_Back    = $FF393532
		#Color_Body_Dark_BackAlt = $FF3F3936
		#Color_Body_Dark_BackHot = $FF46403C
		
		#Color_Body_Light_Back    = $FFF3EDEA
		#Color_Body_Light_BackAlt = $FFE9E3E0
		#Color_Body_Light_BackHot = $FFDCD7D4
		
		#Color_Content_Warm_Palette00 = 	$FFF1C58A
		#Color_Content_Warm_Palette01 = 	$FF8CB5F3
		#Color_Content_Warm_Palette02 = 	$FF8686ED
		#Color_Content_Warm_Palette03 = 	$FFA0E6B5
		#Color_Content_Warm_Palette04 = 	$FFEE87CD
		
		#Color_Content_Light_Palette00 =	$FFE0C198
		#Color_Content_Light_Palette01 =	$FF9DB9E5
		#Color_Content_Light_Palette02 =	$FF8F8FD7
		#Color_Content_Light_Palette03 =	$FFAEDFBD
		#Color_Content_Light_Palette04 =	$FFD991C2
		
		#Color_Content_Palette00 =			$FFE38E17
		#Color_Content_Palette01 =			$FF1C70E8
		#Color_Content_Palette02 =			$FF0F0FDB
		#Color_Content_Palette03 =			$FF53CC41
		#Color_Content_Palette04 =			$FFDC109F
		
	CompilerElse
		
		#Color_Border = $101010FF
		
		#Color_ItemList_Dark_Back = $2F3136FF
		#Color_ItemList_Dark_BackHot = $393C43FF
		#Color_ItemList_Dark_BackWarm = $34373CFF
		
		#Color_ItemList_Dark_Front = $8E9297FF
		#Color_ItemList_Dark_FrontHot = $FFFFFFFF
		#Color_ItemList_Dark_FrontWarm = $DCDDDEFF
		
		#Color_ItemList_Light_Back = $F2F3F5FF
		#Color_ItemList_Light_BackHot = $D4D7DCFF
		#Color_ItemList_Light_BackWarm = $E8EAEDFF
		
		#Color_ItemList_Light_Front = $6A7480FF
		#Color_ItemList_Light_FrontHot = $060607FF
		#Color_ItemList_Light_FrontWarm = $2E3338FF
		
		#Color_Body_Dark_Back = $323539FF
		#Color_Body_Dark_BackAlt = $36393FFF
		#Color_Body_Dark_BackHot = $3C4046FF
		
		#Color_Body_Light_Back    = $FFEAEDF3
		#Color_Body_Light_BackAlt = $FFE0E3E9
		#Color_Body_Light_BackHot = $D4D7DCFF
		
		#Color_Content_Light_Palette00 =	$8AC5F1FF
		#Color_Content_Light_Palette01 =	$F3B58CFF
		#Color_Content_Light_Palette02 =	$ED8686FF
		#Color_Content_Light_Palette03 =	$B5E6A0FF
		#Color_Content_Light_Palette04 =	$CD87EEFF
		
		#Color_Content_Palette00 =			$178EE3FF
		#Color_Content_Palette01 =			$E8701CFF
		#Color_Content_Palette02 =			$DB0F0FFF
		#Color_Content_Palette03 =			$1EE437FF
		#Color_Content_Palette04 =			$9F10DCFF
		
	CompilerEndIf
	;}
	
	; Private procedures declaration
	Declare Redraw(Gadget, RedrawPart = #Redraw_Body)
	
	Declare HandlerCanvas()
	
	Declare HandlerVScrollbar()
	
	Declare HandlerHScrollbar()
	
	Declare Refit(Gadget)
	
	Declare ItemList_ToggleFold(Gadget, *Item.Item)
	
	Declare DrawFoldIcon(X, Y, Fold, FrontColor, BackColor = 0)
	
	Macro FocusOnSelection
		If *Data\State < *Data\VScrollbar_Position
			SetGadgetState(*Data\VScrollbar_ID, *Data\State)
			*Data\VScrollbar_Position = GetGadgetState(*Data\VScrollbar_ID)
		ElseIf *Data\State >= *Data\VScrollbar_Position + *Data\VisibleItems
			SetGadgetState(*Data\VScrollbar_ID, *Data\State - *Data\VisibleItems + 1)
			*Data\VScrollbar_Position = GetGadgetState(*Data\VScrollbar_ID)
		EndIf
	EndMacro
	
	Macro ItemListHover
		Item = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) + *data\VScrollbar_Position
		
		If SelectElement(*Data\DisplayList(), Item)
			If *Data\DisplayList()\item\Folded
				If MouseX >= *Data\DisplayList()\item\XOffset - 2 And MouseX <= *Data\DisplayList()\item\XOffset + #Style_ItemList_FoldSize + 2
					YPos = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_FoldVOffset - 2
					If MouseY >= YPos And MouseY <= YPos + #Style_ItemList_FoldSize + 4
						If *Data\ItemList_Warm > -1
							*Data\ItemList_PreviousWarm = *Data\ItemList_Warm
							*Data\ItemList_Warm = -1
						EndIf
						
						If *Data\ItemList_Toggle <> Item
							*Data\ItemList_Toggle = Item
							Redraw = #True
						EndIf
						
						If EventType() = #PB_EventType_MouseMove
							If Redraw
								Redraw(Gadget, #Redraw_StateOnly)
							EndIf
							ProcedureReturn
						EndIf
					EndIf
				EndIf
			EndIf
			
			If *Data\ItemList_Toggle > -1
				*Data\ItemList_PreviousToggle = *Data\ItemList_Toggle
				*Data\ItemList_Toggle = -1
				Redraw = #True
			EndIf
			
			If Item <> *Data\ItemList_Warm
				If Item <> *Data\State And MouseX > *data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset And MouseX < *Data\XOffset - #Style_ItemList_RoundedBoxOffset
					If *Data\ItemList_PreviousToggle = Item
						*Data\ItemList_PreviousToggle = -1
					EndIf
					*Data\ItemList_PreviousWarm = *Data\ItemList_Warm
					*Data\ItemList_Warm = Item
					Redraw = #True
				Else
					If *Data\ItemList_Warm > -1
						*Data\ItemList_PreviousWarm = *Data\ItemList_Warm
						*Data\ItemList_Warm = -1
						Redraw = #True
					EndIf
				EndIf
			ElseIf Not (MouseX > *data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset And MouseX < *Data\XOffset - #Style_ItemList_RoundedBoxOffset)
				If *Data\ItemList_Warm > -1
					*Data\ItemList_PreviousWarm = *Data\ItemList_Warm
					*Data\ItemList_Warm = -1
					Redraw = #True
				EndIf
			EndIf
		EndIf
	EndMacro
	
	Declare MoveMediaBlock(*Data.GadgetData, *ItemID.Item, Position, Offset)
	
	Declare AddPathMediaBlock(x, y, Width, Height, Radius)
	
	; Public procedures
	Procedure Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
		Protected Result.i, *Data.GadgetData, Theme
		Result = CanvasGadget(Gadget, X, Y, Width, Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
		
		If Result
			If Gadget = #PB_Any
				Gadget = Result
			EndIf
			
			*Data = AllocateStructure(GadgetData)
			
			With *Data
				\Color_Border = #Color_Border
				
				If Flags & #DarkTheme
					\Color_Body_Back = #Color_Body_Dark_Back
					\Color_Body_BackAlt = #Color_Body_Dark_BackAlt
					\Color_Body_BackHot = #Color_Body_Dark_BackHot
					
					\Color_ItemList_Back = #Color_ItemList_Dark_Back
					\Color_ItemList_Front = #Color_ItemList_Dark_Front
					\Color_ItemList_BackHot = #Color_ItemList_Dark_BackHot
					\Color_ItemList_FrontHot = #Color_ItemList_Dark_FrontHot
					\Color_ItemList_BackWarm = #Color_ItemList_Dark_BackWarm
					\Color_ItemList_FrontWarm = #Color_ItemList_Dark_FrontWarm
					
					Theme = CanvasButton::#DarkTheme
				Else
					\Color_Body_Back = #Color_Body_Light_Back
					\Color_Body_BackAlt = #Color_Body_Light_BackAlt
					\Color_Body_BackHot = #Color_Body_Light_BackHot
					
					\Color_ItemList_Back = #Color_ItemList_Light_Back
					\Color_ItemList_Front = #Color_ItemList_Light_Front
					\Color_ItemList_BackHot = #Color_ItemList_Light_BackHot
					\Color_ItemList_FrontHot = #Color_ItemList_Light_FrontHot
					\Color_ItemList_BackWarm = #Color_ItemList_Light_BackWarm
					\Color_ItemList_FrontWarm = #Color_ItemList_Light_FrontWarm
					
					Theme = CanvasButton::#LightTheme
				EndIf
				
				\Color_Content_Light(0) = #Color_Content_Light_Palette00
				\Color_Content_Light(1) = #Color_Content_Light_Palette01
				\Color_Content_Light(2) = #Color_Content_Light_Palette02
				\Color_Content_Light(3) = #Color_Content_Light_Palette03
				\Color_Content_Light(4) = #Color_Content_Light_Palette04
				
				\Color_Content(0) = #Color_Content_Palette00
				\Color_Content(1) = #Color_Content_Palette01
				\Color_Content(2) = #Color_Content_Palette02
				\Color_Content(3) = #Color_Content_Palette03
				\Color_Content(4) = #Color_Content_Palette04
				
				\Border = Bool(Flags & #Border) * #Style_BorderThickness
				\Header = Bool(Flags & #Header)
				
				If \Header
					\ButtonStart_ID = CanvasButton::GadgetImage(#PB_Any,
					                                                 (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5, (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
					                                                 #Style_Header_ButtonSize,
					                                                 #Style_Header_ButtonSize,
					                                                 MaterialVector::#Skip,
					                                                 CanvasButton::#MaterialVectorIcon | Theme | MaterialVector::#style_rotate_180)
					CanvasButton::SetColor(\ButtonStart_ID, CanvasButton::#ColorType_BackCold, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonStart_ID, CanvasButton::#ColorType_BackWarm, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonStart_ID, CanvasButton::#ColorType_BackHot, \Color_ItemList_Back)
					
					\ButtonPlay_ID = CanvasButton::GadgetImage(#PB_Any, (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + #Style_Header_ButtonSize + #Style_Header_ButtonSpace,
					                                                (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
					                                                #Style_Header_ButtonSize,
					                                                #Style_Header_ButtonSize,
					                                                MaterialVector::#Play,
					                                                CanvasButton::#MaterialVectorIcon | Theme)
					CanvasButton::SetColor(\ButtonPlay_ID, CanvasButton::#ColorType_BackCold, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonPlay_ID, CanvasButton::#ColorType_BackWarm, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonPlay_ID, CanvasButton::#ColorType_BackHot, \Color_ItemList_Back)
					
					\ButtonEnd_ID = CanvasButton::GadgetImage(#PB_Any, (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + (#Style_Header_ButtonSize + #Style_Header_ButtonSpace) * 2, (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
					                                               #Style_Header_ButtonSize,
					                                               #Style_Header_ButtonSize,
					                                               MaterialVector::#Skip,
					                                               CanvasButton::#MaterialVectorIcon | Theme)
					
					CanvasButton::SetColor(\ButtonEnd_ID, CanvasButton::#ColorType_BackCold, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonEnd_ID, CanvasButton::#ColorType_BackWarm, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonEnd_ID, CanvasButton::#ColorType_BackHot, \Color_ItemList_Back)
				EndIf
				
				\ItemList_Width = #Style_ItemList_Width
				\YOffset = \Border + \Header * #Style_Header_Height
				\Body_ColumnWidth = #Style_Body_DefaultColumnWidth
				
				\State = -1
				\ItemList_Warm = -1
				\ItemList_PreviousWarm = -1
				\ItemList_Toggle = -1
				\ItemList_PreviousToggle = -1
				\Duration = #DefaultDuration
				
				\VScrollbar_ID = ScrollBarGadget(#PB_Any, 0, \YOffset, 20, \Body_Height, 0, 10, 10,   #PB_ScrollBar_Vertical)
				BindGadgetEvent(\VScrollbar_ID, @HandlerVScrollbar())
				\VScrollbar_Width = GadgetWidth(\VScrollbar_ID, #PB_Gadget_RequiredSize)
				\VScrollbar_Visible = #False
				HideGadget(\VScrollbar_ID, #True)
				SetGadgetData(\VScrollbar_ID, Gadget)
				
				\HScrollbar_ID = ScrollBarGadget(#PB_Any, 0, \YOffset, 20, \Body_Height, 0, \Duration + #Style_Body_Margin, 10)
				BindGadgetEvent(\HScrollbar_ID, @HandlerHScrollbar())
				\HScrollbar_Height = GadgetHeight(\HScrollbar_ID, #PB_Gadget_RequiredSize)
				\HScrollbar_Visible = #False
				HideGadget(\HScrollbar_ID, #True)
				SetGadgetData(\HScrollbar_ID, Gadget)
				
				\FontID = FontID(DefaultFont)
				\Font = DefaultFont
				\FontSize = #Style_ItemList_FontSize
			EndWith
			CloseGadgetList()
			
			SetGadgetData(Gadget, *Data)
			BindGadgetEvent(Gadget, @HandlerCanvas())
			
			Refit(Gadget)
		EndIf
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure AddItem(Gadget, Name.s, Position, *Parent.Item = 0, Flags = #Default)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Result.Item = AllocateStructure(Item)
		
		If *Parent.Item ;{ Add a subitem
			If Position = -1 Or Position >= ListSize(*Parent\Items())
				If *Parent\DisplayListAdress And *Parent\Folded = #Unfolded
					If ListSize(*Parent\Items()) = 0
						ChangeCurrentElement(*Data\DisplayList(), *Parent\DisplayListAdress)
					Else
						LastElement(*Parent\Items())
						ChangeCurrentElement(*Data\DisplayList(), *Parent\Items()\item\DisplayListAdress)
					EndIf
					AddElement(*Data\DisplayList())
					*Result\DisplayListAdress = @*Data\DisplayList()
					*Data\DisplayList()\item = *Result
				Else
					LastElement(*Parent\Items())
				EndIf
				AddElement(*Parent\Items())
			Else
				If *Parent\DisplayListAdress And *Parent\Folded = #Unfolded
					If Position = 0
						ChangeCurrentElement(*Data\DisplayList(), *Parent\DisplayListAdress)
					Else
						SelectElement(*Parent\Items(), Position)
						ChangeCurrentElement(*Data\DisplayList(), *Parent\Items()\item\DisplayListAdress)
					EndIf
					AddElement(*Data\DisplayList())
					*Result\DisplayListAdress = @*Data\DisplayList()
					*Data\DisplayList()\item = *Result
				Else
					SelectElement(*Parent\Items(), Position)
				EndIf
				InsertElement(*Parent\Items())
			EndIf
			
			*Parent\Items()\item = *Result
			
			If *Parent\Folded = #NoFold
				*Parent\Folded = #Folded
			EndIf
			
			*Result\Parent = *Parent
			*Result\XOffset = *Parent\XOffset + #Style_ItemList_SubItemOffset + #Style_ItemList_FoldSize + #Style_ItemList_FoldOffset
			
			If Flags & #Item_InheritColor
				*Result\Color = *Parent\Color
				*Result\Color_Light = *Parent\Color_Light
				*Result\Color_Dark = *Parent\Color_Dark
			Else
				*Result\Color = *Data\Color_Content_Light(*Data\Color_Index)
				*Result\Color_Light = *Data\Color_Content(*Data\Color_Index)
				*Result\Color_Dark =*Data\Color_Content_Dark(*Data\Color_Index)
				
				*Data\Color_Index = (*Data\Color_Index + 1) % (#Color_Palette_Count + 1)
			EndIf
			
			*Result\ShowParentsBlocks = Flags & #Item_ShowParentBlocks
			;}
		Else ;{ add a normal item
			If Position = -1 Or Position >= ListSize(*Data\Items())
				LastElement(*Data\Items())
				AddElement(*Data\Items())
				LastElement(*Data\DisplayList())
				AddElement(*Data\DisplayList())
			Else
				SelectElement(*Data\Items(), Position)
				InsertElement(*Data\Items())
				NextElement(*Data\Items())
				ChangeCurrentElement(*Data\DisplayList(), *Data\Items()\item\DisplayListAdress)
				InsertElement(*Data\DisplayList())
			EndIf
			
			*Data\Items()\item = *Result
			*Result\DisplayListAdress = @*Data\DisplayList()
			*Result\XOffset = #Style_ItemList_XOffset
			*Data\DisplayList()\item = *Result
			
			*Result\Color = *Data\Color_Content_Light(*Data\Color_Index)
			*Result\Color_Light = *Data\Color_Content(*Data\Color_Index)
			*Result\Color_Dark =*Data\Color_Content_Dark(*Data\Color_Index)
			
			*Data\Color_Index = (*Data\Color_Index + 1) % (#Color_Palette_Count + 1)			
			
		EndIf ;}
		
		*Result\ShowChildrenPoints = Flags & #Item_ShowChildrenPoints
		*Result\Name = Name
		
		ReDim *Result\Content(*Data\Duration)
		
		;There might be a need to display the vscrollingbar now...
		Refit(Gadget)
		
		ProcedureReturn *Result
	EndProcedure
	
	Procedure GetItemID(Gadget, Position, *Parent.Item = 0)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Result
		
		If *Parent
			If SelectElement(*Parent\Items(), Position)
				*Result = *Parent\Items()\item
			EndIf
		Else
			If SelectElement(*Data\Items(), Position)
				*Result = *Data\Items()\item
			EndIf
		EndIf
		
		ProcedureReturn *Result
	EndProcedure
	
	Procedure RemoveItem(Gadget, Item)
		
	EndProcedure
	
	Procedure SetDuration(Gadget, Duration)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		
		*Data\Duration = Duration
		
		SetGadgetAttribute(*Data\HScrollbar_ID, #PB_ScrollBar_Maximum, *Data\Duration + #Style_Body_Margin)
		Refit(Gadget)
	EndProcedure
	
	Procedure Freeze(Gadget, State)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		*Data\Frozen = State
		
		If *Data\Frozen And Not State
			*Data\Frozen = #False
			Redraw(Gadget, #True)
		EndIf
		
		*Data\Frozen = State
	EndProcedure
	
	Procedure Resize(Gadget, x, y, Width, Height)
		ResizeGadget(Gadget, x, y, Width, Height)
		Refit(Gadget)
	EndProcedure
	
	Procedure AddMediaBlock(Gadget, *ItemID.Item, Start, Finish, ID)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		Protected Loop
		
		If Finish > *Data\Duration
			Finish = *Data\Duration
		EndIf
		
		*ItemID\Content(Start)\MediaBlock_Type = #MediaBlock_Start
		
		*ItemID\Content(Start)\MediaBlock_Origin = Start
		*ItemID\Content(Start)\MediaBlock_End = Finish
		*ItemID\Content(Start)\MediaBlock_ID = ID
		
		For loop = Start + 1 To Finish
			If *ItemID\Content(loop)\MediaBlock_Type
				MoveMediaBlock(*Data, *ItemID, loop, *ItemID\Content(loop)\MediaBlock_End - loop)
			EndIf
			
			*ItemID\Content(loop)\MediaBlock_Type = #MediaBlock_Body
			
			*ItemID\Content(loop)\MediaBlock_Origin = Start
			*ItemID\Content(loop)\MediaBlock_End = Finish
			*ItemID\Content(loop)\MediaBlock_ID = ID
		Next
		
		*ItemID\Content(Finish)\MediaBlock_Type = #MediaBlock_End
		
	EndProcedure
	
	Procedure AddDataPoint(Gadget, *ItemID.Item, Position, ID)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		
		*ItemID\Content(Position)\DataPoint = #True
		*ItemID\Content(Position)\DataPoint_ID = ID
		
		*ItemID = *ItemID\Parent
		
		While *ItemID
			If *ItemID\ShowChildrenPoints
				*ItemID\Content(Position)\DataPoint + 1
			EndIf
			
			*ItemID = *ItemID\Parent
		Wend
		
	EndProcedure
	
	; Private procedures
	
	Procedure AddPathMediaBlock(x, y, Width, Height, Radius)
		MovePathCursor(x + Width, y)
		AddPathArc(x, y, x,y + Height, Radius)
		AddPathLine(x, y + Height)
		AddPathLine(x + Width, y + Height)
		ClosePath()
	EndProcedure
	
	Procedure MoveMediaBlock(*Data.GadgetData, *ItemID.Item, Position, Offset)
		
	EndProcedure
	
	Procedure DrawFoldIcon(X, Y, Fold, FrontColor, BackColor = 0)
		If BackColor
			MaterialVector::AddPathRoundedBox(X - 4, Y - 4, #Style_ItemList_FoldSize + 8, #Style_ItemList_FoldSize + 8, 6)
			VectorSourceColor(BackColor)
			FillPath()
		EndIf
		
		If Fold = #Folded
			MaterialVector::Draw(MaterialVector::#Chevron, X, Y, #Style_ItemList_FoldSize, FrontColor, 0, MaterialVector::#style_rotate_90)
		Else
			MaterialVector::Draw(MaterialVector::#Chevron, X, Y, #Style_ItemList_FoldSize, FrontColor, 0, MaterialVector::#style_rotate_180)
		EndIf
		
	EndProcedure
	
	Procedure Redraw(Gadget, RedrawPart = #Redraw_Body)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		Protected Loop, YPos, Index, ContentLoop, ContentLoopDuration, MediaBlockDuration
		
		If *data\Frozen
			ProcedureReturn #False
		EndIf
		
		StartVectorDrawing(CanvasVectorOutput(Gadget))
		VectorFont(*data\FontID, *data\FontSize)
		
		If RedrawPart & #Redraw_StateOnly ;{
			If *Data\ItemList_PreviousWarm > -1
				
				SelectElement(*data\DisplayList(), *Data\ItemList_PreviousWarm)
				YPos = *data\YOffset + #Style_ItemList_ItemHeight * (ListIndex(*data\DisplayList()) - *data\VScrollbar_Position)
				
				AddPathBox(*data\Border, YPos, *data\ItemList_Width - 1, #Style_ItemList_ItemHeight)
				VectorSourceColor(*data\Color_ItemList_Back)
				FillPath()
				
				VectorSourceColor(*data\Color_ItemList_Front)
				MovePathCursor(*data\DisplayList()\item\XOffset + Bool(*data\DisplayList()\item\Folded) * (#Style_ItemList_FoldSize + #Style_ItemList_FoldOffset),
				               YPos + #Style_ItemList_TextVOffset)
				DrawVectorText(*data\DisplayList()\item\Name)
				
				If *data\DisplayList()\item\Folded
					DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_Front)
				EndIf
				
				*Data\ItemList_PreviousWarm = -1
			EndIf
			
			If *Data\ItemList_Warm > -1
				SelectElement(*data\DisplayList(), *Data\ItemList_Warm)
				YPos = *data\YOffset + #Style_ItemList_ItemHeight * (ListIndex(*data\DisplayList()) - *data\VScrollbar_Position)
				
				MaterialVector::AddPathRoundedBox(*data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset, YPos, *data\ItemList_Width - *data\DisplayList()\item\XOffset, #Style_ItemList_ItemHeight, 6)
				VectorSourceColor(*data\Color_ItemList_BackWarm)
				FillPath()
				
				VectorSourceColor(*data\Color_ItemList_FrontWarm)
				MovePathCursor(*data\DisplayList()\item\XOffset + Bool(*data\DisplayList()\item\Folded) * (#Style_ItemList_FoldSize + #Style_ItemList_FoldOffset),
				               YPos + #Style_ItemList_TextVOffset)
				DrawVectorText(*data\DisplayList()\item\Name)
				
				If *data\DisplayList()\item\Folded
					DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontWarm)
				EndIf
			EndIf
			
			If *data\ItemList_PreviousToggle > -1
				YPos = *data\YOffset + #Style_ItemList_ItemHeight * (ListIndex(*data\DisplayList()) - *data\VScrollbar_Position)
				If *data\ItemList_PreviousToggle = *data\State
					DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontHot, *data\Color_ItemList_BackHot)
				Else
					DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_Front, *data\Color_ItemList_Back)
				EndIf
				*data\ItemList_PreviousToggle = -1
			EndIf
			
			If *data\ItemList_Toggle > -1
				YPos = *data\YOffset + #Style_ItemList_ItemHeight * (ListIndex(*data\DisplayList()) - *data\VScrollbar_Position)
				
				If *data\ItemList_Toggle = *data\State
					DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontWarm, *data\Color_ItemList_BackWarm)
				Else
					DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontHot, *data\Color_ItemList_BackHot)
				EndIf
			EndIf
			
			StopVectorDrawing()
			ProcedureReturn #True
		EndIf ;}
		
		;{ Header
		If RedrawPart & #Redraw_Header
			; Redraw the header
			AddPathBox(*data\Border, *data\Border, *data\ItemList_Width, #Style_Header_Height)
			VectorSourceColor(*data\Color_ItemList_Back)
			FillPath()
		EndIf
		;}
		
		;{ Body and itemlist
		If RedrawPart & #Redraw_ItemList
			AddPathBox(*data\Border, *data\YOffset, *data\ItemList_Width, *data\Body_Height)
			VectorSourceColor(*data\Color_ItemList_Back)
			FillPath()
		EndIf
		
		AddPathBox(*data\XOffset, *data\YOffset, *data\Body_Width, *data\Body_Height)
		VectorSourceColor(*data\Color_Body_Back)
		FillPath()
		
		If SelectElement(*data\DisplayList(), *data\VScrollbar_Position)
			If *data\HScrollbar_Position + *data\VisibleColumns >= *data\Duration
				ContentLoopDuration = *data\Duration - *data\HScrollbar_Position
			Else
				ContentLoopDuration = *data\VisibleColumns
			EndIf
			
			For Loop = 0 To *data\VisibleItems
				YPos = Loop * #Style_ItemList_ItemHeight + *data\YOffset
				Index = ListIndex(*data\DisplayList())
				
				If Index  = *data\State
					If RedrawPart & #Redraw_ItemList
						MaterialVector::AddPathRoundedBox(*data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset, YPos, *data\ItemList_Width, #Style_ItemList_ItemHeight, 6)
						VectorSourceColor(*data\Color_ItemList_BackHot)
						FillPath()
					EndIf
					
					AddPathBox(*data\XOffset, *data\YOffset + (Loop) * #Style_ItemList_ItemHeight, *data\Body_Width, #Style_ItemList_ItemHeight)
					VectorSourceColor(*data\Color_Body_BackHot)
					FillPath()
				Else
					If Index = *data\ItemList_Warm
						MaterialVector::AddPathRoundedBox(*data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset, YPos, *data\ItemList_Width - *data\DisplayList()\item\XOffset, #Style_ItemList_ItemHeight, 6)
						VectorSourceColor(*data\Color_ItemList_BackWarm)
						FillPath()
					EndIf
					
					If (Loop + *data\VScrollbar_Position) % 2
						AddPathBox(*data\XOffset, YPos, *data\Body_Width, #Style_ItemList_ItemHeight)
						VectorSourceColor(*data\Color_Body_BackAlt)
						FillPath()
					EndIf
				EndIf
				
				If RedrawPart & #Redraw_ItemList
					If Index = *data\State
						If *data\DisplayList()\item\Folded
							If *data\ItemList_Toggle = Index
								DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontWarm, *data\Color_ItemList_BackWarm)
							Else
								DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontHot)
							EndIf
						EndIf
						VectorSourceColor(*data\Color_ItemList_FrontHot)
					ElseIf  Index = *data\ItemList_Warm
						If *data\DisplayList()\item\Folded
							DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontWarm)
						EndIf
						VectorSourceColor(*data\Color_ItemList_FrontWarm)
					Else
						If *data\DisplayList()\item\Folded
							If *data\ItemList_Toggle = Index
								DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_FrontHot, *data\Color_ItemList_BackHot)
							Else
								DrawFoldIcon(*data\DisplayList()\item\XOffset, YPos + #Style_ItemList_FoldVOffset, *data\DisplayList()\item\Folded, *data\Color_ItemList_Front)
							EndIf
						EndIf
						VectorSourceColor(*data\Color_ItemList_Front)
					EndIf
					
					If RedrawPart & #Redraw_ItemList
						MovePathCursor(*data\DisplayList()\item\XOffset + Bool(*data\DisplayList()\item\Folded) * (#Style_ItemList_FoldSize + #Style_ItemList_FoldOffset),
						               YPos + #Style_ItemList_TextVOffset)
						DrawVectorText(*data\DisplayList()\item\Name)
					EndIf
					
					If *data\DisplayList()\item\Content(*data\HScrollbar_Position)\MediaBlock_Type = #MediaBlock_Body
						MediaBlockDuration = *data\DisplayList()\item\Content(*data\HScrollbar_Position)\MediaBlock_End - (*data\HScrollbar_Position) + 1
							
						If MediaBlockDuration > ContentLoopDuration + 1
							MediaBlockDuration = ContentLoopDuration + 1
						EndIf
						
						AddPathBox(*data\XOffset, YPos + #Style_Body_MediablockMargin, MediaBlockDuration * *data\Body_ColumnWidth, #Style_ItemList_ItemHeight - #Style_Body_MediablockMargin * 2)
						VectorSourceColor( *data\DisplayList()\item\Color_Light )
						FillPath()
						
						AddPathBox(*data\XOffset, YPos + #Style_Body_MediablockMargin + #Style_Body_MediablockLineThickness,
						           MediaBlockDuration * *data\Body_ColumnWidth - #Style_Body_MediablockLineThickness,
						           #Style_ItemList_ItemHeight - #Style_Body_MediablockMargin * 2 - #Style_Body_MediablockLineThickness * 2)
						VectorSourceColor( *data\DisplayList()\item\Color )
						FillPath()
					ElseIf  *data\DisplayList()\item\Content(*data\HScrollbar_Position)\MediaBlock_Type = #MediaBlock_End
						AddPathBox(*data\XOffset, YPos + #Style_Body_MediablockMargin, *data\Body_ColumnWidth, #Style_ItemList_ItemHeight - #Style_Body_MediablockMargin * 2)
						VectorSourceColor( *data\DisplayList()\item\Color_Light )
						FillPath()
						
						AddPathBox(*data\XOffset, YPos + #Style_Body_MediablockMargin + #Style_Body_MediablockLineThickness,
						           *data\Body_ColumnWidth - #Style_Body_MediablockLineThickness,
						           #Style_ItemList_ItemHeight - #Style_Body_MediablockMargin * 2 - #Style_Body_MediablockLineThickness * 2)
						VectorSourceColor( *data\DisplayList()\item\Color )
						FillPath()
					EndIf
					
					For ContentLoop = 0 To ContentLoopDuration
						
						If *data\DisplayList()\item\Content(ContentLoop + *data\HScrollbar_Position)\MediaBlock_Type = #MediaBlock_Start
							MediaBlockDuration = *data\DisplayList()\item\Content(ContentLoop + *data\HScrollbar_Position)\MediaBlock_End - (ContentLoop + *data\HScrollbar_Position) + 1
							
							If MediaBlockDuration > ContentLoopDuration - ContentLoop + 1
								MediaBlockDuration = ContentLoopDuration - ContentLoop + 1
							EndIf
							
							AddPathMediaBlock(*data\XOffset + ContentLoop * *data\Body_ColumnWidth,
							                  YPos + #Style_Body_MediablockMargin, MediaBlockDuration * *data\Body_ColumnWidth,
							                  #Style_ItemList_ItemHeight - #Style_Body_MediablockMargin * 2,
							                  *data\Body_ColumnWidth)
							VectorSourceColor( *data\DisplayList()\item\Color_Light )
							FillPath()
							
							AddPathMediaBlock(*data\XOffset + ContentLoop * *data\Body_ColumnWidth + #Style_Body_MediablockLineThickness,
							                  YPos + #Style_Body_MediablockMargin + #Style_Body_MediablockLineThickness,
							                  MediaBlockDuration * *data\Body_ColumnWidth - #Style_Body_MediablockLineThickness * 2,
							                  #Style_ItemList_ItemHeight - #Style_Body_MediablockMargin * 2 - #Style_Body_MediablockLineThickness * 2,
							                  *data\Body_ColumnWidth - #Style_Body_MediablockLineThickness)
							VectorSourceColor( *data\DisplayList()\item\Color )
							FillPath()
							
						EndIf
						
						If *data\DisplayList()\item\Content(ContentLoop + *data\HScrollbar_Position)\DataPoint
							AddPathCircle(*data\XOffset + ContentLoop * *data\Body_ColumnWidth + #Style_Body_HOffset, YPos + #Style_Body_VOffset, #Style_Body_PointSize)
						EndIf
						
					Next
					VectorSourceColor( *data\DisplayList()\item\Color_Light )
					FillPath()
					
					If Not NextElement(*Data\DisplayList())
						Break
					EndIf
				EndIf
			Next
		EndIf
		;}
		
		;{ Border
		CompilerIf #Style_VectorText
			If *data\Border
				AddPathBox(0, 0, VectorOutputWidth(), VectorOutputHeight())
			EndIf
		CompilerEndIf
		
		MovePathCursor(*data\XOffset - 0.5, *data\YOffset + 0.5)
		AddPathLine(0, *data\Body_Height, #PB_Path_Relative)
		VectorSourceColor(*data\Color_Border)
		StrokePath(1)
		;}
		
		StopVectorDrawing()
	EndProcedure
	
	Procedure HandlerCanvas()
		Protected Gadget = EventGadget(), *Data.GadgetData = GetGadgetData(Gadget)
		Protected MouseX = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX), MouseY = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
		Protected Item, Redraw, YPos, Column
		
		Select EventType()
			Case #PB_EventType_MouseMove ;{
				If MouseY <= *data\YOffset ;{ Header
					If *Data\ItemList_Warm > -1 Or *Data\ItemList_Toggle > -1
						*Data\ItemList_PreviousToggle = *Data\ItemList_Toggle
						*Data\ItemList_Toggle = -1
						*Data\ItemList_PreviousWarm = *Data\ItemList_Warm
						*Data\ItemList_Warm = -1
						Redraw(Gadget, #Redraw_StateOnly)
					EndIf
					;}
				ElseIf MouseX < *data\XOffset ;{ Itemlist
					
					ItemListHover
					
					If Redraw
						Redraw(Gadget, #Redraw_StateOnly)
					EndIf
					;}
				Else ;{ Body
					If *Data\ItemList_Warm > -1 Or *Data\ItemList_Toggle > -1
						*Data\ItemList_PreviousToggle = *Data\ItemList_Toggle
						*Data\ItemList_Toggle = -1
						*Data\ItemList_PreviousWarm = *Data\ItemList_Warm
						*Data\ItemList_Warm = -1
						Redraw(Gadget, #Redraw_StateOnly)
					EndIf
					
					Item = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) + *data\VScrollbar_Position
					If SelectElement(*Data\DisplayList(), Item)
						Column = Round((MouseX - *Data\XOffset) / *Data\Body_ColumnWidth, #PB_Round_Down) + *Data\HScrollbar_Position
						
						If *Data\DisplayList()\item\Content(Column)\DataPoint
							Debug "datapoint!"
						EndIf
						
						If *Data\DisplayList()\item\Content(Column)\MediaBlock_Type
							Debug "Mediablock!"
						EndIf
						
					EndIf
					;}
				EndIf
				
				;}
			Case #PB_EventType_LeftButtonDown ;{
				If MouseY <= *data\YOffset ; Header
					
				ElseIf MouseX < *data\XOffset ;{ Itemlist
					If *Data\ItemList_Toggle > -1
						SelectElement(*Data\DisplayList(), *Data\ItemList_Toggle)
						ItemList_ToggleFold(Gadget, *Data\DisplayList()\item)
						Refit(Gadget)
					ElseIf *Data\ItemList_Warm > -1
						*Data\State = *Data\ItemList_Warm
						*Data\ItemList_Warm = -1
						Redraw(Gadget, #Redraw_ItemList)
					EndIf
					;}
				Else ; Timeline
					
				EndIf
				;}
			Case #PB_EventType_MouseLeave ;{
				If *Data\ItemList_Toggle > -1
					*Data\ItemList_PreviousToggle = *Data\ItemList_Toggle
					*Data\ItemList_Toggle = -1
					Redraw(Gadget, #Redraw_StateOnly)
				ElseIf *Data\ItemList_Warm > -1
					*Data\ItemList_PreviousWarm = *Data\ItemList_Warm
					*Data\ItemList_Warm = -1
					Redraw(Gadget, #Redraw_StateOnly)
				EndIf
				;}
			Case #PB_EventType_LeftButtonDown ;{
				;}
			Case #PB_EventType_LeftDoubleClick ;{
				If *Data\ItemList_Toggle = -1
					Item = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) + *data\VScrollbar_Position
					If SelectElement(*Data\DisplayList(), Item) And *Data\DisplayList()\item\Folded
						If MouseX > *data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset And MouseX < *Data\XOffset - #Style_ItemList_RoundedBoxOffset
							ItemList_ToggleFold(Gadget, *Data\DisplayList()\item)
							Refit(Gadget)
						EndIf
					EndIf
				EndIf
				;}
			Case #PB_EventType_KeyDown ;{
				Select GetGadgetAttribute(Gadget, #PB_Canvas_Key)
					Case #PB_Shortcut_Up
						If *Data\State > 0
							*Data\State - 1
							
							FocusOnSelection
							ItemListHover
							
							Redraw(Gadget, #Redraw_ItemList)
						EndIf
					Case #PB_Shortcut_Down
						If *Data\State < ListSize(*Data\DisplayList()) - 1
							*Data\State + 1
							
							FocusOnSelection
							ItemListHover
							
							Redraw(Gadget, #Redraw_ItemList)
						EndIf
					Case #PB_Shortcut_Space
						If *Data\State > -1
							SelectElement(*Data\DisplayList(), *Data\State)
							If *Data\DisplayList()\item\Folded
								ItemList_ToggleFold(Gadget, *Data\DisplayList()\item)
								ItemListHover
								Redraw(Gadget, #Redraw_ItemList)
							EndIf
						EndIf
				EndSelect
				;}
			Case #PB_EventType_MouseWheel ;{
				If *data\VScrollbar_Visible
					Protected Direction = GetGadgetAttribute(Gadget, #PB_Canvas_WheelDelta)
					SetGadgetState(*data\VScrollbar_ID, GetGadgetState(*data\VScrollbar_ID) - Direction)
					Item = GetGadgetState(*data\VScrollbar_ID)
					If Item <> *data\VScrollbar_Position
						*data\VScrollbar_Position = Item
						
						If *Data\ItemList_Toggle Or *Data\ItemList_Warm
							*Data\ItemList_Toggle = -1
							*Data\ItemList_Warm = -1
						EndIf
						
						If MouseY > *Data\YOffset And MouseX < *Data\ItemList_Width
							ItemListHover
						EndIf
							
						Redraw(Gadget, #Redraw_ItemList)
					EndIf
				EndIf
				;}
		EndSelect
	EndProcedure
	
	Procedure AddSubToDisplay(*Data.GadgetData, *Item.Item)
		Protected Result
		
		If *Item\Folded = #Unfolded
			ForEach *Item\Items()
				Result + 1
				AddElement(*Data\DisplayList())
				*Data\DisplayList()\item = *Item\Items()\item
				*Item\Items()\item\DisplayListAdress = @*Data\DisplayList()
				
				If *Item\Items()\item\Folded = #Unfolded
					Result + AddSubToDisplay(*Data.GadgetData, *Item\Items()\item)
				EndIf
			Next
		EndIf
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure RemoveSubFromDisplay(*Data.GadgetData, *Item.Item)
		Protected Result
		
		If *Item\Folded = #Unfolded
			ForEach *Item\Items()
				Result + 1
				NextElement(*Data\DisplayList())
				*Data\DisplayList()\item\DisplayListAdress = 0
				
				If *Data\DisplayList()\item\Folded = #Unfolded
					Result + RemoveSubFromDisplay(*Data, *Data\DisplayList()\item)
				EndIf
				
				DeleteElement(*Data\DisplayList())
			Next
		EndIf
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure ItemList_ToggleFold(Gadget, *Item.Item)
		Protected *Data.GadgetData = GetGadgetData(Gadget), Index, Count
		ChangeCurrentElement(*Data\DisplayList(), *Item\DisplayListAdress)
		
		Index = ListIndex(*Data\DisplayList())
		
		If *Item\Folded = #Folded
			*Item\Folded = #Unfolded
			
			Count = AddSubToDisplay(*Data, *Item)
			
			If Index < *Data\State
				*Data\State + Count
			EndIf
			
		Else
			Count = RemoveSubFromDisplay(*Data, *Item)
			*Item\Folded = #Folded
			If Index < *Data\State
				If *Data\State =< Index + Count
					*Data\State = -1
				Else
					*Data\State - Count
				EndIf
			EndIf
		EndIf
	EndProcedure
	
	Procedure HandlerVScrollbar()
		Protected Gadget = EventGadget()
		Protected State = GetGadgetState(Gadget)
		Protected Canvas = GetGadgetData(Gadget)
		Protected *data.GadgetData = GetGadgetData(Canvas)
		
		If Not (State = *data\VScrollbar_Position)
			*data\VScrollbar_Position = State
			Redraw(Canvas, #Redraw_ItemList)
		EndIf
	EndProcedure
	
	Procedure HandlerHScrollbar()
		Protected Gadget = EventGadget()
		Protected State = GetGadgetState(Gadget)
		Protected Canvas = GetGadgetData(Gadget)
		Protected *data.GadgetData = GetGadgetData(Canvas)
		
		If Not (State = *data\HScrollbar_Position)
			*data\HScrollbar_Position = State
			Redraw(Canvas, #Redraw_ItemList)
		EndIf
		
	EndProcedure
	
	Procedure SearchDisplayedItem(*Data.GadgetData, *Adress)
		
	EndProcedure
	
	Procedure Refit(Gadget)
		Protected Height = GadgetHeight(Gadget), Width = GadgetWidth(Gadget)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		Protected DisplayedItemCount = ListSize(*Data\DisplayList())
		
		*data\XOffset = *data\Border + *data\ItemList_Width
		*data\Body_Height = Height - *data\YOffset - *data\Border
		*data\Body_Width = Width - *data\ItemList_Width - 2 * *data\Border
		*data\VisibleItems = Round(*data\Body_Height / #Style_ItemList_ItemHeight, #PB_Round_Down)
		
		If DisplayedItemCount > *data\VisibleItems
			*data\VScrollbar_Visible = #True
			SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_Maximum, DisplayedItemCount - 1)
			SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_PageLength, *data\VisibleItems)
		Else
			*data\VScrollbar_Visible = #False
			SetGadgetState(*data\VScrollbar_ID, 0)
			*data\VScrollbar_Position = 0
		EndIf
		
		*data\Body_Width = Width - *data\ItemList_Width - 2 * *data\Border - (*data\VScrollbar_Width * *data\VScrollbar_Visible)
		*data\VisibleColumns = Round(*data\Body_Width / *data\Body_ColumnWidth, #PB_Round_Down)
		
		If *data\VisibleColumns < *data\Duration
			*data\HScrollbar_Visible = #True
			ResizeGadget(*data\HScrollbar_ID, *data\XOffset, Height - *Data\HScrollbar_Height - *data\Border, *data\Body_Width - *data\Border, *Data\HScrollbar_Height)
			SetGadgetAttribute(*data\HScrollbar_ID, #PB_ScrollBar_PageLength, *data\VisibleColumns)
			*data\HScrollbar_Position = GetGadgetState(*data\HScrollbar_ID)
			HideGadget(*data\HScrollbar_ID, #False)
		Else
			HideGadget(*data\HScrollbar_ID, #True)
			*data\HScrollbar_Position = 0
			*data\HScrollbar_Visible = #False
		EndIf
		
		If *data\VScrollbar_Visible
			ResizeGadget(*data\VScrollbar_ID, Width - *data\VScrollbar_Width - *data\Border, *data\YOffset, *data\VScrollbar_Width, *data\Body_Height - *Data\HScrollbar_Height * *Data\HScrollbar_Visible - *data\Border)
			HideGadget(*data\VScrollbar_ID, #False)
		Else
			SetGadgetState(*data\HScrollbar_ID, 0)
			*data\VScrollbar_Position = 0
			HideGadget(*data\VScrollbar_ID, #True)
		EndIf
		
		Redraw(Gadget, #Redraw_Everything)
	EndProcedure
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 114
; FirstLine = 60
; Folding = 9wAweTAx
; EnableXP