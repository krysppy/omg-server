package
{

    import components.Console;
    import components.Console;

    import flash.events.*;
    import flash.filesystem.*;
    import flash.net.*;

    import mx.utils.UIDUtil;

    public class Server extends EventDispatcher
    {
        private var sessions: Object;
        private var server: ServerSocket;

        // Data
        private var userNameIdPairs: Object;
        private var users: Object;
        private var rooms: Object;

        private var dataManager: DataManager;

        public function Server(): void
        {
            // Singletons
            dataManager = DataManager.getInstance();

            // Load data from file
            var file: File = File.applicationStorageDirectory.resolvePath("data.json");
            if (!file.exists)
            {
                // No data yet, create an empty file
                var fileStream: FileStream = new FileStream();
                fileStream.open(file, FileMode.WRITE);
                fileStream.writeUTFBytes(JSON.stringify({}));
                fileStream.close();
            }

            // TODO Populate users from data (User)
            users = {};

            // TODO Populate rooms from data (Room)
            rooms = {};

            // Sessions start empty
            sessions = {};

            // Start the server
            server = new ServerSocket();
            server.bind(Service.PORT);
            server.addEventListener(ServerSocketConnectEvent.CONNECT, handleConnect);
            server.listen();
            Console.log("Server started on port " + Service.PORT);
        }

        private function handleConnect(e: ServerSocketConnectEvent): void
        {
            // When a Socket connects
            var session: Session = new Session(e.socket);

            // Session event listeners
            session.addEventListener(Session.DISCONNECT, handleDisconnect);
            session.addEventListener(Session.CONFIRM, handleConfirm);
            session.addEventListener(MessageEvent.DATA, handleDataReceived);
        }

        private function handleConfirm(e: Event): void
        {
            // When a Session that's connected is confirmed (not a "policy connect")
            var session: Session = (e.target as Session);
            sessions[session.id] = session;
            Console.log("Session (" + session.id + ") connected\n  " + session.socket.remoteAddress, "userJoined", {ip: session.socket.remoteAddress});
        }

        private function handleDisconnect(e: Event): void
        {
            // When a Session disconnects
            var session: Session = (e.target as Session);
            delete sessions[session.id];

            Console.log("Session (" + session.id + ") disconnected\n  " + session.socket.remoteAddress, "userLeft", {ip: session.socket.remoteAddress});
        }

        private function handleDataReceived(e: MessageEvent): void
        {
            // Handle all received data from sessions here
            var m: Object = e.data;
            var s: Session = Session(e.target);
            var user: User;

            // Handle messages from all sessions, whether or not they are logged in
            Console.log(JSON.stringify(m));

            if (m.hasOwnProperty("request"))
            {
                // Handle a request
                s.send({"request-return": {id: m.request, data: dataManager.getData(m.request)}});
            }
        }

        private function userIdFromName(name: String): String
        {
            if (!userNameIdPairs)
                userNameIdPairs = {};

            if (!userNameIdPairs[name])
            {
                for each (var user: User in users)
                {
                    if (user.name == name)
                    {
                        userNameIdPairs[name] = user.id;
                        break;
                    }
                }
            }

            return userNameIdPairs[name];
        }

        public function save(): void
        {
            // Save userData
            var file: File = File.applicationStorageDirectory.resolvePath("data.json");
            var fileStream: FileStream = new FileStream();
            fileStream.open(file, FileMode.WRITE);
            //TODO Save user and room data
            //fileStream.writeUTFBytes(JSON.stringify(users) );
            fileStream.close();
        }

        private function addUser(name: String, auth: Object): void
        {
            // Register a new user to users
            //auth["emailVerified"] = false;
            //auth["emailVerificationCode"] = Service.generateKey(1);
            //
            //if (Service.CLOSED_ALPHA)
            //    delete keys[auth.alphaKey];
            //
            //users[name] = {name: name, auth: auth, online: false, timeCreated: new Date().time, nick: null};
            //prepusers(name);
            //
            //var verifyEmailer: Emailer = new Emailer("mail.omgforever.com", 26, "verify@omgforever.com", "OMG4ever");
            //verifyEmailer.send(name, "Verify your Email Address", verifyEmail.replace("%VERIFICATION_CODE%", auth.emailVerificationCode));
        }

        public function sendAll(data: Object): void
        {
            // Send a message to all sessions
            for each (var s: Session in sessions)
                s.send(data);
        }

        public function sendAllUsers(data: Object): void
        {
            // Send a message to all logged in sessions
            for each (var s: Session in sessions)
                s.send(data);
        }

        public function send(session: Session, data: Object): void
        {
            // Send a message to a specific session
            session.send(data);
        }
    }
}