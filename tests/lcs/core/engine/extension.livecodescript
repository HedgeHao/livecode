script "CoreEngineExtensions"
/*
Copyright (C) 2016 LiveCode Ltd.

This file is part of LiveCode.

LiveCode is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License v3 as published by the Free
Software Foundation.

LiveCode is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with LiveCode.  If not see <http://www.gnu.org/licenses/>.  */

constant kBytecodePath = "../_tests/_build/lcs/core/engine"

local sTestExtension

on TestSetup
    TestLoadExtension "com.livecode.library.json"
    TestLoadExtension "com.livecode.widget.clock"

    buildMultiModuleExtension "_extension,_extension_support"
    if the result is not empty then
       throw "Failed to build test support extension:" && the result
    end if
    put it into sTestExtension

    load extension from data sTestExtension
    if the result is not empty then
       throw "Failed to load test support extension:" && the result
    end if
end TestSetup

private command buildMultiModuleExtension pInputs, pOutput
    -- Build a multi-module extension
    local tBasename, tBytecode, tFile
    repeat for each item tBasename in pInputs
       put merge("[[kBytecodePath]]/[[tBasename]].lcm") into tFile
       put url("binfile:" & tFile) after tBytecode
       put the result into tResult
       if tResult is not empty then
          return merge("Failed to load [[tFile]]: [[tResult]]") for error
       end if
    end repeat

    return tBytecode for value
end buildMultiModuleExtension

/////////

on TestUnloadLibraryModule
    unload extension "com.livecode.library.json"
    TestAssert "library extension unloaded", the result is empty
end TestUnloadLibraryModule

/////////

command _TestUnloadWidgetModuleAfterDeletion_DoDeleteAndUnload
    delete widget "TestWidget"
    unload extension "com.livecode.widget.clock"
    TestAssert "widget extension unloaded", the result is empty
end _TestUnloadWidgetModuleAfterDeletion_DoDeleteAndUnload

on TestUnloadWidgetModuleAfterDeletion
    create stack "TestStack"
    create widget "TestWidget" as "com.livecode.widget.clock"

    -- Make sure we delete and then unload widget in a nested wait so that it
    -- isn't immediately deleted.
    send "_TestUnloadWidgetModuleAfterDeletion_DoDeleteAndUnload" to me in 0 millisecs
    wait 1 millisecond with messages
end TestUnloadWidgetModuleAfterDeletion

/////////

function TestExtensionBridgeNames_Version
   return the version
end TestExtensionBridgeNames_Version

on TestExtensionBridgeNames
   TestAssert "LCS names bridge to LCB strings in execute script", \
         TestExtensionBridgeNames_ExecuteScript()
   TestAssert "LCS names bridge to LCB strings in send", \
         TestExtensionBridgeNames_Send()
end TestExtensionBridgeNames

on TestExtensionBridgeNumbers
   TestAssert "LCS numbers bridge to LCB numbers in execute script", \
         TestExtensionBridgeNumbers_ExecuteScript()
end TestExtensionBridgeNumbers

//////////

on TestMultiModuleExtensions
   TestAssert "support modules are not in extension list", \
         "com.livecode.lcs_tests.core.extension.support" is not among \
         the lines of the loadedExtensions
   TestAssert "main modules are in extension list", \
         "com.livecode.lcs_tests.core.extension" is among \
         the lines of the loadedExtensions
   TestAssert "extension support module handlers work", \
         TestExtensionSupportModule_Handler()

   -- Check that unloading an extension also unloads support modules
   -- (allowing them to be loaded again)
   unload extension "com.livecode.lcs_tests.core.extension"
   TestAssert "unload multi-module extension", the result is empty

   load extension from data sTestExtension
   TestAssert "reload multi-module extension", the result is empty

   -- Check that extensions with incorrect support module names don't
   -- load
   unload extension "com.livecode.lcs_tests.core.extension"
   buildMultiModuleExtension "_extension_support,_extension"
   if the result is not empty then
      throw "Failed to build assembly:" && the result
   end if
   load extension from data it
   TestAssert "can't load multi-module extensions with bad module names", \
         the result is not empty
end TestMultiModuleExtensions
