// API configuration
export const API_URL = process.env.NODE_ENV === 'production' 
  ? 'https://aerasync-api.vercel.app'
  : 'http://localhost:3000';

// App configuration
export const APP_CONFIG = {
  maxAeratorOptions: 5,
  defaultLanguage: 'en',
  supportedLanguages: ['en', 'es'],
  defaultChartColors: [
    'rgba(30, 64, 175, 1)',   // blue-800
    'rgba(220, 38, 38, 1)',    // red-600
    'rgba(16, 185, 129, 1)',   // green-500
    'rgba(217, 119, 6, 1)',    // amber-600
    'rgba(124, 58, 237, 1)',   // violet-600
  ],
  simulationSettings: {
    defaultSafetyMargin: 0,
    defaultAnalysisHorizon: 9,
    defaultHoursPerNight: 8
  }
};
