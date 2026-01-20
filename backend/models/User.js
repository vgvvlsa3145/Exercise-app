const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    username: { type: String, required: true }, // Display Name (can be duplicate? No, let's keep unique for now or relax it later. User requested separation, usually display names can be dupes but let's stick to unique for simplicity unless asked)
    email: { type: String, required: true, unique: true },
    password: { type: String }, // Optional for now, but recommended
    age: Number,
    gender: String,
    heightCm: Number,
    weightKg: Number,
    fitnessProfile: { type: Object }, // Stores the 35 questionnaire answers
    totalScore: { type: Number, default: 0 },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', UserSchema);
