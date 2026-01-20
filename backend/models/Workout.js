const mongoose = require('mongoose');

const WorkoutSchema = new mongoose.Schema({
    username: { type: String, required: true },
    exerciseName: { type: String, required: true },
    reps: { type: Number, default: 0 },
    durationSec: { type: Number, default: 0 },
    accuracy: { type: Number, default: 0 },
    caloriesBurned: { type: Number, default: 0 },
    timestamp: { type: String, default: () => new Date().toISOString() }
});

module.exports = mongoose.model('Workout', WorkoutSchema);
