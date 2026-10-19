// Paste your Supabase project values here (Project Settings → API).
// The anon / publishable key is safe to publish: the database rules in
// schema.sql decide who can read and write, not this key.
// Leave both empty to run the board in local demo mode.
window.BOARD_CONFIG = {
  SUPABASE_URL: "https://zzwwhahmddrjkmqoaolj.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_9AFDKqmV4Q_ZvzbrVh289w_hvYLrXf6",

  BOARD_TITLE: "RDT Task Board",
  BOARD_SUBTITLE: "NYU Robotic Design Team · Lunabotics",
  PORTFOLIO_URL: "https://ozanbgurescier.github.io/ozangurescier_portfolio/",

  // Suggested labels in the card editor (you can still type new ones)
  LABELS: ["Excavation", "Deposition", "Electrical", "Locomotion", "Chassis", "Autonomy", "Integration", "Testing"],

  // A column whose name matches this is treated as "finished":
  // its cards are never shown as overdue.
  DONE_COLUMN_PATTERN: "^(done|complete|completed|finished)$"
};
