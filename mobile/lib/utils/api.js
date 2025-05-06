import { API_URL } from '../config.js';

export const apiService = {
  async getBaseData() {
    try {
      const response = await fetch(`${API_URL}/aerator-types`);
      if (!response.ok) throw new Error('Network response was not ok');
      return await response.json();
    } catch (error) {
      console.error('Error fetching aerator types:', error);
      throw error;
    }
  },
  
  async submitSurvey(data) {
    try {
      const response = await fetch(`${API_URL}/compare`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      });
      
      if (!response.ok) throw new Error('Network response was not ok');
      return await response.json();
    } catch (error) {
      console.error('Error submitting survey:', error);
      throw error;
    }
  }
};