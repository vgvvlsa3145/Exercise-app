const mongoose = require('mongoose');

const ExerciseSchema = new mongoose.Schema({
    title: { type: String, required: true },
    subtitle: { type: String, required: true },
    goals: [String], // ["Weight Loss", "Muscle Gain", etc]
    equipmentNeeded: [String], // ["Dumbbells", "None", etc]
    location: { type: String, enum: ["Home", "Gym", "Outdoor", "Any"], default: "Any" },
    intensity: { type: String, enum: ["Low", "Medium", "High"] },
    isInjurySafe: { type: Boolean, default: true },
    difficulty: { type: String, enum: ["Beginner", "Intermediate", "Advanced"] },
    steps: [String], // Step-by-step instructions
    description: String,
});

module.exports = mongoose.model('Exercise', ExerciseSchema);
