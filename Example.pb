IncludeFile "PureTimeline.pbi"

OpenWindow(0, 0, 0, 700, 400, "PureTimeline Example", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
PureTL::Gadget(0, 10, 10, 680, 380, PureTL::#Header)
PureTL::AddItem(0, "Item 1", -1)
PureTL::AddItem(0, "Item 2", -1)
PureTL::AddItem(0, "Item 3", -1)
PureTL::AddItem(0, "Item 4", 3)

Repeat
	WaitWindowEvent()
ForEver
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 2
; EnableXP