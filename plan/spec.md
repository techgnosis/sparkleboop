the goal is to create an android game that is a clone of Bejeweled. The rules of Bejeweled are well documented.

The game is called "Sparkleboop"

your environment has a running `adb` server attached to an android emulator. You need to start `flutter run --machine` and then communicate with it to read the state of the app and to do hot reloads so I can see the progress.

You have a series of scripts at ./scripts. You wrote those scripts and have said they are efficient many times so please use them.

Have the opening screen of the app just say "New Game", "Continue", and "Exit". There are no options. Let the game go on for 20 levels. If you beat level 20, you win. If you exit the game and come back and pick "Continue" then you start at the beginning of whatever level you left at. Picking "New Game" starts you at level 1.

I don't have any graphics or sprites available so you'll need to draw the jewels.

Always use 'bd' to track your work. NEVER write any plans or use markdown files to track any work. ALWAYS use 'bd'.

Breakdown the tasks you need to write the game into epics and issues in 'bd'.
