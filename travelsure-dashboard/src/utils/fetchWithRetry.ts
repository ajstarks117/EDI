import { useUIStore } from '../store/useUIStore';

export async function fetchWithRetry<T>(
  fetchFn: () => Promise<T>,
  options: {
    maxRetries?: number;
    baseDelay?: number;
    errorContext?: string;
  } = {}
): Promise<T> {
  const { maxRetries = 3, baseDelay = 1000, errorContext = 'Operation' } = options;
  const { addToast } = useUIStore.getState();

  let attempt = 0;

  while (attempt < maxRetries) {
    try {
      return await fetchFn();
    } catch (error) {
      attempt++;
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      console.warn(`[${errorContext}] Attempt ${attempt}/${maxRetries} failed:`, errorMessage);

      if (attempt === maxRetries) {
        addToast({
          message: `${errorContext} failed after ${maxRetries} attempts. Please try again later.`,
          type: 'error',
        });
        throw error;
      }

      // Exponential backoff
      const delay = baseDelay * Math.pow(2, attempt - 1);
      
      // We don't want to spam toasts for every internal retry, but maybe on the 2nd failure we notify
      if (attempt === 2) {
        addToast({
          message: `Network instability detected. Retrying ${errorContext.toLowerCase()}...`,
          type: 'info',
        });
      }

      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error('Unreachable');
}
