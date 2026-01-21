const mongoose = require('mongoose');

// CONFIG
const URI = "mongodb+srv://manideep:manideep@cluster0.ab1eq3t.mongodb.net/";

async function repair() {
    console.log("Connecting to Repair...");
    const conn = await mongoose.createConnection(URI).asPromise();

    const Workout = conn.model('Workout', new mongoose.Schema({}, { strict: false }));

    // Find records missing BOTH exerciseName AND exercise_name
    const query = {
        exerciseName: { $exists: false },
        exercise_name: { $exists: false }
    };

    const count = await Workout.countDocuments(query);
    console.log(`Found ${count} BROKEN records (missing name).`);

    if (count > 0) {
        console.log("Fixing...");
        const result = await Workout.updateMany(query, {
            $set: { exerciseName: "Unknown Exercise" }
        });
        console.log(`Repaired ${result.modifiedCount} records.`);
    } else {
        console.log("Data is healthy!");
    }

    await conn.close();
}

repair().catch(console.error);
