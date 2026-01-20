
class Recommendation {
  final String title;
  final String subtitle;
  final String reason;
  final List<String> steps;

  Recommendation({
    required this.title, 
    required this.subtitle, 
    required this.reason,
    this.steps = const [],
  });
}

class RecommendationService {
  static List<Recommendation> getRecommendations(Map<String, dynamic> profile) {
    if (profile.isEmpty) {
      return [
        Recommendation(
          title: "Quick Start",
          subtitle: "General • 10 min",
          reason: "Complete your profile for personalized picks!",
        )
      ];
    }

    List<Recommendation> list = [];

    // --- EXTRACT DATA POINTS ---
    final goal = profile['q15'] ?? "General Health";
    final injuryType = profile['q7'] ?? "";
    final hasInjury = profile['q6'] == "Yes";
    final hasJointIssues = profile['q8'] == "Yes";
    final isPostpartum = profile['q10'] == "Yes";
    final intensity = profile['q18'] ?? "Medium";
    final equipment = List<String>.from(profile['q32'] ?? ["None"]);
    final hasWeights = equipment.contains("Dumbbells");
    final motivation = (profile['q33'] as num?)?.toDouble() ?? 5.0; // 1-10

    // --- 1. SAFETY & INJURY FILTER (Strict) ---
    bool isRestricted = hasInjury || hasJointIssues || isPostpartum;

    if (isPostpartum) {
       list.add(Recommendation(
         title: "Postpartum Core Recovery",
         subtitle: "Gentle • 10 min",
         reason: "Safe, low-pressure core rebuilding",
       ));
       list.add(Recommendation(
         title: "Pelvic Floor Strengthener",
         subtitle: "Static • 8 min",
         reason: "Essential recovery exercise",
       ));
       // Return early for postpartum to avoid high impact suggestions
       return list; 
    }

    if (hasJointIssues || hasInjury) {
       list.add(Recommendation(
         title: "Low Impact Joints",
         subtitle: "Safe • 15 min",
         reason: "Protects your ${injuryType.isNotEmpty ? injuryType : 'joints'}",
       ));
       list.add(Recommendation(
         title: "Static Strength Builder",
         subtitle: "No Jumping • 12 min",
         reason: "Builds muscle without impact",
       ));
    }

    // --- 2. MOTIVATION BOOST (Psychology) ---
    if (motivation < 5.0) {
       list.add(Recommendation(
         title: "Quick 5-Minute Spark",
         subtitle: "Very Easy • 5 min",
         reason: "Low motivation? Just do this quick one!",
       ));
    }

    // --- 3. GOAL & INTENSITY LOGIC ---
    if (goal == "Weight Loss") {
       if (!isRestricted) {
          list.add(Recommendation(
             title: "HIIT Fat Burner",
             subtitle: "High Intensity • 20 min",
             reason: "Max calories for Weight Loss",
          ));
          // Fasted Cardio Check
          if (profile['q19'] == "Intermittent Fasting") {
             list.add(Recommendation(
                title: "Fasted Morning Cardio",
                subtitle: "Moderate • 15 min",
                reason: "Optimized for your Fasting schedule",
             ));
          } else {
             list.add(Recommendation(
                title: "Jumping Jack Blast",
                subtitle: "Cardio • 15 min",
                reason: "Heart rate boost for fat loss",
             ));
          }
       } else {
          // Restricted Weight Loss
          list.add(Recommendation(
             title: "Power Walk & Tone",
             subtitle: "Low Impact • 20 min",
             reason: "Burn calories safely without jumping",
          ));
       }
    } else if (goal == "Muscle Gain") {
       if (hasWeights) {
          list.add(Recommendation(
             title: "Dumbbell Hyper-Growth",
             subtitle: "Weighted • 25 min",
             reason: "Using your Dumbbells for max gains",
          ));
       }
       list.add(Recommendation(
          title: "Push-up Mastery",
          subtitle: "Strength • \${intensity} • 15 min",
          reason: "Compound movement for upper body mass",
       ));
       list.add(Recommendation(
          title: "Volume Squats",
          subtitle: "Legs • 18 min",
          reason: "Key driver for lower body muscle",
       ));
    } else if (goal == "Flexibility") {
       list.add(Recommendation(
          title: "Deep Yoga Stretch",
          subtitle: "Mobility • 20 min",
          reason: "Meeting your Flexibility goal",
       ));
    } else if (goal == "Endurance") {
       list.add(Recommendation(
          title: "Stamina Builder",
          subtitle: "Continuous • 30 min",
          reason: "Long duration for Endurance",
       ));
    }

    // --- 4. LEVEL ADJUSTMENTS ---
    final level = profile['q21'] ?? "Intermediate";
    if (level == "Beginner" && list.length < 3) {
       list.add(Recommendation(
          title: "Foundations 101",
          subtitle: "Beginner • 12 min",
          reason: "Master the basics first",
       ));
    } else if (level == "Advanced" && !isRestricted) {
       list.add(Recommendation(
          title: "The Gauntlet Challenge",
          subtitle: "Extreme • 30 min",
          reason: "Testing your Advanced fitness",
       ));
    }

    // --- 5. FALLBACK FILLER ---
    if (list.length < 2) {
       list.add(Recommendation(
          title: "Full Body Tone",
          subtitle: "General • 15 min",
          reason: "Balanced daily workout",
       ));
    }

    // Return top 3-4 distinct recommendations
    return list.take(4).toList();
  }
}
