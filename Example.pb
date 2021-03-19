IncludeFile "PureTimeline.pbi"

Procedure Handler_CloseWindow()
	End
EndProcedure

Procedure Handler_SizeWindow()
	PureTL::Resize(0, #PB_Ignore, #PB_Ignore, WindowWidth(0) - 20, WindowHeight(0) - 20)
EndProcedure

OpenWindow(0, 0, 0, 700, 400, "PureTimeline Example", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)
PureTL::Gadget(0, 10, 10, 680, 380, PureTL::#Header | PureTL::#DarkTheme)
item_id = PureTL::AddItem(0, "Item 1", -1)
PureTL::AddMediaBlock(0, item_id, 5, 19, 0)
PureTL::AddDataPoint(0, item_id, 19, 0)
PureTL::AddDataPoint(0, item_id, 20, 0)
PureTL::AddDataPoint(0, item_id, 21, 0)
PureTL::AddDataPoint(0, item_id, 22, 0)
PureTL::AddDataPoint(0, item_id, 23, 0)
PureTL::AddDataPoint(0, item_id, 5, 0)
PureTL::AddDataPoint(0, item_id, 6, 0)
item_id = PureTL::AddItem(0, "Item 2", -1)
PureTL::AddMediaBlock(0, item_id, 9, 23, 0)
PureTL::AddDataPoint(0, item_id, 19, 0)
item_id = PureTL::AddItem(0, "Item 3", -1)
PureTL::AddMediaBlock(0, item_id, 17, 31, 0)
PureTL::AddDataPoint(0, item_id, 19, 0)
item_id = PureTL::AddItem(0, "Item 4", 2)
PureTL::AddMediaBlock(0, item_id, 13, 27, 0)
PureTL::AddDataPoint(0, item_id, 19, 0)
item_id = PureTL::AddItem(0, "Item 5", -1)
PureTL::AddMediaBlock(0, item_id, 21, 35, 0)
PureTL::AddDataPoint(0, item_id, 19, 0)
item_id = PureTL::AddItem(0, "Item 6", -1)
PureTL::AddMediaBlock(0, item_id, 25, 39, 0)
PureTL::AddDataPoint(0, item_id, 19, 0)

item_id = PureTL::GetItemID(0, 3)

PureTL::AddItem(0, "Testouille 2", -1, item_id)
PureTL::AddItem(0, "Testouille 1", 0, item_id)

item_id = PureTL::GetItemID(0, 0, item_id)

PureTL::AddItem(0, "Testouille 3", -1, item_id)
PureTL::AddItem(0, "Testouille 4", -1, item_id)
PureTL::AddItem(0, "Testouille 5", -1, item_id)

PureTL::AddItem(0, "Item 7", -1)
PureTL::AddItem(0, "Item 8", -1)
PureTL::AddItem(0, "Item 9", -1)
PureTL::AddItem(0, "Item 10", -1)
PureTL::AddItem(0, "Item 11", -1)

WindowBounds(0, 700, 400, #PB_Ignore, #PB_Ignore)
BindEvent(#PB_Event_CloseWindow, @Handler_CloseWindow())
BindEvent(#PB_Event_SizeWindow, @Handler_SizeWindow())

Repeat
	WaitWindowEvent()
ForEver
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 11
; Folding = -
; EnableXP