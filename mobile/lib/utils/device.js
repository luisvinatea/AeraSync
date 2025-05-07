/**
 * Detects the type of device (mobile, tablet, or desktop)
 * @returns {'mobile'|'tablet'|'desktop'} Device type
 */
export const detectDeviceType = () => {
  const ua = navigator.userAgent;
  if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) {
    return "tablet";
  }
  if (
    /Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated|(hpw|web)OS|Opera M(obi|ini)/.test(
      ua
    )
  ) {
    return "mobile";
  }
  return "desktop";
};

/**
 * Applies device-specific optimizations to improve UX
 */
export function applyDeviceOptimizations() {
  // Detect if this is a mobile device
  const isMobile =
    /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
      navigator.userAgent
    );

  if (isMobile) {
    document.body.classList.add("mobile");
    setViewportHeight();

    // Prevent hover effects on mobile
    document.body.classList.add("no-hover");
  }

  // Fix iOS 100vh issue
  window.addEventListener("resize", setViewportHeight);
  setViewportHeight();
}

/**
 * Sets the viewport height CSS property to handle iOS Safari issues
 */
function setViewportHeight() {
  // Calculate viewport height properly on mobile
  const vh = window.innerHeight * 0.01;
  document.documentElement.style.setProperty("--vh", `${vh}px`);
}

/**
 * Applies background styling for different devices
 */
export function applyBackgroundStyles() {
  // Check if device has high memory/performance for animated background
  const performanceLevel = getDevicePerformanceLevel();

  if (performanceLevel === "low") {
    document.body.classList.add("low-performance");
  } else {
    // Initialize animation if it's a higher performance device
    document.body.classList.add("animated-background");
  }
}

/**
 * Estimates device performance level
 * @returns {'low'|'medium'|'high'} Performance classification
 */
function getDevicePerformanceLevel() {
  const isMobile =
    /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
      navigator.userAgent
    );

  const isOlderDevice = /iPhone\s(5|6|7|8)|iPad\sMini|Android\s[4-6]/i.test(
    navigator.userAgent
  );

  // Simple heuristic based on device type and age
  if (isMobile && isOlderDevice) {
    return "low";
  } else if (isMobile) {
    return "medium";
  } else {
    return "high";
  }
}
