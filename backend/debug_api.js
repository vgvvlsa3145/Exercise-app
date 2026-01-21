const https = require('https');

const url = "https://exercise-app-ppo1.onrender.com/api/workout/history/vgvs";

console.log(`Fetching from ${url}...`);

https.get(url, (res) => {
    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            console.log(`Received ${json.length} records.`);
            if (json.length > 0) {
                console.log("SAMPLE RECORD KEYS:");
                console.log(Object.keys(json[0]));
                console.log("\nFULL SAMPLE:");
                console.log(JSON.stringify(json[0], null, 2));
            } else {
                console.log("No history found for user.");
            }
        } catch (e) {
            console.error("JSON Parse Error:", e);
            console.log("Raw Data:", data);
        }
    });

}).on("error", (err) => {
    console.log("Error: " + err.message);
});
