ScriptName OCumPlayerAliasScript Extends ReferenceAlias

OCumScript Property OCum Auto

Event OnInit()
	OCum = (GetOwningQuest()) as OCumScript
EndEvent

Event OnPlayerLoadGame()
	OCum.onload()
EndEvent
