IncludeFile "PureTimeline.pbi"

OpenWindow(0, 0, 0, 700, 400, "PureTimeline Example", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
PureTL::Gadget(0, 10, 10, 680, 380, PureTL::#Header)
PureTL::AddItem(0, "Item 1", -1)
PureTL::AddItem(0, "Item 2", -1)
PureTL::AddItem(0, "Item 3", -1)
PureTL::AddItem(0, "Item 4", 2)
PureTL::AddItem(0, "Item 5", -1)
PureTL::AddItem(0, "Item 6", -1)
PureTL::AddItem(0, "Item 7", -1)
PureTL::AddItem(0, "Item 8", -1)
PureTL::AddItem(0, "Item 9", -1)
PureTL::AddItem(0, "Item 10", -1)
PureTL::AddItem(0, "Item 11", -1)
PureTL::AddSubItem(0, 2, "Testouille", -1)
PureTL::AddSubItem(0, 2, "Testouille", -1)
PureTL::AddSubItem(0, 5, "Testouille", -1)


Repeat
	WaitWindowEvent()
ForEver
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 14
; EnableXP