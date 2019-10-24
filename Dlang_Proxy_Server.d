/*
    Dlang Proxy.
    Created by Marcone (thegrapevine@email.com) in 2019.
*/

import std;
import core.thread;
import core.stdc.stdlib;

// Configuracoes.
ushort LISTEN_PORT = 80;
ushort TARGET_PORT = 22; // Redirect to this SSH port.

void conecta(Socket c, int conn_number, ushort TARGET_PORT){

    writeln("\nConnection #", conn_number);
	writeln("[#] Received Client.");

    char[8192] request;
    auto rq = c.receive(request);

    auto s = new Socket(AddressFamily.INET, SocketType.STREAM);
    s.blocking = true;
    writeln("[-] Redirecting to Target Local Port: ", TARGET_PORT);
    try{
        s.connect(new InternetAddress("0.0.0.0", TARGET_PORT));
    }catch(Exception){
        writeln("[!] Error when try to connect to Target Local Port: ", TARGET_PORT);
    }
    
    c.send("HTTP/1.1 200 Established\r\n\r\n");

    auto set = new SocketSet();
    char[8192] data;

    while(true){
        set.reset();
        set.add(s);
        set.add(c);
        Socket.select(set, null, null, null); 
        
        if (set.isSet(s)){
            // Download
            auto got = s.receive(data);
            if (got == 0){break;}
            c.send(data[0 .. got]);
        } else {
            // Upload
            auto got = c.receive(data);
            if (got == 0){break;}
            s.send(data[0 .. got]);
        }
    }
    writeln("[!] Client Disconnected!");
    writeln("[!] Connection #%d Closed!".format(conn_number));
}

void main(){
	writeln("-*-*-*- Dlang Proxy -*-*-*-\nCreated by Marcone (thegrapevine@email.com) in 2019\n");

    int conn_number = 0;

	// Listen
	auto l = new Socket(AddressFamily.INET, SocketType.STREAM);
    l.blocking = true;
    try {
        l.bind(new InternetAddress("0.0.0.0", LISTEN_PORT));
        l.blocking = true;
    } catch(Exception){
        writeln("[!] Listen Error! Listen Port ", LISTEN_PORT, " is alread in Use!" );
        readln();
        exit(1);
    } 
    l.listen(1);
    writeln("[-] Proxy Listening on Port: ", LISTEN_PORT, "\n");

    while(true){
        conn_number += 1;
        task!conecta(l.accept(), conn_number, TARGET_PORT).executeInNewThread();
    }
}