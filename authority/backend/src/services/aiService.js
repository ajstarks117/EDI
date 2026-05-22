'use strict';

const fs = require('fs');
const path = require('path');
const { query } = require('../config/db');

// Fallback JSON path
const KNOWLEDGE_BASE_PATH = path.join(__dirname, '../data/emergency_knowledge_base.json');

const KEYWORDS = [
  'injured', 'trapped', 'attack', 'bleeding', 'fire',
  'drowning', 'unconscious', 'snake bite', 'heart', "can't move"
];

// Helper to check for active zones using PostGIS
const getActiveZonesForPosition = async (lat, lng) => {
  if (lat === undefined || lng === undefined) return [];
  try {
    const { rows } = await query(
      `SELECT name, zone_type FROM geofence_zones 
       WHERE is_active = true AND ST_Contains(geom, ST_SetSRID(ST_MakePoint($1, $2), 4326))`
      , [lng, lat]
    );
    return rows.map(r => `${r.name} (${r.zone_type})`);
  } catch (err) {
    console.error('Error fetching active zones for position:', err.message);
    return [];
  }
};

const getFallbackResponse = (message) => {
  try {
    const data = JSON.parse(fs.readFileSync(KNOWLEDGE_BASE_PATH, 'utf8'));
    const lowerMessage = message.toLowerCase();
    for (const [key, entry] of Object.entries(data)) {
      if (entry.keywords.some(kw => lowerMessage.includes(kw.toLowerCase()))) {
        return entry.response;
      }
    }
    return "I am an offline safety assistant. Please call emergency services if you are in immediate danger. If safe, try to find a secure location.";
  } catch (err) {
    console.error('Error reading emergency knowledge base:', err.message);
    return "Emergency services recommended. Cannot access offline knowledge base.";
  }
};

const callAnthropic = async (systemPrompt, message) => {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error("ANTHROPIC_API_KEY is not set");
  
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 400,
      system: systemPrompt,
      messages: [{ role: "user", content: message }]
    })
  });
  
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Anthropic API error: ${response.status} ${errorText}`);
  }
  
  const data = await response.json();
  return data.content[0].text;
};

const callGemini = async (systemPrompt, message) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error("GEMINI_API_KEY is not set");
  
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [
        { role: 'user', parts: [{ text: systemPrompt + "\\n\\nUser Message: " + message }] }
      ]
    })
  });
  
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Gemini API error: ${response.status} ${errorText}`);
  }
  
  const data = await response.json();
  return data.candidates[0].content.parts[0].text;
};

/**
 * processQuery(tourist, message, lat, lng)
 */
const processQuery = async (tourist, message, lat, lng) => {
  // Check explicit emergency keywords first (Step 3)
  const lowerMessage = message.toLowerCase();
  const hasEmergencyKeyword = KEYWORDS.some(kw => lowerMessage.includes(kw));

  // Step 1 — Build context
  const active_zones = await getActiveZonesForPosition(lat, lng);
  const name = tourist.full_name || 'Tourist';
  const blood_group = tourist.blood_group || 'Unknown';
  
  // Note: languages might not be in the DB strictly as an array. Assuming 'English' if missing.
  const languages = tourist.languages || ['English'];
  
  // Step 2 — System prompt
  const systemPrompt = `You are an offline emergency safety assistant for TravelSure.
Tourist name: ${name}. Blood group: ${blood_group}.
Active zones: ${active_zones.join(', ') || 'None'}.
Respond in: ${languages[0] || 'English'}.
If IMMEDIATE danger: start response with EXACTLY: SOS_TRIGGER`;

  let responseText = '';
  let providerUsed = process.env.AI_PROVIDER || 'anthropic';
  let fallback = false;

  try {
    // Step 4 — Call LLM
    if (providerUsed === 'anthropic') {
      responseText = await callAnthropic(systemPrompt, message);
    } else if (providerUsed === 'gemini') {
      responseText = await callGemini(systemPrompt, message);
    } else {
      throw new Error(`Unsupported AI_PROVIDER: ${providerUsed}`);
    }
  } catch (err) {
    console.error('LLM API failed, using fallback:', err.message);
    responseText = getFallbackResponse(message);
    fallback = true;
    providerUsed = 'fallback';
  }

  // Step 5 — Detect SOS
  const sos_triggered = responseText.startsWith('SOS_TRIGGER ') || hasEmergencyKeyword;
  
  if (responseText.startsWith('SOS_TRIGGER ')) {
    responseText = responseText.replace('SOS_TRIGGER ', '').trim();
  }

  // Step 6 — Return
  return {
    response: responseText,
    sos_triggered,
    intent: 'chat', // default
    provider: providerUsed,
    ...(fallback && { fallback: true })
  };
};

module.exports = {
  processQuery
};
