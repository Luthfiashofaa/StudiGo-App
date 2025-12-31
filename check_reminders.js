const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'http://127.0.0.1:54321',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJhdG9ud25xZHd4YXhzY2p5a3ciLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzM0NTU1MjAwLCJleHAiOjE4OTczMDk2MDB9.x4RG0Ay-XfM8eZEqQFXB2FRqVGiZNu2WjLfKAVxpJds'
);

async function checkReminders() {
  try {
    const { data, error } = await supabase
      .from('reminders')
      .select('id, title, body, category, reminder_at, sent, created_at')
      .order('created_at', { ascending: false })
      .limit(5);
    
    if (error) throw error;
    console.log('Latest reminders:');
    data.forEach(r => {
      console.log(`- ${r.title} (${r.category}): sent=${r.sent}, reminder_at=${r.reminder_at}`);
    });
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkReminders();
