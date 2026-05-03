// Formats an ISO 8601 timestamp as a friendly relative-time string
// ("just now", "2 min ago", "1 day ago"). The returned ref re-evaluates
// every 60 seconds via a shared interval, so any number of devices
// using this stay in sync without each starting their own timer.
//
// Pass a Ref<string|null> or a getter; returns a computed Ref<string>.

import { computed, ref, onMounted, onUnmounted, type Ref, type ComputedRef } from 'vue';

const tickRef = ref(0);
let intervalId: ReturnType<typeof setInterval> | null = null;
let subscriberCount = 0;

function startTicking() {
  if (intervalId !== null)
    return;

  intervalId = setInterval(() => {
    tickRef.value += 1;
  }, 60000);
}

function stopTicking() {
  if (intervalId === null)
    return;

  clearInterval(intervalId);
  intervalId = null;
}

export default function useRelativeTime(
  source: Ref<string | null> | (() => string | null)
): ComputedRef<string> {
  onMounted(() => {
    subscriberCount += 1;
    startTicking();
  });

  onUnmounted(() => {
    subscriberCount -= 1;
    if (subscriberCount <= 0)
      stopTicking();
  });

  return computed(() => {
    void tickRef.value; // dependency

    const iso = typeof source === 'function' ? source() : source.value;
    if (!iso)
      return 'never';

    const ts = new Date(iso).getTime();
    if (isNaN(ts))
      return 'never';

    const diffSec = Math.max(0, Math.round((Date.now() - ts) / 1000));

    if (diffSec < 30)
      return 'just now';
    if (diffSec < 60)
      return `${diffSec} sec ago`;

    const diffMin = Math.round(diffSec / 60);
    if (diffMin < 60)
      return diffMin === 1 ? '1 min ago' : `${diffMin} min ago`;

    const diffHr = Math.round(diffMin / 60);
    if (diffHr < 24)
      return diffHr === 1 ? '1 hour ago' : `${diffHr} hours ago`;

    const diffDay = Math.round(diffHr / 24);
    if (diffDay < 30)
      return diffDay === 1 ? '1 day ago' : `${diffDay} days ago`;

    const diffMonth = Math.round(diffDay / 30);
    if (diffMonth < 12)
      return diffMonth === 1 ? '1 month ago' : `${diffMonth} months ago`;

    const diffYear = Math.round(diffMonth / 12);
    return diffYear === 1 ? '1 year ago' : `${diffYear} years ago`;
  });
}
