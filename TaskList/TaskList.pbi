DeclareModule TaskList
	
	Declare Create(Maximum = -1)
	Declare Free(TaskList)
	Declare ReDo(TaskList)
	Declare Undo(TaskList)
	Declare NewTask(TaskList, *Data, *Callback)
EndDeclareModule


Module TaskList
	;{ Private variables, structures, constants...
	Structure Task
		*Callback
		*Data
	EndStructure
	
	Structure TaskList
		Maximum.i
		List Task.Task()
	EndStructure
	;}
	
	;{ Private procedures declaration
	
	;}
	
	;{ Public procedures
	Procedure Create(Maximum = -1)
		Protected *Data.TaskList = AllocateStructure(TaskList)
		
		*Data\Maximum = Maximum
		
		ProcedureReturn *Data
	EndProcedure
	
	Procedure Free(*TaskList.TaskList)
		ForEach *TaskList\Task()
			FreeMemory(*TaskList\Task()\Data)
		Next
		
		FreeStructure(*TaskList)
	EndProcedure
	
	Procedure ReDo(*TaskList.TaskList)
		If NextElement(*TaskList\Task())
			CallFunctionFast(*TaskList\Task()\Callback, *TaskList\Task()\Data, #True)
		EndIf
	EndProcedure
	
	Procedure Undo(*TaskList.TaskList)
		If ListIndex(*TaskList\Task()) > -1
			CallFunctionFast(*TaskList\Task()\Callback, *TaskList\Task()\Data, #False)
			If Not PreviousElement(*TaskList\Task())
				ResetList(*TaskList\Task())
			EndIf
		EndIf
	EndProcedure
	
	Procedure NewTask(*TaskList.TaskList, *Data, *Callback)
		If ListIndex(*TaskList\Task()) < ListSize(*TaskList\Task()) - 1
			While NextElement(*TaskList\Task())
				FreeMemory(*TaskList\Task()\Data)
				DeleteElement(*TaskList\Task())
			Wend
		EndIf
		
		AddElement(*TaskList\Task())
		*TaskList\Task()\Data = *Data
		*TaskList\Task()\Callback = *Callback
	EndProcedure
	;}
	
	;{ Private procedures
	
	;}
	
	
	
	
EndModule

; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 54
; FirstLine = 5
; Folding = --
; EnableXP