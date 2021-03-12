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
	
	Enumeration ;Content Type
		#Contant_Media
		#Contant_DataPoints
	EndEnumeration
	
	#DefaultDuration = 119
	
	; Public procedures declaration
	Declare Gadget(Gadget, X, Y, Width, Height, Flags = #False)
	Declare AddItem(Gadget, Name.s, Position)
	Declare AddSubItem(Gadget, Item, Name.s, Position)
	Declare RemoveItem(Gadget)
	Declare SetDuration(Gadget)
	Declare Freeze(Gadget, State) ;Disable the redrawing of the gadget (Should be used before a large amount is done to avoid CPU consumption spike)
	Declare Resize(Gadget, x, y, Width, Height)
	
EndDeclareModule

Module PureTL
	EnableExplicit
	;{ Private variables, structures, constants...
	Enumeration ;Displayed item types
		#Item_Main
		#Item_Sub
	EndEnumeration
	
	Enumeration -1 ;Fold
		#NoFold
		#Folded
		#Unfolded
	EndEnumeration
	
	Structure Content
		Color.l
	EndStructure
	
	Structure SubItem
		Name.s
		ContentType.b
		Array ContentArray.Content(#DefaultDuration)
	EndStructure
	
	Structure Item
		Name.s
		Folded.b
		List SubItems.SubItem()
		ContentType.b
		Array ContentArray.Content(#DefaultDuration)
	EndStructure
	
	Structure DisplayedItem
		Type.b
		*Adress
		*ParentAdress
		Name.s
		YOffset.i
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
		ItemListUpdate.b
		HorizontalMovement.b
		ItemList_Width.i
		State.i
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
		VisibleItems.i							;current maximum number of displayable item. Will change when resizing or showing/hiding the header
		VisibleColumns.i						;current  maximum number of displayable time unit. Will change when resizing or zooming.
			
		Color_Border.i
		
		Color_Body_Back.i
		Color_Body_BackAlt.i
		Color_Body_BackHot.i
		
		Color_ItemList_Back.i
		Color_ItemList_Front.i
		Color_ItemList_BackHot.i
		Color_ItemList_FrontHot.i
		
		List DisplayedItems.DisplayedItem()
		
		;Items
		List Items.Item()
		
	EndStructure
	
	;Style
	#Style_Header_Height = 60
	#Style_Header_ButtonSize = 30
	#Style_Header_ButtonSpace = 20
	#Style_BorderThickness = 1
	
	#Style_ItemList_Width = 240
	#Style_ItemList_ItemHeight = 58
	
	#Style_ItemList_FoldOffset = 24
	#Style_ItemList_FoldSize = 12
	#Style_ItemList_TextOffset = #Style_ItemList_FoldSize + #Style_ItemList_FoldOffset + 16
	#Style_ItemList_SubTextOffset = #Style_ItemList_TextOffset + 12
	
	#Style_ItemList_FoldVOffset = (#Style_ItemList_ItemHeight - #Style_ItemList_FoldSize) / 2 + 1
	#Style_ItemList_TextVOffset = (#Style_ItemList_ItemHeight - 20) / 2
	#Style_ItemList_FontSize	= 20
	
	#Style_VectorText = #True ; I find the vector drawn text to impair readability too much on Windows, so we'll fallback on the classic 2D drawing for text... Though drawing twice on the same canvas provokes the occasional flikering.
	
	#Style_Body_DefaultUnitWidth = 15
	#Style_Body_Margin = 2																					; Number of empty column placed at the start and the end of the timeline, making the gadget more legible.
	
	Global DefaultFont = LoadFont(#PB_Any, "Bebas Neue", #Style_ItemList_FontSize, #PB_Font_HighQuality)
	
	;Colors
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows ; RGB/GBR switcharoo...
		#Color_Border = $FF101010
		
		#Color_ItemList_Dark_Back = $FF36312F
		#Color_ItemList_Dark_BackHot = $FF433C39
		#Color_ItemList_Dark_Front = $FF97928E
		#Color_ItemList_Dark_FrontHot = $FFFFFFFF
		
		#Color_ItemList_Light_Back = $FFF5F3F2
		#Color_ItemList_Light_BackHot = $FFDCD7D4
		#Color_ItemList_Light_Front = $FF80746A
		#Color_ItemList_Light_FrontHot = $FF070606
		
		#Color_Body_Dark_Back    = $FF393532
		#Color_Body_Dark_BackAlt = $FF3F3936
		#Color_Body_Dark_BackHot = $FF46403C
		
		#Color_Body_Light_Back    = $FFF3EDEA
		#Color_Body_Light_BackAlt = $FFE9E3E0
		#Color_Body_Light_BackHot = $FFDCD7D4
		
		
	CompilerElse
		#Color_Border = $101010FF
		
		#Color_ItemList_Dark_Back = $2F3136FF
		#Color_ItemList_Dark_BackHot = $393C43FF
		#Color_ItemList_Dark_Front = $8E9297FF
		#Color_ItemList_Dark_FrontHot = $FFFFFFFF
		
		#Color_ItemList_Light_Back = $F2F3F5FF
		#Color_ItemList_Light_BackHot = $D4D7DCFF
		#Color_ItemList_Light_Front = $6A7480FF
		#Color_ItemList_Light_FrontHot = $060607FF
		
		#Color_Body_Dark_Back = $323539FF
		#Color_Body_Dark_BackAlt = $36393FFF
		#Color_Body_Dark_BackHot = $3C4046FF
		
		#Color_Body_Light_Back    = $FFEAEDF3
		#Color_Body_Light_BackAlt = $FFE0E3E9
		#Color_Body_Light_BackHot = $D4D7DCFF
		
	CompilerEndIf
	
	;Icons
	
	;}
	
	; Private procedures declaration
	Declare Redraw(Gadget, CompleteRedraw = #False)
	
	Declare HandlerCanvas()
	
	Declare HandlerVScrollbar()
	
	Declare SearchDisplayedItem(*data.GadgetData, *Adress)
	
	Declare Refit(Gadget)
	
	Declare ToggleFold(Gadget, *data.GadgetData, Item)
	
	; Public procedures
	Procedure Gadget(Gadget, X, Y, Width, Height, Flags = #False)
		Protected Result.i, *data.GadgetData, Theme
		Result = CanvasGadget(Gadget, X, Y, Width, Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
		
		If Result
			If Gadget = #PB_Any
				Gadget = Result
			EndIf
			
			*data = AllocateStructure(GadgetData)
			
			*data\Color_Border = #Color_Border
			
			If Flags & #DarkTheme
				*data\Color_Body_Back = #Color_Body_Dark_Back
				*data\Color_Body_BackAlt = #Color_Body_Dark_BackAlt
				*data\Color_Body_BackHot = #Color_Body_Dark_BackHot
				
				*data\Color_ItemList_Back = #Color_ItemList_Dark_Back
				*data\Color_ItemList_Front = #Color_ItemList_Dark_Front
				*data\Color_ItemList_BackHot = #Color_ItemList_Dark_BackHot
				*data\Color_ItemList_FrontHot = #Color_ItemList_Dark_FrontHot
				
				Theme = CanvasButton::#DarkTheme
			Else
				*data\Color_Body_Back = #Color_Body_Light_Back
				*data\Color_Body_BackAlt = #Color_Body_Light_BackAlt
				*data\Color_Body_BackHot = #Color_Body_Light_BackHot
				
				*data\Color_ItemList_Back = #Color_ItemList_Light_Back
				*data\Color_ItemList_Front = #Color_ItemList_Light_Front
				*data\Color_ItemList_BackHot = #Color_ItemList_Light_BackHot
				*data\Color_ItemList_FrontHot = #Color_ItemList_Light_FrontHot
				
				Theme = CanvasButton::#LightTheme
			EndIf
			
			*data\Border = Bool(Flags & #Border) * #Style_BorderThickness
			*data\Header = Bool(Flags & #Header)
			
			If *data\Header
				*data\ButtonStart_ID = CanvasButton::GadgetImage(#PB_Any,
				                                                 (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5, (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
				                                                 #Style_Header_ButtonSize,
				                                                 #Style_Header_ButtonSize,
				                                                 MaterialVector::#Skip,
				                                                 CanvasButton::#MaterialVectorIcon | Theme | MaterialVector::#style_rotate_180)
				CanvasButton::SetColor(*data\ButtonStart_ID, CanvasButton::#ColorType_BackCold, *data\Color_ItemList_Back)
				CanvasButton::SetColor(*data\ButtonStart_ID, CanvasButton::#ColorType_BackWarm, *data\Color_ItemList_Back)
				CanvasButton::SetColor(*data\ButtonStart_ID, CanvasButton::#ColorType_BackHot, *data\Color_ItemList_Back)
				
				*data\ButtonPlay_ID = CanvasButton::GadgetImage(#PB_Any, (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + #Style_Header_ButtonSize + #Style_Header_ButtonSpace,
				                                                (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
				                                                #Style_Header_ButtonSize,
				                                                #Style_Header_ButtonSize,
				                                                MaterialVector::#Play,
				                                                CanvasButton::#MaterialVectorIcon | Theme)
				CanvasButton::SetColor(*data\ButtonPlay_ID, CanvasButton::#ColorType_BackCold, *data\Color_ItemList_Back)
				CanvasButton::SetColor(*data\ButtonPlay_ID, CanvasButton::#ColorType_BackWarm, *data\Color_ItemList_Back)
				CanvasButton::SetColor(*data\ButtonPlay_ID, CanvasButton::#ColorType_BackHot, *data\Color_ItemList_Back)
				
				*data\ButtonEnd_ID = CanvasButton::GadgetImage(#PB_Any, (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + (#Style_Header_ButtonSize + #Style_Header_ButtonSpace) * 2, (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
				                                               #Style_Header_ButtonSize,
				                                               #Style_Header_ButtonSize,
				                                               MaterialVector::#Skip,
				                                               CanvasButton::#MaterialVectorIcon | Theme)
				
				CanvasButton::SetColor(*data\ButtonEnd_ID, CanvasButton::#ColorType_BackCold, *data\Color_ItemList_Back)
				CanvasButton::SetColor(*data\ButtonEnd_ID, CanvasButton::#ColorType_BackWarm, *data\Color_ItemList_Back)
				CanvasButton::SetColor(*data\ButtonEnd_ID, CanvasButton::#ColorType_BackHot, *data\Color_ItemList_Back)
			EndIf
			
			
			*data\ItemList_Width = #Style_ItemList_Width
			*data\YOffset = *data\Border + *data\Header * #Style_Header_Height
			*data\Body_ColumnWidth = #Style_Body_DefaultUnitWidth
			
			*data\State = -1
			*data\Duration = #DefaultDuration
			
			*data\VScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, 10, 10,   #PB_ScrollBar_Vertical)
			BindGadgetEvent(*data\VScrollbar_ID, @HandlerVScrollbar())
			*data\VScrollbar_Width = GadgetWidth(*data\VScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\VScrollbar_Visible = #False
			HideGadget(*data\VScrollbar_ID, #True)
			SetGadgetData(*data\VScrollbar_ID, Gadget)
			
			*data\HScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, *data\Duration + #Style_Body_Margin, 10)
			*data\HScrollbar_Height = GadgetHeight(*data\HScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\HScrollbar_Visible = #False
			HideGadget(*data\HScrollbar_ID, #True)
			SetGadgetData(*data\HScrollbar_ID, Gadget)
			
			*data\FontID = FontID(DefaultFont)
			*data\Font = DefaultFont
			*data\FontSize = #Style_ItemList_FontSize
			
			CloseGadgetList()
			
			SetGadgetData(Gadget, *data)
			BindGadgetEvent(Gadget, @HandlerCanvas())
			
			Refit(Gadget)
		EndIf
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure AddItem(Gadget, Name.s, Position)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		
		If Position = -1 Or Position >= ListSize(*data\Items())
			LastElement(*data\Items())
			AddElement(*data\Items())
			LastElement(*data\DisplayedItems())
			AddElement(*data\DisplayedItems())
		Else
			SelectElement(*data\Items(), Position)
			SearchDisplayedItem(*data, @*data\Items())
			InsertElement(*data\Items())
			InsertElement(*data\DisplayedItems())
		EndIf
		
		*data\Items()\Name = Name
		*data\Items()\Folded = #NoFold
		
		*data\DisplayedItems()\Name = *data\Items()\Name
		*data\DisplayedItems()\Adress = @*data\Items()
		*data\DisplayedItems()\YOffset = *data\Border + #Style_ItemList_FoldOffset + 2
		
		SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_Maximum, ListSize(*data\DisplayedItems()) - 1)
		
		If (ListSize(*data\DisplayedItems()) > *data\VisibleItems) And Not *Data\VScrollbar_Visible
			Refit(Gadget)
		Else
			If ListIndex(*data\DisplayedItems()) < *data\HScrollbar_Visible + *data\VisibleItems ; Avoid useless redraw...
				Redraw(Gadget, #True)
			EndIf
		EndIf
	EndProcedure
	
	Procedure AddSubItem(Gadget, Item, Name.s, Position)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		If Item < ListSize(*data\Items())
			SelectElement(*data\Items(), Item)
			
			If Position = -1 Or Position >= ListSize(*data\Items()\SubItems())
				LastElement(*data\Items()\SubItems())
				AddElement(*data\Items()\SubItems())
			Else
				SelectElement(*data\Items()\SubItems(), Position)
				InsertElement(*data\Items()\SubItems())
			EndIf
			
			*data\Items()\SubItems()\Name = Name
			
			If *data\Items()\Folded = #NoFold
				*data\Items()\Folded = #Folded
				SearchDisplayedItem(*data, @*data\Items())
				*data\DisplayedItems()\YOffset = *data\Border + #Style_ItemList_TextOffset
				*data\ItemListUpdate = #True
				Redraw(Gadget)
			ElseIf *data\Items()\Folded = #Unfolded
				If ListIndex(*data\Items()\SubItems()) = 0
					SearchDisplayedItem(*data, @*data\Items())
				Else
					PreviousElement(*data\Items()\SubItems())
					SearchDisplayedItem(*data, @*data\Items()\SubItems())
					NextElement(*data\Items()\SubItems())
				EndIf
				
				AddElement(*data\DisplayedItems())
				
				*data\DisplayedItems()\Name = Name
				*data\DisplayedItems()\ParentAdress = @*data\Items()
				*data\DisplayedItems()\Adress = @*data\Items()\SubItems()
				*data\DisplayedItems()\Type = #Item_Sub
				*data\DisplayedItems()\YOffset = #Style_ItemList_SubTextOffset
				
				SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_Maximum, ListSize(*data\DisplayedItems()) - 1)
				
				If (ListSize(*data\DisplayedItems()) > *data\VisibleItems) And Not *Data\VScrollbar_Visible
					Refit(Gadget)
				Else ; We can avoid some redraw by checking if the new item is within the displayed area... Once scrolling is implemented, of course.
					Redraw(Gadget, #True)
				EndIf
			EndIf
		EndIf
	EndProcedure
	
	Procedure RemoveItem(Gadget)
	EndProcedure
	
	Procedure SetDuration(Gadget)
	EndProcedure
	
	Procedure Freeze(Gadget, State)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		*data\Frozen = State
		
		If *data\Frozen And Not State
			*data\Frozen = #False
			Redraw(Gadget, #True)
		EndIf
		
		*data\Frozen = State
	EndProcedure
	
	Procedure Resize(Gadget, x, y, Width, Height)
		ResizeGadget(Gadget, x, y, Width, Height)
		Refit(Gadget)
	EndProcedure
	
	; Private procedures
	Procedure Redraw(Gadget, CompleteRedraw = #False)
		;Ugly code is uglyyyyyy~. First place to refactor once everything is in.
		Protected *data.GadgetData = GetGadgetData(Gadget)
		Protected YPos, Loop, FrontColor, BodyColor
		
		If *data\Frozen
			ProcedureReturn #False
		EndIf
		
		StartVectorDrawing(CanvasVectorOutput(Gadget))
		VectorFont(*data\FontID, *data\FontSize)
		
		;{ Header
		If *data\HorizontalMovement Or CompleteRedraw
			; Redraw the header
			AddPathBox(*data\Border, *data\Border, *data\ItemList_Width, #Style_Header_Height)
			VectorSourceColor(*data\Color_ItemList_Back)
			FillPath()
			*data\HorizontalMovement = #False
		EndIf
		;}
		
		If *data\ItemListUpdate Or CompleteRedraw
			AddPathBox(*data\Border, *data\YOffset, *data\ItemList_Width, *data\Body_Height)
			VectorSourceColor(*data\Color_ItemList_Back)
			FillPath()
		EndIf
		
		AddPathBox(*data\XOffset, *data\YOffset, *data\Body_Width, *data\Body_Height)
		VectorSourceColor(*data\Color_Body_Back)
		FillPath()
		
		If SelectElement(*data\DisplayedItems(), *data\VScrollbar_Position)
			For Loop = 0 To *data\VisibleItems
				YPos = Loop * #Style_ItemList_ItemHeight + *data\YOffset
				
				If *data\DisplayedItems()\Type = #Item_Main
					ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\Adress)
				Else
					ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\ParentAdress)
					ChangeCurrentElement(*data\Items()\SubItems(), *data\DisplayedItems()\Adress)
				EndIf
				
				If ListIndex(*data\DisplayedItems()) = *data\State
					FrontColor = *data\Color_ItemList_FrontHot
					BodyColor = *data\Color_Body_BackHot
					
					If *data\ItemListUpdate Or CompleteRedraw
						If *data\DisplayedItems()\Type = #Item_Main
							MaterialVector::AddPathRoundedBox(*data\Border + #Style_ItemList_FoldOffset - 8, YPos, *data\ItemList_Width, #Style_ItemList_ItemHeight, 6)
						Else
							MaterialVector::AddPathRoundedBox(*data\Border + #Style_ItemList_SubTextOffset - 8, YPos, *data\ItemList_Width, #Style_ItemList_ItemHeight, 6)
						EndIf
						VectorSourceColor(*data\Color_ItemList_BackHot)
						FillPath()
					EndIf
				Else
					FrontColor = *data\Color_ItemList_Front
					If (Loop + *data\VScrollbar_Position) % 2
						BodyColor = *data\Color_Body_BackAlt
					Else
						BodyColor = 0
					EndIf
				EndIf
				
				If *data\ItemListUpdate Or CompleteRedraw
					If *data\DisplayedItems()\Type = #Item_Main
						If *Data\Items()\Folded = #Folded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + #Style_ItemList_FoldOffset, YPos + #Style_ItemList_FoldVOffset, #Style_ItemList_FoldSize, FrontColor, 0, MaterialVector::#style_rotate_90)
						ElseIf *Data\Items()\Folded = #Unfolded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + #Style_ItemList_FoldOffset, YPos + #Style_ItemList_FoldVOffset, #Style_ItemList_FoldSize, FrontColor, 0, MaterialVector::#style_rotate_180)
						EndIf
					EndIf
					
					CompilerIf #Style_VectorText 
						VectorSourceColor(FrontColor)
						MovePathCursor(*data\DisplayedItems()\YOffset, YPos + #Style_ItemList_TextVOffset, #PB_Path_Default)
						DrawVectorText(*data\DisplayedItems()\Name)
					CompilerEndIf
				EndIf
				
				If BodyColor
					AddPathBox(*data\XOffset, *data\YOffset + (Loop) * #Style_ItemList_ItemHeight, *data\Body_Width, #Style_ItemList_ItemHeight)
					VectorSourceColor(BodyColor)
					FillPath()
				EndIf
				
				; Here goes the content loop...
				
				
				
				If Not NextElement(*Data\DisplayedItems())
					Break
				EndIf
			Next
			
			If *data\VScrollbar_Visible And *data\HScrollbar_Visible
				AddPathBox(VectorOutputWidth() - *data\VScrollbar_Width, VectorOutputHeight() - *data\HScrollbar_Height,*data\VScrollbar_Width, *data\HScrollbar_Height)
				VectorSourceColor(RGBA(240, 240, 240, 255)) ;-WARNING : should theme the scrollbar and this together...
				FillPath()
			EndIf
			
		EndIf
		;{ Border
		CompilerIf #Style_VectorText
			If *data\Border
				AddPathBox(0, 0, VectorOutputWidth(), VectorOutputHeight())
				VectorSourceColor(*data\Color_Border)
				StrokePath(1)
			EndIf
		CompilerEndIf
		;}
		StopVectorDrawing()
		
		;{ Border and Itemlist in 2DDrawing mode
		CompilerIf Not #Style_VectorText
			If CompleteRedraw Or *data\ItemListUpdate
				*data\ItemListUpdate = #False
				
				StartDrawing(CanvasOutput(Gadget))
				
				DrawingFont(*data\FontID)
				DrawingMode(#PB_2DDrawing_Transparent)
				If SelectElement(*data\DisplayedItems(), *data\VScrollbar_Position)
					For Loop = 0 To *data\VisibleItems
						If ListIndex(*data\DisplayedItems()) = *data\State
							DrawText(*data\DisplayedItems()\YOffset, Loop * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_TextVOffset , *data\DisplayedItems()\Name,*data\Color_ItemList_FrontHot, 0)
						Else
							DrawText(*data\DisplayedItems()\YOffset, Loop * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_TextVOffset , *data\DisplayedItems()\Name,*data\Color_ItemList_Front, 0)
						EndIf
						
						If Not NextElement(*Data\DisplayedItems())
							Break
						EndIf
					Next
				EndIf
				
				If *data\Border
					DrawingMode(#PB_2DDrawing_Outlined)
					Box(0, 0, OutputWidth(), OutputHeight(), *data\Color_Border)
				EndIf
				
				StopDrawing()
			EndIf
		CompilerEndIf
		;}
	EndProcedure
	
	Procedure HandlerCanvas()
		Protected Gadget = EventGadget(), MouseX = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX), MouseY = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		Protected Item, Key
		
		Select EventType()
			Case #PB_EventType_LeftDoubleClick
				If MouseY >= *data\YOffset And MouseX < *data\XOffset
					Item = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) + *data\VScrollbar_Position
					If SelectElement(*data\DisplayedItems(), Item)
						ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\Adress)
						ToggleFold(Gadget, *data, Item)
					EndIf
				EndIf
			Case #PB_EventType_LeftButtonDown
				If MouseY <= *data\YOffset ; Header
					
				ElseIf MouseX < *data\XOffset ;{ Itemlist
					Item = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) + *data\VScrollbar_Position
					
					If SelectElement(*data\DisplayedItems(), Item)
						If *data\DisplayedItems()\Type = #Item_Main
							If MouseX < #Style_ItemList_TextOffset
								ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\Adress)
								
								ToggleFold(Gadget, *data, Item)
								
								If *data\State <> Item
									*data\State = Item
									*data\ItemListUpdate = #True
									Redraw(Gadget)
								EndIf
							ElseIf *data\State <> Item
								*data\State = Item
								*data\ItemListUpdate = #True
								Redraw(Gadget)
							EndIf
							
						ElseIf *data\State <> Item
							*data\State = Item
							*data\ItemListUpdate = #True
							Redraw(Gadget)
						EndIf
					Else
						If *data\State <> Item
							*data\State = Item
							*data\ItemListUpdate = #True
							Redraw(Gadget)
						EndIf
					EndIf
					;}
				Else ; Timeline
					
				EndIf
			Case #PB_EventType_MouseWheel ;{
				SetGadgetState(*data\VScrollbar_ID, GetGadgetState(*data\VScrollbar_ID) - GetGadgetAttribute(Gadget, #PB_Canvas_WheelDelta))
				Item = GetGadgetState(*data\VScrollbar_ID)
				If Item <> *data\VScrollbar_Position
					*data\VScrollbar_Position = Item
					*data\ItemListUpdate = #True
					Redraw(Gadget)
				EndIf
				;}
			Case #PB_EventType_KeyDown ;{
				Key = GetGadgetAttribute(Gadget, #PB_Canvas_Key)  
				Select Key
					Case #PB_Shortcut_Up
						If *data\State > 0
							*data\State - 1
							
							If *data\State < *data\VScrollbar_Position
								*data\VScrollbar_Position = *data\State
								SetGadgetState(*data\VScrollbar_ID, *data\VScrollbar_Position)
							ElseIf *data\State >= *data\VScrollbar_Position + *data\VisibleItems
								SetGadgetState(*data\VScrollbar_ID, *data\State - *data\VisibleItems + 1)
								*data\VScrollbar_Position = GetGadgetState(*data\VScrollbar_ID)
							EndIf
							
							*data\ItemListUpdate = #True
							Redraw(Gadget)
						EndIf
					Case #PB_Shortcut_Down
						If *data\State < ListSize(*data\DisplayedItems()) - 1 
							*data\State + 1
							
							If *data\State >= *data\VScrollbar_Position + *data\VisibleItems
								SetGadgetState(*data\VScrollbar_ID, *data\State - *data\VisibleItems + 1)
								*data\VScrollbar_Position = GetGadgetState(*data\VScrollbar_ID)
							ElseIf *data\State < *data\VScrollbar_Position
								*data\VScrollbar_Position = *data\State
								SetGadgetState(*data\VScrollbar_ID, *data\VScrollbar_Position)
							EndIf
							
							*data\ItemListUpdate = #True
							Redraw(Gadget)
							
						EndIf
					Case #PB_Shortcut_Space
						SelectElement(*data\DisplayedItems(), *data\State)
						If *data\DisplayedItems()\Type = #Item_Main
							ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\Adress)
							ToggleFold(Gadget, *data, *data\State)
						EndIf
				EndSelect
				;}
		EndSelect
	EndProcedure
	
	Procedure ToggleFold(Gadget, *data.GadgetData, Item)
		If *data\Items()\Folded = #Folded
			*data\Items()\Folded = #Unfolded
			ForEach *data\Items()\SubItems()
				AddElement(*data\DisplayedItems())
				*data\DisplayedItems()\Type = #Item_Sub
				*data\DisplayedItems()\Adress = @*data\Items()\SubItems()
				*data\DisplayedItems()\ParentAdress = @*data\Items()
				*data\DisplayedItems()\Name = *data\Items()\SubItems()\Name
				*data\DisplayedItems()\YOffset = #Style_ItemList_SubTextOffset
			Next
			
			SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_Maximum, ListSize(*data\DisplayedItems()) - 1)
			
			*data\State = Item
			*data\ItemListUpdate = #True
			
			If (ListSize(*data\DisplayedItems()) > *data\VisibleItems) And Not *Data\VScrollbar_Visible
				Refit(Gadget)
			Else
				Redraw(Gadget)
			EndIf
		ElseIf *data\Items()\Folded = #Unfolded
			*data\Items()\Folded = #Folded
			
			While NextElement(*data\DisplayedItems())
				If *data\DisplayedItems()\Type = #Item_Sub
					DeleteElement(*data\DisplayedItems())
				Else
					Break
				EndIf
			Wend
			
			SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_Maximum, ListSize(*data\DisplayedItems()) - 1)
			
			*data\State = Item
			*data\ItemListUpdate = #True
			
			If (ListSize(*data\DisplayedItems()) <= *data\VisibleItems) And *Data\VScrollbar_Visible
				Refit(Gadget)
			Else
				*data\VScrollbar_Position = GetGadgetState(*data\VScrollbar_ID)
				Redraw(Gadget)
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
			*data\ItemListUpdate = #True
			Redraw(Canvas)
		EndIf
			
	EndProcedure
	
	Procedure SearchDisplayedItem(*data.GadgetData, *Adress)
		ForEach *data\DisplayedItems()
			If *data\DisplayedItems()\Adress = *Adress
				ProcedureReturn #True
			EndIf
		Next
		
		ProcedureReturn #False
	EndProcedure
	
	Procedure Refit(Gadget)
		Protected Height = GadgetHeight(Gadget), Width = GadgetWidth(Gadget)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		
		*data\XOffset = *data\Border + *data\ItemList_Width
		
		*data\Body_Height = Height - *data\YOffset - *data\Border
		*data\VisibleItems = Round(*data\Body_Height / #Style_ItemList_ItemHeight, #PB_Round_Down)
		
		If ListSize(*data\DisplayedItems()) > *data\VisibleItems
			*data\VScrollbar_Visible = #True
			SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_PageLength, *data\VisibleItems)
			*data\VScrollbar_Position = GetGadgetState(*data\VScrollbar_ID)
		Else
			*data\VScrollbar_Visible = #False
			*data\VScrollbar_Position = 0
		EndIf
		
		*data\Body_Width = Width - *data\ItemList_Width - 2 * *data\Border - *data\VScrollbar_Width * *data\VScrollbar_Visible
		*data\VisibleColumns = Round(*data\Body_Width / *Data\Body_ColumnWidth, #PB_Round_Down)
		
		If *data\Duration + 2 * #Style_Body_Margin >= *data\VisibleColumns
			*data\HScrollbar_Visible = #True
			SetGadgetAttribute(*data\HScrollbar_ID, #PB_ScrollBar_PageLength, *data\VisibleColumns)
			*data\HScrollbar_Position = GetGadgetState(*data\HScrollbar_ID)
		Else
			*data\HScrollbar_Visible = #False
			*data\HScrollbar_Position = 0
		EndIf
		
		If *data\VScrollbar_Visible
			ResizeGadget(*data\VScrollbar_ID, Width - *data\Border - *data\VScrollbar_Width, *data\YOffset, *data\VScrollbar_Width, *data\Body_Height - *data\HScrollbar_Height * *data\HScrollbar_Visible)
		Else
			SetGadgetState(*data\VScrollbar_ID, 0)
		EndIf
		
		If *data\HScrollbar_Visible
 			ResizeGadget(*data\HScrollbar_ID, *data\XOffset, Height - *Data\HScrollbar_Height - *data\Border, *data\Body_Width, *data\HScrollbar_Height)
		Else
			SetGadgetState(*data\HScrollbar_ID, 0)
		EndIf
		
		HideGadget(*data\VScrollbar_ID, Bool(Not *data\VScrollbar_Visible))
		HideGadget(*data\HScrollbar_ID, Bool(Not *data\HScrollbar_Visible))
		
		Redraw(Gadget, #True)
	EndProcedure
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 292
; FirstLine = 194
; Folding = fB+75
; EnableXP