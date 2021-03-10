CompilerIf Not Defined(MaterialVector,#PB_Module)
	IncludeFile "MaterialVector\MaterialVector.pbi"
CompilerEndIf

DeclareModule PureTL
	; Public variables, structures, constants...
	#Header = 2
	#Border = 4
	
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
	
	Structure SubItem
		Name.s
	EndStructure
	
	Structure Item
		Name.s
		Folded.b
		
		List SubItems.SubItem()
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
		
		;state
		VerticalMovement.b
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
		Body_UnitWidth.i
		FontID.i
		Font.i
		VisibleItems.i							;current maximum number of displayable item. Will change when resizing or showing/hiding the header
		VisibleUnits.i							;current  maximum number of displayable time unit. Will change when resizing or zooming.
		List DisplayedItems.DisplayedItem()
		
		;Items
		List Items.Item()
		
	EndStructure
	
	Global DefaultFont = LoadFont(#PB_Any, "Calibri", 12, #PB_Font_HighQuality)
	
	;Style
	#Style_HeaderHeight = 50
	#Style_BorderThickness = 1
	
	#Style_ItemList_Width = 240
	#Style_ItemList_ItemHeight = 38
	
	#Style_ItemList_FoldOffset = 18
	#Style_ItemList_FoldSize = 12
	#Style_ItemList_TextOffset = #Style_ItemList_FoldSize + #Style_ItemList_FoldOffset + 8
	#Style_ItemList_SubTextOffset = #Style_ItemList_TextOffset + 12
	
	#Style_ItemList_FoldVOffset = (#Style_ItemList_ItemHeight - #Style_ItemList_FoldSize) / 2
	#Style_ItemList_TextVOffset = (#Style_ItemList_ItemHeight - 20) / 2
	
	#Style_VectorText = #False ; I find the vector drawn text to impair readability too much on Windows, so we'll fallback on the classic 2D drawing for text... Though drawing twice on the same canvas provokes the occasional flikering.
	
	#Style_Body_DefaultUnitWidth = 5
	#Style_Body_Margin = 2																					; Number of empty unit placed at the start and the end of the timeline, making the gadget thing more legible.
	
	;Colors
	Global Color_Border = RGBA(16,16,16,255)
	Global Color_BackColor = RGBA(54,57,63,255)
	
	Global Color_ItemList_BackColor = RGBA(47,49,54,255)
	Global Color_ItemList_FrontColor = RGBA(142,146,151,255)
	
	Global Color_ItemList_BackColorHot = RGBA(57,60,67,255)
	Global Color_ItemList_FrontColorHot = RGBA(255,255,255,255)
	
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
		Protected Result.i, *data.GadgetData
		Result = CanvasGadget(Gadget, X, Y, Width, Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
		
		If Result
			If Gadget = #PB_Any
				Gadget = Result
			EndIf
			
			*data = AllocateStructure(GadgetData)
			
			*data\Border = Bool(Flags & #Border) * #Style_BorderThickness
			*data\Header = Bool(Flags & #Header)
			
			*data\ItemList_Width = #Style_ItemList_Width
			*data\YOffset = *data\Border + *data\Header * #Style_HeaderHeight
			*data\Body_UnitWidth = #Style_Body_DefaultUnitWidth
			
			*data\State = -1
			*data\Duration = 120
			
			*data\VScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, 10, 10,   #PB_ScrollBar_Vertical)
			BindGadgetEvent(*data\VScrollbar_ID, @HandlerVScrollbar())
			*data\VScrollbar_Width = GadgetWidth(*data\VScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\VScrollbar_Visible = #False
			HideGadget(*data\VScrollbar_ID, #True)
			SetGadgetData(*data\VScrollbar_ID, Gadget)
			
			*data\HScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, *data\Duration + 2, 10)
			*data\HScrollbar_Height = GadgetHeight(*data\HScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\HScrollbar_Visible = #False
			HideGadget(*data\HScrollbar_ID, #True)
			SetGadgetData(*data\HScrollbar_ID, Gadget)
			
			*data\FontID = FontID(DefaultFont)
			*data\Font = DefaultFont
			
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
				*data\VerticalMovement = #True
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
		Protected YPos, Loop, LineCount, Height
		Protected CurrentColor = Color_ItemList_FrontColor
		
		If *data\Frozen
			ProcedureReturn #False
		EndIf
		
		StartVectorDrawing(CanvasVectorOutput(Gadget))
		VectorFont(*data\FontID)
		
		;{ Header
		If *data\HorizontalMovement Or CompleteRedraw
			; Redraw the header
			*data\HorizontalMovement = #False
		EndIf
		;}
		
		;{ Itemlist
		If *data\VerticalMovement Or CompleteRedraw
			; Redraw the itemlist
			CompilerIf #Style_VectorText
				*data\VerticalMovement = #False
			CompilerEndIf

			AddPathBox(*data\Border, *data\YOffset, *data\ItemList_Width, *data\Body_Height)
			VectorSourceColor(Color_ItemList_BackColor)
			FillPath()
			
			VectorSourceColor(Color_ItemList_FrontColor)
			If SelectElement(*data\DisplayedItems(), *data\VScrollbar_Position)
				For Loop = 0 To *data\VisibleItems 
					YPos = Loop * #Style_ItemList_ItemHeight + *data\YOffset
					
					If ListIndex(*data\DisplayedItems()) = *data\State
						If *data\DisplayedItems()\Type = #Item_Main
							MaterialVector::AddPathRoundedBox(*data\Border + #Style_ItemList_FoldOffset - 8, YPos, *data\ItemList_Width, #Style_ItemList_ItemHeight, 6)
						Else
							MaterialVector::AddPathRoundedBox(*data\Border + #Style_ItemList_SubTextOffset - 8, YPos, *data\ItemList_Width, #Style_ItemList_ItemHeight, 6)
						EndIf
						VectorSourceColor(Color_ItemList_BackColorHot)
						FillPath()
						CurrentColor = Color_ItemList_FrontColorHot
					Else
						CurrentColor = Color_ItemList_FrontColor
					EndIf
					
					If *data\DisplayedItems()\Type = #Item_Main
						ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\Adress)
						If *data\Items()\Folded = #Folded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + #Style_ItemList_FoldOffset, YPos + #Style_ItemList_FoldVOffset, #Style_ItemList_FoldSize, CurrentColor, Color_ItemList_BackColor, MaterialVector::#style_rotate_90)
						ElseIf *data\Items()\Folded = #Unfolded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + #Style_ItemList_FoldOffset, YPos + #Style_ItemList_FoldVOffset, #Style_ItemList_FoldSize, CurrentColor, Color_ItemList_BackColor, MaterialVector::#style_rotate_180)
						EndIf
					EndIf
					
					CompilerIf #Style_VectorText 
						MovePathCursor(*data\DisplayedItems()\YOffset, YPos + #Style_ItemList_TextVOffset, #PB_Path_Default)
						DrawVectorText(*data\DisplayedItems()\Name)
					CompilerEndIf
					
					If Not NextElement(*Data\DisplayedItems())
						Break
					EndIf
				Next
			EndIf
		EndIf
		;}
		
		;{ Body
		AddPathBox(*data\XOffset, *data\YOffset, *data\Body_Width, *data\Body_Height)
		VectorSourceColor(Color_BackColor)
		FillPath()
		
		LineCount = Loop
		For Loop = 0 To LineCount
			MovePathCursor(*data\XOffset, *data\YOffset + (Loop + 1) * #Style_ItemList_ItemHeight)
			AddPathLine(*data\Body_Width, 0, #PB_Path_Relative)
		Next
		
		Height = (LineCount + 1) * #Style_ItemList_ItemHeight
		
		If (*data\Duration +  #Style_Body_Margin) < *Data\VisibleUnits
			LineCount = *data\Duration
		Else
			LineCount = *Data\VisibleUnits
		EndIf
		
		For Loop = 0 To LineCount
			MovePathCursor(*data\XOffset + (2 + Loop) * *data\Body_UnitWidth, *data\YOffset)
			AddPathLine(0, Height, #PB_Path_Relative)
		Next
		
		VectorSourceColor(RGBA(240, 240, 240, 255))
		StrokePath(1)
		
		If *data\VScrollbar_Visible And *data\HScrollbar_Visible
			AddPathBox(VectorOutputWidth() - *data\VScrollbar_Width, VectorOutputHeight() - *data\HScrollbar_Height,*data\VScrollbar_Width, *data\HScrollbar_Height)
			VectorSourceColor(RGBA(240, 240, 240, 255))
			FillPath()
		EndIf
		;}
		
		;{ Border
		CompilerIf #Style_VectorText
			If *data\Border
				AddPathBox(0, 0, VectorOutputWidth(), VectorOutputHeight())
				VectorSourceColor(Color_Border)
				StrokePath(1)
			EndIf
		CompilerEndIf
		;}
		StopVectorDrawing()
		
		;{ Border and Itemlist in 2DDrawing mode
		CompilerIf Not #Style_VectorText
			If CompleteRedraw Or *data\VerticalMovement
				*data\VerticalMovement = #False
				
				StartDrawing(CanvasOutput(Gadget))
				
				DrawingFont(*data\FontID)
				DrawingMode(#PB_2DDrawing_Transparent)
				If SelectElement(*data\DisplayedItems(), *data\VScrollbar_Position)
					For Loop = 0 To *data\VisibleItems
						If ListIndex(*data\DisplayedItems()) = *data\State
							DrawText(*data\DisplayedItems()\YOffset, Loop * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_TextVOffset , *data\DisplayedItems()\Name,Color_ItemList_FrontColorHot, 0)
						Else
							DrawText(*data\DisplayedItems()\YOffset, Loop * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_TextVOffset , *data\DisplayedItems()\Name,Color_ItemList_FrontColor, 0)
						EndIf
						
						If Not NextElement(*Data\DisplayedItems())
							Break
						EndIf
					Next
				EndIf
				
				If *data\Border
					DrawingMode(#PB_2DDrawing_Outlined)
					Box(0, 0, OutputWidth(), OutputHeight(), Color_Border)
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
									*data\VerticalMovement = #True
									Redraw(Gadget)
								EndIf
							ElseIf *data\State <> Item
								*data\State = Item
								*data\VerticalMovement = #True
								Redraw(Gadget)
							EndIf
							
						ElseIf *data\State <> Item
							*data\State = Item
							*data\VerticalMovement = #True
							Redraw(Gadget)
						EndIf
					Else
						If *data\State <> Item
							*data\State = Item
							*data\VerticalMovement = #True
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
					*data\VerticalMovement = #True
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
							
							*data\VerticalMovement = #True
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
							
							*data\VerticalMovement = #True
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
			*data\VerticalMovement = #True
			
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
			*data\VerticalMovement = #True
			
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
			*data\VerticalMovement = #True
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
		Else
			*data\VScrollbar_Visible = #False
			*data\VScrollbar_Position = 0
		EndIf
		
		*data\Body_Width = Width - *data\ItemList_Width - 2 * *data\Border - *data\VScrollbar_Width * *data\VScrollbar_Visible
		*data\VisibleUnits = Round(*data\Body_Width / *Data\Body_UnitWidth, #PB_Round_Down)
		
		If *data\Duration + 2 * #Style_Body_Margin >= *data\VisibleUnits
			*data\HScrollbar_Visible = #True
			SetGadgetAttribute(*data\HScrollbar_ID, #PB_ScrollBar_PageLength, *data\VisibleUnits)
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
; CursorPosition = 382
; FirstLine = 150
; Folding = PwcFx
; EnableXP