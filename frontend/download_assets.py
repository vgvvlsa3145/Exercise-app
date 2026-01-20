import urllib.request
import os
import shutil

BASE_URL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/"

# Map sanitized UI name to DB folder name
EXERCISES = {
    "burpees": "Burpee",
    "jumping_jacks": "Jumping_Jack",
    "high_knees": "High_Knees",
    "mountain_climbers": "Mountain_Climber",
    "jump_squats": "Jump_Squat",
    "skaters": "Skater_Hop",
    "butt_kicks": "Butt_Kicks",
    "tuck_jumps": "Tuck_Jump",
    "plank_jacks": "Plank_Jack",
    "sprint_in_place": "Running",
    "push-ups": "Push-up",
    "diamond_push-ups": "Diamond_Push-up",
    "pike_push-ups": "Pike_Push-up",
    "wide_push-ups": "Wide-arm_Push-up",
    "decline_push-ups": "Decline_Push-up",
    "squats": "Squat",
    "lunges": "Lunge",
    "bulgarian_split_squats": "Bulgarian_Split_Squat",
    "glute_bridges": "Glute_Bridge",
    "single-leg_glute_bridges": "Single-leg_Glute_Bridge",
    "calf_raises": "Calf_Raise",
    "dips": "Bench_Dip",
    "plank": "Plank",
    "crunches": "Crunch",
    "bicycle_crunches": "Bicycle_Crunch",
    "leg_raises": "Leg_Raise",
    "side_plank": "Side_Plank",
    "superman_holds": "Superman",
    "wall_sits": "Wall_Sit",
    "pistol_squats": "Pistol_Squat",
    "archer_push-ups": "Archer_Push-up",
    "pseudo_planche_push-ups": "Pseudo_Planche_Push-up",
    "single-leg_deadlifts": "Single-leg_Deadlift",
    "hollow_body_holds": "Hollow_Body_Hold",
    "l-sits": "L-sit",
    "handstand_push-ups": "Handstand_Push-up",
    "nordic_curls": "Nordic_Hamstring_Curl",
    "decline_pike_push-ups": "Decline_Pike_Push-up",
    "v-ups": "V-up"
}

TARGET_DIR = "assets/exercises"
os.makedirs(TARGET_DIR, exist_ok=True)

success_count = 0
fail_count = 0

for filename, db_name in EXERCISES.items():
    local_path = os.path.join(TARGET_DIR, f"{filename}.gif")
    
    # Try JPG first
    url = f"{BASE_URL}{db_name}/0.jpg"
    print(f"Downloading {filename}...")
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            with open(local_path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)
        print(f"  -> OK (JPG)")
        success_count += 1
        continue
    except:
        pass

    # Try GIF if JPG fails
    url = f"{BASE_URL}{db_name}/0.gif"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            with open(local_path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)
        print(f"  -> OK (GIF)")
        success_count += 1
    except:
        print(f"  -> FAILED")
        fail_count += 1

print(f"\nSummary: {success_count} succeeded, {fail_count} failed.")
