'use strict';

/**
 * Escalation Service
 *
 * Runs a setInterval every 60 seconds to find medium-priority SOS alerts
 * that have been active for > 30 minutes and promote them to critical.
 * Broadcasts SOS_UPDATE via WebSocket for each escalated alert.
 *
 * Start by calling startEscalationService() after the HTTP server begins
 * listening. The returned timer handle can be passed to clearInterval() on
 * graceful shutdown.
 */

const { escalateOverdue } = require('./sosService');

const ESCALATION_INTERVAL_MS = 60 * 1000; // 60 seconds

/**
 * Start the escalation polling loop.
 * @returns {NodeJS.Timeout}  Timer handle (pass to clearInterval on shutdown)
 */
const startEscalationService = () => {
  console.log('[escalation] Auto-escalation service started (interval: 60s).');

  const timer = setInterval(async () => {
    try {
      await escalateOverdue();
    } catch (err) {
      // Never crash the server — log and continue
      console.error('[escalation] Error during escalation run:', err.message);
    }
  }, ESCALATION_INTERVAL_MS);

  // Allow Node to exit even if the timer is still live
  timer.unref();

  return timer;
};

module.exports = { startEscalationService };
