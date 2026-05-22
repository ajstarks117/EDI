'use strict';

/**
 * Middleware to create an audit log for sensitive actions.
 * Format: [AUDIT] ISO_TIMESTAMP | action | actor | target | result
 *
 * @param {string} action - The action being performed (e.g., 'TRIGGER_SOS', 'REGISTER_TOURIST')
 */
const auditLog = (action) => {
  return (req, res, next) => {
    // Capture the original send to intercept the response result
    const originalSend = res.send;
    
    res.send = function (body) {
      // Restore original send to avoid infinite loops
      res.send = originalSend;
      
      const timestamp = new Date().toISOString();
      const actor = (req.tourist && req.tourist.id) || (req.authority && req.authority.id) || req.ip;
      
      // Determine the target (usually a path param like ID, or specific body field)
      const target = req.params.id || (req.body && req.body.badge_id) || (req.body && req.body.phone) || 'N/A';
      
      const result = res.statusCode >= 200 && res.statusCode < 300 ? 'SUCCESS' : `FAILURE (${res.statusCode})`;

      console.log(`[AUDIT] ${timestamp} | ${action} | actor:${actor} | target:${target} | result:${result}`);
      
      // Proceed with sending the response
      return res.send(body);
    };

    next();
  };
};

module.exports = { auditLog };
