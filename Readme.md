## Compression of Apple II Graphic files

This utility can compress Apple II High/Double Resolution graphic files. It can also inflate the compressed file producing a copy of the original file. Detailed Information can be found in the Documentation.rtfd file.

The program is set to save all messages output using the NSLog function to a file named `messages.log`. This file is stored in the user's Library/Application Support directory. The full pathname is /Users/user_name/Library/Application Support/CompressIIX/messages.log

Output to the log file can be viewed using Apple's Console.app. The program has a menu named `Logs`. The `Display` menu item will pass the file `messages.log` to Console.app which will open and display its contents for viewing. The `Clear` menu item will remove all messages from the log file.

The user can turn off this feature by commenting out the relevant code if he/she is running the program under XCode. All output will be sent to XCode's console.


Compiler version:

XCode 3.2.x or late

Runtime:

macOS 10.5.x or later


Todo:

Add a progress window.
