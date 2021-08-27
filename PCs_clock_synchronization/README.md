# Computers clock synchronization method

The clocks of the two computers were synchronized by calculating the time difference between them, each day of experiments. To do so, the two computers were connected through an Ethernet cable and a custom code (the server and client code in this repo) was run on each computer to establish a standard TCP/IP communication between them (see the illustration below): a message was sent from computer 1 to computer 2 (in red), and the second computer replied back (in yellow); the LabRecorder app was also running in each computer (independently of one another), to record three timestamps – the app in the first computer registered the instant when the message of computer 1 was sent to computer 2 (t_1) and the instant when the answer of computer 2 arrived to computer 1 (t_3); the app in the second computer registered the instant when the message of computer 1 arrived to computer 2 (t_2). This way, with t_travel=(t_3-t_1)/2 we could get the time of travel, and with t_diff=t_2-t_1-t_travel we could get the time difference between the clocks of the computers. This was done every day, before running the experiments and, later, offline, t_diff  was used to align the timestamps of the data collected by the two computers.

![clocks](https://user-images.githubusercontent.com/65245040/131116448-40b0eb8a-e702-4c1f-9eec-a7781331784f.png)



# Code usage

The files 

PCs_clock_synchronization\tcp_server_4synch\tcp_client_4synch\client.cpp  and PCs_clock_synchronization\tcp_server_4synch\tcp_server_4synch\server.cpp

are the source code that creates the TCP/IP communication between the computers and that creates the LSL outlet data stream for the LabRecorder app to assign timestamps to the messages exchaged via TCP between the computers.


------------------------------------------------------------------------------------

If you wish to modify the IP address, to reuse the code, connect the computers by an ethernet cable, check the IP address of the pc that you will use as the TCP server and update this address in the line 55 of PCs_clock_synchronization\tcp_server_4synch\tcp_client_4synch\client.cpp file. Recompile. Then, go to the folder PCs_clock_synchronization\tcp_server_4synch\x64 and:

- Copy the tcp_client_4synch.exe to one of the two computers.
- Copy the tcp_server_4synch.exe to the second computer.

liblsl64.dll must be copied to both computers, in the same folder as the executables.

Don't forget to start the LSL LabRecorder app (PCs_clock_synchronization\LabRecorder-1.12d\LabRecorder.exe) to record the timestamps, so that you can calculate afterwards the clocks time difference from. The timestamps will be saved in an XDF file, generated by the LabRecorder.

------------------------------------------------------------------------------------

If you don't want to change the code, just use the executables in the folder PCs_clock_synchronization\executables. Remember that liblsl64.dll must be copied to both computers, in the same folder as the executables.
Before running anythig, change the IP address of the computer that will be the TCP server to 192.169.200.2