const mongoose = require('mongoose');

// CONFIG
const URI = "mongodb+srv://manideep:manideep@cluster0.ab1eq3t.mongodb.net/";

async function check() {
    console.log("Connecting...");
    const conn = await mongoose.createConnection(URI).asPromise();

    // Schema - timestamp is stored as String usually based on migration
    const Workout = conn.model('Workout', new mongoose.Schema({
        timestamp: String,
        username: String,
        exerciseName: String
    }, { strict: false }));

    // Query for String starting with "2026-01-20"
    // Note: If you stored them as ISO Dates in Mongo, this regex won't work on Date objects.
    // But migration copied raw data, and previous cat showed: timestamp: '2026-01-20T15:07:12.828216'

    console.log("Searching for 2026-01-20...");

    // Check for VALID data (reps > 0)
    const validCount = await Workout.countDocuments({
        timestamp: { $regex: /^2026-01-20/ },
        reps: { $gt: 0 }
    });
    console.log(`Found VALID records (reps > 0): ${validCount}`);

    // Try Regex (for String)
    const countStr = await Workout.countDocuments({ timestamp: { $regex: /^2026-01-20/ } });

    // Try Date Range (for Date objects, just in case)
    const start = new Date("2026-01-20T00:00:00Z");
    const end = new Date("2026-01-20T23:59:59Z");
    const countDate = await Workout.countDocuments({ timestamp: { $gte: start, $lte: end } });

    console.log(`Found MATCHING (String Regex): ${countStr}`);
    console.log(`Found MATCHING (Date Object): ${countDate}`);

    if (countStr > 0) {
        const samples = await Workout.find({ timestamp: { $regex: /^2026-01-20/ } }).limit(5);
        console.log("\n--- SAMPLES ---");
        samples.forEach(s => {
            console.log(JSON.stringify(s, null, 2));
        });
    }

    await conn.close();
}

check().catch(console.error);
