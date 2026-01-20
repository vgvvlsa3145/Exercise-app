@echo off
echo 🚀 Launching HyperPulseX System...

:: Start Backend
start cmd /k "cd backend && npm install && nodemon server.js"

:: Start Frontend
start cmd /k "cd frontend && flutter run"

echo ✅ Both Backend and Frontend are starting.
echo 🌐 Backend: http://localhost:5000
echo 🦾 Frontend: Checking device connection...
pause
