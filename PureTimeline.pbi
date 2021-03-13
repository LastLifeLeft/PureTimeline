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
	
	EnumerationBinary ; Items flags
		#Item_AutoFill = 1
	EndEnumeration
	
	Enumeration ;Content Type
		#Content_Media
		#Content_DataPoints
	EndEnumeration
	
	#DefaultDuration = 119
	
	; Public procedures declaration
	Declare Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
	
	Declare AddItem(Gadget, Name.s, Position, ParentID = 0, Flags = #Default)
	Declare AddMediaBlock(Gadget, Item, SubItem, Start, Finish, ID, Color)
	Declare AddDataPoint(Gadget, Item, SubItem, Position, ID, Color)
	
	Declare GetItemID(Gadget, Position, ParentID = 0)
	
	Declare SetDuration(Gadget, Duration)
	
	Declare RemoveItem(Gadget, Item)
	
	
	
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
	
	Enumeration ; MediaBlock Type
		#MediaBlock_Start
		#MediaBlock_Body
		#MediaBlock_End
	EndEnumeration
	
	Structure Content
		MediaBlock_Color.l
		MediaBlock_End.l
		MediaBlock_Origin.l
		MediaBlock_ID.i
		
		DataPoint.b
		DataPoint_Color.b
		DataPoint_Count.i
		DataPoint_ID.i
	EndStructure

	Structure Itemlist
		*item.Item
	EndStructure
	
	Structure Item
		Name.s
		Folded.b
		AutoFill.b
		Visible.b
		List SubItems.Itemlist()
		; 		Array ContentArray.Content(#DefaultDuration)
		
		;Draw info
		YOffset.i
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
		
		List DisplayedItems.Itemlist()
		
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
	
	#Style_ItemList_FoldOffset = 24
	#Style_ItemList_FoldSize = 12
	#Style_ItemList_TextOffset = #Style_ItemList_FoldSize + #Style_ItemList_FoldOffset + 16
	#Style_ItemList_SubTextOffset = #Style_ItemList_TextOffset + 12
	
	#Style_ItemList_FoldVOffset = (#Style_ItemList_ItemHeight - #Style_ItemList_FoldSize) / 2 + 1
	#Style_ItemList_TextVOffset = (#Style_ItemList_ItemHeight - 20) / 2
	#Style_ItemList_FontSize	= 20
	
	#Style_VectorText = #True 										; I find the vector drawn text to impair readability too much on Windows, so we'll fallback on the classic 2D drawing for text... Though drawing twice on the same canvas provokes the occasional flikering.
	
	#Style_Body_DefaultColumnWidth = 15
	#Style_Body_Margin = 2											; Number of empty column placed at the start and the end of the timeline, making the gadget more legible.
	
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
	
	Declare Refit(Gadget)
	
	Declare ToggleFold(Gadget, *Data.GadgetData, Item)
	
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
					
					Theme = CanvasButton::#DarkTheme
				Else
					\Color_Body_Back = #Color_Body_Light_Back
					\Color_Body_BackAlt = #Color_Body_Light_BackAlt
					\Color_Body_BackHot = #Color_Body_Light_BackHot
					
					\Color_ItemList_Back = #Color_ItemList_Light_Back
					\Color_ItemList_Front = #Color_ItemList_Light_Front
					\Color_ItemList_BackHot = #Color_ItemList_Light_BackHot
					\Color_ItemList_FrontHot = #Color_ItemList_Light_FrontHot
					
					Theme = CanvasButton::#LightTheme
				EndIf
				
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
				\Duration = #DefaultDuration
				
				\VScrollbar_ID = ScrollBarGadget(#PB_Any, 0, \YOffset, 20, \Body_Height, 0, 10, 10,   #PB_ScrollBar_Vertical)
				BindGadgetEvent(\VScrollbar_ID, @HandlerVScrollbar())
				\VScrollbar_Width = GadgetWidth(\VScrollbar_ID, #PB_Gadget_RequiredSize)
				\VScrollbar_Visible = #False
				HideGadget(\VScrollbar_ID, #True)
				SetGadgetData(\VScrollbar_ID, Gadget)
				
				\HScrollbar_ID = ScrollBarGadget(#PB_Any, 0, \YOffset, 20, \Body_Height, 0, \Duration + #Style_Body_Margin, 10)
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
		
		If *Parent.Item
			AddElement(*Parent\SubItems())
			*Parent\SubItems()\item = *Result
		Else
			AddElement(*Data\Items())
			*Data\Items()\item = *Result
		EndIf
		
		ProcedureReturn *Result
	EndProcedure
	
	Procedure GetItemID(Gadget, Position, ParentID = 0)
		
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
	
	Procedure AddMediaBlock(Gadget, Item, SubItem, Start, Finish, ID, Color)
		
	EndProcedure
	
	Procedure AddDataPoint(Gadget, Item, SubItem, Position, ID, Color)
		
	EndProcedure
	
	; Private procedures
	Procedure Redraw(Gadget, CompleteRedraw = #False)

	EndProcedure
	
	Procedure HandlerCanvas()
		
	EndProcedure
	
	Procedure ToggleFold(Gadget, *Data.GadgetData, Item)
		
	EndProcedure
	
	Procedure HandlerVScrollbar()
		
	EndProcedure
	
	Procedure SearchDisplayedItem(*Data.GadgetData, *Adress)

	EndProcedure
	
	Procedure Refit(Gadget)
		
	EndProcedure
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 233
; FirstLine = 170
; Folding = cO5-
; EnableXP