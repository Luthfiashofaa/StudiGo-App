#!/usr/bin/env node
/**
 * Auto-dispatch reminders every minute
 * Usage: node auto-dispatch-simple.js
 * 
 * This is the simplest solution while we setup cron properly
 */

const SUPABASE_URL = "https://batonwnqdwxaxcsjykxw.supabase.co";
const SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhdG9ud25xZHd4YXhjc2p5a3h3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNTU5OTUxNiwiZXhwIjoyMDQxMTc1NTE2fQ.yCRPazIjjFQh0Ow0jP-d3xkK4sKJqkdOqHHGddMQjNc";

async function dispatchReminders() {
  try {
    const timestamp = new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' });
    
    const response = await fetch(
      `${SUPABASE_URL}/functions/v1/send-reminder/dispatch`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const data = await response.json();
    
    if (response.ok) {
      console.log(`✅ [${timestamp}] Dispatched:`, data);
    } else {
      console.error(`❌ [${timestamp}] Error:`, data);
    }
  } catch (error) {
    console.error(`⚠️  [${new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' })}] Connection error:`, error.message);
  }
}

// Run immediately
console.log('🚀 Starting auto-dispatch...');
dispatchReminders();

// Then every minute
setInterval(dispatchReminders, 60000);

console.log('⏰ Will dispatch reminders every minute');
console.log('📲 Press Ctrl+C to stop\n');
