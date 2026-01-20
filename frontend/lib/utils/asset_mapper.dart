
class AssetMapper {
  static String getGifPath(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    // --- WEIGHT LOSS ---
    if (name.contains("burpee")) return "assets/exercises/burpees.gif";
    if (name.contains("jump") && name.contains("jack")) return "assets/exercises/jumping_jacks.gif";
    if (name.contains("high knee")) return "assets/exercises/high_knees.gif";
    if (name.contains("mountain")) return "assets/exercises/mountain_climbers.gif";
    if (name.contains("jump squat")) return "assets/exercises/jump_squats.gif";
    if (name.contains("skater")) return "assets/exercises/skaters.gif";
    if (name.contains("butt kick")) return "assets/exercises/butt_kicks.gif";
    if (name.contains("tuck")) return "assets/exercises/tuck_jumps.gif";
    if (name.contains("plank jack")) return "assets/exercises/plank_jacks.gif";
    if (name.contains("sprint")) return "assets/exercises/sprint.gif";

    // --- WEIGHT GAIN / MUSCLE (PUSHUPS) ---
    if (name.contains("diamond")) return "assets/exercises/diamond_pushups.gif";
    if (name.contains("pike") && name.contains("decline")) return "assets/exercises/decline_pike.gif";
    if (name.contains("pike")) return "assets/exercises/pike_pushups.gif";
    if (name.contains("wide")) return "assets/exercises/wide_pushups.gif";
    if (name.contains("decline")) return "assets/exercises/decline_pushups.gif";
    if (name.contains("archer")) return "assets/exercises/archer_pushups.gif";
    if (name.contains("pseudo")) return "assets/exercises/pseudo_pushups.gif";
    if (name.contains("handstand")) return "assets/exercises/handstand_pushups.gif";
    if (name.contains("pull")) return "assets/exercises/dips.gif"; // Placeholder until file exists
    if (name.contains("push")) return "assets/exercises/push-ups.gif"; // Default pushup

    // --- LEGS ---
    if (name.contains("pistol")) return "assets/exercises/pistol_squats.gif";
    if (name.contains("bulgarian")) return "assets/exercises/bulgarian_split_squats.gif";
    if (name.contains("squat")) return "assets/exercises/squats.gif"; // Revert to plural (real file)
    if (name.contains("lunge")) return "assets/exercises/lunges.gif";
    if (name.contains("calf")) return "assets/exercises/calf_raises.gif";
    if (name.contains("dip")) return "assets/exercises/dips.gif";
    if (name.contains("nordic")) return "assets/exercises/nordic_curls.gif";
    if (name.contains("deadlift")) return "assets/exercises/single_leg_deadlift.gif";

    // --- GLUTES ---
    if (name.contains("single") && (name.contains("glute") || name.contains("bridge"))) return "assets/exercises/single_leg_bridge.gif";
    if (name.contains("glute") || name.contains("bridge")) return "assets/exercises/glute_bridges.gif";

    // --- ABS / CORE ---
    if (name.contains("bicycle")) return "assets/exercises/bicycle_crunches.gif";
    if (name.contains("crunch")) return "assets/exercises/crunches.gif";
    if (name.contains("leg raise")) return "assets/exercises/leg_raises.gif";
    if (name.contains("v-up")) return "assets/exercises/v_ups.gif";
    if (name.contains("side plank")) return "assets/exercises/side_plank.gif";
    if (name.contains("plank")) return "assets/exercises/plank.gif";
    if (name.contains("superman")) return "assets/exercises/superman.gif";
    if (name.contains("hollow")) return "assets/exercises/hollow_body.gif";
    if (name.contains("l-sit")) return "assets/exercises/l_sit.gif";
    if (name.contains("wall sit")) return "assets/exercises/wall_sit.gif";

    // Default Fallback
    return "assets/exercises/squats.gif";
  }
}
