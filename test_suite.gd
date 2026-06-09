extends SceneTree

func _init():
    print("=== ORBIT SURVIVOR TEST SUITE ===")
    
    # Test 1: SignalBus autoload
    print("\n--- Test 1: SignalBus autoload ---")
    if SignalBus:
        print("OK: SignalBus found")
        var signals = ["game_started", "game_ready", "scene_changed", "player_hit", 
                       "crystal_collected", "portal_reached", "level_selected"]
        for s in signals:
            if SignalBus.has_signal(s):
                print("  OK: signal '", s, "' exists")
            else:
                print("  FAIL: signal '", s, "' MISSING!")
    else:
        print("FAIL: SignalBus not an autoload!")
    
    # Test 2: Globals autoload
    print("\n--- Test 2: Globals autoload ---")
    if Globals:
        print("OK: Globals found")
        if "GAME_SCENE" in Globals:
            print("  OK: GAME_SCENE = ", Globals.GAME_SCENE)
        if "CRYSTAL_SCORE_VALUE" in Globals:
            print("  OK: CRYSTAL_SCORE_VALUE = ", Globals.CRYSTAL_SCORE_VALUE)
    else:
        print("FAIL: Globals not an autoload!")
    
    # Test 3: GameManager
    print("\n--- Test 3: GameManager ---")
    if GameManager:
        print("OK: GameManager found")
        print("  SCENES: ", GameManager.SCENES)
    else:
        print("FAIL: GameManager not an autoload!")
    
    # Test 4: LevelManager
    print("\n--- Test 4: LevelManager ---")
    if LevelManager:
        print("OK: LevelManager found")
        LevelManager.load_level("level_01")
        var data = LevelManager.get_current_level_data()
        if data and data.size() > 0:
            print("  OK: level_01 loaded, ", data.size(), " keys")
            print("  name: ", data.get("name", "MISSING"))
            print("  nodes: ", data.get("nodes", []).size())
            print("  crystals: ", data.get("crystals", []).size())
        else:
            print("  FAIL: level_01 data is empty!")
    else:
        print("FAIL: LevelManager not an autoload!")
    
    # Test 5: Scene loading
    print("\n--- Test 5: Scene loading ---")
    var scenes_to_check = [
        "res://scenes/ui/main_menu.tscn",
        "res://scenes/levels/level_scene.tscn",
        "res://scenes/ui/game_hud.tscn",
        "res://scenes/ui/victory_screen.tscn",
        "res://scenes/ui/game_over_screen.tscn",
        "res://scenes/ui/pause_menu.tscn",
        "res://scenes/ui/level_select.tscn",
        "res://scenes/ui/settings_screen.tscn"
    ]
    for s in scenes_to_check:
        if ResourceLoader.exists(s):
            var scene = load(s)
            if scene:
                print("  OK: ", s)
            else:
                print("  FAIL: ", s, " failed to load!")
        else:
            print("  FAIL: ", s, " doesn't exist!")
    
    # Test 6: Level JSON files
    print("\n--- Test 6: Level JSON files ---")
    for i in range(1, 11):
        var path = "res://data/levels/level_%02d.json" % i
        if FileAccess.file_exists(path):
            print("  OK: level_%02d.json" % i)
        else:
            print("  FAIL: level_%02d.json missing!" % i)
    
    # Test 7: Audio files
    print("\n--- Test 7: Audio files ---")
    var audio_files = [
        "res://assets/audio/sfx/tap.wav",
        "res://assets/audio/sfx/crystal.wav",
        "res://assets/audio/sfx/hit.wav",
        "res://assets/audio/sfx/victory.wav",
        "res://assets/audio/sfx/portal.wav",
        "res://assets/audio/sfx/button.wav",
        "res://assets/audio/sfx/game_over.wav",
        "res://assets/audio/music/music_menu.wav"
    ]
    for a in audio_files:
        if FileAccess.file_exists(a):
            print("  OK: ", a)
        else:
            print("  FAIL: ", a, " missing!")
    
    # Test 8: Simulate game flow (without visuals)
    print("\n--- Test 8: Simulating game flow ---")
    print("Emitting game_started...")
    SignalBus.game_started.emit()
    print("After emit, scene should change to: ", Globals.GAME_SCENE)
    
    print("\n=== TEST SUITE COMPLETE ===")
    quit(0)
