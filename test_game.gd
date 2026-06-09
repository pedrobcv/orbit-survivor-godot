extends SceneTree

func _init():
    print("=== INIT ===")
    # Wait a few frames then simulate pressing play
    var timer = create_timer(2.0)
    timer.timeout.connect(_check_and_play)
    root.size = Vector2i(720, 1280)

func _check_and_play():
    print("Checking main menu...")
    # Try to find the main menu
    var mm = root.get_child(root.get_child_count() - 1)
    if mm and mm.has_method("_on_play_pressed"):
        print("Found main menu, simulating PLAY button...")
        mm._on_play_pressed()
    else:
        print("Main menu not found, children:")
        for c in root.get_children():
            print("  ", c.name, " - ", c.get_class())
    
    # Check after 3 more seconds what scene we're on
    var timer2 = create_timer(3.0)
    timer2.timeout.connect(_check_after_play)

func _check_after_play():
    print("=== Current scene state ===")
    for c in root.get_children():
        print("  Child: ", c.name, " class: ", c.get_class())
        if c.get_child_count() > 0:
            for cc in c.get_children():
                print("    ", cc.name, " - ", cc.get_class(), " children:", cc.get_child_count())
    
    # Check for runtime errors
    print("=== Checking runtime errors ===")
    # Take screenshot
    print("Game should be running...")
    quit(0)
