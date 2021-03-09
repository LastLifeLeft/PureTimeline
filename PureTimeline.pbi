DeclareModule PureTL
	; Public variables, structures, constants...
	#Header = 2
	#Border = 4
	
	; Public procedures declaration
	Declare Gadget(Gadget, X, Y, Width, Height, Flags = #False)
	Declare AddItem(Gadget, Name.s, Position)
	Declare RemoveItem(Gadget)
	Declare SetDuration(Gadget)
	
	
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
	
	Structure Item
		Name.s
		Folded.b
		
		List SubItems.i()
	EndStructure
	
	Structure DisplayedItem
		Type.b
		*Adress
		Name.s
	EndStructure
	
	Structure GadgetData
		;Flags & options
		Header.b
		Border.b
		
		;Componants
		VScrollbar_ID.i
		VScrollbar_Hidden.b
		VScrollbar_Width.i
		HScrollbar_ID.i
		HScrollbar_Hidden.b
		HScrollbar_Height.i
		
		;state
		VerticalMovement.b
		HorizontalMovement.b
		ItemList_Width.i
		
		;Redraw
		YOffset.i
		XOffset.i
		Body_Height.i
		Body_Width.i
		FontID.i
		Font.i
		List DisplayedItems.DisplayedItem()
		
		;Items
		List Items.Item()
		
	EndStructure
	
	Global DefaultFont = LoadFont(#PB_Any, "Calibri", 12, #PB_Font_HighQuality)
	
	;Style
	#Style_HeaderHeight = 50
	#Style_BorderThickness = 1
	
	#Style_ItemList_Width = 240
	#Style_ItemList_ItemHeight = 30
	#Style_ItemList_YOffset = 10
	
	;Colors
	Global Color_Border = RGBA(16,16,16,255)
	Global Color_BackColor = RGBA(54,57,63,255)
	
	Global Color_ItemList_BackColor = RGBA(47,49,54,255)
	Global Color_ItemList_FrontColor = RGBA(142,146,151,255)
	
	;Icons
	
	;}
	
	; Private procedures declaration
	Declare Redraw(Gadget, CompleteRedraw = #False)
	
	Declare Handler()
	
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
			
			*data\VScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, 10, 10,   #PB_ScrollBar_Vertical)
			*data\VScrollbar_Width = GadgetWidth(*data\VScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\VScrollbar_Hidden = #True
			HideGadget(*data\VScrollbar_ID, #True)
			
			*data\HScrollbar_ID = ScrollBarGadget(#PB_Any, 0, *data\YOffset, 20, *data\Body_Height, 0, 10, 10)
			*data\HScrollbar_Height = GadgetHeight(*data\VScrollbar_ID, #PB_Gadget_RequiredSize)
			*data\HScrollbar_Hidden = #True
			HideGadget(*data\HScrollbar_ID, #True)
			
			*data\FontID = FontID(DefaultFont)
			*data\Font = DefaultFont
			
			CloseGadgetList()
			
			SetGadgetData(Gadget, *data)
			BindGadgetEvent(Gadget, @Handler())
			
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
			InsertElement(*data\Items())
			LastElement(*data\DisplayedItems()) ; /!\ Ca va pas marcher une fois qu'on aura des subitems...
			AddElement(*data\DisplayedItems())
		EndIf
		
		*data\Items()\Name = Name
		*data\DisplayedItems()\Name = *data\Items()\Name
		*data\DisplayedItems()\Adress = @*data\Items()
		
		Redraw(Gadget, #True)
	EndProcedure
	
	Procedure RemoveItem(Gadget)
	EndProcedure
	
	Procedure SetDuration(Gadget)
	EndProcedure
	
	; Private procedures
	Procedure Redraw(Gadget, CompleteRedraw = #False)
		Protected *data.GadgetData = GetGadgetData(Gadget)
; 		
; 		StartDrawing(CanvasOutput(Gadget))
; 		DrawingFont(*data\FontID)
; 		
; 		If *data\HorizontalMovement Or CompleteRedraw
; 			; Redraw the header
; 			*data\HorizontalMovement = #False
; 		EndIf
; 		
; 		If *data\VerticalMovement Or CompleteRedraw
; 			; Redraw the itemlist
; 			*data\VerticalMovement = #False
; 			Box(*data\Border, *data\YOffset, *data\ItemList_Width, *data\Body_Height, Color_ItemList_BackColor)
; 			
; 			ForEach *data\Items()
; 				DrawText(15, ListIndex(*data\Items()) * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_YOffset , *data\Items()\Name,Color_ItemList_FrontColor, Color_ItemList_BackColor)
; 			Next
; 			
; 		EndIf
; 		
; 		Box(*data\XOffset, *data\YOffset, *data\Body_Width, *data\Body_Height, Color_BackColor)
; 		
; 		If *data\Border
; 			DrawingMode(#PB_2DDrawing_Outlined)
; 			Box(0, 0, OutputWidth(), OutputHeight(), Color_Border)
; 		EndIf
; 		
; 		StopDrawing()
		
		
		StartVectorDrawing(CanvasVectorOutput(Gadget))
		VectorFont(*data\FontID)
		
		If *data\HorizontalMovement Or CompleteRedraw
			; Redraw the header
			*data\HorizontalMovement = #False
		EndIf
		
		If *data\VerticalMovement Or CompleteRedraw
			; Redraw the itemlist
			*data\VerticalMovement = #False

			AddPathBox(*data\Border, *data\YOffset, *data\ItemList_Width, *data\Body_Height)
			VectorSourceColor(Color_ItemList_BackColor)
			FillPath()
			
			VectorSourceColor(Color_ItemList_FrontColor)
			ForEach *data\Items()
				MovePathCursor(15, ListIndex(*data\Items()) * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_YOffset, #PB_Path_Default)
; 				DrawVectorText(*data\Items()\Name)
			Next
			
		EndIf
		
		AddPathBox(*data\XOffset, *data\YOffset, *data\Body_Width, *data\Body_Height)
		VectorSourceColor(Color_BackColor)
		FillPath()
		
		StopVectorDrawing()
		
		If CompleteRedraw Or *data\VerticalMovement Or *data\Border ; I find the vector drawn text to impair readability too much on Windows, so we'll fallback on the classic 2D drawing for text.
			StartDrawing(CanvasOutput(Gadget))
			
			If CompleteRedraw Or *data\VerticalMovement
				DrawingFont(*data\FontID)
				ForEach *data\Items()
					DrawText(15, ListIndex(*data\Items()) * #Style_ItemList_ItemHeight + *data\YOffset + #Style_ItemList_YOffset , *data\Items()\Name,Color_ItemList_FrontColor, Color_ItemList_BackColor)
				Next
			EndIf
			
			If *data\Border
				DrawingMode(#PB_2DDrawing_Outlined)
				Box(0, 0, OutputWidth(), OutputHeight(), Color_Border)
			EndIf
			
			StopDrawing()
		EndIf
		
	EndProcedure
	
	Procedure Handler()
		
	EndProcedure
EndModule






;"►▼"



































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 235
; FirstLine = 15
; Folding = --
; EnableXP