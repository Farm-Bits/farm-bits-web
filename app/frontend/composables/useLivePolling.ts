import { ref, onUnmounted } from 'vue';

export function useLivePolling(
  fetchFn: () => Promise<void>,
  options: {
  intervalMs?: number;
  immediate?: boolean;
} = {}) {
  const { intervalMs = 30000, immediate = true } = options;

  const isPolling = ref(false);
  const isPaused = ref(false);
  const lastPollAt = ref<Date | null>(null);
  let timerId: ReturnType<typeof setInterval> | null = null;

  async function pollNow() {
    if (isPaused.value)
      return;

    try {
      await fetchFn();
      lastPollAt.value = new Date();
    } catch (error) {
      console.error('Polling error:', error);
    }
  }

  function start(): void {
    if (timerId)
      return;

    isPolling.value = true;
    isPaused.value = false;

    if (immediate)
      pollNow();

    timerId = setInterval(pollNow, intervalMs);
  }

  function stop(): void {
    if (timerId) {
      clearInterval(timerId);
      timerId = null;
    }
    isPolling.value = false;
    isPaused.value = false;
  }

  function pause(): void {
    isPaused.value = true;
  }

  function resume(): void {
    isPaused.value = false;
    pollNow();
  }

  onUnmounted(() => {
    stop();
  });

  return {
    isPolling,
    isPaused,
    lastPollAt,
    start,
    stop,
    pause,
    resume,
    pollNow,
  };
}
