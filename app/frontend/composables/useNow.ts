import { ref, onScopeDispose } from 'vue';

// Shared 1 Hz clock. N countdowns cost one interval, not N. The timer runs
// only while a consumer is mounted, and pauses while the tab is hidden.
const now = ref(Date.now());
let consumers = 0;
let timerId: ReturnType<typeof setInterval> | null = null;

function tick() {
  now.value = Date.now();
}

function start() {
  if (timerId !== null)
    return;
  tick();
  timerId = setInterval(tick, 1000);
}

function stop() {
  if (timerId === null)
    return;
  clearInterval(timerId);
  timerId = null;
}

function handleVisibility() {
  if (document.hidden)
    stop();
  else if (consumers > 0)
    start(); // tick() inside start() snaps to the correct value on return
}

export function useNow() {
  if (consumers === 0) {
    start();
    document.addEventListener('visibilitychange', handleVisibility);
  }
  consumers++;

  onScopeDispose(() => {
    consumers--;
    if (consumers === 0) {
      stop();
      document.removeEventListener('visibilitychange', handleVisibility);
    }
  });

  return now;
}
