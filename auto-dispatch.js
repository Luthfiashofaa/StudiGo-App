// Auto-dispatch reminders every minute
// Run: node auto-dispatch.js

const SUPABASE_URL = "https://batonwnqdwxaxcsjykxw.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhdG9ud25xZHd4YXhjc2p5a3h3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU1OTk1MTYsImV4cCI6MjA0MTE3NTUxNn0.Caa6WsKy-dWpJmVnfVj_8c9K-jcKevW3aqX0qEMVWVw";

async function dispatch() {
  try {
    const response = await fetch(
      `${SUPABASE_URL}/functions/v1/send-reminder/dispatch`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${SUPABASE_KEY}`
        }
      }
    );
    
    const data = await response.json();
    const time = new Date().toLocaleTimeString('id-ID');
    console.log(`[${time}] Dispatched:`, data);
  } catch (error) {
    const time = new Date().toLocaleTimeString('id-ID');
    console.error(`[${time}] Error:`, error.message);
  }
}

// Run immediately
dispatch();

// Then run every minute
setInterval(dispatch, 60000);

console.log('🚀 Auto-dispatch started. Running every minute...');
console.log('Press Ctrl+C to stop');
