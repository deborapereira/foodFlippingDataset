# Computers clock synchronization method

The clocks of the two computers were synchronized by calculating the time difference between them, each day of experiments. To do so, the two computers were connected through an Ethernet cable and a custom code (the server and client code in this repo) was run on each computer to establish a standard TCP/IP communication between them (see the illustration below): a message was sent from computer 1 to computer 2 (in red), and the second computer replied back (in yellow); the LabRecorder app was also running in each computer (independently of one another), to record three timestamps – the app in the first computer registered the instant when the message of computer 1 was sent to computer 2 (t_1) and the instant when the answer of computer 2 arrived to computer 1 (t_3); the app in the second computer registered the instant when the message of computer 1 arrived to computer 2 (t_2). This way, with t_travel=(t_3-t_1)/2 we could get the time of travel, and with t_diff=t_2-t_1-t_travel we could get the time difference between the clocks of the computers. This was done every day, before running the experiments and, later, offline, t_diff  was used to align the timestamps of the data collected by the two computers.

![clocks](https://user-images.githubusercontent.com/65245040/131116579-00829a63-99cd-4492-bcf0-b01d07a00cf2.jpg)




# Code usage

The files 

PCs_clock_synchronization\tcp_server_4synch\tcp_client_4synch\client.cpp and PCs_clock_synchronization\tcp_server_4synch\tcp_server_4synch\server.cpp

are the source code that creates the TCP/IP communication between the computers and that creates the LSL outlet data stream for the LabRecorder app to assign timestamps to the messages exchaged via TCP between the computers.


------------------------------------------------------------------------------------

To reuse the code, it is necessary to modify the code of client.cpp to have the correct IP address of your TCP server, as follows:

1. connect the computers by an ethernet cable;
2. go to the "Network and Sharing Center" (Windows OS) of the computer that you will use as TCP server and check the IP address of the computer that is attributed automatically (click on the ethernet connection, then in "Details");
3. open tcp_server_4synch.sln in Visual Studio for recompiling the project;
4. write the observed IP address in the line 55 of PCs_clock_synchronization\tcp_server_4synch\tcp_client_4synch\client.cpp file. 
5. on the "Solution Explorer" of Visual Studio, click on "tcp_client_4synch" with the right button and select "Set as StartUp project";
6. recompile (set "Release" and "x64" and click on "Local Windows Debugger"). (If the cmd starts with the tcp client, just close it)
7. go to the folder "x64" (attention: the one that is inside the same folder containing the tcp_server_4synch.sln!) and run the tcp_server_4synch.exe;
8. start the LabRecorder, click on "Update", check the "server_stream", define a name for the xdf file and click "Start" (the cmd window running tcp_server_4synch.exe should say "Connected to LSL");
9. copy the tcp_client_4synch.exe that is in the same "x64" folder (mentioned in 7.) to the second computer and run it;
10. start LabRecorder in the second computer, too (click on "Update", check the "client_stream" only, define a name for the xdf file and click "Start" (the cmd window running tcp_client_4synch.exe should say "Connected to LSL" and immediately after "SYNCHRONIZATION DONE"));
11. save the xdf file created by the LabRecorder of each computer.

NOTE #1: liblsl64.dll and vcruntime140_1.dll must be copied to both computers, in the same folder where you put the executables! They are in PCs_clock_synchronization\dll_files.

NOTE #2: the LSL LabRecorder app is in PCs_clock_synchronization\LabRecorder-1.12d\LabRecorder.exe

