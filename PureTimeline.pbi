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
		
		;Redraw
		Frozen.b
		YOffset.i
		XOffset.i
		Body_Height.i
		Body_Width.i
		FontID.i
		Font.i
		VisibleItems.i
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
	
	#Style_ItemList_FoldOffset = 9
	#Style_ItemList_FoldSize = 12
	#Style_ItemList_TextOffset = #Style_ItemList_FoldSize + #Style_ItemList_FoldOffset + 8
	#Style_ItemList_SubTextOffset = #Style_ItemList_TextOffset + 12
	
	#Style_ItemList_FoldVOffset = (#Style_ItemList_ItemHeight - #Style_ItemList_FoldSize) / 2
	#Style_ItemList_TextVOffset = (#Style_ItemList_ItemHeight - 20) / 2
	
	#Style_VectorText = #False ; I find the vector drawn text to impair readability too much on Windows, so we'll fallback on the classic 2D drawing for text.
	
	
	
	;Colors
	Global Color_Border = RGBA(16,16,16,255)
	Global Color_BackColor = RGBA(54,57,63,255)
	
	Global Color_ItemList_BackColor = RGBA(47,49,54,255)
	Global Color_ItemList_FrontColor = RGBA(142,146,151,255)
	
	;Icons
	
	;}
	
	; Private procedures declaration
	Declare Redraw(Gadget, CompleteRedraw = #False)
	
	Declare HandlerCanvas()
	
	Declare HandlerVScrollbar()
	
	Declare SearchDisplayedItem(*data.GadgetData, *Adress)
	
	Declare Refit(Gadget)
	
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
			*data\XOffset = *data\Border + *data\ItemList_Width
			*data\Body_Height = Height - *data\YOffset - *data\Border
			*data\Body_Width = Width - *data\ItemList_Width - 2 * *data\Border
			*data\VisibleItems = Round(*data\Body_Height / #Style_ItemList_ItemHeight, #PB_Round_Down)
			
			*data\VScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, 10, 10,   #PB_ScrollBar_Vertical)
			BindGadgetEvent(*data\VScrollbar_ID, @HandlerVScrollbar())
			*data\VScrollbar_Width = GadgetWidth(*data\VScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\VScrollbar_Visible = #False
			HideGadget(*data\VScrollbar_ID, #True)
			SetGadgetData(*data\VScrollbar_ID, Gadget)
			
			*data\HScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, 10, 10)
			*data\HScrollbar_Height = GadgetHeight(*data\VScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\HScrollbar_Visible = #False
			HideGadget(*data\HScrollbar_ID, #True)
			SetGadgetData(*data\HScrollbar_ID, Gadget)
			
			*data\FontID = FontID(DefaultFont)
			*data\Font = DefaultFont
			
			CloseGadgetList()
			
			SetGadgetData(Gadget, *data)
			BindGadgetEvent(Gadget, @HandlerCanvas())
			
			Redraw(Gadget, #True)
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
		*data\DisplayedItems()\YOffset = *data\Border + #Style_ItemList_FoldOffset
		
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
		
	EndProcedure
	
	; Private procedures
	Procedure Redraw(Gadget, CompleteRedraw = #False)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		Protected YPos, Loop
		
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
					
					If *data\DisplayedItems()\Type = #Item_Main
						ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\Adress)
						If *data\Items()\Folded = #Folded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + #Style_ItemList_FoldOffset, YPos + #Style_ItemList_FoldVOffset, #Style_ItemList_FoldSize, Color_ItemList_FrontColor, Color_ItemList_BackColor, MaterialVector::#style_rotate_90)
						ElseIf *data\Items()\Folded = #Unfolded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + #Style_ItemList_FoldOffset, YPos + #Style_ItemList_FoldVOffset, #Style_ItemList_FoldSize, Color_ItemList_FrontColor, Color_ItemList_BackColor, MaterialVector::#style_rotate_180)
						EndIf
					Else
						ChangeCurrentElement(*data\Items(), *data\DisplayedItems()\ParentAdress)
						ChangeCurrentElement(*data\Items()\SubItems(), *data\DisplayedItems()\Adress)
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
			If CompleteRedraw Or *data\VerticalMovement Or *data\Border 
				StartDrawing(CanvasOutput(Gadget))
				
				If CompleteRedraw Or *data\VerticalMovement
					DrawingFont(*data\FontID)
					DrawingMode(#PB_2DDrawing_Transparent)
					If SelectElement(*data\DisplayedItems(), *data\VScrollbar_Position)
						For Loop = 0 To *data\VisibleItems
							DrawText(*data\DisplayedItems()\YOffset, Loop * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_TextVOffset , *data\DisplayedItems()\Name,Color_ItemList_FrontColor, Color_ItemList_BackColor)
							If Not NextElement(*Data\DisplayedItems())
								Break
							EndIf
						Next
					EndIf
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
		Protected Gadget = EventGadget(), MouseX = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX), MouseY =  GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
		
		
		
		Select EventType()
			Case #PB_EventType_MouseMove
				
		EndSelect
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
		
		;Calculate available If we need the horizontal scrollbar
		
		If *data\VScrollbar_Visible
			ResizeGadget(*data\VScrollbar_ID, Width - *data\Border - *data\VScrollbar_Width, *data\YOffset, *data\VScrollbar_Width, *data\Body_Height - *data\HScrollbar_Height * *data\HScrollbar_Visible)
		Else
			SetGadgetState(*data\VScrollbar_ID, 0)
		EndIf
		
		HideGadget(*data\VScrollbar_ID, Bool(Not *data\VScrollbar_Visible))
		HideGadget(*data\HScrollbar_ID, Bool(Not *data\HScrollbar_Visible))
		
		Redraw(Gadget, #True)
	EndProcedure
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 441
; FirstLine = 303
; Folding = -wPX+
; EnableXP